import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_state.dart';
import '../models/place.dart';
import 'mock_data.dart';
import 'notification_states_repository.dart';
import 'preferences_repository.dart';

class AppNotification {
  final int placeId;
  final String title;
  final String message;
  final List<String> tags;
  bool isRead;

  AppNotification({
    required this.placeId,
    required this.title,
    required this.message,
    required this.tags,
    required this.isRead,
  });
}

class NotificationsRepository extends ChangeNotifier {
  NotificationsRepository({PreferencesRepository? preferences})
    : _prefs = preferences ?? PreferencesRepository();

  static const String _storageKey = 'salgo_notifications_state';

  final PreferencesRepository _prefs;
  SharedPreferences? _storage;
  NotificationStatesRepository? _remote;
  String? _userId;
  bool _isLoadingStates = false;
  bool notificationsEnabled = true;
  final ValueNotifier<String?> syncError = ValueNotifier<String?>(null);

  List<AppNotification> _notifications = <AppNotification>[];
  final Map<int, bool> _readById = <int, bool>{};
  final Set<int> _dismissedIds = <int>{};

  List<AppNotification> get notifications =>
      List<AppNotification>.unmodifiable(_notifications);

  Set<int> get dismissedIds => _dismissedIds;

  bool get hasPreferences => _prefs.hasData;
  bool get isLoadingStates => _isLoadingStates;

  int get unreadCount => _notifications
      .where(
        (AppNotification notification) =>
            !notification.isRead &&
            !_dismissedIds.contains(notification.placeId),
      )
      .length;

  Future<void> init(
    SharedPreferences? storage, {
    NotificationStatesRepository? remote,
  }) async {
    _storage = storage;
    _remote = remote ?? NotificationStatesRepository();
    if (storage != null) {
      try {
        final String? raw = storage.getString(_storageKey);
        if (raw != null) {
          final Map<String, dynamic> data =
              jsonDecode(raw) as Map<String, dynamic>;
          final List<dynamic> readIds =
              data['readIds'] as List<dynamic>? ?? const <dynamic>[];
          final List<dynamic> dismissedIds =
              data['dismissedIds'] as List<dynamic>? ?? const <dynamic>[];

          _readById.clear();
          for (final Object? id in readIds) {
            if (id is int) _readById[id] = true;
          }

          _dismissedIds.clear();
          for (final Object? id in dismissedIds) {
            if (id is int) _dismissedIds.add(id);
          }
        }
      } catch (_) {
        _readById.clear();
        _dismissedIds.clear();
        try {
          await storage.remove(_storageKey);
        } catch (_) {}
      }
    }
    refresh();
  }

  void refresh() {
    _generateNotifications(_prefs.toMap());
    notifyListeners();
  }

  Future<void> onSignedIn(String userId) async {
    final NotificationStatesRepository? remote = _remote;
    if (remote == null) return;

    _userId = userId;
    _isLoadingStates = true;
    syncError.value = null;
    notifyListeners();

    final List<NotificationState>? states = await remote.fetchAll(userId);
    if (states == null) {
      syncError.value = 'No se pudieron cargar tus estados de notificación.';
    } else {
      _applyStates(states);
      refresh();
    }

    _isLoadingStates = false;
    notifyListeners();
  }

  Future<void> onSignedOut() async {
    _userId = null;
    _readById.clear();
    _dismissedIds.clear();
    notificationsEnabled = true;
    syncError.value = null;
    try {
      await _storage?.remove(_storageKey);
    } catch (_) {}
    refresh();
  }

  Future<void> setGlobalEnabled(bool enabled) async {
    notificationsEnabled = enabled;
    refresh();
    await _saveRemote(
      (NotificationStatesRepository remote, String userId) => remote.setEnabled(
        userId,
        NotificationStatesRepository.globalType,
        enabled,
      ),
    );
  }

