import '../data/mock_data.dart';
import '../data/places_catalog_service.dart';
import '../models/place.dart';

class PlaceFormValues {
  const PlaceFormValues({
    this.id,
    required this.name,
    required this.category,
    required this.city,
    required this.rating,
    required this.reviewCount,
    required this.address,
    required this.schedule,
    required this.price,
    required this.description,
    required this.lat,
    required this.lng,
    required this.imageUrl,
    required this.isActive,
  });

  factory PlaceFormValues.fromPlace(Place place) {
    return PlaceFormValues(
      id: place.id,
      name: place.name,
      category: place.category,
      city: place.city,
      rating: place.rating,
      reviewCount: place.reviewCount,
      address: place.address,
      schedule: place.schedule,
      price: place.price,
      description: place.description,
      lat: place.lat,
      lng: place.lng,
      imageUrl: place.imageUrl ?? '',
      isActive: place.isActive,
    );
  }

  final int? id;
  final String name;
  final String category;
  final String city;
  final double rating;
  final int reviewCount;
  final String address;
  final String schedule;
  final String price;
  final String description;
  final double lat;
  final double lng;
  final String imageUrl;
  final bool isActive;

  PlaceFormValues copyWith({
    int? id,
    String? name,
    String? category,
    String? city,
    double? rating,
    int? reviewCount,
    String? address,
    String? schedule,
    String? price,
    String? description,
    double? lat,
    double? lng,
    String? imageUrl,
    bool? isActive,
  }) {
    return PlaceFormValues(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      city: city ?? this.city,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      address: address ?? this.address,
      schedule: schedule ?? this.schedule,
      price: price ?? this.price,
      description: description ?? this.description,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toRemote() {
    final String trimmedImageUrl = imageUrl.trim();
    return <String, dynamic>{
      'name': name.trim(),
      'category': category,
      'city': city,
      'rating': rating,
      'review_count': reviewCount,
      'address': address.trim(),
      'schedule': schedule.trim(),
      'price': price.trim(),
      'description': description.trim(),
      'lat': lat,
      'lng': lng,
      'image_url': trimmedImageUrl.isEmpty ? null : trimmedImageUrl,
      'is_active': isActive,
    };
  }
}

class PlaceFormValidator {
  static const Set<String> categories = PlacesCatalogService.knownCategories;
  static const List<String> cities = MockData.cities;

  static Map<String, String> validate(PlaceFormValues values) {
    final Map<String, String> errors = <String, String>{};

    if (values.name.trim().isEmpty) {
      errors['name'] = 'Ingresa el nombre del lugar.';
    }
    if (!categories.contains(values.category)) {
      errors['category'] = 'Selecciona una categoría válida.';
    }
    if (!cities.contains(values.city)) {
      errors['city'] = 'Selecciona una ciudad válida.';
    }
    if (!values.rating.isFinite || values.rating < 0 || values.rating > 5) {
      errors['rating'] = 'El rating debe estar entre 0 y 5.';
    }
    if (values.reviewCount < 0) {
      errors['reviewCount'] = 'El número de reseñas no puede ser negativo.';
    }
    if (values.address.trim().isEmpty) {
      errors['address'] = 'Ingresa la dirección.';
    }
    if (values.schedule.trim().isEmpty) {
      errors['schedule'] = 'Ingresa el horario.';
    }
    if (values.price.trim().isEmpty) {
      errors['price'] = 'Ingresa el precio.';
    }
    if (values.description.trim().isEmpty) {
      errors['description'] = 'Ingresa la descripción.';
    }
    if (!values.lat.isFinite || values.lat < -90 || values.lat > 90) {
      errors['lat'] = 'La latitud debe estar entre -90 y 90.';
    }
    if (!values.lng.isFinite || values.lng < -180 || values.lng > 180) {
      errors['lng'] = 'La longitud debe estar entre -180 y 180.';
    }

    final String imageUrl = values.imageUrl.trim();
    if (imageUrl.isNotEmpty) {
      final Uri? uri = Uri.tryParse(imageUrl);
      if (uri == null ||
          uri.host.isEmpty ||
          uri.scheme.toLowerCase() != 'https') {
        errors['imageUrl'] = 'La imagen debe ser una URL https válida.';
      }
    }

    return errors;
  }
}
