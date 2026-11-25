import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/notification_state.dart';
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

class NotificationStatesRepository {
  static const String _table = 'salgo_notification_states';
  static const String globalType = 'suggestions';
  static const String _loadError =
      'No se pudieron cargar tus estados de notificación.';
  static const String _saveError =
      'No se pudieron guardar tus estados de notificación.';

  NotificationStatesRepository({SupabaseClient? client})
    : _client = client ?? SupabaseGate.client;

  final SupabaseClient? _client;

  static String placeType(int placeId) => 'place:$placeId';

  Future<List<NotificationState>?> fetchAll(String userId) async {
    final SupabaseClient? client = _client;
    if (client == null) return null;

    try {
      final List<Map<String, dynamic>> rows = await client
          .from(_table)
          .select()
          .eq('user_id', userId);
      return rows
          .map((Map<String, dynamic> row) => NotificationState.fromJson(row))
          .toList(growable: false);
    } on PostgrestException catch (error) {
      debugPrint(
        '$_table PostgrestException code=${_redact(error.code)} '
        'message=${_redact(error.message)} details=${_redact(error.details)} '
        'hint=${_redact(error.hint)}',
      );
      return null;
    } on Object {
      return null;
    }
  }

  Future<String?> setEnabled(
    String userId,
    String notificationType,
    bool enabled,
  ) async {
    final SupabaseClient? client = _client;
    if (client == null) return _saveError;

    final DateTime now = DateTime.now().toUtc();
    try {
      final List<Map<String, dynamic>> rows = await client
          .from(_table)
          .update(<String, dynamic>{'enabled': enabled})
          .eq('user_id', userId)
          .eq('notification_type', notificationType)
          .select();
      if (rows.isNotEmpty) return null;

      return await _upsert(<NotificationState>[
        NotificationState(
          userId: userId,
          notificationType: notificationType,
          enabled: enabled,
          createdAt: now,
          updatedAt: now,
        ),
      ]);
    } on PostgrestException catch (error) {
      debugPrint(
        '$_table PostgrestException code=${_redact(error.code)} '
        'message=${_redact(error.message)} details=${_redact(error.details)} '
        'hint=${_redact(error.hint)}',
      );
      return _saveError;
    } on Object {
      return _saveError;
    }
  }

  Future<String?> markRead(String userId, String notificationType) async {
    final SupabaseClient? client = _client;
    if (client == null) return _saveError;

    final DateTime now = DateTime.now().toUtc();
    try {
      final List<Map<String, dynamic>> rows = await client
          .from(_table)
          .update(<String, dynamic>{'last_read_at': now.toIso8601String()})
          .eq('user_id', userId)
          .eq('notification_type', notificationType)
          .select();
      if (rows.isNotEmpty) return null;

      return await _upsert(<NotificationState>[
        NotificationState(
          userId: userId,
          notificationType: notificationType,
          lastReadAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      ]);
    } on PostgrestException catch (error) {
      debugPrint(
        '$_table PostgrestException code=${_redact(error.code)} '
        'message=${_redact(error.message)} details=${_redact(error.details)} '
        'hint=${_redact(error.hint)}',
      );
      return _saveError;
    } on Object {
      return _saveError;
    }
  }

  Future<String?> markManyRead(
    String userId,
    List<String> notificationTypes,
  ) async {
    final SupabaseClient? client = _client;
    if (client == null) return _saveError;
    if (notificationTypes.isEmpty) return null;

    final List<NotificationState>? existing = await fetchAll(userId);
    if (existing == null) return _loadError;

    final Map<String, NotificationState> byType = <String, NotificationState>{
      for (final NotificationState state in existing)
        state.notificationType: state,
    };
    final DateTime now = DateTime.now().toUtc();
    final List<NotificationState> states = <NotificationState>[
      for (final String type in notificationTypes.toSet())
        NotificationState(
          id: byType[type]?.id ?? '',
          userId: userId,
          notificationType: type,
          enabled: byType[type]?.enabled ?? true,
          lastReadAt: now,
          createdAt: byType[type]?.createdAt ?? now,
          updatedAt: now,
        ),
    ];
    return _upsert(states);
  }

  Future<String?> _upsert(List<NotificationState> states) async {
    final SupabaseClient? client = _client;
    if (client == null) return _saveError;

    try {
      await client
          .from(_table)
          .upsert(
            states.map((NotificationState state) => state.toJson()).toList(),
            onConflict: 'user_id,notification_type',
          );
      return null;
    } on PostgrestException catch (error) {
      debugPrint(
        '$_table PostgrestException code=${_redact(error.code)} '
        'message=${_redact(error.message)} details=${_redact(error.details)} '
        'hint=${_redact(error.hint)}',
      );
      return _saveError;
    } on Object {
      return _saveError;
    }
  }
}