  Future<void> markAllRead() async {
    final List<String> types = <String>[
      NotificationStatesRepository.globalType,
      for (final AppNotification notification in _notifications)
        NotificationStatesRepository.placeType(notification.placeId),
    ];
    for (final AppNotification notification in _notifications) {
      notification.isRead = true;
      _readById[notification.placeId] = true;
    }
    _persistState();
    notifyListeners();
    await _saveRemote(
      (NotificationStatesRepository remote, String userId) =>
          remote.markManyRead(userId, types),
    );
  }

  Future<void> markRead(int placeId) async {
    if (_readById[placeId] != true) {
      _readById[placeId] = true;
      for (final AppNotification notification in _notifications) {
        if (notification.placeId == placeId) notification.isRead = true;
      }
      _persistState();
      notifyListeners();
    }
    await _saveRemote(
      (NotificationStatesRepository remote, String userId) => remote.markRead(
        userId,
        NotificationStatesRepository.placeType(placeId),
      ),
    );
  }

  Future<void> markDismissed(int placeId) async {
    _dismissedIds.add(placeId);
    _persistState();
    notifyListeners();
    await _saveRemote(
      (NotificationStatesRepository remote, String userId) => remote.setEnabled(
        userId,
        NotificationStatesRepository.placeType(placeId),
        false,
      ),
    );
  }

  bool isDismissed(int placeId) => _dismissedIds.contains(placeId);

  Future<void> _saveRemote(
    Future<String?> Function(NotificationStatesRepository remote, String userId)
    operation,
  ) async {
    final String? userId = _userId;
    final NotificationStatesRepository? remote = _remote;
    if (userId == null || remote == null) return;
    final String? error = await operation(remote, userId);
    if (error != null) syncError.value = error;
  }

  void _applyStates(List<NotificationState> states) {
    notificationsEnabled = true;
    _readById.clear();
    _dismissedIds.clear();
    const String prefix = 'place:';
    for (final NotificationState state in states) {
      if (state.notificationType == NotificationStatesRepository.globalType) {
        notificationsEnabled = state.enabled;
        continue;
      }
      if (!state.notificationType.startsWith(prefix)) continue;
      final int? placeId = int.tryParse(
        state.notificationType.substring(prefix.length),
      );
      if (placeId == null) continue;
      if (state.lastReadAt != null) _readById[placeId] = true;
      if (!state.enabled) _dismissedIds.add(placeId);
    }
  }

  void _persistState() {
    final SharedPreferences? storage = _storage;
    if (storage == null) return;
    unawaited(
      storage
          .setString(
            _storageKey,
            jsonEncode(<String, dynamic>{
              'readIds': _readById.keys.toList(),
              'dismissedIds': _dismissedIds.toList(),
            }),
          )
          .then((bool _) {}, onError: (Object _) {}),
    );
  }

  static const List<double> _budgetThresholds = <double>[100000, 300000];

  static String _budgetLevel(double budget) {
    if (budget < _budgetThresholds[0]) return 'bajo';
    if (budget < _budgetThresholds[1]) return 'medio';
    return 'alto';
  }

  String _getBudgetLabel(double budget) {
    switch (_budgetLevel(budget)) {
      case 'bajo':
        return 'con un buen presupuesto';
      case 'medio':
        return 'con un presupuesto accesible';
      default:
        return 'sin preocuparte del gasto';
    }
  }

  String _getCompanionLabel(String? companion) {
    switch (companion) {
      case 'Pareja':
        return 'en pareja';
      case 'Familia':
        return 'compartir en familia';
      case 'Amigos':
        return 'pasarla con amigos';
      case 'Solo':
        return 'para ti solo';
      default:
        return '';
    }
  }

  String _getDurationLabel(double minutes) {
    if (minutes >= 300) return 'para toda la tarde';
    if (minutes >= 120) return 'para unas horas';
    return 'para un plan rápido';
  }

