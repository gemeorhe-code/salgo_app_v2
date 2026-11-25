import 'package:supabase_flutter/supabase_flutter.dart';

import 'google_auth_service.dart';
import 'local_auth_migration.dart';
import 'notifications_repository.dart';
import 'places_repository.dart';
import 'preferences_repository.dart';
import 'supabase_gate.dart';
import 'user_profile_repository.dart';

class AuthCompletion {
  const AuthCompletion({required this.started, this.message});

  final bool started;
  final String? message;
}

class AuthSessionFlow {
  AuthSessionFlow({
    required this.userProfile,
    required this.preferences,
    required this.notifications,
    required this.places,
    LocalAuthMigration? migration,
  }) : _migration = migration ?? LocalAuthMigration();

  final UserProfileRepository userProfile;
  final PreferencesRepository preferences;
  final NotificationsRepository notifications;
  final PlacesRepository places;
  final LocalAuthMigration _migration;
  final Set<String> _completed = <String>{};
  final Map<String, Future<AuthCompletion>> _inFlight =
      <String, Future<AuthCompletion>>{};

  Future<AuthCompletion> completeGoogleSignIn({
    required GoogleAuthUser googleUser,
    required User user,
  }) {
    return completeSignIn(
      user,
      profileSync: () => userProfile.completeGoogleSignIn(
        googleUser: googleUser,
        supabaseUser: user,
      ),
    );
  }

  Future<AuthCompletion> completeEmailSignIn({
    required User user,
    String? name,
    String? city,
  }) {
    final Map<String, dynamic>? metadata = user.userMetadata;
    final String resolvedName =
        name ??
        metadata?['full_name'] as String? ??
        metadata?['name'] as String? ??
        userProfile.name;
    final String resolvedCity =
        city ?? metadata?['city'] as String? ?? userProfile.city;
    final String resolvedEmail = user.email ?? userProfile.email;

    return completeSignIn(
      user,
      profileSync: () => userProfile.completeEmailSignIn(
        supabaseUser: user,
        name: resolvedName,
        email: resolvedEmail,
        city: resolvedCity,
      ),
    );
  }

  Future<AuthCompletion> completeSignIn(
    User user, {
    Future<String?> Function()? profileSync,
  }) async {
    final String userId = user.id;
    final Future<AuthCompletion>? running = _inFlight[userId];
    if (running != null) return running;
    if (_completed.contains(userId)) {
      return const AuthCompletion(started: false);
    }

    final Future<AuthCompletion> operation = _perform(
      userId,
      profileSync: profileSync,
    );
    _inFlight[userId] = operation;
    try {
      final AuthCompletion result = await operation;
      if (result.message == null) _completed.add(userId);
      return result;
    } finally {
      _inFlight.remove(userId);
    }
  }

  Future<AuthCompletion> _perform(
    String userId, {
    Future<String?> Function()? profileSync,
  }) async {
    if (profileSync != null) {
      final String? profileError = await profileSync();
      if (profileError != null) {
        return AuthCompletion(started: true, message: profileError);
      }
    }

    if (await _migration.isPending()) {
      final bool uploaded = await _migration.uploadNotificationStates(
        userId: userId,
      );
      if (!uploaded) {
        return const AuthCompletion(
          started: true,
          message:
              'No se pudieron subir tus datos locales. Se conservarán '
              'en este dispositivo y se intentará de nuevo en el próximo ingreso.',
        );
      }
    }

    await Future.wait<void>(<Future<void>>[
      preferences.onSignedIn(userId),
      notifications.onSignedIn(userId),
      places.onSignedIn(userId),
    ]);
    await _migration.clear();

    return const AuthCompletion(started: true);
  }

  Future<void> markMigrationPending({String? email}) =>
      _migration.markPending(email: email);

  void reset(String userId) {
    _completed.remove(userId);
    _inFlight.remove(userId);
  }

  void resetCurrentUser() {
    final String? userId = SupabaseGate.client?.auth.currentUser?.id;
    if (userId == null) return;
    reset(userId);
  }
}
