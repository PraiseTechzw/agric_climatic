import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../widgets/location_dropdown.dart';

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
        title: const Text('Weather Dashboard'),
        actions: [
          Consumer<WeatherProvider>(
            builder: (context, weatherProvider, child) {
              return LocationDropdown(
                selectedLocation: weatherProvider.currentLocation,
                onLocationChanged: (location) {
                  weatherProvider.changeLocation(location);
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<WeatherProvider>(
        builder: (context, weatherProvider, child) {
          return weatherProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => weatherProvider.refreshAll(),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (weatherProvider.currentWeather != null)
                          _buildCurrentWeatherCard(
                              context, weatherProvider.currentWeather!),
                        const SizedBox(height: 16),
                        if (weatherProvider.weatherAlerts.isNotEmpty) ...[
                          Text('Weather Alerts',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          ...weatherProvider.weatherAlerts.map((alert) => Card(
                              child: ListTile(
                                  title: Text(alert.title),
                                  subtitle: Text(alert.description)))),
                        ],
                      ],
                    ),
                  ),
                );
        },
      ),
    );
  }

  Widget _buildCurrentWeatherCard(BuildContext context, weather) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('${weather.temperature.toStringAsFixed(1)}°C',
                style: Theme.of(context).textTheme.displayLarge),
            Text(weather.description),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('Humidity: ${weather.humidity.toStringAsFixed(0)}%'),
                Text('Wind: ${weather.windSpeed.toStringAsFixed(1)} km/h'),
                Text('Pressure: ${weather.pressure.toStringAsFixed(0)} hPa'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
