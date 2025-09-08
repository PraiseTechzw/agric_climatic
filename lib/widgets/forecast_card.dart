import 'package:flutter/material.dart';
import '../models/weather.dart';

class ForecastCard extends StatelessWidget {
  final Weather forecast;

  const ForecastCard({
    super.key,
    required this.forecast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Date
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(forecast.dateTime),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTime(forecast.dateTime),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),

            // Weather Icon
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getWeatherIcon(forecast.condition),
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),

            // Temperature
            Expanded(
              flex: 2,
              child: Text(
                '${forecast.temperature.toStringAsFixed(1)}°C',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                textAlign: TextAlign.center,
              ),
            ),

            // Description
            Expanded(
              flex: 3,
              child: Text(
                forecast.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final forecastDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (forecastDate == today) {
      return 'Today';
    } else if (forecastDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[dateTime.weekday - 1];
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return Icons.wb_sunny;
      case 'cloudy':
      case 'partly cloudy':
        return Icons.cloud;
      case 'rainy':
      case 'rain':
        return Icons.water_drop;
      case 'snowy':
      case 'snow':
        return Icons.snowing;
      case 'stormy':
      case 'thunderstorm':
        return Icons.thunderstorm;
      default:
        return Icons.wb_cloudy;
    }
  }
}
