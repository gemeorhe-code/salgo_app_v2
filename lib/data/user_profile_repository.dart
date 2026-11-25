import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'google_auth_service.dart';
import 'profiles_repository.dart';
import 'supabase_auth_service.dart';
import 'supabase_gate.dart';

class UserProfileRepository extends ChangeNotifier {
  UserProfileRepository._internal();
  static UserProfileRepository _instance = UserProfileRepository._internal();
  factory UserProfileRepository() => _instance;

  static void resetForTesting() {
    _instance = UserProfileRepository._internal();
  }

  static const String _storageKey = 'salgo_user_profile';
  static const String _defaultName = 'Usuario SALGO';
  static const String _defaultEmail = 'usuario@salgo.com';
  static const String _neutralName = 'Usuario';

  String _name = _defaultName;
  String _email = _defaultEmail;
  String _city = 'Bucaramanga';
  String? _photoUrl;
  bool _isSignedIn = false;
  bool _hasLocalProfile = false;
  bool _nameEdited = false;
  bool _cityEdited = false;
  DateTime _updatedAt = DateTime.now().toUtc();
  final Map<String, String> _emailNames = <String, String>{};
  final Set<String> _migratedUserIds = <String>{};
  SharedPreferences? _preferences;

  String get name => _name;
  String get email => _email;
  String get city => _city;
  String? get photoUrl => _photoUrl;
  bool get isSignedIn => _isSignedIn;

  Future<void> init() async {
    try {
      _preferences = await SharedPreferences.getInstance();
    } on Object {
      _preferences = null;
    }

    final String? raw = _preferences?.getString(_storageKey);
    if (raw != null) {
      try {
        final Map<String, dynamic> data =
            jsonDecode(raw) as Map<String, dynamic>;
        _name = data['name'] as String? ?? _defaultName;
        _email = data['email'] as String? ?? _defaultEmail;
        _city = data['city'] as String? ?? _city;
        _photoUrl = data['photoUrl'] as String?;
        _isSignedIn = data['isSignedIn'] as bool? ?? false;
        _hasLocalProfile =
            data['hasLocalProfile'] as bool? ??
            (_name != _defaultName || _email != _defaultEmail);
        _nameEdited = data['nameEdited'] as bool? ?? false;
        _cityEdited = data['cityEdited'] as bool? ?? false;
        _updatedAt =
            DateTime.tryParse(data['updatedAt'] as String? ?? '')?.toUtc() ??
            DateTime.now().toUtc();

        final Object? rawNames = data['emailNames'];
        if (rawNames is Map<String, dynamic>) {
          rawNames.forEach((String key, dynamic value) {
            if (value is String && value.isNotEmpty) {
              _emailNames[_normalizeEmail(key)] = value;
            }
          });
        }

        final Object? rawMigrated = data['migratedUserIds'];
        if (rawMigrated is List<dynamic>) {
          for (final Object? id in rawMigrated) {
            if (id is String && id.isNotEmpty) _migratedUserIds.add(id);
          }
        }
      } on FormatException {
        await _preferences?.remove(_storageKey);
      }
    }

    final User? currentUser = SupabaseGate.client?.auth.currentUser;
    if (currentUser != null) {
      final Map<String, dynamic>? metadata = currentUser.userMetadata;
      _isSignedIn = true;
      _email = currentUser.email ?? _email;
      _photoUrl =
          metadata?['avatar_url'] as String? ??
          metadata?['picture'] as String? ??
          _photoUrl;
    }

    notifyListeners();
  }

  void update(String name, String email, String city) {
    if (name.trim() != _name.trim()) _nameEdited = true;
    if (city.trim() != _city.trim()) _cityEdited = true;
    _name = name;
    _email = email;
    _city = city;
    _hasLocalProfile = true;
    _rememberName(_email, _name);
    _touch();
    _persist();
    notifyListeners();
  }

  void registerLocal({required String name, required String email}) {
    _name = name;
    _email = email;
    _photoUrl = null;
    _hasLocalProfile = true;
    _isSignedIn = true;
    _nameEdited = false;
    _cityEdited = false;
    _rememberName(_email, _name);
    _touch();
    _persist();
    notifyListeners();
  }

  void signInWithEmail({required String email}) {
    final String normalizedEmail = _normalizeEmail(email);
    final String? rememberedName = _emailNames[normalizedEmail];
    _name = rememberedName ?? _neutralName;
    _email = email;
    _photoUrl = null;
    _hasLocalProfile = true;
    _isSignedIn = true;
    if (rememberedName != null) {
      _rememberName(_email, rememberedName);
    }
    _touch();
    _persist();
    notifyListeners();
  }

