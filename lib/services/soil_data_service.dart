import '../models/soil_data.dart';
import 'zimbabwe_api_service.dart';
import 'firebase_service.dart';

class SoilDataService {
  // Using OpenWeatherMap's One Call API for additional data
  // and Open-Meteo for soil data (free tier available)
  // static const String _baseUrl = 'https://api.open-meteo.com/v1';

  // Get soil data for a specific location
  Future<SoilData> getSoilData({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Try to get from Firebase first
      final city = _getCityFromCoordinates(latitude, longitude);
      final cachedData = await FirebaseService.getLatestSoilData(city);

      if (cachedData != null) {
        // Check if data is recent (less than 24 hours old)
        final hoursSinceUpdate = DateTime.now()
            .difference(cachedData.lastUpdated)
            .inHours;
        if (hoursSinceUpdate < 24) {
          return cachedData;
        }
      }

      // Get fresh data from Zimbabwe API
      final soilData = await ZimbabweApiService.getZimbabweSoilData(city);

      // Save to Firebase
      await FirebaseService.saveSoilData(soilData);

      return soilData;
    } catch (e) {
      throw Exception(
        'Failed to get soil data for coordinates $latitude, $longitude: $e',
      );
    }
  }

  // Get soil health score (0-100)
  double getSoilHealthScore(SoilData soilData) {
    double score = 0.0;

    // pH score (optimal range 6.0-7.5)
    if (soilData.ph >= 6.0 && soilData.ph <= 7.5) {
      score += 25.0;
    } else if (soilData.ph >= 5.5 && soilData.ph <= 8.0) {
      score += 20.0;
    } else {
      score += 10.0;
    }

    // Organic matter score (optimal > 3%)
    if (soilData.organicMatter >= 3.0) {
      score += 25.0;
    } else if (soilData.organicMatter >= 2.0) {
      score += 20.0;
    } else {
      score += 10.0;
    }

    // Nutrient levels
    if (soilData.nitrogen >= 50.0)
      score += 15.0;
    else if (soilData.nitrogen >= 30.0)
      score += 10.0;
    else
      score += 5.0;

    if (soilData.phosphorus >= 30.0)
      score += 15.0;
    else if (soilData.phosphorus >= 15.0)
      score += 10.0;
    else
      score += 5.0;

    if (soilData.potassium >= 200.0)
      score += 20.0;
    else if (soilData.potassium >= 150.0)
      score += 15.0;
    else
      score += 10.0;

    return score.clamp(0.0, 100.0);
  }

  // Get city name from coordinates (simplified)
  String _getCityFromCoordinates(double latitude, double longitude) {
    // This is a simplified mapping - in production, you'd use reverse geocoding
    if (latitude > -17.5 &&
        latitude < -17.0 &&
        longitude > 30.5 &&
        longitude < 31.5) {
      return 'Harare';
    } else if (latitude > -20.5 &&
        latitude < -19.5 &&
        longitude > 28.0 &&
        longitude < 29.0) {
      return 'Bulawayo';
    } else if (latitude > -19.0 &&
        latitude < -18.5 &&
        longitude > 30.5 &&
        longitude < 31.5) {
      return 'Chitungwiza';
    } else if (latitude > -19.0 &&
        latitude < -18.5 &&
        longitude > 32.0 &&
        longitude < 33.0) {
      return 'Mutare';
    } else if (latitude > -19.5 &&
        latitude < -19.0 &&
        longitude > 29.0 &&
        longitude < 30.0) {
      return 'Gweru';
    } else if (latitude > -19.0 &&
        latitude < -18.5 &&
        longitude > 29.5 &&
        longitude < 30.0) {
      return 'Kwekwe';
    } else if (latitude > -18.5 &&
        latitude < -18.0 &&
        longitude > 29.5 &&
        longitude < 30.0) {
      return 'Kadoma';
    } else if (latitude > -20.5 &&
        latitude < -19.5 &&
        longitude > 30.0 &&
        longitude < 31.0) {
      return 'Masvingo';
    } else if (latitude > -17.5 &&
        latitude < -17.0 &&
        longitude > 30.0 &&
        longitude < 30.5) {
      return 'Chinhoyi';
    } else if (latitude > -17.5 &&
        latitude < -17.0 &&
        longitude > 31.0 &&
        longitude < 31.5) {
      return 'Bindura';
    } else if (latitude > -18.5 &&
        latitude < -18.0 &&
        longitude > 31.0 &&
        longitude < 32.0) {
      return 'Marondera';
    } else if (latitude > -18.0 &&
        latitude < -17.5 &&
        longitude > 25.5 &&
        longitude < 26.0) {
      return 'Victoria Falls';
    } else if (latitude > -18.5 &&
        latitude < -18.0 &&
        longitude > 26.0 &&
        longitude < 27.0) {
      return 'Hwange';
    } else if (latitude > -21.0 &&
        latitude < -20.5 &&
        longitude > 28.5 &&
        longitude < 29.5) {
      return 'Gwanda';
    }
    return 'Harare'; // Default fallback
  }

  // Get soil recommendations based on data
  List<String> getSoilRecommendations(SoilData soilData) {
    final recommendations = <String>[];

    // pH recommendations
    if (soilData.ph < 6.0) {
      recommendations.add('Add lime to increase pH (target: 6.5-7.0)');
    } else if (soilData.ph > 7.5) {
      recommendations.add('Add sulfur or organic matter to decrease pH');
    }

    // Organic matter recommendations
    if (soilData.organicMatter < 3.0) {
      recommendations.add(
        'Add compost or organic matter to improve soil structure',
      );
    }

    // Nutrient recommendations
    if (soilData.nitrogen < 50.0) {
      recommendations.add('Apply nitrogen fertilizer (N-P-K: 20-10-10)');
    }

    if (soilData.phosphorus < 30.0) {
      recommendations.add('Apply phosphorus fertilizer (N-P-K: 10-20-10)');
    }

    if (soilData.potassium < 200.0) {
      recommendations.add('Apply potassium fertilizer (N-P-K: 10-10-20)');
    }

    // Moisture recommendations
    if (soilData.soilMoisture < 30.0) {
      recommendations.add(
        'Irrigate immediately - soil moisture critically low',
      );
    } else if (soilData.soilMoisture < 50.0) {
      recommendations.add('Consider irrigation - soil moisture is low');
    }

    // Drainage recommendations
    if (soilData.drainage == 'Poor') {
      recommendations.add(
        'Improve drainage with raised beds or drainage systems',
      );
    }

    return recommendations;
  }
}
