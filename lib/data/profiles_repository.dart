import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_gate.dart';

String _redact(Object? value) {
  final String text = value?.toString() ?? 'null';
  return text
      .replaceAll(RegExp(r'\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+'), '[token]')
      .replaceAll(RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+'), '[email]');
}

class ProfileRecord {
  const ProfileRecord({
    required this.id,
    required this.email,
    required this.name,
    required this.avatarUrl,
    required this.city,
    required this.updatedAt,
  });

  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final String city;
  final DateTime updatedAt;

  factory ProfileRecord.fromMap(Map<String, dynamic> map) {
    return ProfileRecord(
      id: map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      name: map['full_name'] as String? ?? 'Usuario SALGO',
      avatarUrl: map['avatar_url'] as String?,
      city: map['city'] as String? ?? 'Bucaramanga',
      updatedAt:
          DateTime.tryParse(map['updated_at'] as String? ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

class ProfileSyncResult {
  const ProfileSyncResult({
    required this.record,
    required this.wroteLocal,
  });

  final ProfileRecord record;
  final bool wroteLocal;
}

class ProfilesRepository {
  static const String _table = 'salgo_profiles';

  ProfilesRepository({SupabaseClient? client})
    : _client = client ?? SupabaseGate.client;

  final SupabaseClient? _client;

  Future<ProfileSyncResult?> upsertFromGoogle({
    required User user,
    required String name,
    required String email,
    required String? photoUrl,
    required String city,
    required DateTime updatedAt,
  }) async {
    final SupabaseClient? client = _client;
    if (client == null) return null;

    try {
      final List<Map<String, dynamic>> rows = await client
          .from(_table)
          .select()
          .eq('id', user.id);

      final ProfileRecord? remote =
          rows.isEmpty ? null : ProfileRecord.fromMap(rows.first);
      if (remote != null && updatedAt.isBefore(remote.updatedAt)) {
        return ProfileSyncResult(record: remote, wroteLocal: false);
      }

      final Map<String, dynamic> values = <String, dynamic>{
        'id': user.id,
        'email': email,
        'full_name': name,
        'avatar_url': photoUrl,
        'city': city,
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

      if (remote == null) {
        await client.from(_table).insert(values);
      } else {
        await client.from(_table).update(values).eq('id', user.id);
      }

      return ProfileSyncResult(
        record: ProfileRecord.fromMap(values),
        wroteLocal: true,
      );
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
}
