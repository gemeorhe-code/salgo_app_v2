abstract final class SupabaseConfig {
  static const String url = 'https://aahwpemvozaoxyhjzwvr.supabase.co';
  static const String publishableKey =
      'sb_publishable_IXGZ3UKocMIYOPROcum7oQ_QMWMtKpl';

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}
