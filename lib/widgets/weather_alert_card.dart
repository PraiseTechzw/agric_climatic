import 'package:flutter/material.dart';
import '../models/weather_alert.dart';

class WeatherAlertCard extends StatelessWidget {
  final WeatherAlert alert;

  const WeatherAlertCard({
    super.key,
    required this.alert,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alert Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getSeverityColor(alert.severity).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getAlertIcon(alert.type),
                color: _getSeverityColor(alert.severity),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Alert Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Severity
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getSeverityColor(alert.severity),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          alert.severity,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Duration
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        alert.duration,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Description
                  Text(
                    alert.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Location and Date
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        alert.location,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(alert.date),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'HIGH':
        return Colors.orange;
      case 'MEDIUM':
        return Colors.blue;
      case 'LOW':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getAlertIcon(String type) {
    switch (type.toLowerCase()) {
      case 'thunderstorm':
        return Icons.thunderstorm_rounded;
      case 'drought':
      case 'dry':
        return Icons.wb_sunny_rounded;
      case 'flood':
        return Icons.water_drop_rounded;
      case 'wind':
        return Icons.air_rounded;
      case 'rain':
        return Icons.water_drop_rounded;
      case 'snow':
        return Icons.ac_unit_rounded;
      default:
        return Icons.warning_rounded;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
