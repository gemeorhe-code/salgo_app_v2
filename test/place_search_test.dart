import 'package:flutter_test/flutter_test.dart';
import 'package:salgo_app/models/place.dart';
import 'package:salgo_app/utils/place_search.dart';

Place _place(
  int id, {
  required String name,
  String category = 'Otro',
  String city = 'Bucaramanga',
  String address = 'Dirección',
}) {
  return Place(
    id: id,
    name: name,
    category: category,
    city: city,
    rating: 4.5,
    reviewCount: 10,
    address: address,
    schedule: 'Todo el día',
    price: 'Gratis',
    description: 'Descripción $id',
    lat: 7.1,
    lng: -73.1,
  );
}

void main() {
  test('normaliza mayúsculas, tildes, ñ y tildes descompuestas', () {
    expect(normalizeSearchText('MÚSICAS'), 'musicas');
    expect(normalizeSearchText('San Pío'), 'san pio');
    expect(normalizeSearchText('Mu\u0301sicas'), 'musicas');
    expect(normalizeSearchText('Niños'), 'ninos');
  });

  test('busca por nombre ignorando mayúsculas y tildes', () {
    final List<Place> places = <Place>[
      _place(1, name: 'Auditorio Músicas'),
      _place(2, name: 'Cine Cacique'),
    ];

    expect(
      searchPlaces(places, 'MUSICAS').map((Place place) => place.id),
      <int>[1],
    );
    expect(
      searchPlaces(places, 'san pio').map((Place place) => place.id),
      isEmpty,
    );
  });

  test('busca por ciudad, categoría y dirección', () {
    final List<Place> places = <Place>[
      _place(1, name: 'Uno', city: 'Floridablanca'),
      _place(2, name: 'Dos', category: 'Músicas'),
      _place(3, name: 'Tres', address: 'Carrera 33 # 45'),
    ];

    expect(
      searchPlaces(places, 'florida').single.id,
      1,
    );
    expect(
      searchPlaces(places, 'MUSICAS').single.id,
      2,
    );
    expect(
      searchPlaces(places, 'carrera 33').single.id,
      3,
    );
  });

  test('ordena primero los que empiezan con el texto', () {
    final List<Place> places = <Place>[
      _place(1, name: 'Zona Parque'),
      _place(2, name: 'Centro Parque', category: 'Parques'),
      _place(3, name: 'Parque Central'),
    ];

    expect(
      searchPlaces(places, 'par').map((Place place) => place.id),
      <int>[3, 2, 1],
    );
  });

  test('sin resultados devuelve una lista vacía', () {
    final List<Place> places = <Place>[
      _place(1, name: 'Parque San Pío'),
    ];

    expect(searchPlaces(places, 'zzzz'), isEmpty);
  });

  test('consulta vacía devuelve el catálogo en su orden original', () {
    final List<Place> places = <Place>[
      _place(3, name: 'Tres'),
      _place(1, name: 'Uno'),
      _place(2, name: 'Dos'),
    ];

    expect(
      searchPlaces(places, '   ').map((Place place) => place.id),
      <int>[3, 1, 2],
    );
  });
}
