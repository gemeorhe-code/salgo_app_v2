import 'dart:async';

import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/place.dart';
import 'favorites_sync.dart';
import 'places_catalog_service.dart';
import 'supabase_gate.dart';

class PlacesRepository extends ChangeNotifier with WidgetsBindingObserver {
  PlacesRepository({
    List<Place>? places,
    FavoritesSyncService? sync,
    PlacesCatalogService? catalog,
  })  : _places = List<Place>.of(places ?? MockData.places),
        _sync = sync ?? FavoritesSyncService(),
        _catalog = catalog ?? PlacesCatalogService();

  final List<Place> _places;
  final FavoritesSyncService _sync;
  final PlacesCatalogService _catalog;
  bool _observerAdded = false;
  bool _disposed = false;

  ValueNotifier<String?> get syncMessage => _sync.errorNotifier;

  Future<void> init() async {
    if (!_observerAdded && !_disposed) {
      WidgetsBinding.instance.addObserver(this);
      _observerAdded = true;
    }
    await _sync.init();
    final List<Place> fallback = List<Place>.of(_places);
    final List<Place>? cached = await _catalog.loadFromCache();
    _replaceCatalog(cached ?? fallback);
  }

  Future<void> onSignedIn(String userId) async {
    await _sync.onSignedIn(userId);
    final List<Place>? remote = await _catalog.fetchRemote();
    if (remote == null) {
      _applyEntries();
      PlacesCatalog.publish(_places);
      notifyListeners();
      return;
    }
    _replaceCatalog(remote);
  }

  Future<void> onSignedOut() async {
    await _sync.onSignedOut();
    _applyEntries();
    PlacesCatalog.publish(_places);
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

  void _replaceCatalog(List<Place> places) {
    _places
      ..clear()
      ..addAll(places);
    _applyEntries();
    PlacesCatalog.publish(_places);
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || _disposed) return;
    if (SupabaseGate.client?.auth.currentUser == null) return;
    unawaited(_refreshRemoteCatalog());
  }

  Future<void> _refreshRemoteCatalog() async {
    final List<Place>? remote = await _catalog.fetchRemote();
    if (remote == null || _disposed) return;
    _replaceCatalog(remote);
  }

  @override
  void dispose() {
    _disposed = true;
    if (_observerAdded) {
      WidgetsBinding.instance.removeObserver(this);
      _observerAdded = false;
    }
    _sync.dispose();
    super.dispose();
  }
}
