class Weather {
  final String id;
  final DateTime dateTime;
  final double temperature;
  final double humidity;
  final double windSpeed;
  final String condition;
  final String description;
  final String icon;
  final double? precipitation;
  final double? pressure;
  final double? visibility;

  Weather({
    required this.id,
    required this.dateTime,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.condition,
    required this.description,
    required this.icon,
    this.precipitation,
    this.pressure,
    this.visibility,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      id: json['id'] ?? '',
      dateTime: DateTime.parse(json['dateTime']),
      temperature: (json['temperature'] ?? 0).toDouble(),
      humidity: (json['humidity'] ?? 0).toDouble(),
      windSpeed: (json['windSpeed'] ?? 0).toDouble(),
      condition: json['condition'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      precipitation: json['precipitation']?.toDouble(),
      pressure: json['pressure']?.toDouble(),
      visibility: json['visibility']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'temperature': temperature,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'condition': condition,
      'description': description,
      'icon': icon,
      'precipitation': precipitation,
      'pressure': pressure,
      'visibility': visibility,
    };
  }
}

class WeatherForecast {
  final List<Weather> hourly;
  final List<Weather> daily;

  WeatherForecast({
    required this.hourly,
    required this.daily,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    return WeatherForecast(
      hourly: (json['hourly'] as List<dynamic>?)
              ?.map((e) => Weather.fromJson(e))
              .toList() ??
          [],
      daily: (json['daily'] as List<dynamic>?)
              ?.map((e) => Weather.fromJson(e))
              .toList() ??
          [],
    );
  }
}
