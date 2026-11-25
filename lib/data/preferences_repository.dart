import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesRepository extends ChangeNotifier {
  PreferencesRepository._internal();
  static PreferencesRepository _instance = PreferencesRepository._internal();
  factory PreferencesRepository() => _instance;

  static void resetForTesting() {
    _instance = PreferencesRepository._internal();
  }

  static const String _storageKey = 'salgo_preferences';

  String? _plan;
  double _budget = 0;
  String? _companion;
  String? _place;
  double _minutes = 0;

  SharedPreferences? _storage;

  String? get plan => _plan;
  double get budget => _budget;
  String? get companion => _companion;
  String? get place => _place;
  double get minutes => _minutes;

  bool get hasData =>
      _plan != null ||
      _companion != null ||
      _place != null ||
      _budget > 0 ||
      _minutes > 0;

  Future<void> init(SharedPreferences? storage) async {
    _storage = storage;
    if (storage == null) return;
    try {
      final String? raw = storage.getString(_storageKey);
      if (raw == null) return;
      final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;
      fromMap(data);
    } catch (_) {
      try {
        await storage.remove(_storageKey);
      } catch (_) {}
    }
  }

  Future<void> saveAll({
    required String? plan,
    required double budget,
    required String? companion,
    required String? place,
    required double minutes,
  }) async {
    _plan = plan;
    _budget = budget;
    _companion = companion;
    _place = place;
    _minutes = minutes;
    await _persist();
    notifyListeners();
  }

  void updatePlan(String? plan) {
    _plan = plan;
    notifyListeners();
  }

  void updateBudget(double budget) {
    _budget = budget;
    notifyListeners();
  }

  void updateCompanion(String? companion) {
    _companion = companion;
    notifyListeners();
  }

  void updatePlace(String? place) {
    _place = place;
    notifyListeners();
  }

  void updateMinutes(double minutes) {
    _minutes = minutes;
    notifyListeners();
  }

  Map<String, dynamic> toMap() {
    return {
      'plan': _plan,
      'budget': _budget,
      'companion': _companion,
      'place': _place,
      'minutes': _minutes,
    };
  }

  void fromMap(Map<String, dynamic> map) {
    _plan = map['plan'] as String?;
    _budget = (map['budget'] as num?)?.toDouble() ?? 0;
    _companion = map['companion'] as String?;
    _place = map['place'] as String?;
    _minutes = (map['minutes'] as num?)?.toDouble() ?? 0;
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      await _storage?.setString(_storageKey, jsonEncode(toMap()));
    } catch (_) {}
  }
}
