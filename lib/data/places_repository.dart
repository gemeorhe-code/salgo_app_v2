import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/place.dart';
import 'favorites_sync.dart';

class PlacesRepository extends ChangeNotifier {
  PlacesRepository({List<Place>? places, FavoritesSyncService? sync})
    : _places = List<Place>.of(places ?? MockData.places),
      _sync = sync ?? FavoritesSyncService();

  final List<Place> _places;
  final FavoritesSyncService _sync;

  ValueNotifier<String?> get syncMessage => _sync.errorNotifier;

  Future<void> init() async {
    await _sync.init();
    _applyEntries();
    notifyListeners();
  }

  Future<void> onSignedIn(String userId) async {
    await _sync.onSignedIn(userId);
    _applyEntries();
    notifyListeners();
  }

  Future<void> onSignedOut() async {
    await _sync.onSignedOut();
    _applyEntries();
    notifyListeners();
  }

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
        final bool next = !_places[i].isFavorite;
        _places[i] = _places[i].copyWith(isFavorite: next);
        notifyListeners();
        _sync.enqueue(id, next);
        return;
      }
    }
  }

  void _applyEntries() {
    for (int i = 0; i < _places.length; i++) {
      final FavoriteEntry? entry = _sync.items[_places[i].id];
      final bool isFavorite = entry?.isFavorite ?? false;
      if (_places[i].isFavorite != isFavorite) {
        _places[i] = _places[i].copyWith(isFavorite: isFavorite);
      }
    }
  }

  @override
  void dispose() {
    _sync.dispose();
    super.dispose();
  }
}
