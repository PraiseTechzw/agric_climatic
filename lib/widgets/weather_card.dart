import 'package:flutter/material.dart';
import '../models/weather.dart';

class WeatherCard extends StatelessWidget {
  final Weather weather;

  const WeatherCard({
    super.key,
    required this.weather,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            Theme.of(context).colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Weather',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${weather.temperature.toStringAsFixed(1)}°C',
                        style:
                            Theme.of(context).textTheme.displayMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _getWeatherIcon(weather.condition),
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                weather.description,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildWeatherInfo(
                    'Humidity',
                    '${weather.humidity.toStringAsFixed(1)}%',
                    Icons.water_drop,
                    Colors.blue,
                  ),
                  _buildWeatherInfo(
                    'Wind Speed',
                    '${weather.windSpeed.toStringAsFixed(1)} m/s',
                    Icons.air,
                    Colors.green,
                  ),
                  _buildWeatherInfo(
                    'Pressure',
                    '${weather.pressure?.toStringAsFixed(1) ?? 'N/A'} hPa',
                    Icons.speed,
                    Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherInfo(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
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
