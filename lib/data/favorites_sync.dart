import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_gate.dart';

class FavoriteEntry {
  const FavoriteEntry({
    required this.isFavorite,
    required this.updatedAt,
    required this.pending,
  });

  final bool isFavorite;
  final DateTime updatedAt;
  final bool pending;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'isFavorite': isFavorite,
    'updatedAt': updatedAt.toIso8601String(),
    'pending': pending,
  };

  factory FavoriteEntry.fromJson(Map<String, dynamic> json) {
    return FavoriteEntry(
      isFavorite: json['isFavorite'] as bool? ?? false,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      pending: json['pending'] as bool? ?? false,
    );
  }

  FavoriteEntry copyWith({bool? isFavorite, DateTime? updatedAt, bool? pending}) {
    return FavoriteEntry(
      isFavorite: isFavorite ?? this.isFavorite,
      updatedAt: updatedAt ?? this.updatedAt,
      pending: pending ?? this.pending,
    );
  }
}

class FavoritesSyncService with WidgetsBindingObserver {
  FavoritesSyncService({SupabaseClient? client})
    : _client = client ?? SupabaseGate.client;

  static const String _table = 'salgo_favorites';
  static const String storageKey = 'salgo_favorites_v1';
  static const int _maxAttemptsPerCycle = 3;
  static const Duration _signInTimeout = Duration(seconds: 8);
  static const Duration _signOutTimeout = Duration(seconds: 5);

  final SupabaseClient? _client;
  SharedPreferences? _storage;
  String? _ownerId;
  final Map<int, FavoriteEntry> _items = <int, FavoriteEntry>{};
  final ValueNotifier<String?> errorNotifier = ValueNotifier<String?>(null);
  bool _observerAdded = false;
  bool _disposed = false;
  bool _cycleRunning = false;
  int _generation = 0;

  String? get ownerId => _ownerId;

  Map<int, FavoriteEntry> get items =>
      Map<int, FavoriteEntry>.unmodifiable(_items);

  Future<void> init() async {
    if (!_observerAdded && !_disposed) {
      WidgetsBinding.instance.addObserver(this);
      _observerAdded = true;
    }
    try {
      _storage ??= await SharedPreferences.getInstance();
    } on Object {
      _storage = null;
    }

    final String? raw = _storage?.getString(storageKey);
    if (raw != null) {
      try {
        final Map<String, dynamic> data =
            jsonDecode(raw) as Map<String, dynamic>;
        _ownerId = data['ownerId'] as String?;
        _items.clear();
        final Object? rawItems = data['items'];
        if (rawItems is Map<String, dynamic>) {
          rawItems.forEach((String key, dynamic value) {
            final int? id = int.tryParse(key);
            if (id != null && value is Map<String, dynamic>) {
              _items[id] = FavoriteEntry.fromJson(value);
            }
          });
        }
      } on Object {
        _items.clear();
        _ownerId = null;
        await _storage?.remove(storageKey);
      }
    }
    await _flushPendingCycle(generation: _generation, suppressErrors: true);
  }

  void enqueue(int placeId, bool isFavorite) {
    _items[placeId] = FavoriteEntry(
      isFavorite: isFavorite,
      updatedAt: DateTime.now().toUtc(),
      pending: true,
    );
    unawaited(_persist());
    unawaited(_flushPendingCycle(generation: _generation, maxAttempts: 1));
  }

  Future<void> onSignedIn(String userId) async {
    final int generation = ++_generation;
    try {
      await _performSignIn(userId, generation).timeout(_signInTimeout);
    } on Object {
      if (generation == _generation && !_disposed) {
        _report(
          'No se pudieron sincronizar tus favoritos. Se reintentará más tarde.',
        );
      }
    }
  }

  Future<void> onSignedOut() async {
    final int generation = ++_generation;
    await _flushPendingCycle(
      generation: generation,
      suppressErrors: true,
      maxAttempts: 1,
    ).timeout(_signOutTimeout).catchError((Object _) async {});

    if (generation != _generation || _disposed) return;
    _items.clear();
    _ownerId = null;
    await _persist();
  }

  Future<void> _performSignIn(String userId, int generation) async {
    if (_ownerId != null && _ownerId != userId) {
      _items.clear();
    }
    _ownerId = userId;
    await _persist();

    final SupabaseClient? client = _client;
    if (client != null) {
      final List<Map<String, dynamic>> rows = await client
          .from(_table)
          .select()
          .eq('user_id', userId);
      if (generation != _generation) return;

      for (final Map<String, dynamic> row in rows) {
        final int? placeId = (row['place_id'] as num?)?.toInt();
        if (placeId == null) continue;
        final DateTime remoteAt =
            DateTime.tryParse(row['updated_at'] as String? ?? '')?.toUtc() ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
        final FavoriteEntry remote = FavoriteEntry(
          isFavorite: row['is_favorite'] as bool? ?? false,
          updatedAt: remoteAt,
          pending: false,
        );
        final FavoriteEntry? local = _items[placeId];
        if (local == null || !local.updatedAt.isAfter(remoteAt)) {
          _items[placeId] = remote;
        }
      }
      await _persist();
    }

    await _flushPendingCycle(generation: generation);
  }

  Future<void> _flushPendingCycle({
    required int generation,
    bool suppressErrors = false,
    int maxAttempts = _maxAttemptsPerCycle,
  }) async {
    if (_cycleRunning) return;
    final SupabaseClient? client = _client;
    final String? userId = client?.auth.currentUser?.id ?? _ownerId;
    if (client == null || userId == null) return;

    final List<int> pendingIds = _items.entries
        .where((MapEntry<int, FavoriteEntry> entry) => entry.value.pending)
        .map((MapEntry<int, FavoriteEntry> entry) => entry.key)
        .toList();
    if (pendingIds.isEmpty) return;

    _cycleRunning = true;
    try {
      for (int attempt = 0; attempt < maxAttempts; attempt++) {
        if (generation != _generation) return;
        if (attempt > 0) {
          await Future<void>.delayed(Duration(seconds: attempt));
        }
        bool allSent = true;
        for (final int placeId in pendingIds) {
          final FavoriteEntry? entry = _items[placeId];
          if (entry == null || !entry.pending) continue;
          if (generation != _generation) return;
          try {
            await client.from(_table).upsert(<String, dynamic>{
              'user_id': userId,
              'place_id': placeId,
              'is_favorite': entry.isFavorite,
              'updated_at': entry.updatedAt.toUtc().toIso8601String(),
            });
            if (generation == _generation) {
              _items[placeId] = entry.copyWith(pending: false);
            }
          } on Object {
            allSent = false;
            break;
          }
        }
        if (allSent) {
          await _persist();
          return;
        }
      }
    } finally {
      _cycleRunning = false;
    }

    if (!suppressErrors && generation == _generation && !_disposed) {
      _report(
        'No se pudieron sincronizar tus favoritos. Se reintentará al abrir la app.',
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_disposed) {
      unawaited(_flushPendingCycle(generation: _generation));
    }
  }

  void _report(String message) => errorNotifier.value = message;

  Future<void> _persist() async {
    await _storage
        ?.setString(
          storageKey,
          jsonEncode(<String, dynamic>{
            'ownerId': _ownerId,
            'items': _items.map(
              (int key, FavoriteEntry value) =>
                  MapEntry<String, dynamic>(key.toString(), value.toJson()),
            ),
          }),
        )
        .catchError((Object _) async => false);
  }

  void dispose() {
    _disposed = true;
    if (_observerAdded) {
      WidgetsBinding.instance.removeObserver(this);
      _observerAdded = false;
    }
    errorNotifier.dispose();
  }
}
