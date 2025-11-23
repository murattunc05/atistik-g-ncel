import 'package:flutter/material.dart';

class ComparisonService extends ChangeNotifier {
  static final ComparisonService _instance = ComparisonService._internal();
  factory ComparisonService() => _instance;
  ComparisonService._internal();

  final List<Map<String, dynamic>> _selectedHorses = [];

  List<Map<String, dynamic>> get selectedHorses => _selectedHorses;

  void addHorse(Map<String, dynamic> horse) {
    if (!_selectedHorses.any((h) => h['name'] == horse['name'])) {
      _selectedHorses.add(horse);
      notifyListeners();
    }
  }

  void removeHorse(String horseName) {
    _selectedHorses.removeWhere((h) => h['name'] == horseName);
    notifyListeners();
  }

  void clear() {
    _selectedHorses.clear();
    notifyListeners();
  }

  bool isSelected(String horseName) {
    return _selectedHorses.any((h) => h['name'] == horseName);
  }
}
