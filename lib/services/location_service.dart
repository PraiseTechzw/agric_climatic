import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Zimbabwe cities with coordinates
  static const Map<String, Map<String, double>> _zimbabweCities = {
    'Harare': {'lat': -17.8252, 'lon': 31.0335},
    'Bulawayo': {'lat': -20.1569, 'lon': 28.5891},
    'Chitungwiza': {'lat': -18.0128, 'lon': 31.0756},
    'Mutare': {'lat': -18.9707, 'lon': 32.6722},
    'Gweru': {'lat': -19.4500, 'lon': 29.8167},
    'Kwekwe': {'lat': -18.9283, 'lon': 29.8149},
    'Kadoma': {'lat': -18.3333, 'lon': 29.9167},
    'Masvingo': {'lat': -20.0744, 'lon': 30.8328},
    'Chinhoyi': {'lat': -17.3667, 'lon': 30.2000},
    'Bindura': {'lat': -17.3019, 'lon': 31.3306},
    'Marondera': {'lat': -18.1853, 'lon': 31.5519},
    'Victoria Falls': {'lat': -17.9243, 'lon': 25.8572},
    'Hwange': {'lat': -18.3644, 'lon': 26.4981},
    'Gwanda': {'lat': -20.9333, 'lon': 29.0000},
  };

  Position? _currentPosition;
  String? _currentCity;
  bool _isLocationEnabled = false;

  Position? get currentPosition => _currentPosition;
  String? get currentCity => _currentCity;
  bool get isLocationEnabled => _isLocationEnabled;

  Future<bool> requestLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      _isLocationEnabled = true;
      return true;
    } catch (e) {
      _isLocationEnabled = false;
      throw Exception('Failed to get location permission: $e');
    }
  }

  Future<Position> getCurrentLocation() async {
    try {
      await requestLocationPermission();

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      );

      await _determineZimbabweLocation(_currentPosition!);
      return _currentPosition!;
    } catch (e) {
      throw Exception('Failed to get current location: $e');
    }
  }

  Future<void> _determineZimbabweLocation(Position position) async {
    try {
      // Try reverse geocoding first
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          final cityName =
              placemark.locality ?? placemark.administrativeArea ?? 'Unknown';

          if (_zimbabweCities.containsKey(cityName)) {
            _currentCity = cityName;
            return;
          }
        }
      } catch (e) {
        // Fallback to distance calculation
      }

      // Find closest city by distance
      String closestCity = 'Harare';
      double minDistance = double.infinity;

      for (final entry in _zimbabweCities.entries) {
        final city = entry.key;
        final data = entry.value;
        final distance = _calculateDistance(
          position.latitude,
          position.longitude,
          data['lat']!,
          data['lon']!,
        );

        if (distance < minDistance) {
          minDistance = distance;
          closestCity = city;
        }
      }

      _currentCity = closestCity;
    } catch (e) {
      _currentCity = 'Harare';
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371;
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  List<String> getAllZimbabweCities() {
    return _zimbabweCities.keys.toList();
  }

  void resetLocation() {
    _currentPosition = null;
    _currentCity = null;
    _isLocationEnabled = false;
  }

  // Get location accuracy status
  String getLocationAccuracyStatus() {
    if (_currentPosition == null) return 'No location data';

    final accuracy = _currentPosition!.accuracy;
    if (accuracy <= 10) {
      return 'High accuracy (${accuracy.toStringAsFixed(1)}m)';
    } else if (accuracy <= 50) {
      return 'Medium accuracy (${accuracy.toStringAsFixed(1)}m)';
    } else {
      return 'Low accuracy (${accuracy.toStringAsFixed(1)}m)';
    }
  }
}
