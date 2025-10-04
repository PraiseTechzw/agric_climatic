import 'package:flutter/material.dart';

class WeatherAlert {
  final String id;
  final String title;
  final String description;
  final String severity;
  final String duration;
  final String location;
  final DateTime date;
  final String icon;
  final String type;
  final DateTime startTime;
  final DateTime endTime;
  final bool isActive;
  final List<String> recommendations;

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
    required this.startTime,
    required this.endTime,
    required this.isActive,
    required this.recommendations,
  });

  factory WeatherAlert.fromJson(Map<String, dynamic> json) {
    return WeatherAlert(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      severity: json['severity'],
      duration: json['duration'],
      location: json['location'],
      date: DateTime.parse(json['date']),
      icon: json['icon'],
      type: json['type'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      isActive: json['isActive'] ?? false,
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }

  Color get severityColor {
    switch (severity) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'critical':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData get severityIcon {
    switch (severity) {
      case 'low':
        return Icons.info_outline;
      case 'medium':
        return Icons.warning_outlined;
      case 'high':
        return Icons.warning;
      case 'critical':
        return Icons.error;
      default:
        return Icons.help_outline;
    }
  }
}
