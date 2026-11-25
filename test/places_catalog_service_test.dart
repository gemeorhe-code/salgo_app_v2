import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salgo_app/data/places_catalog_service.dart';
import 'package:salgo_app/models/place.dart';

Map<String, dynamic> _row(
  int id, {
  String name = 'Lugar',
  String category = 'Parques',
  double lat = 7.1,
  double lng = -73.1,
  String? imageUrl,
}) {
  return <String, dynamic>{
    'id': id,
    'name': name,
    'category': category,
    'city': 'Bucaramanga',
    'rating': 4.5,
    'review_count': 10,
    'address': 'Dirección $id',
    'schedule': 'Todo el día',
    'price': 'Gratis',
    'description': 'Descripción $id',
    'lat': lat,
    'lng': lng,
    'image_url': imageUrl,
    'is_active': true,
  };
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    PlacesCatalog.resetForTesting();
  });

  test('sin cliente ni caché devuelve null sin lanzar', () async {
    final PlacesCatalogService service = PlacesCatalogService(client: null);

    expect(await service.loadFromCache(), isNull);
    expect(await service.fetchRemote(), isNull);
  });

  test('descarta filas inválidas y normaliza categoría desconocida', () {
    final List<Place> places = PlacesCatalogService.parseRows(<dynamic>[
      _row(1, category: 'Cocina exótica'),
      _row(2, lat: 91),
      _row(3, lng: -181),
      _row(4, name: ''),
      _row(5, imageUrl: 'http://example.com/a.jpg'),
      _row(6, imageUrl: 'https://example.com/a.jpg'),
    ]);

    expect(places.map((Place place) => place.id), <int>[1, 5, 6]);
    expect(places.first.category, 'Otro');
    expect(places[1].imageUrl, isNull);
    expect(places[2].imageUrl, 'https://example.com/a.jpg');
  });

  test('guarda y lee la caché del catálogo', () async {
    final PlacesCatalogService service = PlacesCatalogService(client: null);
    final List<Place> places = PlacesCatalogService.parseRows(<dynamic>[
      _row(9),
    ]);

    await service.saveToCache(places);
    final List<Place>? cached = await PlacesCatalogService(
      client: null,
    ).loadFromCache();

    expect(cached, isNotNull);
    expect(cached!.single.id, 9);
  });
}
