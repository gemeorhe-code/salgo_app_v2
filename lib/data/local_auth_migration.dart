import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'notification_states_repository.dart';

class LocalAuthMigration {
  LocalAuthMigration({SharedPreferences? storage})
    : _storage = storage,
      _storageResolved = storage != null;

  static const String pendingKey = 'salgo_pending_auth_migration';
  static const String favoritesKey = 'salgo_favorites_v1';
  static const String preferencesKey = 'salgo_preferences';
  static const String notificationsKey = 'salgo_notifications_state';

  final SharedPreferences? _storage;
  final bool _storageResolved;

  Future<SharedPreferences?> get _resolvedStorage async {
    if (_storageResolved) return _storage;
    try {
      return await SharedPreferences.getInstance();
    } on Object {
      return null;
    }
  }

  Future<bool> isPending() async {
    final SharedPreferences? storage = await _resolvedStorage;
    if (storage == null) return false;
    return storage.containsKey(pendingKey);
  }

  Future<String?> pendingEmail() async {
    final SharedPreferences? storage = await _resolvedStorage;
    final String? raw = storage?.getString(pendingKey);
    if (raw == null) return null;
    try {
      final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;
      return data['email'] as String?;
    } on Object {
      return null;
    }
  }

  Future<void> markPending({String? email}) async {
    final SharedPreferences? storage = await _resolvedStorage;
    if (storage == null) return;
    final String? existingEmail = await pendingEmail();
    final String? trimmedEmail = email?.trim();
    await storage.setString(
      pendingKey,
      jsonEncode(<String, dynamic>{
        'email': trimmedEmail != null && trimmedEmail.isNotEmpty
            ? trimmedEmail
            : existingEmail,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      }),
    );
  }

  Future<void> ensurePendingFromLocalData() async {
    if (await isPending()) return;

    final SharedPreferences? storage = await _resolvedStorage;
    if (storage == null) return;

    bool hasOwnerlessFavorites = false;
    final String? favoritesRaw = storage.getString(favoritesKey);
    if (favoritesRaw != null) {
      try {
        final Map<String, dynamic> data =
            jsonDecode(favoritesRaw) as Map<String, dynamic>;
        final Object? items = data['items'];
        final bool hasItems = items is Map<String, dynamic> && items.isNotEmpty;
        hasOwnerlessFavorites = data['ownerId'] == null && hasItems;
      } on Object {
        hasOwnerlessFavorites = false;
      }
    }

    final bool hasPreferences = storage.containsKey(preferencesKey);
    final bool hasNotifications = storage.containsKey(notificationsKey);
    if (hasOwnerlessFavorites || hasPreferences || hasNotifications) {
      await markPending();
    }
  }

  Future<bool> uploadNotificationStates({
    required String userId,
    NotificationStatesRepository? notificationStates,
  }) async {
    final SharedPreferences? storage = await _resolvedStorage;
    final String? raw = storage?.getString(notificationsKey);
    if (raw == null) return true;

    final List<int> readIds = <int>[];
    final List<int> dismissedIds = <int>[];
    try {
      final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;
      final Object? rawRead = data['readIds'];
      if (rawRead is List<dynamic>) {
        for (final Object? value in rawRead) {
          if (value is int) readIds.add(value);
        }
      }
      final Object? rawDismissed = data['dismissedIds'];
      if (rawDismissed is List<dynamic>) {
        for (final Object? value in rawDismissed) {
          if (value is int) dismissedIds.add(value);
        }
      }
    } on Object {
      return false;
    }

    if (readIds.isEmpty && dismissedIds.isEmpty) return true;

    final NotificationStatesRepository remote =
        notificationStates ?? NotificationStatesRepository();
    if (readIds.isNotEmpty) {
      final List<String> types = <String>[
        NotificationStatesRepository.globalType,
        for (final int id in readIds)
          NotificationStatesRepository.placeType(id),
      ];
      final String? error = await remote.markManyRead(userId, types);
      if (error != null) return false;
    }
    for (final int id in dismissedIds) {
      final String? error = await remote.setEnabled(
        userId,
        NotificationStatesRepository.placeType(id),
        false,
      );
      if (error != null) return false;
    }
    return true;
  }

  Future<void> clear() async {
    final SharedPreferences? storage = await _resolvedStorage;
    await storage?.remove(pendingKey);
  }
}
