class WeatherPattern {
  final String id;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final String patternType;
  final String description;
  final double severity;
  final List<String> indicators;
  final Map<String, dynamic> statistics;
  final List<String> impacts;
  final List<String> recommendations;

  WeatherPattern({
    required this.id,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.patternType,
    required this.description,
    required this.severity,
    required this.indicators,
    required this.statistics,
    required this.impacts,
    required this.recommendations,
  });

  factory WeatherPattern.fromJson(Map<String, dynamic> json) {
    return WeatherPattern(
      id: json['id'] ?? '',
      location: json['location'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      patternType: json['patternType'] ?? '',
      description: json['description'] ?? '',
      severity: (json['severity'] ?? 0).toDouble(),
      indicators: List<String>.from(json['indicators'] ?? []),
      statistics: Map<String, dynamic>.from(json['statistics'] ?? {}),
      impacts: List<String>.from(json['impacts'] ?? []),
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location': location,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'patternType': patternType,
      'description': description,
      'severity': severity,
      'indicators': indicators,
      'statistics': statistics,
      'impacts': impacts,
      'recommendations': recommendations,
    };
  }
}
