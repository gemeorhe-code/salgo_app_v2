import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_preferences.dart';
import 'supabase_gate.dart';

String _redact(Object? value) {
  final String text = value?.toString() ?? 'null';
  return text
      .replaceAll(
        RegExp(r'\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+'),
        '[token]',
      )
      .replaceAll(RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+'), '[email]');
}

class UserPreferencesFetchResult {
  const UserPreferencesFetchResult({this.preferences, this.error});

  final UserPreferences? preferences;
  final String? error;
}

class UserPreferencesRepository {
  static const String _table = 'salgo_user_preferences';

  UserPreferencesRepository({SupabaseClient? client})
    : _client = client ?? SupabaseGate.client;

  final SupabaseClient? _client;

  Future<UserPreferencesFetchResult> fetchOrCreate(
    String userId,
    UserPreferences fallback,
  ) async {
    final SupabaseClient? client = _client;
    if (client == null) {
      return const UserPreferencesFetchResult(
        error: 'Supabase no está disponible.',
      );
    }

    try {
      final List<Map<String, dynamic>> rows = await client
          .from(_table)
          .select()
          .eq('user_id', userId);
      if (rows.isNotEmpty) {
        return UserPreferencesFetchResult(
          preferences: UserPreferences.fromJson(rows.first),
        );
      }
    } on PostgrestException catch (error) {
      debugPrint(
        '$_table PostgrestException code=${_redact(error.code)} '
        'message=${_redact(error.message)} details=${_redact(error.details)} '
        'hint=${_redact(error.hint)}',
      );
      return const UserPreferencesFetchResult(
        error: 'No se pudieron cargar tus preferencias. Se mantienen las del dispositivo.',
      );
    } on Object {
      return const UserPreferencesFetchResult(
        error: 'No se pudieron cargar tus preferencias. Se mantienen las del dispositivo.',
      );
    }

    final String? error = await upsert(fallback);
    if (error != null) {
      return UserPreferencesFetchResult(error: error);
    }
    return UserPreferencesFetchResult(preferences: fallback);
  }

  Future<String?> upsert(UserPreferences preferences) async {
    final SupabaseClient? client = _client;
    if (client == null) return 'Supabase no está disponible.';

    try {
      final List<Map<String, dynamic>> rows = await client
          .from(_table)
          .upsert(preferences.toJson(), onConflict: 'user_id')
          .select();
      if (rows.isEmpty) {
        return 'No se pudieron guardar tus preferencias. Inténtalo de nuevo.';
      }
      return null;
    } on PostgrestException catch (error) {
      debugPrint(
        '$_table PostgrestException code=${_redact(error.code)} '
        'message=${_redact(error.message)} details=${_redact(error.details)} '
        'hint=${_redact(error.hint)}',
      );
      return 'No se pudieron guardar tus preferencias en Supabase. Quedaron guardadas en el dispositivo.';
    } on Object {
      return 'No se pudieron guardar tus preferencias en Supabase. Quedaron guardadas en el dispositivo.';
    }
  }
}
