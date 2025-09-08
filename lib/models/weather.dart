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
}
