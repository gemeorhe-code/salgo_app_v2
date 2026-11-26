import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/place.dart';
import '../models/place_access.dart';
import 'places_catalog_service.dart';
import 'supabase_gate.dart';

class PlaceSaveResult {
  const PlaceSaveResult({this.id, this.error});

  final int? id;
  final String? error;
}

class PlaceAdminRepository {
  PlaceAdminRepository({
    SupabaseClient? client,
    this.timeout = const Duration(seconds: 8),
  }) : _client = client ?? SupabaseGate.client;

  static const String networkMessage =
      'Sin conexión: no se puede guardar el lugar. Inténtalo cuando haya red.';
  static const String _table = 'salgo_places';

  final SupabaseClient? _client;
  final Duration timeout;

  bool get isAvailable => _client != null;

  Future<PlaceAccess> fetchAccess() async {
    final SupabaseClient? client = _client;
    if (client == null) return PlaceAccess.empty;

    try {
      final Object? response = await client
          .rpc('salgo_my_place_access')
          .timeout(timeout);
      if (response is List<dynamic>) {
        return PlaceAccess.fromRows(response);
      }
      return PlaceAccess.empty;
    } on Object {
      return PlaceAccess.empty;
    }
  }

  Future<List<Place>> fetchPlaces() async {
    final SupabaseClient? client = _client;
    if (client == null) return const <Place>[];

    try {
      final List<dynamic> rows = await client
          .from(_table)
          .select()
          .order('id')
          .timeout(timeout);
      return PlacesCatalogService.parseRows(rows);
    } on Object {
      return const <Place>[];
    }
  }

  Future<PlaceSaveResult> savePlace(
    Map<String, dynamic> values, {
    int? id,
  }) async {
    final SupabaseClient? client = _client;
    if (client == null) {
      return PlaceSaveResult(error: networkMessage);
    }

    try {
      if (id == null) {
        final Map<String, dynamic> row = await client
            .from(_table)
            .insert(values)
            .select()
            .single()
            .timeout(timeout);
        final Object? rawId = row['id'];
        final int? insertedId = rawId is num ? rawId.toInt() : null;
        return PlaceSaveResult(id: insertedId);
      }

      final List<dynamic> rows = await client
          .from(_table)
          .update(values)
          .eq('id', id)
          .select()
          .timeout(timeout);
      if (rows.isEmpty) {
        return const PlaceSaveResult(
          error: 'No se pudo guardar el lugar. Inténtalo de nuevo.',
        );
      }
      return PlaceSaveResult(id: id);
    } on PostgrestException catch (error) {
      if (error.code == '42501' || error.code == 'PGRST301') {
        return const PlaceSaveResult(
          error: 'No tienes permiso para guardar este lugar.',
        );
      }
      return const PlaceSaveResult(
        error: 'No se pudo guardar el lugar. Inténtalo de nuevo.',
      );
    } on Object {
      return PlaceSaveResult(error: networkMessage);
    }
  }

  Future<String?> assignOwner(String email, int placeId) =>
      _callOwnerRpc('salgo_assign_owner', email, placeId);

  Future<String?> removeOwner(String email, int placeId) =>
      _callOwnerRpc('salgo_remove_owner', email, placeId);

  Future<String?> _callOwnerRpc(
    String function,
    String email,
    int placeId,
  ) async {
    final SupabaseClient? client = _client;
    if (client == null) return networkMessage;
    final String trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) return 'Ingresa el correo del dueño.';

    try {
      await client.rpc(
        function,
        params: <String, dynamic>{
          'p_email': trimmedEmail,
          'p_place_id': placeId,
        },
      ).timeout(timeout);
      return null;
    } on PostgrestException catch (error) {
      if (error.code == '42501' || error.code == 'PGRST301') {
        return 'No tienes permiso para asignar dueños.';
      }
      return error.message.isEmpty
          ? 'No se pudo actualizar el dueño.'
          : error.message;
    } on Object {
      return networkMessage;
    }
  }
}
