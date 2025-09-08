import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../widgets/weather_card.dart';
import '../widgets/forecast_card.dart';
import '../widgets/weather_chart.dart';
import '../widgets/weather_alert_card.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherProvider>().refreshAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weather Dashboard',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'Last updated: Just now',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<WeatherProvider>().refreshAll();
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).colorScheme.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primaryContainer,
              ],
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: Consumer<WeatherProvider>(
        builder: (context, weatherProvider, child) {
          return weatherProvider.isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading weather data...',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await weatherProvider.refreshAll();
                  },
                  color: Theme.of(context).colorScheme.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Location Display
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                weatherProvider.currentLocation,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Critical Weather Alerts
                        if (weatherProvider.weatherAlerts.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.warning_rounded,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Critical Weather Alerts',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red[700],
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...weatherProvider.weatherAlerts.map(
                            (alert) => WeatherAlertCard(alert: alert),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Current Weather
                        if (weatherProvider.currentWeather != null)
                          WeatherCard(
                            weather: weatherProvider.currentWeather!,
                          ),

                        const SizedBox(height: 20),

                        // Weather Chart
                        if (weatherProvider.hourlyForecast.isNotEmpty)
                          WeatherChart(
                            hourlyForecast: weatherProvider.hourlyForecast,
                          ),

                        const SizedBox(height: 20),

                        // 7-Day Forecast
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '7-Day Forecast',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (weatherProvider.dailyForecast.isNotEmpty)
                          ...weatherProvider.dailyForecast.map(
                            (forecast) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ForecastCard(
                                forecast: forecast,
                              ),
                            ),
                          ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
        },
      ),
    );
  }
}