  String _getCategoryAdaptation(
    String category, {
    required double budget,
    required String? companion,
    required double minutes,
  }) {
    final List<String> parts = <String>[
      _getCompanionLabel(companion),
      _getDurationLabel(minutes),
      _getBudgetLabel(budget),
    ].where((String part) => part.isNotEmpty).toList();
    return '$category: ${parts.join(', ')}.';
  }

  static bool _matchesPlan(String category, String? plan) {
    if (plan == null || plan == 'Otro') return true;
    final String value = category.toLowerCase();
    switch (plan) {
      case 'Deportes':
        return value.contains('deport');
      case 'Cine':
        return value.contains('cine');
      case 'Parques':
        return value.contains('parque');
      case 'Juegos':
        return value.contains('juego');
      case 'Músicas':
        return value.contains('músic') || value.contains('music');
      case 'Furniture':
        return value.contains('furniture');
      case 'Restaurante':
        return value.contains('restaurante');
      default:
        return true;
    }
  }

  static double _priceOf(Place place) {
    final RegExpMatch? match = RegExp(r'\d[\d.]*').firstMatch(place.price);
    if (match == null) return 0;
    return double.tryParse(match.group(0)!.replaceAll('.', '')) ?? 0;
  }

  List<String> _tagsFor(
    Place place, {
    required String? companion,
    required double budget,
  }) {
    final Set<String> tags = <String>{};

    if (companion != null) {
      if (companion == 'Familia') {
        tags.add('Familia');
      } else if (companion == 'Pareja') {
        tags.add('En pareja');
      } else if (companion == 'Solo') {
        tags.add('Solo');
      } else {
        tags.add('Con amigos');
      }
    }

    if (budget < _budgetThresholds[0]) {
      tags.add('Presupuesto bajo');
    } else if (budget < _budgetThresholds[1]) {
      tags.add('Presupuesto medio');
    } else {
      tags.add('Presupuesto alto');
    }

    final String category = place.category.toLowerCase();
    if (category.contains('parque')) tags.add('Al aire libre');
    if (category.contains('cine')) tags.add('Entretenimiento');
    if (category.contains('restaurante')) tags.add('Gastronomía');
    if (category.contains('deport')) tags.add('Deportes');

    return tags.toList();
  }

  void _generateNotifications(Map<String, dynamic> prefs) {
    if (!notificationsEnabled) {
      _notifications = <AppNotification>[];
      return;
    }

    final double budget = (prefs['budget'] as num?)?.toDouble() ?? 0;
    final String? plan = prefs['plan'] as String?;
    final String? companion = prefs['companion'] as String?;
    final double minutes = (prefs['minutes'] as num?)?.toDouble() ?? 0;
    final String? city = prefs['place'] as String?;

    if (city == null || city.isEmpty) {
      _notifications = <AppNotification>[];
      _pruneReadState();
      return;
    }

    final List<Place> matches = MockData.places.where((Place place) {
      if (_dismissedIds.contains(place.id)) return false;
      if (place.city != city) return false;
      if (!_matchesPlan(place.category, plan)) return false;
      if (_priceOf(place) > budget) return false;
      return true;
    }).toList();

    final List<AppNotification> result = <AppNotification>[];
    for (final Place place in matches.take(5)) {
      result.add(
        AppNotification(
          placeId: place.id,
          title: place.name,
          message: _getCategoryAdaptation(
            place.category,
            budget: budget,
            companion: companion,
            minutes: minutes,
          ),
          tags: _tagsFor(place, companion: companion, budget: budget),
          isRead: _readById[place.id] ?? false,
        ),
      );
    }

    _notifications = result;
    _pruneReadState();
  }

  void _pruneReadState() {
    final Set<int> currentIds = _notifications
        .map((AppNotification item) => item.placeId)
        .toSet();
    _readById.removeWhere((int id, bool _) => !currentIds.contains(id));
  }

  @override
  void dispose() {
    syncError.dispose();
    super.dispose();
  }
}
