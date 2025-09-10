class Weather {
  final String id;
  final DateTime dateTime;
  final double temperature;
  final double humidity;
  final double windSpeed;
  final String condition;
  final String description;
  final String icon;
  final double pressure;
  final double? visibility;
  final double precipitation;
  final double? uvIndex;
  final double? feelsLike;
  final double? dewPoint;
  final double? windGust;
  final int? windDegree;
  final String? windDirection;
  final double? cloudCover;
  final AirQuality? airQuality;
  final PollenData? pollenData;

  Weather({
    required this.id,
    required this.dateTime,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.condition,
    required this.description,
    required this.icon,
    required this.pressure,
    this.visibility,
    required this.precipitation,
    this.uvIndex,
    this.feelsLike,
    this.dewPoint,
    this.windGust,
    this.windDegree,
    this.windDirection,
    this.cloudCover,
    this.airQuality,
    this.pollenData,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      id: json['id'] ?? '',
      dateTime: DateTime.parse(json['date_time']),
      temperature: json['temperature'].toDouble(),
      humidity: json['humidity'].toDouble(),
      windSpeed: json['wind_speed'].toDouble(),
      condition: json['condition'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      pressure: json['pressure'].toDouble(),
      visibility: json['visibility']?.toDouble(),
      precipitation: json['precipitation']?.toDouble() ?? 0.0,
      uvIndex: json['uv_index']?.toDouble(),
      feelsLike: json['feels_like']?.toDouble(),
      dewPoint: json['dew_point']?.toDouble(),
      windGust: json['wind_gust']?.toDouble(),
      windDegree: json['wind_degree']?.toInt(),
      windDirection: json['wind_direction'],
      cloudCover: json['cloud_cover']?.toDouble(),
      airQuality: json['air_quality'] != null
          ? AirQuality.fromJson(json['air_quality'])
          : null,
      pollenData: json['pollen_data'] != null
          ? PollenData.fromJson(json['pollen_data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date_time': dateTime.toIso8601String(),
      'temperature': temperature,
      'humidity': humidity,
      'wind_speed': windSpeed,
      'condition': condition,
      'description': description,
      'icon': icon,
      'pressure': pressure,
      'visibility': visibility,
      'precipitation': precipitation,
      'uv_index': uvIndex,
      'feels_like': feelsLike,
      'dew_point': dewPoint,
      'wind_gust': windGust,
      'wind_degree': windDegree,
      'wind_direction': windDirection,
      'cloud_cover': cloudCover,
      'air_quality': airQuality?.toJson(),
      'pollen_data': pollenData?.toJson(),
    };
  }
}

class WeatherForecast {
  final List<Weather> hourly;
  final List<Weather> daily;

  WeatherForecast({required this.hourly, required this.daily});
}

class AirQuality {
  final double? co; // Carbon Monoxide (μg/m3)
  final double? o3; // Ozone (μg/m3)
  final double? no2; // Nitrogen dioxide (μg/m3)
  final double? so2; // Sulphur dioxide (μg/m3)
  final double? pm2_5; // PM2.5 (μg/m3)
  final double? pm10; // PM10 (μg/m3)
  final int? usEpaIndex; // US EPA standard (1-6)
  final int? gbDefraIndex; // UK Defra Index (1-10)

  AirQuality({
    this.co,
    this.o3,
    this.no2,
    this.so2,
    this.pm2_5,
    this.pm10,
    this.usEpaIndex,
    this.gbDefraIndex,
  });

  factory AirQuality.fromJson(Map<String, dynamic> json) {
    return AirQuality(
      co: json['co']?.toDouble(),
      o3: json['o3']?.toDouble(),
      no2: json['no2']?.toDouble(),
      so2: json['so2']?.toDouble(),
      pm2_5: json['pm2_5']?.toDouble(),
      pm10: json['pm10']?.toDouble(),
      usEpaIndex: json['us-epa-index']?.toInt(),
      gbDefraIndex: json['gb-defra-index']?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'co': co,
      'o3': o3,
      'no2': no2,
      'so2': so2,
      'pm2_5': pm2_5,
      'pm10': pm10,
      'us-epa-index': usEpaIndex,
      'gb-defra-index': gbDefraIndex,
    };
  }
}

class PollenData {
  final double? hazel; // Pollen grains per cubic meter of air
  final double? alder;
  final double? birch;
  final double? oak;
  final double? grass;
  final double? mugwort;
  final double? ragweed;

  PollenData({
    this.hazel,
    this.alder,
    this.birch,
    this.oak,
    this.grass,
    this.mugwort,
    this.ragweed,
  });

  factory PollenData.fromJson(Map<String, dynamic> json) {
    return PollenData(
      hazel: json['Hazel']?.toDouble(),
      alder: json['Alder']?.toDouble(),
      birch: json['Birch']?.toDouble(),
      oak: json['Oak']?.toDouble(),
      grass: json['Grass']?.toDouble(),
      mugwort: json['Mugwort']?.toDouble(),
      ragweed: json['Ragweed']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Hazel': hazel,
      'Alder': alder,
      'Birch': birch,
      'Oak': oak,
      'Grass': grass,
      'Mugwort': mugwort,
      'Ragweed': ragweed,
    };
  }

  String getRiskLevel(String pollenType) {
    double? value;
    switch (pollenType.toLowerCase()) {
      case 'hazel':
        value = hazel;
        break;
      case 'alder':
        value = alder;
        break;
      case 'birch':
        value = birch;
        break;
      case 'oak':
        value = oak;
        break;
      case 'grass':
        value = grass;
        break;
      case 'mugwort':
        value = mugwort;
        break;
      case 'ragweed':
        value = ragweed;
        break;
    }

    if (value == null) return 'Unknown';
    if (value >= 1 && value < 20) return 'Low';
    if (value >= 20 && value < 100) return 'Moderate';
    if (value >= 100 && value < 300) return 'High';
    if (value >= 300) return 'Very High';
    return 'Unknown';
  }
}

class AstronomyData {
  final String sunrise;
  final String sunset;
  final String moonrise;
  final String moonset;
  final String moonPhase;
  final double moonIllumination;
  final bool isMoonUp;
  final bool isSunUp;

  AstronomyData({
    required this.sunrise,
    required this.sunset,
    required this.moonrise,
    required this.moonset,
    required this.moonPhase,
    required this.moonIllumination,
    required this.isMoonUp,
    required this.isSunUp,
  });

  factory AstronomyData.fromJson(Map<String, dynamic> json) {
    return AstronomyData(
      sunrise: json['sunrise'] ?? '',
      sunset: json['sunset'] ?? '',
      moonrise: json['moonrise'] ?? '',
      moonset: json['moonset'] ?? '',
      moonPhase: json['moon_phase'] ?? '',
      moonIllumination: json['moon_illumination']?.toDouble() ?? 0.0,
      isMoonUp: json['is_moon_up'] == 1,
      isSunUp: json['is_sun_up'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sunrise': sunrise,
      'sunset': sunset,
      'moonrise': moonrise,
      'moonset': moonset,
      'moon_phase': moonPhase,
      'moon_illumination': moonIllumination,
      'is_moon_up': isMoonUp ? 1 : 0,
      'is_sun_up': isSunUp ? 1 : 0,
    };
  }
}
