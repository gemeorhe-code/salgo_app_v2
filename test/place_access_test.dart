import 'package:flutter_test/flutter_test.dart';

import 'package:salgo_app/models/place_access.dart';

void main() {
  test('sin filas no da acceso', () {
    const PlaceAccess access = PlaceAccess.empty;
    expect(access.canManage, isFalse);
    expect(access.canEdit(1), isFalse);
  });

  test('admin administra todos los lugares', () {
    final PlaceAccess access = PlaceAccess.fromRows(<dynamic>[
      <String, dynamic>{'role': 'admin', 'place_ids': <dynamic>[]},
    ]);
    expect(access.isAdmin, isTrue);
    expect(access.canManage, isTrue);
    expect(access.canEdit(1), isTrue);
    expect(access.canEdit(1000), isTrue);
  });

  test('owner solo administra sus lugares', () {
    final PlaceAccess access = PlaceAccess.fromRows(<dynamic>[
      <String, dynamic>{'role': 'owner', 'place_ids': <dynamic>[1000, 1002]},
    ]);
    expect(access.isAdmin, isFalse);
    expect(access.canManage, isTrue);
    expect(access.canEdit(1000), isTrue);
    expect(access.canEdit(1), isFalse);
  });

  test('ignora filas mal formadas', () {
    final PlaceAccess access = PlaceAccess.fromRows(<dynamic>[
      <String, dynamic>{'role': 'otro', 'place_ids': <dynamic>[1]},
      <String, dynamic>{'role': 'owner', 'place_ids': 'no-lista'},
      'no-map',
    ]);
    expect(access.canManage, isFalse);
  });
}
