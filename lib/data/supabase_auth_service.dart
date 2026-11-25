import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_deep_links.dart';
import 'google_auth_service.dart';
import 'supabase_gate.dart';

class SupabaseAuthException implements Exception {
  const SupabaseAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class EmailSignUpResult {
  const EmailSignUpResult({this.user, this.session});

  final User? user;
  final Session? session;

  bool get needsConfirmation => session == null;
}

abstract final class SupabaseAuthService {
  static Future<AuthResponse> signInWithGoogle(GoogleAuthUser user) async {
    final SupabaseClient? client = SupabaseGate.client;
    if (client == null) {
      throw const SupabaseAuthException(
        'Supabase no está disponible. Revisa la conexión e inténtalo de nuevo.',
      );
    }
    if (user.idToken.isEmpty) {
      throw const SupabaseAuthException(
        'Google no devolvió un token de identidad. Inténtalo de nuevo.',
      );
    }

    try {
      return await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: user.idToken,
        accessToken: user.accessToken,
      );
    } on AuthException catch (error) {
      throw SupabaseAuthException(_messageFor(error.message));
    } on Object {
      throw const SupabaseAuthException(
        'No se pudo iniciar sesión con Supabase. Revisa tu conexión e inténtalo de nuevo.',
      );
    }
  }

  static Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final SupabaseClient client = _requireClient();
    try {
      return await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (error) {
      throw SupabaseAuthException(_emailMessageFor(error.message));
    } on Object {
      throw const SupabaseAuthException(
        'No se pudo iniciar sesión. Revisa tu conexión e inténtalo de nuevo.',
      );
    }
  }

  static Future<EmailSignUpResult> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String city,
  }) async {
    final SupabaseClient client = _requireClient();
    try {
      final AuthResponse response = await client.auth.signUp(
        email: email.trim(),
        password: password,
        emailRedirectTo: AuthDeepLinks.confirm,
        data: <String, dynamic>{'full_name': name.trim(), 'city': city.trim()},
      );
      return EmailSignUpResult(user: response.user, session: response.session);
    } on AuthException catch (error) {
      if (_isAlreadyRegistered(error.message)) {
        return const EmailSignUpResult();
      }
      throw SupabaseAuthException(_emailMessageFor(error.message));
    } on Object {
      throw const SupabaseAuthException(
        'No se pudo enviar el correo de confirmación. Inténtalo de nuevo.',
      );
    }
  }

  static Future<void> resendConfirmation({required String email}) async {
    final SupabaseClient client = _requireClient();
    try {
      await client.auth.resend(
        email: email.trim(),
        type: OtpType.signup,
        emailRedirectTo: AuthDeepLinks.confirm,
      );
    } on AuthException catch (error) {
      if (_isAlreadyRegistered(error.message)) return;
      throw SupabaseAuthException(_emailMessageFor(error.message));
    } on Object {
      throw const SupabaseAuthException(
        'No se pudo reenviar el correo. Inténtalo de nuevo.',
      );
    }
  }

  static Future<void> requestPasswordReset({required String email}) async {
    final SupabaseClient client = _requireClient();
    try {
      await client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: AuthDeepLinks.reset,
      );
    } on Object {
      throw const SupabaseAuthException(
        'No se pudo enviar el correo de recuperación. Inténtalo de nuevo.',
      );
    }
  }

  static Future<void> updatePassword({required String password}) async {
    final SupabaseClient client = _requireClient();
    try {
      await client.auth.updateUser(UserAttributes(password: password));
    } on AuthException catch (error) {
      throw SupabaseAuthException(_emailMessageFor(error.message));
    } on Object {
      throw const SupabaseAuthException(
        'No se pudo actualizar la contraseña. Inténtalo de nuevo.',
      );
    }
  }

  static Future<String?> signOut() async {
    final SupabaseClient? client = SupabaseGate.client;
    if (client == null) return null;
    try {
      await client.auth.signOut();
      return null;
    } on AuthException catch (error) {
      return _messageFor(error.message);
    } on Object {
      return 'No se pudo cerrar sesión en Supabase.';
    }
  }

  static SupabaseClient _requireClient() {
    final SupabaseClient? client = SupabaseGate.client;
    if (client == null) {
      throw const SupabaseAuthException(
        'Supabase no está disponible. Revisa la conexión e inténtalo de nuevo.',
      );
    }
    return client;
  }

  static bool _isAlreadyRegistered(String message) {
    final String lower = message.toLowerCase();
    return (lower.contains('already') && lower.contains('registered')) ||
        lower.contains('ya está registrado') ||
        lower.contains('ya existe');
  }

  static String _messageFor(String message) {
    final String lower = message.toLowerCase();
    if (lower.contains('network') ||
        lower.contains('socket') ||
        lower.contains('timeout') ||
        lower.contains('failed to host')) {
      return 'Sin conexión con Supabase. Revisa tu red e inténtalo de nuevo.';
    }
    if (lower.contains('invalid') ||
        lower.contains('token') ||
        lower.contains('nonce') ||
        lower.contains('provider')) {
      return 'Google no pudo validar la sesión en Supabase. Configura el proveedor Google e inténtalo de nuevo.';
    }
    return 'No se pudo completar la operación con Supabase. Inténtalo de nuevo.';
  }

  static String _emailMessageFor(String message) {
    final String lower = message.toLowerCase();
    if (lower.contains('network') ||
        lower.contains('socket') ||
        lower.contains('timeout') ||
        lower.contains('failed to host')) {
      return 'Sin conexión con Supabase. Revisa tu red e inténtalo de nuevo.';
    }
    if (lower.contains('invalid login') ||
        lower.contains('invalid credentials') ||
        lower.contains('credenciales') ||
        lower.contains('contraseña incorrect')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (lower.contains('weak password') || lower.contains('password')) {
      return 'La contraseña no cumple los requisitos. Usa al menos 6 caracteres.';
    }
    if (lower.contains('expired') ||
        lower.contains('vencid') ||
        lower.contains('invalid')) {
      return 'El enlace venció o no es válido. Solicita uno nuevo.';
    }
    return 'No se pudo completar la operación. Inténtalo de nuevo.';
  }
}
