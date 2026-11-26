class Place {
  const Place({
    required this.id,
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
    this.imageUrl,
    this.isFavorite = false,
    this.isActive = true,
  });

  final int id;
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

  /// Ruta o URL de la imagen. Cuando es null se muestra un placeholder
  /// con gradiente e ícono representativo.
  final String? imageUrl;
  final bool isFavorite;
  final bool isActive;

  Place copyWith({String? imageUrl, bool? isFavorite, bool? isActive}) {
    return Place(
      id: id,
      name: name,
      category: category,
      city: city,
      rating: rating,
      reviewCount: reviewCount,
      address: address,
      schedule: schedule,
      price: price,
      description: description,
      lat: lat,
      lng: lng,
      imageUrl: imageUrl ?? this.imageUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      isActive: isActive ?? this.isActive,
    );
  }
}
