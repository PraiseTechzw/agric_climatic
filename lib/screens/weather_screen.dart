import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/weather_provider.dart';
import '../widgets/location_dropdown.dart';
import '../services/soil_data_service.dart';
import '../models/soil_data.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>
    with TickerProviderStateMixin {
  final SoilDataService _soilService = SoilDataService();
  SoilData? _soilData;
  late TabController _tabController;
  late AnimationController _cardAnimationController;
  late Animation<double> _cardSlideAnimation;
  late Animation<double> _cardFadeAnimation;

  // Forecast filters
  String _selectedPeriod = '7 Days';
  String _selectedView = 'Daily';
  final List<String> _periods = ['3 Days', '7 Days', '14 Days'];
  final List<String> _views = ['Daily', 'Hourly'];

  // Alert management
  final Set<String> _expandedAlerts = {};
  final Set<String> _dismissedAlerts = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize animations
    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _cardSlideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _cardAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _cardFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardAnimationController, curve: Curves.easeIn),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Try to detect location first, then load weather
      context.read<WeatherProvider>().detectLocation();
      _loadSoilData();
      _cardAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadSoilData() async {
    try {
      final weatherProvider = context.read<WeatherProvider>();
      final locationService = weatherProvider.locationService;

      // Use detected location if available, otherwise use Harare as default
      double latitude = -17.8252; // Harare default
      double longitude = 31.0335;

      if (locationService.currentPosition != null) {
        latitude = locationService.currentPosition!.latitude;
        longitude = locationService.currentPosition!.longitude;
      }

      final soilData = await _soilService.getSoilData(
        latitude: latitude,
        longitude: longitude,
      );

      setState(() {
        _soilData = soilData;
      });
    } catch (e) {
      // Handle error silently for now
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.wb_sunny,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Weather'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Current', icon: Icon(Icons.wb_sunny_outlined)),
            Tab(text: 'Forecast', icon: Icon(Icons.calendar_today)),
          ],
        ),
        actions: [
          // Location detection button
          IconButton(
            onPressed: () async {
              await context.read<WeatherProvider>().detectLocation();
              _loadSoilData(); // Reload soil data with new location
            },
            icon: const Icon(Icons.my_location),
            tooltip: 'Detect my location',
          ),
          // Notification badge
          Consumer<WeatherProvider>(
            builder: (context, weatherProvider, child) {
              final alertCount = weatherProvider.weatherAlerts.length;
              return Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () {
                        // Navigate to notifications screen
                        Navigator.pushNamed(context, '/notifications');
                      },
                    ),
                    if (alertCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$alertCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          Consumer<WeatherProvider>(
            builder: (context, weatherProvider, child) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: LocationDropdown(
                  selectedLocation: weatherProvider.currentLocation,
                  onLocationChanged: (location) {
                    weatherProvider.changeLocation(location);
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Current Weather Tab
          _buildCurrentWeatherTab(),
          // Forecast Tab
          _buildForecastTab(),
        ],
      ),
    );
  }

  // Build Current Weather Tab
  Widget _buildCurrentWeatherTab() {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, child) {
        return weatherProvider.isLoading
            ? _buildLoadingState()
            : RefreshIndicator(
                onRefresh: () async {
                  await weatherProvider.refreshAll();
                  await _loadSoilData();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Removed verbose backend banner to keep UI focused

                      // Location status
                      _buildLocationStatus(weatherProvider),

                      if (weatherProvider.currentWeather != null)
                        AnimatedBuilder(
                          animation: _cardAnimationController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _cardSlideAnimation.value),
                              child: Opacity(
                                opacity: _cardFadeAnimation.value,
                                child: child,
                              ),
                            );
                          },
                          child: _buildCurrentWeatherCard(
                            context,
                            weatherProvider.currentWeather!,
                          ),
                        ),
                      const SizedBox(height: 20),
                      // Smart Insights based on current weather
                      if (weatherProvider.currentWeather != null)
                        _buildWeatherInsights(
                          context,
                          weatherProvider.currentWeather!,
                        ),
                      const SizedBox(height: 20),
                      // Weather Alerts Section - Always show for better visibility
                      _buildAlertsSection(
                        context,
                        weatherProvider.weatherAlerts,
                      ),
                      const SizedBox(height: 24),
                      _buildWeatherDetailsCard(
                        context,
                        weatherProvider.currentWeather,
                      ),
                      const SizedBox(height: 24),
                      if (_soilData != null) ...[
                        _buildSoilDataCard(context, _soilData!),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              );
      },
    );
  }

  // Build Forecast Tab
  Widget _buildForecastTab() {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, child) {
        if (weatherProvider.isLoading) {
          return _buildLoadingState();
        }

        final forecasts = _buildForecastList(weatherProvider);

        return RefreshIndicator(
          onRefresh: () => weatherProvider.refreshAll(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter header
                _buildForecastHeader(),
                const SizedBox(height: 16),
                // Filter chips
                _buildForecastFilters(),
                const SizedBox(height: 20),
                // Forecast content
                if (forecasts.isEmpty)
                  _buildNoForecastData()
                else if (_selectedView == 'Daily')
                  _buildDailyForecastView(forecasts)
                else
                  _buildHourlyForecastView(weatherProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildForecastHeader() {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Weather Forecast',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Detailed forecast for agricultural planning',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading weather data...',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStatus(WeatherProvider weatherProvider) {
    final locationService = weatherProvider.locationService;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Location: ${weatherProvider.currentLocation}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (locationService.currentPosition != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '📍 ${locationService.getLocationAccuracyStatus()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Text(
                    'Tap location icon to detect your position',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentWeatherCard(BuildContext context, weather) {
    final accent = _timeOfDayColor(weather.dateTime);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withOpacity(0.18),
            Theme.of(context).colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Weather',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${weather.temperature.toStringAsFixed(1)}°C',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _timeOfDayLabel(weather.dateTime),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: accent.withOpacity(0.9),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent.withOpacity(0.25),
                          accent.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _getWeatherIcon(weather.condition),
                      size: 48,
                      color: accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                weather.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                'Updated ${_formatTime(weather.dateTime)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildWeatherMetric(
                      context,
                      'Humidity',
                      '${weather.humidity.toStringAsFixed(0)}%',
                      Icons.water_drop,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildWeatherMetric(
                      context,
                      'Wind',
                      '${weather.windSpeed.toStringAsFixed(1)} km/h',
                      Icons.air,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildWeatherMetric(
                      context,
                      'Pressure',
                      '${weather.pressure.toStringAsFixed(0)} hPa',
                      Icons.speed,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherMetric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsSection(BuildContext context, List<dynamic> alerts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: alerts.isNotEmpty ? Colors.orange[600] : Colors.grey[400],
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Weather Alerts',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (alerts.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${alerts.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        if (alerts.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.green[600],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No weather alerts at this time. Conditions are favorable for agricultural activities.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...alerts.map((alert) => _buildAlertCard(context, alert)),
      ],
    );
  }

  Widget _buildAlertCard(BuildContext context, dynamic alert) {
    final alertId = '${alert.title}_${alert.date}';

    // Skip dismissed alerts
    if (_dismissedAlerts.contains(alertId)) {
      return const SizedBox.shrink();
    }

    final isExpanded = _expandedAlerts.contains(alertId);
    final severityColor = _severityColor(alert.severity);
    final severityLevel = _getSeverityLevel(alert.severity);

    return Dismissible(
      key: Key(alertId),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text(
              'Dismiss',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (direction) {
        setState(() {
          _dismissedAlerts.add(alertId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alert dismissed: ${alert.title}'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () {
                setState(() {
                  _dismissedAlerts.remove(alertId);
                });
              },
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              severityColor.withOpacity(0.12),
              severityColor.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: severityColor.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: severityColor.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedAlerts.remove(alertId);
                  } else {
                    _expandedAlerts.add(alertId);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Severity indicator strip
                        Container(
                          width: 4,
                          height: 60,
                          decoration: BoxDecoration(
                            color: severityColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: severityColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: severityColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            _alertIcon(alert.type),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      alert.title ?? 'Alert',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  // Severity badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: severityColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          severityLevel['icon'] as IconData,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          severityLevel['label'] as String,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                alert.description ?? '',
                                maxLines: isExpanded ? null : 2,
                                overflow: isExpanded
                                    ? TextOverflow.visible
                                    : TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Colors.grey[700],
                                      height: 1.4,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatRelativeTime(alert.date),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Expand icon
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: severityColor,
                          size: 24,
                        ),
                      ],
                    ),

                    // Expanded content
                    if (isExpanded) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: severityColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: severityColor.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: severityColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Recommended Actions',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: severityColor,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ..._getAlertActions(alert.type).map(
                              (action) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 6),
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: severityColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        action,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Colors.grey[800],
                                              height: 1.4,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _dismissedAlerts.add(alertId);
                                });
                              },
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Acknowledge'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: severityColor,
                                side: BorderSide(color: severityColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Navigate to recommendations
                                DefaultTabController.of(context).animateTo(2);
                              },
                              icon: const Icon(
                                Icons.lightbulb_outline,
                                size: 18,
                              ),
                              label: const Text('View Tips'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: severityColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getSeverityLevel(String severity) {
    switch (severity.toLowerCase()) {
      case 'severe':
      case 'extreme':
        return {'label': 'SEVERE', 'icon': Icons.warning};
      case 'moderate':
        return {'label': 'MODERATE', 'icon': Icons.error_outline};
      default:
        return {'label': 'MINOR', 'icon': Icons.info};
    }
  }

  List<String> _getAlertActions(String alertType) {
    switch (alertType.toLowerCase()) {
      case 'rain':
      case 'heavy rain':
        return [
          'Ensure proper drainage in fields to prevent waterlogging',
          'Postpone irrigation activities',
          'Check and secure farm structures and equipment',
          'Harvest ripe crops before heavy rainfall if possible',
        ];
      case 'drought':
      case 'dry':
        return [
          'Implement water conservation measures',
          'Increase irrigation frequency for critical crops',
          'Apply mulch to retain soil moisture',
          'Consider drought-tolerant crop varieties for next season',
        ];
      case 'heat':
      case 'high temperature':
        return [
          'Water crops during early morning or evening hours',
          'Provide shade for sensitive crops and livestock',
          'Monitor crops for heat stress symptoms',
          'Avoid heavy field work during peak heat hours',
        ];
      case 'wind':
      case 'strong wind':
        return [
          'Secure loose farm equipment and structures',
          'Postpone spraying operations',
          'Check and reinforce support for tall crops',
          'Keep livestock in sheltered areas',
        ];
      case 'frost':
      case 'cold':
        return [
          'Protect sensitive crops with covers',
          'Move potted plants to sheltered locations',
          'Ensure livestock have adequate shelter and bedding',
          'Drain irrigation systems to prevent freezing',
        ];
      default:
        return [
          'Monitor weather conditions closely',
          'Follow standard safety protocols',
          'Keep emergency contacts readily available',
          'Check local agricultural extension updates',
        ];
    }
  }

  Widget _buildWeatherDetailsCard(BuildContext context, weather) {
    if (weather == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weather Details',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      context,
                      'Visibility',
                      '${weather.visibility?.toStringAsFixed(1) ?? 'N/A'} km',
                      Icons.visibility,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      context,
                      'Precipitation',
                      '${weather.precipitation.toStringAsFixed(1)} mm',
                      Icons.water_drop,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSoilDataCard(BuildContext context, SoilData soilData) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.brown.withOpacity(0.1),
            Colors.green.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.terrain, color: Colors.brown[600], size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Soil Conditions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSoilMetric(
                      context,
                      'pH Level',
                      soilData.ph.toStringAsFixed(1),
                      soilData.phDescription,
                      _getPHColor(soilData.ph),
                      Icons.science,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSoilMetric(
                      context,
                      'Temperature',
                      '${soilData.soilTemperature.toStringAsFixed(1)}°C',
                      'Soil Temp',
                      Colors.red,
                      Icons.thermostat,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSoilMetric(
                      context,
                      'Type',
                      soilData.soilType,
                      soilData.texture,
                      Colors.brown,
                      Icons.terrain,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSoilMetric(
    BuildContext context,
    String label,
    String value,
    String description,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPHColor(double ph) {
    if (ph < 5.5) return Colors.red;
    if (ph < 6.5) return Colors.orange;
    if (ph < 7.5) return Colors.green;
    if (ph < 8.5) return Colors.blue;
    return Colors.purple;
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
      case 'sunny':
        return Icons.wb_sunny;
      case 'cloudy':
        return Icons.cloud;
      case 'rainy':
        return Icons.grain;
      case 'stormy':
        return Icons.thunderstorm;
      default:
        return Icons.wb_cloudy;
    }
  }

  String _timeOfDayLabel(DateTime dt) {
    final hour = dt.hour;
    if (hour >= 5 && hour < 12) return 'Morning';
    if (hour >= 12 && hour < 17) return 'Afternoon';
    if (hour >= 17 && hour < 21) return 'Evening';
    return 'Night';
  }

  Color _timeOfDayColor(DateTime dt) {
    switch (_timeOfDayLabel(dt)) {
      case 'Morning':
        return Colors.orange;
      case 'Afternoon':
        return Colors.blue;
      case 'Evening':
        return Colors.purple;
      case 'Night':
      default:
        return Colors.indigo;
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  Color _severityColor(String? severity) {
    switch ((severity ?? '').toLowerCase()) {
      case 'critical':
      case 'severe':
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
      default:
        return Colors.green;
    }
  }

  IconData _alertIcon(String? type) {
    switch ((type ?? '').toLowerCase()) {
      case 'fire':
        return Icons.local_fire_department;
      case 'flood':
        return Icons.water;
      case 'wind':
        return Icons.air;
      case 'heat':
        return Icons.thermostat;
      case 'cold':
        return Icons.ac_unit;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  String _formatRelativeTime(DateTime? dt) {
    if (dt == null) return 'now';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // Forecast helper methods
  List<Map<String, dynamic>> _buildForecastList(
    WeatherProvider weatherProvider,
  ) {
    final dailyForecast = weatherProvider.dailyForecast;
    if (dailyForecast.isEmpty) return [];

    final forecastCount = _selectedPeriod == '3 Days'
        ? 3
        : _selectedPeriod == '7 Days'
        ? 7
        : 14;

    return dailyForecast.take(forecastCount).map((weather) {
      return {
        'date': weather.dateTime,
        'dayName': DateFormat('EEEE').format(weather.dateTime),
        'temp': weather.temperature,
        'tempMin': weather.temperature - 5,
        'tempMax': weather.temperature + 5,
        'condition': weather.description,
        'humidity': weather.humidity,
        'windSpeed': weather.windSpeed,
        'precipitation': weather.precipitation,
        'icon': _getWeatherIcon(weather.description),
      };
    }).toList();
  }

  Widget _buildForecastFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ..._periods.map(
            (period) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(period),
                selected: _selectedPeriod == period,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedPeriod = period);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          ..._views.map(
            (view) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(view),
                selected: _selectedView == view,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedView = view);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoForecastData() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No forecast data available',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull down to refresh',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyForecastView(List<Map<String, dynamic>> forecasts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: forecasts
          .map((forecast) => _buildDailyForecastCard(forecast))
          .toList(),
    );
  }

  Widget _buildDailyForecastCard(Map<String, dynamic> forecast) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    forecast['icon'],
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        forecast['dayName'],
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy').format(forecast['date']),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${forecast['temp'].round()}°',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    Text(
                      '${forecast['tempMin'].round()}° / ${forecast['tempMax'].round()}°',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              forecast['condition'],
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildForecastMetric(
                    'Humidity',
                    '${forecast['humidity'].round()}%',
                    Icons.opacity,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildForecastMetric(
                    'Wind',
                    '${forecast['windSpeed'].round()} km/h',
                    Icons.air,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildForecastMetric(
                    'Rain',
                    '${forecast['precipitation'].round()}mm',
                    Icons.water_drop,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastMetric(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyForecastView(WeatherProvider weatherProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hourly Forecast',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          'Hourly forecast data coming soon',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  // Smart Weather Insights
  Widget _buildWeatherInsights(BuildContext context, dynamic weather) {
    final insights = <Map<String, dynamic>>[];
    final temp = weather.temperature;
    final humidity = weather.humidity;
    final windSpeed = weather.windSpeed;
    final feelsLike = weather.feelsLike;
    final uvIndex = weather.uvIndex ?? 0;

    // Temperature insights
    if (temp > 30) {
      insights.add({
        'icon': Icons.wb_sunny,
        'color': Colors.red,
        'title': 'Hot Conditions',
        'message':
            'High temperature. Increase irrigation frequency and monitor crop stress.',
      });
    } else if (temp < 10) {
      insights.add({
        'icon': Icons.ac_unit,
        'color': Colors.blue,
        'title': 'Cold Alert',
        'message':
            'Low temperature. Protect sensitive crops from potential frost damage.',
      });
    }

    // Feels like difference
    if (feelsLike != null && (feelsLike - temp).abs() > 5) {
      insights.add({
        'icon': Icons.thermostat,
        'color': Colors.orange,
        'title': 'Feels Different',
        'message':
            'Actual temperature differs from feels-like by ${(feelsLike - temp).abs().toStringAsFixed(1)}°C. Factor this for outdoor work planning.',
      });
    }

    // Humidity insights
    if (humidity > 80) {
      insights.add({
        'icon': Icons.water_drop,
        'color': Colors.blue,
        'title': 'High Humidity',
        'message':
            'Elevated moisture levels. Monitor for fungal diseases and reduce irrigation.',
      });
    } else if (humidity < 30) {
      insights.add({
        'icon': Icons.water_drop_outlined,
        'color': Colors.orange,
        'title': 'Low Humidity',
        'message':
            'Dry air conditions. Increase watering and consider mulching to retain soil moisture.',
      });
    }

    // Wind insights
    if (windSpeed > 30) {
      insights.add({
        'icon': Icons.air,
        'color': Colors.purple,
        'title': 'Strong Winds',
        'message':
            'High wind speeds. Delay spraying operations and secure farm structures.',
      });
    }

    // UV Index insights
    if (uvIndex > 8) {
      insights.add({
        'icon': Icons.sunny,
        'color': Colors.red,
        'title': 'Very High UV',
        'message':
            'Extreme UV levels. Ensure sun protection for workers and livestock.',
      });
    } else if (uvIndex > 5) {
      insights.add({
        'icon': Icons.sunny_snowing,
        'color': Colors.amber,
        'title': 'High UV',
        'message':
            'Elevated UV levels. Take sun protection measures during midday.',
      });
    }

    // Optimal conditions
    if (temp >= 18 &&
        temp <= 28 &&
        humidity >= 40 &&
        humidity <= 70 &&
        windSpeed < 15) {
      insights.add({
        'icon': Icons.check_circle,
        'color': Colors.green,
        'title': 'Ideal Conditions',
        'message':
            'Perfect weather for most farming activities. Good time for planting and spraying.',
      });
    }

    if (insights.isEmpty) {
      insights.add({
        'icon': Icons.info_outline,
        'color': Colors.blue,
        'title': 'Normal Conditions',
        'message':
            'Weather conditions are within normal range for farming operations.',
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lightbulb, color: Colors.amber, size: 20),
            ),
            const SizedBox(width: 8),
            Text(
              'Weather Insights',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...insights
            .take(2)
            .map(
              (insight) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (insight['color'] as Color).withOpacity(0.08),
                        (insight['color'] as Color).withOpacity(0.02),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (insight['color'] as Color).withOpacity(0.25),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: insight['color'] as Color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          insight['icon'] as IconData,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              insight['title'] as String,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              insight['message'] as String,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.grey[700],
                                    height: 1.3,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ],
    );
  }
}
