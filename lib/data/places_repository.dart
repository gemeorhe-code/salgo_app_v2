import 'package:flutter/material.dart';

import '../models/place.dart';
import '../data/mock_data.dart';

class PlacesRepository extends ChangeNotifier {
  PlacesRepository({List<Place>? places})
    : _places = List<Place>.of(places ?? MockData.places);

  final List<Place> _places;

  List<Place> get places => List<Place>.unmodifiable(_places);

  List<Place> get favorites =>
      _places.where((place) => place.isFavorite).toList(growable: false);

  List<Place> placesByCity(String city) =>
      _places.where((place) => place.city == city).toList(growable: false);

  Place? findById(int id) {
    for (final Place place in _places) {
      if (place.id == id) return place;
    }
    return null;
  }

  Place? placeById(int id) => findById(id);

  void toggleFavorite(int id) {
    for (int i = 0; i < _places.length; i++) {
      if (_places[i].id == id) {
        _places[i] = _places[i].copyWith(isFavorite: !_places[i].isFavorite);
        notifyListeners();
        return;
      }
    }
  }
}
