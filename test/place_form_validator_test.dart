import 'package:flutter_test/flutter_test.dart';

import 'package:salgo_app/utils/place_form_validator.dart';

void main() {
  PlaceFormValues validValues() => const PlaceFormValues(
    name: 'Parque San Pio',
    category: 'Parques',
    city: 'Bucaramanga',
    rating: 4.5,
    reviewCount: 120,
    address: 'Calle 15',
    schedule: 'Todos los días',
    price: 'Gratis',
    description: 'Lugar para caminar.',
    lat: 7.118523,
    lng: -73.110751,
    imageUrl: '',
    isActive: true,
  );

  test('acepta valores válidos', () {
    expect(PlaceFormValidator.validate(validValues()), isEmpty);
  });

  test('valida latitud y longitud', () {
    final Map<String, String> errors = PlaceFormValidator.validate(
      validValues().copyWith(lat: 91, lng: -181),
    );
    expect(errors['lat'], contains('latitud'));
    expect(errors['lng'], contains('longitud'));
  });

  test('valida rating 0..5 y reseñas no negativas', () {
    final Map<String, String> errors = PlaceFormValidator.validate(
      validValues().copyWith(rating: 5.1, reviewCount: -1),
    );
    expect(errors['rating'], contains('rating'));
    expect(errors['reviewCount'], contains('negativo'));
  });

  test('valida categoría y ciudad conocidas', () {
    final Map<String, String> errors = PlaceFormValidator.validate(
      validValues().copyWith(category: 'Otro invalido', city: 'Bogotá'),
    );
    expect(errors['category'], isNotEmpty);
    expect(errors['city'], isNotEmpty);
  });

  test('acepta https y rechaza http', () {
    expect(
      PlaceFormValidator.validate(
        validValues().copyWith(imageUrl: 'https://example.com/a.png'),
      ),
      isEmpty,
    );
    expect(
      PlaceFormValidator.validate(
        validValues().copyWith(imageUrl: 'http://example.com/a.png'),
      )['imageUrl'],
      isNotEmpty,
    );
  });

  test('valida campos de texto obligatorios', () {
    final Map<String, String> errors = PlaceFormValidator.validate(
      validValues().copyWith(
        name: '  ',
        address: '',
        schedule: '',
        price: '',
        description: '',
      ),
    );
    expect(errors.keys, containsAll(<String>[
      'name',
      'address',
      'schedule',
      'price',
      'description',
    ]));
  });

  test('toRemote convierte image_url vacío en null', () {
    expect(validValues().toRemote()['image_url'], isNull);
    expect(
      validValues().copyWith(imageUrl: ' https://example.com/a.png ').toRemote()[
          'image_url'],
      'https://example.com/a.png',
    );
  });
}
