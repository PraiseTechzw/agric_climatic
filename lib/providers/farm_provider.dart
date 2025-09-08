import 'package:flutter/foundation.dart';
import '../models/farm.dart';
import '../services/farm_service.dart';

class FarmProvider with ChangeNotifier {
  final FarmService _farmService = FarmService();

  List<Farm> _farms = [];
  bool _isLoading = false;
  String? _error;

  List<Farm> get farms => _farms;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadFarms() async {
    _setLoading(true);
    try {
      _farms = await _farmService.getFarms();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addFarm(Farm farm) async {
    try {
      final newFarm = await _farmService.addFarm(farm);
      _farms.add(newFarm);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> updateFarm(Farm farm) async {
    try {
      await _farmService.updateFarm(farm);
      final index = _farms.indexWhere((f) => f.id == farm.id);
      if (index != -1) {
        _farms[index] = farm;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> deleteFarm(String farmId) async {
    try {
      await _farmService.deleteFarm(farmId);
      _farms.removeWhere((f) => f.id == farmId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
