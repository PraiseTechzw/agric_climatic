class WeatherAlert {
  final String id;
  final String title;
  final String description;
  final String severity; // 'HIGH', 'MEDIUM', 'LOW'
  final String duration;
  final String location;
  final DateTime date;
  final String icon;
  final String type; // 'thunderstorm', 'drought', 'flood', etc.

  WeatherAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.duration,
    required this.location,
    required this.date,
    required this.icon,
    required this.type,
  });

  factory WeatherAlert.fromJson(Map<String, dynamic> json) {
    return WeatherAlert(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      severity: json['severity'] ?? 'LOW',
      duration: json['duration'] ?? '',
      location: json['location'] ?? '',
      date: DateTime.parse(json['date']),
      icon: json['icon'] ?? '',
      type: json['type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'severity': severity,
      'duration': duration,
      'location': location,
      'date': date.toIso8601String(),
      'icon': icon,
      'type': type,
    };
  }
}
