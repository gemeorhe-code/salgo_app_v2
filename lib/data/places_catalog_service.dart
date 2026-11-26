import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/place.dart';
import 'mock_data.dart';
import 'supabase_gate.dart';

class PlacesCatalog {
  PlacesCatalog._();

  static final ValueNotifier<List<Place>> places = ValueNotifier<List<Place>>(
    List<Place>.unmodifiable(MockData.places),
  );

  static void publish(List<Place> places) {
    PlacesCatalog.places.value = List<Place>.unmodifiable(places);
  }

  static void resetForTesting() {
    publish(MockData.places);
  }
}

class PlacesCatalogService {
  PlacesCatalogService({
    SupabaseClient? client,
    this.storage,
    this.timeout = const Duration(seconds: 8),
  }) : _client = client ?? SupabaseGate.client;

  static const String storageKey = 'salgo_places_cache_v1';
  static const String _table = 'salgo_places';
  static const int _schema = 1;
  static const Set<String> knownCategories = <String>{
    'Deportes',
    'Cine',
    'Parques',
    'Juegos',
    'Músicas',
    'Furniture',
    'Restaurante',
    'Otro',
  };

  final SupabaseClient? _client;
  SharedPreferences? storage;
  final Duration timeout;

  Future<List<Place>?> loadFromCache() async {
    final SharedPreferences? storage = await _resolveStorage();
    if (storage == null) return null;
    final String? raw = storage.getString(storageKey);
    if (raw == null) return null;
    try {
      final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['schema'] != _schema) {
        await storage.remove(storageKey);
        return null;
      }
      final Object? rawPlaces = data['places'];
      if (rawPlaces is! List<dynamic>) {
        await storage.remove(storageKey);
        return null;
      }
      final List<Place> places = parseRows(rawPlaces);
      if (places.isEmpty) {
        await storage.remove(storageKey);
        return null;
      }
      return places;
    } on Object {
      await storage.remove(storageKey).catchError((Object _) async => false);
      return null;
    }
  }

  Future<List<Place>?> fetchRemote() async {
    final SupabaseClient? client = _client;
    if (client == null) return null;
    try {
      return await _fetchAndCache(client).timeout(timeout);
    } on Object {
      return null;
    }
  }

  Future<void> saveToCache(List<Place> places) async {
    final SharedPreferences? storage = await _resolveStorage();
    if (storage == null || places.isEmpty) return;
    try {
      await storage.setString(
        storageKey,
        jsonEncode(<String, dynamic>{
          'schema': _schema,
          'savedAt': DateTime.now().toUtc().toIso8601String(),
          'places': places.map(_placeToCacheMap).toList(),
        }),
      );
    } on Object {
      return;
    }
  }

  Future<List<Place>?> _fetchAndCache(SupabaseClient client) async {
    final List<Map<String, dynamic>> rows = await client
        .from(_table)
        .select()
        .eq('is_active', true)
        .order('id');
    final List<Place> places = parseRows(rows);
    if (places.isEmpty) return null;
    await saveToCache(places);
    return places;
  }

  Future<SharedPreferences?> _resolveStorage() async {
    final SharedPreferences? resolved = storage;
    if (resolved != null) return resolved;
    try {
      storage = await SharedPreferences.getInstance();
      return storage;
    } on Object {
      return null;
    }
  }

  static List<Place> parseRows(List<dynamic> rows) {
    final List<Place> places = <Place>[];
    for (final Object? row in rows) {
      final Map<String, dynamic>? data = _asStringMap(row);
      if (data == null) continue;
      final Place? place = placeFromRow(data);
      if (place != null) places.add(place);
    }
    places.sort((Place a, Place b) => a.id.compareTo(b.id));
    return List<Place>.unmodifiable(places);
  }

  static Place? placeFromRow(Map<String, dynamic> row) {
    final int? id = _intOf(row['id']);
    if (id == null || id <= 0) return null;

    final String name = _stringOf(row['name']);
    final String categoryRaw = _stringOf(row['category']);
    final String city = _stringOf(row['city']);
    final String address = _stringOf(row['address']);
    final String schedule = _stringOf(row['schedule']);
    final String price = _stringOf(row['price']);
    final String description = _stringOf(row['description']);

    if (name.isEmpty ||
        categoryRaw.isEmpty ||
        city.isEmpty ||
        address.isEmpty ||
        schedule.isEmpty ||
        price.isEmpty ||
        description.isEmpty) {
      return null;
    }

    final double? rating = _doubleOf(row['rating']);
    if (rating == null || !rating.isFinite || rating < 0) return null;

    final int? reviewCount = _intOf(row['review_count']);
    if (reviewCount == null || reviewCount < 0) return null;

    final double? lat = _doubleOf(row['lat']);
    if (lat == null || !lat.isFinite || lat < -90 || lat > 90) return null;

    final double? lng = _doubleOf(row['lng']);
    if (lng == null || !lng.isFinite || lng < -180 || lng > 180) return null;

    final String category = knownCategories.contains(categoryRaw)
        ? categoryRaw
        : 'Otro';

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
      imageUrl: _httpsUrlOf(row['image_url']),
      isActive: row['is_active'] is bool ? row['is_active'] as bool : true,
    );
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

  static String _stringOf(Object? value) =>
      value is String ? value.trim() : '';

  static int? _intOf(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static double? _doubleOf(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  static String? _httpsUrlOf(Object? value) {
    final String raw = _stringOf(value);
    if (raw.isEmpty) return null;
    final Uri? uri = Uri.tryParse(raw);
    if (uri == null || uri.host.isEmpty) return null;
    if (uri.scheme.toLowerCase() != 'https') return null;
    return raw;
  }

  static Map<String, dynamic> _placeToCacheMap(Place place) =>
      <String, dynamic>{
        'id': place.id,
        'name': place.name,
        'category': place.category,
        'city': place.city,
        'rating': place.rating,
        'review_count': place.reviewCount,
        'address': place.address,
        'schedule': place.schedule,
        'price': place.price,
        'description': place.description,
        'lat': place.lat,
        'lng': place.lng,
        'image_url': place.imageUrl,
        'is_active': place.isActive,
      };
}
