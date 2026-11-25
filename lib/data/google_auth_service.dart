import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';

import 'google_auth_config.dart';

class GoogleAuthException implements Exception {
  const GoogleAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GoogleAuthUser {
  const GoogleAuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.idToken,
    required this.accessToken,
    this.photoUrl,
  });

  final String id;
  final String name;
  final String email;
  final String idToken;
  final String accessToken;
  final String? photoUrl;
}

abstract final class GoogleAuthService {
  static bool _initialized = false;
  static Object? _initializationError;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: GoogleAuthConfig.webClientId,
      );
    } on Object catch (error) {
      _initializationError = error;
    }
  }

  static Future<GoogleAuthUser> signIn() async {
    if (_initializationError != null) {
      throw const GoogleAuthException(
        'Error de configuración de Google. Verifica el cliente OAuth.',
      );
    }
    try {
      final GoogleSignInAccount account = await GoogleSignIn.instance
          .authenticate()
          .timeout(const Duration(seconds: 60));

      final String? idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const GoogleAuthException(
          'Google no devolvió un token de identidad. Inténtalo de nuevo.',
        );
      }

      final GoogleSignInClientAuthorization? authorization =
          await account.authorizationClient.authorizationForScopes(
            const <String>['email', 'profile'],
          );
      final GoogleSignInClientAuthorization granted =
          authorization ??
          await account.authorizationClient.authorizeScopes(
            const <String>['email', 'profile'],
          );

      return GoogleAuthUser(
        id: account.id,
        name: account.displayName ?? account.email,
        email: account.email,
        photoUrl: account.photoUrl,
        idToken: idToken,
        accessToken: granted.accessToken,
      );
    } on TimeoutException catch (_) {
      throw const GoogleAuthException(
        'Google tardó demasiado en responder. Revisa tu conexión e inténtalo de nuevo.',
      );
    } on GoogleAuthException {
      rethrow;
    } on GoogleSignInException catch (error) {
      throw GoogleAuthException(_messageFor(error.code));
    } on Object {
      throw const GoogleAuthException(
        'No se pudo conectar con Google. Revisa tu conexión e inténtalo de nuevo.',
      );
    }
  }

  static Future<void> signOut() => GoogleSignIn.instance.signOut();

  static String _messageFor(GoogleSignInExceptionCode code) {
    if (code == GoogleSignInExceptionCode.canceled) {
      return 'Ingreso con Google cancelado.';
    }
    if (code == GoogleSignInExceptionCode.clientConfigurationError ||
        code == GoogleSignInExceptionCode.providerConfigurationError ||
        code == GoogleSignInExceptionCode.uiUnavailable) {
      return 'Error de configuración de Google. Verifica el cliente OAuth.';
    }
    return 'No se pudo conectar con Google. Revisa tu conexión e inténtalo de nuevo.';
  }
}
