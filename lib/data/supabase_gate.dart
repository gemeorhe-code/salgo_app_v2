import 'package:supabase_flutter/supabase_flutter.dart';

abstract final class SupabaseGate {
  static SupabaseClient? _client;

  static SupabaseClient? get client => _client;

  static bool get isAvailable => _client != null;

  static void configure(SupabaseClient client) => _client = client;

  static void reset() => _client = null;
}
