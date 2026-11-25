import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_preferences.dart';
import 'user_preferences_repository.dart';

class PreferencesRepository extends ChangeNotifier {
  PreferencesRepository._internal();
  static PreferencesRepository _instance = PreferencesRepository._internal();
  factory PreferencesRepository() => _instance;

  static void resetForTesting() {
    _instance = PreferencesRepository._internal();
  }

  static const String _storageKey = 'salgo_preferences';

  String? _plan;
  double _budget = 0;
  String? _companion;
  String? _place;
  double _minutes = 0;

  SharedPreferences? _storage;
  UserPreferencesRepository? _remote;
  String? _userId;
  bool _isSyncing = false;
  final ValueNotifier<String?> syncError = ValueNotifier<String?>(null);

  String? get plan => _plan;
  double get budget => _budget;
  String? get companion => _companion;
  String? get place => _place;
  double get minutes => _minutes;
  bool get isSyncing => _isSyncing;

  bool get hasData =>
      _plan != null ||
      _companion != null ||
      _place != null ||
      _budget > 0 ||
      _minutes > 0;

  Future<void> init(
    SharedPreferences? storage, {
    UserPreferencesRepository? remote,
  }) async {
    _storage = storage;
    _remote = remote ?? UserPreferencesRepository();
    if (storage == null) return;
    try {
      final String? raw = storage.getString(_storageKey);
      if (raw == null) return;
      final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;
      fromMap(data);
    } catch (_) {
      try {
        await storage.remove(_storageKey);
      } catch (_) {}
    }
  }

  Future<void> saveAll({
    required String? plan,
    required double budget,
    required String? companion,
    required String? place,
    required double minutes,
  }) async {
    _plan = plan;
    _budget = budget;
    _companion = companion;
    _place = place;
    _minutes = minutes;
    await _persist();
    notifyListeners();
    await _saveRemote();
  }

  Future<void> onSignedIn(String userId) async {
    if (_isSyncing) return;
    final UserPreferencesRepository? remote = _remote;
    if (remote == null) return;

    _userId = userId;
    _isSyncing = true;
    syncError.value = null;
    notifyListeners();

    try {
      final UserPreferencesFetchResult result = await remote.fetchOrCreate(
        userId,
        _toModel(),
      );
      if (result.error != null) {
        syncError.value = result.error;
        return;
      }
      final UserPreferences? preferences = result.preferences;
      if (preferences != null) {
        _apply(preferences);
        await _persist();
      }
    } on Object {
      syncError.value = 'No se pudieron cargar tus preferencias.';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> onSignedOut() async {
    _userId = null;
    _plan = null;
    _budget = 0;
    _companion = null;
    _place = null;
    _minutes = 0;
    syncError.value = null;
    try {
      await _storage?.remove(_storageKey);
    } catch (_) {}
    notifyListeners();
  }

  void updatePlan(String? plan) {
    _plan = plan;
    notifyListeners();
  }

  void updateBudget(double budget) {
    _budget = budget;
    notifyListeners();
  }

  void updateCompanion(String? companion) {
    _companion = companion;
    notifyListeners();
  }

  void updatePlace(String? place) {
    _place = place;
    notifyListeners();
  }

  void updateMinutes(double minutes) {
    _minutes = minutes;
    notifyListeners();
  }

  Map<String, dynamic> toMap() {
    return {
      'plan': _plan,
      'budget': _budget,
      'companion': _companion,
      'place': _place,
      'minutes': _minutes,
    };
  }

  void fromMap(Map<String, dynamic> map) {
    _plan = map['plan'] as String?;
    _budget = (map['budget'] as num?)?.toDouble() ?? 0;
    _companion = map['companion'] as String?;
    _place = map['place'] as String?;
    _minutes = (map['minutes'] as num?)?.toDouble() ?? 0;
    notifyListeners();
  }

  Future<void> _saveRemote() async {
    final String? userId = _userId;
    final UserPreferencesRepository? remote = _remote;
    if (userId == null || remote == null) return;
    final String? error = await remote.upsert(_toModel());
    if (error != null && !_isSyncing) syncError.value = error;
  }

  UserPreferences _toModel() {
    final DateTime now = DateTime.now().toUtc();
    return UserPreferences(
      userId: _userId ?? '',
      plan: _plan,
      budget: _budget,
      companion: _companion,
      place: _place,
      minutes: _minutes,
      createdAt: now,
      updatedAt: now,
    );
  }

  void _apply(UserPreferences preferences) {
    _plan = preferences.plan;
    _budget = preferences.budget;
    _companion = preferences.companion;
    _place = preferences.place;
    _minutes = preferences.minutes;
  }

  Future<void> _persist() async {
    try {
      await _storage?.setString(_storageKey, jsonEncode(toMap()));
    } catch (_) {}
  }

  @override
  void dispose() {
    syncError.dispose();
    super.dispose();
  }
}