  Future<String?> completeGoogleSignIn({
    required GoogleAuthUser googleUser,
    required User supabaseUser,
  }) async {
    final bool firstLogin = !_migratedUserIds.contains(supabaseUser.id);
    final String cityToUpload = _city;

    String nextName = _name;
    String nextEmail = googleUser.email;
    String? nextPhoto = googleUser.photoUrl;

    if (firstLogin || !_nameEdited) {
      nextName = googleUser.name;
    }

    final ProfileSyncResult? result = await ProfilesRepository()
        .upsertFromGoogle(
          user: supabaseUser,
          name: nextName,
          email: nextEmail,
          photoUrl: nextPhoto,
          city: cityToUpload,
          updatedAt: _updatedAt,
        );

    if (result != null) {
      if (!result.wroteLocal) {
        nextName = result.record.name;
        nextEmail = result.record.email;
        nextPhoto = result.record.avatarUrl;
        _city = result.record.city;
      }
      _updatedAt = result.record.updatedAt;
    } else {
      _touch();
    }

    _name = nextName;
    _email = nextEmail;
    _photoUrl = nextPhoto;
    _hasLocalProfile = true;
    _isSignedIn = true;
    _migratedUserIds.add(supabaseUser.id);
    if (firstLogin) {
      _nameEdited = false;
      _cityEdited =
          cityToUpload.trim().isNotEmpty && cityToUpload != 'Bucaramanga';
    }
    _rememberName(_email, _name);
    _persist();
    notifyListeners();

    if (result == null) {
      return 'No se pudo sincronizar el perfil con Supabase. Tus datos siguen guardados en el dispositivo.';
    }
    return null;
  }

  Future<String?> completeEmailSignIn({
    required User supabaseUser,
    required String name,
    required String email,
    required String city,
  }) async {
    final bool firstLogin = !_migratedUserIds.contains(supabaseUser.id);
    final String cityToUpload = _city.trim().isEmpty ? city : _city;
    final Map<String, dynamic>? metadata = supabaseUser.userMetadata;

    String nextName = firstLogin && !_nameEdited ? name : _name;
    String nextEmail = email.trim().isEmpty ? _email : email;
    String? nextPhoto =
        metadata?['avatar_url'] as String? ??
        metadata?['picture'] as String? ??
        _photoUrl;

    final ProfileSyncResult? result = await ProfilesRepository()
        .upsertFromEmail(
          user: supabaseUser,
          name: nextName,
          email: nextEmail,
          photoUrl: nextPhoto,
          city: cityToUpload,
          updatedAt: _updatedAt,
        );

    if (result != null) {
      if (!result.wroteLocal) {
        nextName = result.record.name;
        nextEmail = result.record.email;
        nextPhoto = result.record.avatarUrl;
        _city = result.record.city;
      }
      _updatedAt = result.record.updatedAt;
    } else {
      _touch();
    }

    _name = nextName;
    _email = nextEmail;
    _photoUrl = nextPhoto;
    _hasLocalProfile = true;
    _isSignedIn = true;
    _migratedUserIds.add(supabaseUser.id);
    if (firstLogin) {
      _nameEdited = false;
      _cityEdited =
          cityToUpload.trim().isNotEmpty && cityToUpload != 'Bucaramanga';
    }
    _rememberName(_email, _name);
    _persist();
    notifyListeners();

    if (result == null) {
      return 'No se pudo sincronizar el perfil con Supabase. Tus datos siguen guardados en el dispositivo.';
    }
    return null;
  }

  void clearLocalSessionFlag() {
    if (!_isSignedIn) return;
    _isSignedIn = false;
    _persist();
    notifyListeners();
  }

  Future<String?> signOut() async {
    final String? supabaseError = await SupabaseAuthService.signOut();

    String? googleError;
    try {
      await GoogleAuthService.signOut();
    } on Object {
      googleError = 'No se pudo cerrar sesión con Google.';
    }

    _photoUrl = null;
    _isSignedIn = false;
    _touch();
    _persist();
    notifyListeners();

    if (supabaseError != null) return supabaseError;
    return googleError;
  }

  static UserProfileRepository of(BuildContext context) =>
      Provider.of<UserProfileRepository>(context, listen: false);

  void _rememberName(String email, String name) {
    final String normalizedEmail = _normalizeEmail(email);
    final String trimmedName = name.trim();
    if (normalizedEmail.isEmpty || trimmedName.isEmpty) return;
    _emailNames[normalizedEmail] = trimmedName;
  }

  String _normalizeEmail(String email) =>
      email.replaceAll(RegExp(r'\s+'), '').toLowerCase();

  void _touch() => _updatedAt = DateTime.now().toUtc();

  void _persist() {
    unawaited(
      _preferences?.setString(
        _storageKey,
        jsonEncode(<String, dynamic>{
          'name': _name,
          'email': _email,
          'city': _city,
          'photoUrl': _photoUrl,
          'isSignedIn': _isSignedIn,
          'hasLocalProfile': _hasLocalProfile,
          'emailNames': _emailNames,
          'nameEdited': _nameEdited,
          'cityEdited': _cityEdited,
          'updatedAt': _updatedAt.toIso8601String(),
          'migratedUserIds': _migratedUserIds.toList(),
        }),
      ),
    );
  }
}
