import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../models/weather.dart';
import '../models/weather_pattern.dart';
import '../models/agricultural_recommendation.dart';
import '../providers/weather_provider.dart';
import '../services/historical_weather_service.dart';

class ClimateDashboardScreen extends StatefulWidget {
  const ClimateDashboardScreen({super.key});

  @override
  State<ClimateDashboardScreen> createState() => _ClimateDashboardScreenState();
}

class _ClimateDashboardScreenState extends State<ClimateDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final HistoricalWeatherService _weatherService = HistoricalWeatherService();

  String _selectedTimeRange = 'Week';
  String _selectedYear = DateTime.now().year.toString();
  List<Weather> _historicalData = [];
  List<WeatherPattern> _weatherPatterns = [];
  List<AgriculturalRecommendation> _recommendations = [];
  Map<String, dynamic> _climateStatistics = {};
  bool _isLoading = false;

  final List<String> _timeRanges = ['Week', 'Month', 'Season', 'Year'];
  final List<String> _years = ['2025', '2024', '2023', '2022', '2021', '2020'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Update drawer selection indicator
    });
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    print('Loading dashboard data...');
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      await _loadHistoricalData();
      print('Historical data loaded: ${_historicalData.length} records');

      await _loadWeatherPatterns();
      print('Weather patterns loaded: ${_weatherPatterns.length} patterns');

      await _loadRecommendations();
      print(
        'Recommendations loaded: ${_recommendations.length} recommendations',
      );

      await _loadClimateStatistics();
      print('Climate statistics loaded');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      print('Dashboard data loaded successfully!');
    } catch (e) {
      print('Error loading dashboard data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to load dashboard data: $e');
      }
    }
  }

  Future<void> _loadHistoricalData() async {
    try {
      final startDate = _getStartDateForRange(
        _selectedTimeRange,
        _selectedYear,
      );
      final endDate = DateTime.now();

      print('=== Loading Historical Data ===');
      print('Start Date: $startDate');
      print('End Date: $endDate');
      print('Time Range: $_selectedTimeRange');
      print('Year: $_selectedYear');

      final data = await _weatherService.getHistoricalWeatherData(
        startDate: startDate,
        endDate: endDate,
      );

      print('Received ${data.length} weather records from service');

      if (data.isNotEmpty) {
        print('First record date: ${data.first.dateTime}');
        print('Last record date: ${data.last.dateTime}');
        print(
          'Sample data: Temp=${data.first.temperature}°C, Humidity=${data.first.humidity}%',
        );
      }

      if (mounted) {
        setState(() {
          _historicalData = data;
        });
      }

      print(
        'Historical data loaded into state: ${_historicalData.length} records',
      );
      print('=== End Loading Historical Data ===');
    } catch (e) {
      print('❌ Error loading historical data: $e');
      print('Stack trace: ${StackTrace.current}');
      if (mounted) {
        setState(() {
          _historicalData = [];
        });
      }
    }
  }

  Future<void> _loadWeatherPatterns() async {
    try {
      final startDate = _getStartDateForRange(
        _selectedTimeRange,
        _selectedYear,
      );
      final endDate = DateTime.now();

      print('Analyzing weather patterns...');
      final patterns = await _weatherService.analyzeWeatherPatterns(
        startDate: startDate,
        endDate: endDate,
      );

      if (mounted) {
        setState(() {
          _weatherPatterns = patterns;
        });
      }

      print('Found ${patterns.length} weather patterns');
    } catch (e) {
      print('Error loading weather patterns: $e');
      if (mounted) {
        setState(() {
          _weatherPatterns = [];
        });
      }
    }
  }

  Future<void> _loadRecommendations() async {
    try {
      print('Generating recommendations...');
      final recommendations = _generateRecommendationsFromData();

      if (mounted) {
        setState(() {
          _recommendations = recommendations;
        });
      }

      print('Generated ${recommendations.length} recommendations');
    } catch (e) {
      print('Error loading recommendations: $e');
      if (mounted) {
        setState(() {
          _recommendations = [];
        });
      }
    }
  }

  Future<void> _loadClimateStatistics() async {
    try {
      final startDate = _getStartDateForRange(
        _selectedTimeRange,
        _selectedYear,
      );
      final endDate = DateTime.now();

      print('Calculating climate statistics...');
      final stats = await _weatherService.getClimateStatistics(
        startDate: startDate,
        endDate: endDate,
      );

      if (mounted) {
        setState(() {
          _climateStatistics = stats;
        });
      }

      print('Climate statistics calculated: ${stats.keys.length} metrics');
    } catch (e) {
      print('Error loading climate statistics: $e');
      if (mounted) {
        setState(() {
          _climateStatistics = {};
        });
      }
    }
  }

  DateTime _getStartDateForRange(String range, String year) {
    final yearInt = int.parse(year);
    switch (range) {
      case 'Week':
        return DateTime.now().subtract(const Duration(days: 7));
      case 'Month':
        return DateTime.now().subtract(const Duration(days: 30));
      case 'Season':
        return DateTime.now().subtract(const Duration(days: 90));
      case 'Year':
        return DateTime(yearInt, 1, 1);
      default:
        return DateTime.now().subtract(const Duration(days: 7));
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: const Text('Farm Weather Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh Weather Data',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedTimeRange = value;
              });
              _loadHistoricalData();
            },
            itemBuilder: (context) => _timeRanges.map((range) {
              return PopupMenuItem(value: range, child: Text(range));
            }).toList(),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedTimeRange),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.home), text: 'Farm Overview'),
            Tab(icon: Icon(Icons.analytics), text: 'Weather Analysis'),
            Tab(icon: Icon(Icons.trending_up), text: 'Seasonal Trends'),
            Tab(icon: Icon(Icons.lightbulb), text: 'Farming Advice'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading farm weather data...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildAnalysisTab(),
                  _buildTrendsTab(),
                  _buildRecommendationsTab(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showDataManagementDialog,
        icon: const Icon(Icons.cloud_upload),
        label: const Text('Upload Data'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroHeader(),
          const SizedBox(height: 16),
          _buildQuickActionsRow(),
          const SizedBox(height: 16),
          _buildTimeRangeSelector(),
          const SizedBox(height: 20),
          _buildWeatherSummaryCards(),
          const SizedBox(height: 20),
          _buildQuickStatsGrid(),
          const SizedBox(height: 20),
          _buildRecentPatternsCard(),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    final now = DateTime.now();
    final season = _currentSeason(now.month);
    return Consumer<WeatherProvider>(
      builder: (context, wp, _) {
        final placeName = wp.currentLocation;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.12),
                Theme.of(context).colorScheme.secondary.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.agriculture,
                size: 36,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      placeName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('EEE, d MMM yyyy').format(now),
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  season,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _currentSeason(int month) {
    if (month >= 11 || month <= 4) return 'Wet Season';
    return 'Dry Season';
  }

  Widget _buildQuickActionsRow() {
    return LayoutBuilder(
      builder: (context, c) {
        final isNarrow = c.maxWidth < 380;
        final actions = [
          _quickAction(
            icon: Icons.cloud_upload,
            label: 'Upload',
            onTap: _showDataManagementDialog,
          ),
          _quickAction(
            icon: Icons.download,
            label: 'Export',
            onTap: _showExportDialog,
          ),
          _quickAction(
            icon: Icons.refresh,
            label: 'Refresh',
            onTap: _loadDashboardData,
          ),
          _quickAction(
            icon: Icons.help_outline,
            label: 'Help',
            onTap: _showHelpDialog,
          ),
        ];
        if (isNarrow) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: actions[0]),
                  const SizedBox(width: 12),
                  Expanded(child: actions[1]),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: actions[2]),
                  const SizedBox(width: 12),
                  Expanded(child: actions[3]),
                ],
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: actions[0]),
            const SizedBox(width: 12),
            Expanded(child: actions[1]),
            const SizedBox(width: 12),
            Expanded(child: actions[2]),
            const SizedBox(width: 12),
            Expanded(child: actions[3]),
          ],
        );
      },
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnalysisHeader(),
          const SizedBox(height: 20),
          _buildTemperatureChart(),
          const SizedBox(height: 20),
          _buildHumidityChart(),
          const SizedBox(height: 20),
          _buildPrecipitationChart(),
          const SizedBox(height: 20),
          _buildWeatherPatternAnalysis(),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTrendsHeader(),
          const SizedBox(height: 20),
          _buildHistoricalComparisonChart(),
          const SizedBox(height: 20),
          _buildSeasonalTrendsCard(),
          const SizedBox(height: 20),
          _buildClimateIndicatorsCard(),
        ],
      ),
    );
  }

  Widget _buildRecommendationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecommendationsHeader(),
          const SizedBox(height: 20),
          _buildRecommendationsList(),
          const SizedBox(height: 20),
          _buildActionItemsCard(),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Time Range Selection',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, c) {
                if (c.maxWidth < 380) {
                  return Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedTimeRange,
                        decoration: InputDecoration(
                          labelText: 'Time Range',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                        items: _timeRanges.map((range) {
                          return DropdownMenuItem(
                            value: range,
                            child: Text(range),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedTimeRange = value!;
                          });
                          _loadHistoricalData();
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedYear,
                        decoration: InputDecoration(
                          labelText: 'Year',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                        items: _years.map((year) {
                          return DropdownMenuItem(
                            value: year,
                            child: Text(year),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedYear = value!;
                          });
                          _loadHistoricalData();
                        },
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedTimeRange,
                        decoration: InputDecoration(
                          labelText: 'Time Range',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                        items: _timeRanges.map((range) {
                          return DropdownMenuItem(
                            value: range,
                            child: Text(range),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedTimeRange = value!;
                          });
                          _loadHistoricalData();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedYear,
                        decoration: InputDecoration(
                          labelText: 'Year',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                        items: _years.map((year) {
                          return DropdownMenuItem(
                            value: year,
                            child: Text(year),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedYear = value!;
                          });
                          _loadHistoricalData();
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherSummaryCards() {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, child) {
        final currentWeather = weatherProvider.currentWeather;

        if (currentWeather == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('No weather data available')),
            ),
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Temperature',
                '${currentWeather.temperature.toStringAsFixed(1)}°C',
                Icons.thermostat,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Humidity',
                '${currentWeather.humidity.toStringAsFixed(1)}%',
                Icons.water_drop,
                Colors.blue,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.08), color.withOpacity(0.03)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsGrid() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Statistics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 380;
                if (isNarrow) {
                  return Column(
                    children: [
                      _buildStatItem(
                        'Avg Temp',
                        _climateStatistics['temperature']?['average']
                                ?.toStringAsFixed(1) ??
                            'N/A',
                        Icons.thermostat,
                      ),
                      const SizedBox(height: 12),
                      _buildStatItem(
                        'Max Temp',
                        _climateStatistics['temperature']?['max']
                                ?.toStringAsFixed(1) ??
                            'N/A',
                        Icons.wb_sunny,
                      ),
                      const SizedBox(height: 12),
                      _buildStatItem(
                        'Min Temp',
                        _climateStatistics['temperature']?['min']
                                ?.toStringAsFixed(1) ??
                            'N/A',
                        Icons.ac_unit,
                      ),
                      const SizedBox(height: 12),
                      _buildStatItem(
                        'Rainfall',
                        _climateStatistics['precipitation']?['total']
                                ?.toStringAsFixed(1) ??
                            'N/A',
                        Icons.water_drop,
                      ),
                    ],
                  );
                }
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 2.8,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _buildStatItem(
                      'Avg Temp',
                      _climateStatistics['temperature']?['average']
                              ?.toStringAsFixed(1) ??
                          'N/A',
                      Icons.thermostat,
                    ),
                    _buildStatItem(
                      'Max Temp',
                      _climateStatistics['temperature']?['max']
                              ?.toStringAsFixed(1) ??
                          'N/A',
                      Icons.wb_sunny,
                    ),
                    _buildStatItem(
                      'Min Temp',
                      _climateStatistics['temperature']?['min']
                              ?.toStringAsFixed(1) ??
                          'N/A',
                      Icons.ac_unit,
                    ),
                    _buildStatItem(
                      'Rainfall',
                      _climateStatistics['precipitation']?['total']
                              ?.toStringAsFixed(1) ??
                          'N/A',
                      Icons.water_drop,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.25),
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPatternsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.waves,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recent Weather Patterns',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                // Data count badge
                if (_historicalData.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_historicalData.length} records',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Show data summary if we have historical data
            if (_historicalData.isNotEmpty) ...[
              _buildDataSummary(),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
            ],
            // Show patterns or empty state
            if (_weatherPatterns.isEmpty && _historicalData.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.cloud_off, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'No data available',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Upload weather data to see patterns',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else if (_weatherPatterns.isEmpty && _historicalData.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.analytics, size: 40, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'Analyzing patterns...',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._weatherPatterns.map((pattern) => _buildPatternItem(pattern)),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSummary() {
    if (_historicalData.isEmpty) return const SizedBox.shrink();

    final avgTemp =
        _historicalData.map((w) => w.temperature).reduce((a, b) => a + b) /
        _historicalData.length;
    final avgHumidity =
        _historicalData.map((w) => w.humidity).reduce((a, b) => a + b) /
        _historicalData.length;
    final totalPrecip = _historicalData
        .map((w) => w.precipitation)
        .reduce((a, b) => a + b);

    final dateRange = _historicalData.length > 1
        ? '${DateFormat('MMM d').format(_historicalData.first.dateTime)} - ${DateFormat('MMM d').format(_historicalData.last.dateTime)}'
        : DateFormat('MMM d, yyyy').format(_historicalData.last.dateTime);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.summarize,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Data Summary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            dateRange,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  Icons.thermostat,
                  '${avgTemp.toStringAsFixed(1)}°C',
                  'Avg Temp',
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryItem(
                  Icons.water_drop,
                  '${avgHumidity.toStringAsFixed(0)}%',
                  'Avg Humidity',
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryItem(
                  Icons.cloudy_snowing,
                  '${totalPrecip.toStringAsFixed(1)}mm',
                  'Total Rain',
                  Colors.cyan,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(fontSize: 9, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternItem(WeatherPattern pattern) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pattern.patternType,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: pattern.severity > 0.7
                      ? Colors.red.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Severity: ${(pattern.severity * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: pattern.severity > 0.7 ? Colors.red : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(pattern.description, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildAnalysisHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.12),
            Theme.of(context).colorScheme.secondary.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.analytics,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weather Data Analysis',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Detailed analysis of weather patterns and trends',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureChart() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.thermostat, color: Colors.orange, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Temperature Trends',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: _responsiveChartHeight(context),
              child: _historicalData.isEmpty
                  ? const Center(child: Text('No data available'))
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text('${value.toInt()}°C');
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text('Day ${value.toInt()}');
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _historicalData.asMap().entries.map((entry) {
                              return FlSpot(
                                entry.key.toDouble(),
                                entry.value.temperature,
                              );
                            }).toList(),
                            isCurved: true,
                            color: Colors.orange,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.orange.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHumidityChart() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.water_drop, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Humidity Levels',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: _responsiveChartHeight(context),
              child: _historicalData.isEmpty
                  ? const Center(child: Text('No data available'))
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 100,
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text('${value.toInt()}%');
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text('Day ${value.toInt()}');
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        barGroups: _historicalData.asMap().entries.map((entry) {
                          return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: entry.value.humidity,
                                color: Colors.blue,
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrecipitationChart() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloudy_snowing, color: Colors.cyan, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Precipitation Data',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: _responsiveChartHeight(context),
              child: _historicalData.isEmpty
                  ? const Center(child: Text('No data available'))
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text('${value.toInt()}mm');
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text('Day ${value.toInt()}');
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _historicalData.asMap().entries.map((entry) {
                              return FlSpot(
                                entry.key.toDouble(),
                                entry.value.precipitation,
                              );
                            }).toList(),
                            isCurved: true,
                            color: Colors.cyan,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.cyan.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  double _responsiveChartHeight(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    // 22% of screen height, clamped to [180, 280]
    return (h * 0.22).clamp(180, 280).toDouble();
  }

  Widget _buildWeatherPatternAnalysis() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pattern Analysis',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_weatherPatterns.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No patterns to analyze'),
                ),
              )
            else
              ..._weatherPatterns.map((pattern) => _buildAnalysisItem(pattern)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisItem(WeatherPattern pattern) {
    Color color;
    String status;

    if (pattern.severity > 0.7) {
      color = Colors.red;
      status = 'High';
    } else if (pattern.severity > 0.4) {
      color = Colors.orange;
      status = 'Medium';
    } else {
      color = Colors.green;
      status = 'Low';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      pattern.patternType,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  pattern.description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.12),
            Theme.of(context).colorScheme.secondary.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.trending_up,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Historical Trends',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Compare current conditions with historical data',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricalComparisonChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historical Comparison',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}°C');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(2020, 26.5),
                        const FlSpot(2021, 27.2),
                        const FlSpot(2022, 28.1),
                        const FlSpot(2023, 28.8),
                        const FlSpot(2024, 29.2),
                      ],
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonalTrendsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seasonal Trends',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSeasonalItem(
              'Spring',
              '22-28°C',
              'Moderate rainfall',
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildSeasonalItem(
              'Summer',
              '28-35°C',
              'Low rainfall',
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildSeasonalItem(
              'Autumn',
              '20-26°C',
              'Variable rainfall',
              Colors.brown,
            ),
            const SizedBox(height: 12),
            _buildSeasonalItem(
              'Winter',
              '15-22°C',
              'Minimal rainfall',
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonalItem(
    String season,
    String tempRange,
    String rainfall,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  season,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '$tempRange • $rainfall',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClimateIndicatorsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Climate Indicators',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildIndicatorItem('Heat Index', 'High', Colors.red),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildIndicatorItem(
                    'Drought Risk',
                    'Medium',
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildIndicatorItem('Flood Risk', 'Low', Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildIndicatorItem(
                    'Crop Stress',
                    'Medium',
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorItem(String label, String level, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              level,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.withOpacity(0.12),
            Colors.orange.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.lightbulb, color: Colors.orange, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Farming Advice',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Smart recommendations based on weather analysis',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsList() {
    if (_recommendations.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No recommendations available',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: _recommendations
          .map((recommendation) => _buildRecommendationCard(recommendation))
          .toList(),
    );
  }

  Widget _buildRecommendationCard(AgriculturalRecommendation recommendation) {
    Color priorityColor;
    switch (recommendation.priority.toLowerCase()) {
      case 'high':
        priorityColor = Colors.red;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        break;
      case 'low':
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recommendation.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: priorityColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    recommendation.priority.toUpperCase(),
                    style: TextStyle(
                      color: priorityColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              recommendation.description,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Text(
              'Actions:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            ...recommendation.actions.map(
              (action) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 2),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(action)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItemsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showDataManagementDialog(),
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Upload Data'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showExportDialog(),
                    icon: const Icon(Icons.download),
                    label: const Text('Export Report'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showSettingsDialog(),
                    icon: const Icon(Icons.settings),
                    label: const Text('Settings'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _loadDashboardData(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDataManagementDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.cloud_upload,
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
                          'Data Management',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Manage your weather data',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Options
            ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildBottomSheetOption(
                  icon: Icons.cloud_upload,
                  iconColor: Colors.blue,
                  title: 'Upload Weather Data',
                  subtitle: 'Import data from CSV or API',
                  onTap: () {
                    Navigator.pop(context);
                    _showUploadDialog();
                  },
                ),
                _buildBottomSheetOption(
                  icon: Icons.edit,
                  iconColor: Colors.orange,
                  title: 'Edit Weather Data',
                  subtitle: 'Modify existing weather records',
                  onTap: () {
                    Navigator.pop(context);
                    _showEditDialog();
                  },
                ),
                _buildBottomSheetOption(
                  icon: Icons.delete,
                  iconColor: Colors.red,
                  title: 'Delete Weather Data',
                  subtitle: 'Remove weather records',
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteDialog();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showUploadDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.cloud_upload,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload Weather Data',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Choose your upload method',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Upload options
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildUploadOptionCard(
                    icon: Icons.table_chart,
                    iconColor: Colors.green,
                    title: 'Upload CSV File',
                    subtitle: 'Import weather data from CSV file',
                    onTap: () {
                      Navigator.pop(context);
                      _uploadFromCSV();
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildUploadOptionCard(
                    icon: Icons.api,
                    iconColor: Colors.blue,
                    title: 'Import from API',
                    subtitle: 'Fetch weather data from OpenWeatherMap',
                    onTap: () {
                      Navigator.pop(context);
                      _uploadFromAPI();
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildUploadOptionCard(
                    icon: Icons.edit,
                    iconColor: Colors.orange,
                    title: 'Manual Entry',
                    subtitle: 'Enter weather data manually',
                    onTap: () {
                      Navigator.pop(context);
                      _manualEntry();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadOptionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [iconColor.withOpacity(0.08), iconColor.withOpacity(0.02)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: iconColor.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 18, color: iconColor),
          ],
        ),
      ),
    );
  }

  void _showEditDialog() {
    if (_historicalData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No weather records to edit')),
      );
      return;
    }

    Weather selected = _historicalData.last;
    final tempCtrl = TextEditingController(
      text: selected.temperature.toStringAsFixed(1),
    );
    final humidityCtrl = TextEditingController(
      text: selected.humidity.toStringAsFixed(1),
    );
    final precipCtrl = TextEditingController(
      text: selected.precipitation.toStringAsFixed(1),
    );
    final windSpeedCtrl = TextEditingController(
      text: selected.windSpeed.toStringAsFixed(1),
    );
    final windDirCtrl = TextEditingController(
      text: selected.windDirection ?? '',
    );
    final pressureCtrl = TextEditingController(
      text: selected.pressure.toStringAsFixed(1),
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Edit Weather Record'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Weather>(
                    value: selected,
                    decoration: const InputDecoration(
                      labelText: 'Select Record',
                    ),
                    items: _historicalData
                        .map(
                          (w) => DropdownMenuItem(
                            value: w,
                            child: Text(
                              DateFormat('yyyy-MM-dd HH:mm').format(w.dateTime),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (w) {
                      if (w == null) return;
                      setStateDialog(() {
                        selected = w;
                        tempCtrl.text = w.temperature.toStringAsFixed(1);
                        humidityCtrl.text = w.humidity.toStringAsFixed(1);
                        precipCtrl.text = w.precipitation.toStringAsFixed(1);
                        windSpeedCtrl.text = w.windSpeed.toStringAsFixed(1);
                        windDirCtrl.text = w.windDirection ?? '';
                        pressureCtrl.text = w.pressure.toStringAsFixed(1);
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: tempCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Temperature (°C)',
                    ),
                  ),
                  TextField(
                    controller: humidityCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Humidity (%)',
                    ),
                  ),
                  TextField(
                    controller: precipCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Precipitation (mm)',
                    ),
                  ),
                  TextField(
                    controller: windSpeedCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Wind Speed'),
                  ),
                  TextField(
                    controller: windDirCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Wind Direction',
                    ),
                  ),
                  TextField(
                    controller: pressureCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Pressure (hPa)',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final updated = Weather(
                      id: selected.id,
                      dateTime: selected.dateTime,
                      temperature: double.parse(tempCtrl.text),
                      humidity: double.parse(humidityCtrl.text),
                      precipitation: double.parse(precipCtrl.text),
                      windSpeed: double.parse(windSpeedCtrl.text),
                      windDirection: windDirCtrl.text.isEmpty
                          ? null
                          : windDirCtrl.text,
                      pressure: double.parse(pressureCtrl.text),
                      condition: selected.condition,
                      description: selected.description,
                      icon: selected.icon,
                      visibility: selected.visibility,
                      uvIndex: selected.uvIndex,
                    );
                    await _weatherService.updateWeatherData(updated);
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Record updated')),
                    );
                    await _loadDashboardData();
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Update failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteDialog() {
    if (_historicalData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No weather records to delete')),
      );
      return;
    }

    Weather selected = _historicalData.last;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Delete Weather Record'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Weather>(
                  value: selected,
                  decoration: const InputDecoration(labelText: 'Select Record'),
                  items: _historicalData
                      .map(
                        (w) => DropdownMenuItem(
                          value: w,
                          child: Text(
                            DateFormat('yyyy-MM-dd HH:mm').format(w.dateTime),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (w) {
                    if (w == null) return;
                    setStateDialog(() => selected = w);
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  'This will permanently remove the selected record.',
                  style: TextStyle(color: Colors.red[700]),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.delete),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  try {
                    await _weatherService.deleteWeatherData(selected.id);
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Record deleted')),
                    );
                    await _loadDashboardData();
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Delete failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                label: const Text('Delete'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showExportDialog() {
    if (_historicalData.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No data to export')));
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln(
      'date_time,temperature,humidity,precipitation,wind_speed,wind_direction,pressure,condition,description,icon',
    );
    for (final w in _historicalData) {
      buffer.writeln(
        '${w.dateTime.toIso8601String()},${w.temperature.toStringAsFixed(2)},${w.humidity.toStringAsFixed(2)},${w.precipitation.toStringAsFixed(2)},${w.windSpeed.toStringAsFixed(2)},${(w.windDirection ?? '').replaceAll(',', ' ')},${w.pressure.toStringAsFixed(2)},${w.condition.replaceAll(',', ' ')},${w.description.replaceAll(',', ' ')},${w.icon.replaceAll(',', ' ')}',
      );
    }

    final csvData = buffer.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Weather Data'),
        content: const Text('Copy CSV to clipboard?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: csvData));
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('CSV copied to clipboard')),
              );
            },
            child: const Text('Copy CSV'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: const Text('Settings functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadFromCSV() async {
    try {
      // Show file picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        // Show loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Processing CSV file...'),
                ],
              ),
              duration: const Duration(seconds: 30),
              backgroundColor: Colors.blue,
            ),
          );
        }

        final file = File(result.files.single.path!);
        final csvContent = await file.readAsString();

        // Parse CSV
        final rows = const CsvToListConverter().convert(csvContent);

        if (rows.length < 2) {
          throw Exception(
            'CSV file must have at least a header and one data row',
          );
        }

        final List<Weather> weatherData = [];
        int skippedRows = 0;

        // Skip header row and process data
        for (int i = 1; i < rows.length; i++) {
          final row = rows[i];

          // Check if row has enough columns
          if (row.length < 9) {
            skippedRows++;
            print('Skipping row $i: insufficient columns (${row.length})');
            continue;
          }

          try {
            // Parse each field
            final dateTime = DateTime.parse(row[0].toString().trim());
            final temperature = double.parse(row[1].toString().trim());
            final humidity = double.parse(row[2].toString().trim());
            final windSpeed = double.parse(row[3].toString().trim());
            final condition = row[4].toString().trim();
            final description = row[5].toString().trim();
            final icon = row[6].toString().trim();
            final pressure = double.parse(row[7].toString().trim());
            final precipitation = double.parse(row[8].toString().trim());

            final weather = Weather(
              id: 'csv_${dateTime.millisecondsSinceEpoch}_$i',
              dateTime: dateTime,
              temperature: temperature,
              humidity: humidity,
              windSpeed: windSpeed,
              pressure: pressure,
              precipitation: precipitation,
              condition: condition,
              description: description,
              icon: icon,
            );
            weatherData.add(weather);
          } catch (e) {
            skippedRows++;
            print('Error parsing row $i: $e');
            print('Row data: $row');
            continue;
          }
        }

        if (weatherData.isEmpty) {
          throw Exception(
            'No valid weather data found in CSV. Please check the format.',
          );
        }

        // Store the data
        print('=== Storing ${weatherData.length} weather records ===');
        print('First record to store: ${weatherData.first.toJson()}');

        await _weatherService.storeMultipleWeatherData(weatherData);
        print('✅ Data stored successfully in Firestore');

        if (mounted) {
          // Hide loading indicator
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Upload Successful!',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${weatherData.length} records added${skippedRows > 0 ? ' ($skippedRows skipped)' : ''}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          // Force refresh the dashboard to show new data
          print('=== Starting Dashboard Refresh ===');

          // Wait for Firestore to propagate data
          await Future.delayed(const Duration(milliseconds: 1000));

          // Clear existing data first
          if (mounted) {
            setState(() {
              _historicalData = [];
              _weatherPatterns = [];
              _recommendations = [];
              _climateStatistics = {};
            });
          }

          // Force reload all data with fresh query
          if (mounted) {
            print('Reloading dashboard data...');
            await _loadDashboardData();

            print('=== Dashboard Refresh Complete ===');
            print('Final data count: ${_historicalData.length} records');

            // Show confirmation
            if (_historicalData.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '✅ Dashboard updated with ${_historicalData.length} records!',
                  ),
                  backgroundColor: Colors.blue,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        }
      } else {
        print('File picker cancelled or no file selected');
      }
    } catch (e) {
      print('CSV upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Upload Failed',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(e.toString(), style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _uploadFromAPI() async {
    final apiKeyController = TextEditingController();
    final locationController = TextEditingController(text: 'Harare');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import from Weather API'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'Harare, Zimbabwe',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: apiKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key (optional)',
                hintText: 'OpenWeatherMap API key',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _fetchWeatherFromAPI(
                apiKeyController.text,
                locationController.text,
              );
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchWeatherFromAPI(String apiKey, String location) async {
    try {
      final apiUrl =
          'https://api.openweathermap.org/data/2.5/weather?q=$location&appid=$apiKey&units=metric';
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final weather = Weather(
          id: 'api_${DateTime.now().millisecondsSinceEpoch}',
          dateTime: DateTime.now(),
          temperature: data['main']['temp'].toDouble(),
          humidity: data['main']['humidity'].toDouble(),
          windSpeed: data['wind']['speed'].toDouble(),
          pressure: data['main']['pressure'].toDouble(),
          precipitation: data['rain']?['1h']?.toDouble() ?? 0.0,
          condition: data['weather'][0]['main'],
          description: data['weather'][0]['description'],
          icon: data['weather'][0]['icon'],
        );

        await _weatherService.storeWeatherData(weather);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.cloud_done, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'API Import Successful!',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Weather data for $location added',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          // Refresh the dashboard to show new data
          await _loadDashboardData();
        }
      } else {
        throw Exception('Failed to fetch from API: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing from API: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _manualEntry() {
    final dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    final tempController = TextEditingController();
    final humidityController = TextEditingController();
    final precipitationController = TextEditingController(text: '0');
    final windSpeedController = TextEditingController();
    final windDirectionController = TextEditingController();
    final pressureController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual Weather Entry'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dateController,
                decoration: const InputDecoration(
                  labelText: 'Date (YYYY-MM-DD)',
                ),
              ),
              TextField(
                controller: tempController,
                decoration: const InputDecoration(
                  labelText: 'Temperature (°C)',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: humidityController,
                decoration: const InputDecoration(labelText: 'Humidity (%)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: precipitationController,
                decoration: const InputDecoration(
                  labelText: 'Precipitation (mm)',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: windSpeedController,
                decoration: const InputDecoration(
                  labelText: 'Wind Speed (km/h)',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: windDirectionController,
                decoration: const InputDecoration(labelText: 'Wind Direction'),
              ),
              TextField(
                controller: pressureController,
                decoration: const InputDecoration(labelText: 'Pressure (hPa)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final weather = Weather(
                  id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
                  dateTime: DateTime.parse(dateController.text),
                  temperature: double.parse(tempController.text),
                  humidity: double.parse(humidityController.text),
                  precipitation: double.parse(precipitationController.text),
                  windSpeed: double.parse(windSpeedController.text),
                  windDirection: windDirectionController.text,
                  pressure: double.parse(pressureController.text),
                  condition: 'Manual Entry',
                  description: 'Manually entered weather data',
                  icon: 'manual',
                );

                await _weatherService.storeWeatherData(weather);

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.edit_calendar, color: Colors.white),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Manual Entry Saved!',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Weather record added successfully',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 4),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );

                  // Refresh the dashboard to show new data
                  await _loadDashboardData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  List<AgriculturalRecommendation> _generateRecommendationsFromData() {
    final recommendations = <AgriculturalRecommendation>[];

    // Generate recommendations based on weather patterns
    for (final pattern in _weatherPatterns) {
      recommendations.add(
        AgriculturalRecommendation(
          id: 'rec_${pattern.id}',
          title: 'Action Required: ${pattern.patternType}',
          description: pattern.description,
          category: _getCategoryFromPattern(pattern.patternType),
          priority: _getPriorityFromSeverity(pattern.severity),
          date: DateTime.now(),
          location: pattern.location,
          cropType: 'General',
          actions: pattern.recommendations,
          conditions: pattern.statistics,
          createdAt: DateTime.now(),
        ),
      );
    }

    // Generate seasonal recommendations based on current data
    if (_historicalData.isNotEmpty) {
      recommendations.addAll(_generateSeasonalRecommendations());
    }

    // Always add general farming tips if no other recommendations
    if (recommendations.isEmpty) {
      recommendations.addAll(_generateDefaultRecommendations());
    }

    return recommendations;
  }

  List<AgriculturalRecommendation> _generateSeasonalRecommendations() {
    final recommendations = <AgriculturalRecommendation>[];

    if (_historicalData.isEmpty) return recommendations;

    // Calculate average conditions
    final avgTemp =
        _historicalData.map((w) => w.temperature).reduce((a, b) => a + b) /
        _historicalData.length;
    final avgHumidity =
        _historicalData.map((w) => w.humidity).reduce((a, b) => a + b) /
        _historicalData.length;
    final totalPrecip = _historicalData
        .map((w) => w.precipitation)
        .reduce((a, b) => a + b);

    final now = DateTime.now();
    final season = _currentSeason(now.month);

    // Temperature-based recommendations
    if (avgTemp > 30) {
      recommendations.add(
        AgriculturalRecommendation(
          id: 'temp_high_${now.millisecondsSinceEpoch}',
          title: 'High Temperature Alert',
          description:
              'Average temperature is ${avgTemp.toStringAsFixed(1)}°C. Take action to protect your crops from heat stress.',
          category: 'Temperature Management',
          priority: 'High',
          date: now,
          location: 'Your Farm',
          cropType: 'All Crops',
          actions: [
            'Increase irrigation frequency to cool soil',
            'Apply mulch to reduce soil temperature',
            'Provide shade for sensitive crops',
            'Water early morning or evening',
            'Monitor crops for heat stress signs',
          ],
          conditions: {'avgTemp': avgTemp},
          createdAt: now,
        ),
      );
    } else if (avgTemp < 20) {
      recommendations.add(
        AgriculturalRecommendation(
          id: 'temp_low_${now.millisecondsSinceEpoch}',
          title: 'Cool Temperature Advisory',
          description:
              'Average temperature is ${avgTemp.toStringAsFixed(1)}°C. Protect crops from cold stress.',
          category: 'Temperature Management',
          priority: 'Medium',
          date: now,
          location: 'Your Farm',
          cropType: 'All Crops',
          actions: [
            'Cover sensitive plants at night',
            'Delay planting heat-loving crops',
            'Consider cold-tolerant varieties',
            'Reduce watering frequency',
            'Monitor for frost risk',
          ],
          conditions: {'avgTemp': avgTemp},
          createdAt: now,
        ),
      );
    }

    // Humidity-based recommendations
    if (avgHumidity > 75) {
      recommendations.add(
        AgriculturalRecommendation(
          id: 'humidity_high_${now.millisecondsSinceEpoch}',
          title: 'High Humidity Alert',
          description:
              'Average humidity is ${avgHumidity.toStringAsFixed(0)}%. Risk of fungal diseases increases.',
          category: 'Disease Prevention',
          priority: 'High',
          date: now,
          location: 'Your Farm',
          cropType: 'All Crops',
          actions: [
            'Improve air circulation around plants',
            'Apply fungicide preventively',
            'Avoid overhead watering',
            'Remove infected plant material',
            'Space plants adequately',
          ],
          conditions: {'avgHumidity': avgHumidity},
          createdAt: now,
        ),
      );
    }

    // Precipitation-based recommendations
    if (totalPrecip < 10) {
      recommendations.add(
        AgriculturalRecommendation(
          id: 'precip_low_${now.millisecondsSinceEpoch}',
          title: 'Dry Conditions - Irrigation Needed',
          description:
              'Only ${totalPrecip.toStringAsFixed(1)}mm rainfall recorded. Supplement with irrigation.',
          category: 'Irrigation',
          priority: 'High',
          date: now,
          location: 'Your Farm',
          cropType: 'All Crops',
          actions: [
            'Implement regular irrigation schedule',
            'Use drip irrigation for efficiency',
            'Apply mulch to retain soil moisture',
            'Water deeply but less frequently',
            'Monitor soil moisture levels daily',
          ],
          conditions: {'totalPrecip': totalPrecip},
          createdAt: now,
        ),
      );
    } else if (totalPrecip > 50) {
      recommendations.add(
        AgriculturalRecommendation(
          id: 'precip_high_${now.millisecondsSinceEpoch}',
          title: 'Heavy Rainfall - Drainage Advisory',
          description:
              '${totalPrecip.toStringAsFixed(1)}mm rainfall recorded. Ensure proper drainage.',
          category: 'Water Management',
          priority: 'Medium',
          date: now,
          location: 'Your Farm',
          cropType: 'All Crops',
          actions: [
            'Check and clear drainage systems',
            'Avoid waterlogged areas',
            'Delay irrigation if soil is saturated',
            'Monitor for root rot signs',
            'Consider raised beds for future planting',
          ],
          conditions: {'totalPrecip': totalPrecip},
          createdAt: now,
        ),
      );
    }

    // Seasonal recommendations for Zimbabwe
    if (season == 'Wet Season') {
      recommendations.add(
        AgriculturalRecommendation(
          id: 'season_wet_${now.millisecondsSinceEpoch}',
          title: 'Wet Season Farming Guide',
          description:
              'Optimal planting season for Zimbabwe farmers. Make the most of rainfall.',
          category: 'Seasonal Planning',
          priority: 'Low',
          date: now,
          location: 'Zimbabwe',
          cropType: 'General',
          actions: [
            'Plant maize, tobacco, and cotton now',
            'Ensure proper seed bed preparation',
            'Apply fertilizer at planting',
            'Control weeds early in the season',
            'Monitor for pests and diseases',
          ],
          conditions: {'season': season},
          createdAt: now,
        ),
      );
    } else {
      recommendations.add(
        AgriculturalRecommendation(
          id: 'season_dry_${now.millisecondsSinceEpoch}',
          title: 'Dry Season Management',
          description:
              'Limited rainfall period. Focus on irrigation and harvest.',
          category: 'Seasonal Planning',
          priority: 'Low',
          date: now,
          location: 'Zimbabwe',
          cropType: 'General',
          actions: [
            'Harvest mature crops',
            'Prepare land for next season',
            'Irrigate winter crops if available',
            'Store harvested produce properly',
            'Plan crop rotation for wet season',
          ],
          conditions: {'season': season},
          createdAt: now,
        ),
      );
    }

    return recommendations;
  }

  List<AgriculturalRecommendation> _generateDefaultRecommendations() {
    final now = DateTime.now();
    final season = _currentSeason(now.month);

    return [
      AgriculturalRecommendation(
        id: 'default_seasonal_${now.millisecondsSinceEpoch}',
        title: season == 'Wet Season'
            ? 'Wet Season Planting Guide'
            : 'Dry Season Management',
        description: season == 'Wet Season'
            ? 'November to April is the main planting season in Zimbabwe. Take advantage of rainfall for crop production.'
            : 'May to October is the dry season. Focus on irrigation, harvesting, and land preparation.',
        category: 'Seasonal Planning',
        priority: 'Low',
        date: now,
        location: 'Zimbabwe',
        cropType: 'General',
        actions: season == 'Wet Season'
            ? [
                'Plant maize, sorghum, and millet',
                'Ensure soil is properly prepared',
                'Apply basal fertilizer before planting',
                'Control weeds within first 6 weeks',
                'Monitor for Fall Armyworm',
              ]
            : [
                'Harvest mature summer crops',
                'Store grain in dry, cool conditions',
                'Prepare land for next season',
                'Plant winter vegetables if water available',
                'Maintain farm equipment',
              ],
        conditions: {'season': season},
        createdAt: now,
      ),
      AgriculturalRecommendation(
        id: 'default_upload_${now.millisecondsSinceEpoch}',
        title: 'Upload Weather Data',
        description:
            'Start tracking weather data to get personalized farming recommendations based on your specific conditions.',
        category: 'Data Management',
        priority: 'Medium',
        date: now,
        location: 'Your Farm',
        cropType: 'General',
        actions: [
          'Upload weather data via CSV file',
          'Import from OpenWeatherMap API',
          'Enter data manually as you collect it',
          'Track temperature and rainfall daily',
          'Review patterns to plan farming activities',
        ],
        conditions: {},
        createdAt: now,
      ),
      AgriculturalRecommendation(
        id: 'default_general_${now.millisecondsSinceEpoch}',
        title: 'General Farming Best Practices',
        description:
            'Essential practices for successful farming in Zimbabwe climate.',
        category: 'Best Practices',
        priority: 'Low',
        date: now,
        location: 'Zimbabwe',
        cropType: 'All Crops',
        actions: [
          'Test soil fertility regularly',
          'Practice crop rotation annually',
          'Use certified seeds from trusted sources',
          'Keep farm records for planning',
          'Join local farmer groups for knowledge sharing',
        ],
        conditions: {},
        createdAt: now,
      ),
    ];
  }

  String _getCategoryFromPattern(String patternType) {
    switch (patternType.toLowerCase()) {
      case 'temperature trend':
        return 'Temperature Management';
      case 'precipitation pattern':
        return 'Irrigation';
      case 'humidity pattern':
        return 'Humidity Control';
      default:
        return 'General';
    }
  }

  String _getPriorityFromSeverity(double severity) {
    if (severity > 0.7) return 'High';
    if (severity > 0.4) return 'Medium';
    return 'Low';
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.95),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Enhanced Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.agriculture,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Farm Weather',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Zimbabwe Farmers Dashboard',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Data indicator
                    if (_historicalData.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.cloud_done,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_historicalData.length} Records Loaded',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Navigation Section
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  children: [
                    _buildDrawerSectionTitle('Navigation'),
                    _buildEnhancedDrawerItem(
                      context,
                      'Farm Overview',
                      'Current weather conditions',
                      Icons.home_rounded,
                      Colors.blue,
                      () {
                        Navigator.pop(context);
                        _tabController.animateTo(0);
                      },
                      isSelected: _tabController.index == 0,
                    ),
                    _buildEnhancedDrawerItem(
                      context,
                      'Weather Analysis',
                      'Detailed charts & graphs',
                      Icons.analytics_rounded,
                      Colors.purple,
                      () {
                        Navigator.pop(context);
                        _tabController.animateTo(1);
                      },
                      isSelected: _tabController.index == 1,
                    ),
                    _buildEnhancedDrawerItem(
                      context,
                      'Seasonal Trends',
                      'Historical patterns',
                      Icons.trending_up_rounded,
                      Colors.orange,
                      () {
                        Navigator.pop(context);
                        _tabController.animateTo(2);
                      },
                      isSelected: _tabController.index == 2,
                    ),
                    _buildEnhancedDrawerItem(
                      context,
                      'Farming Advice',
                      'Smart recommendations',
                      Icons.lightbulb_rounded,
                      Colors.amber,
                      () {
                        Navigator.pop(context);
                        _tabController.animateTo(3);
                      },
                      isSelected: _tabController.index == 3,
                    ),
                    const SizedBox(height: 8),
                    _buildDrawerSectionTitle('Data Management'),
                    _buildEnhancedDrawerItem(
                      context,
                      'Upload Data',
                      'Import weather records',
                      Icons.cloud_upload_rounded,
                      Colors.green,
                      () {
                        Navigator.pop(context);
                        _showDataManagementDialog();
                      },
                    ),
                    _buildEnhancedDrawerItem(
                      context,
                      'Download Reports',
                      'Export your data',
                      Icons.download_rounded,
                      Colors.teal,
                      () {
                        Navigator.pop(context);
                        _showExportDialog();
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildDrawerSectionTitle('Other'),
                    _buildEnhancedDrawerItem(
                      context,
                      'Refresh Data',
                      'Update weather info',
                      Icons.refresh_rounded,
                      Colors.indigo,
                      () {
                        Navigator.pop(context);
                        _loadDashboardData();
                      },
                    ),
                    _buildEnhancedDrawerItem(
                      context,
                      'Help & Support',
                      'Get farming tips',
                      Icons.help_rounded,
                      Colors.pink,
                      () {
                        Navigator.pop(context);
                        _showHelpDialog();
                      },
                    ),
                  ],
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.wb_sunny,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Powered by AgriClimate',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      'v1.0',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildEnhancedDrawerItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
    VoidCallback onTap, {
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Colors.transparent,
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 15,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[800],
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey[400],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showHelpDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade400,
                            Colors.green.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.help_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Help & Support',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Guide for Zimbabwe Farmers',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children:
                      [
                        _buildHelpSection(
                          'Dashboard Features',
                          Icons.dashboard_rounded,
                          Colors.blue,
                          [
                            'View current weather conditions for your farm',
                            'Check weather alerts and warnings',
                            'See seasonal weather trends',
                            'Get farming advice based on weather',
                            'Upload your own weather data',
                            'Download weather reports',
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildHelpSection(
                          'How to Use',
                          Icons.lightbulb_rounded,
                          Colors.amber,
                          [
                            'Check "Farm Overview" for today\'s weather',
                            'Look at "Weather Analysis" for detailed charts',
                            'View "Seasonal Trends" for long-term patterns',
                            'Read "Farming Advice" for crop recommendations',
                            'Use "Upload Data" to add your weather records',
                            'Tap "Refresh" to update weather information',
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildHelpSection(
                          'Zimbabwe Farming Calendar',
                          Icons.calendar_month_rounded,
                          Colors.green,
                          [
                            'Wet season: November to April',
                            'Dry season: May to October',
                            'Best planting time: October to December',
                            'Harvest time: March to May',
                            'Watch for drought warnings',
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildHelpSection(
                          'Data Upload Tips',
                          Icons.cloud_upload_rounded,
                          Colors.purple,
                          [
                            'CSV format: date_time, temperature, humidity...',
                            'API imports require OpenWeatherMap key',
                            'Manual entry for single records',
                            'Data shows immediately after upload',
                            'Export reports anytime to CSV format',
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Contact section
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.1),
                                Theme.of(
                                  context,
                                ).colorScheme.secondary.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.support_agent,
                                size: 40,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Need More Help?',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Contact our support team for assistance',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpSection(
    String title,
    IconData icon,
    Color color,
    List<String> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
