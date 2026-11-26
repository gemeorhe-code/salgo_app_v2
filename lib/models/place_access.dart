class PlaceAccess {
  const PlaceAccess({
    this.isAdmin = false,
    Set<int>? ownerPlaceIds,
  }) : _ownerPlaceIds = ownerPlaceIds ?? const <int>{};

  static const PlaceAccess empty = PlaceAccess();

  final bool isAdmin;
  final Set<int> _ownerPlaceIds;

  Set<int> get ownerPlaceIds => Set<int>.unmodifiable(_ownerPlaceIds);

  bool get canManage => isAdmin || _ownerPlaceIds.isNotEmpty;

  bool canEdit(int placeId) => isAdmin || _ownerPlaceIds.contains(placeId);

  factory PlaceAccess.fromRows(List<dynamic> rows) {
    bool isAdmin = false;
    final Set<int> ownerPlaceIds = <int>{};

    for (final Object? row in rows) {
      final Map<String, dynamic>? data = _asStringMap(row);
      if (data == null) continue;

      final String role = data['role'] is String ? data['role'] as String : '';
      if (role == 'admin') {
        isAdmin = true;
        continue;
      }
      if (role != 'owner') continue;

      final Object? rawIds = data['place_ids'];
      if (rawIds is! List<dynamic>) continue;
      for (final Object? rawId in rawIds) {
        final int? id = _intOf(rawId);
        if (id != null && id > 0) ownerPlaceIds.add(id);
      }
    }

    return PlaceAccess(isAdmin: isAdmin, ownerPlaceIds: ownerPlaceIds);
  }

  static Map<String, dynamic>? _asStringMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map<Object?, Object?>) {
      return value.map(
        (Object? key, Object? value) =>
            MapEntry<String, dynamic>(key.toString(), value),
      );
    }
    return null;
  }

  static int? _intOf(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}
