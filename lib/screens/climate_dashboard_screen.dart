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
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      await _loadHistoricalData();
      await _loadWeatherPatterns();
      await _loadRecommendations();
      await _loadClimateStatistics();
    } catch (e) {
      _showErrorSnackBar('Failed to load dashboard data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadHistoricalData() async {
    try {
      final startDate = _getStartDateForRange(
        _selectedTimeRange,
        _selectedYear,
      );
      final endDate = DateTime.now();

      _historicalData = await _weatherService.getHistoricalWeatherData(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      print('Error loading historical data: $e');
    }
  }

  Future<void> _loadWeatherPatterns() async {
    try {
      final startDate = _getStartDateForRange(
        _selectedTimeRange,
        _selectedYear,
      );
      final endDate = DateTime.now();

      _weatherPatterns = await _weatherService.analyzeWeatherPatterns(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      print('Error loading weather patterns: $e');
    }
  }

  Future<void> _loadRecommendations() async {
    try {
      // Generate recommendations based on current patterns
      _recommendations = _generateRecommendationsFromData();
    } catch (e) {
      print('Error loading recommendations: $e');
    }
  }

  Future<void> _loadClimateStatistics() async {
    try {
      final startDate = _getStartDateForRange(
        _selectedTimeRange,
        _selectedYear,
      );
      final endDate = DateTime.now();

      _climateStatistics = await _weatherService.getClimateStatistics(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      print('Error loading climate statistics: $e');
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time Range Selection',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedTimeRange,
                    decoration: const InputDecoration(
                      labelText: 'Time Range',
                      border: OutlineInputBorder(),
                    ),
                    items: _timeRanges.map((range) {
                      return DropdownMenuItem(value: range, child: Text(range));
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
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      border: OutlineInputBorder(),
                    ),
                    items: _years.map((year) {
                      return DropdownMenuItem(value: year, child: Text(year));
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

        return LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 380;
            final children = [
              _buildSummaryCard(
                'Temperature',
                '${currentWeather.temperature.toStringAsFixed(1)}°C',
                Icons.thermostat,
                Colors.orange,
              ),
              _buildSummaryCard(
                'Humidity',
                '${currentWeather.humidity.toStringAsFixed(1)}%',
                Icons.water_drop,
                Colors.blue,
              ),
              _buildSummaryCard(
                'Precipitation',
                '${currentWeather.precipitation.toStringAsFixed(1)}mm',
                Icons.cloudy_snowing,
                Colors.cyan,
              ),
            ];
            if (isNarrow) {
              return Column(
                children: [
                  for (int i = 0; i < children.length; i++) ...[
                    children[i],
                    if (i != children.length - 1) const SizedBox(height: 12),
                  ],
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: children[0]),
                const SizedBox(width: 12),
                Expanded(child: children[1]),
                const SizedBox(width: 12),
                Expanded(child: children[2]),
              ],
            );
          },
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsGrid() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Statistics',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
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
                  _climateStatistics['temperature']?['max']?.toStringAsFixed(
                        1,
                      ) ??
                      'N/A',
                  Icons.wb_sunny,
                ),
                _buildStatItem(
                  'Min Temp',
                  _climateStatistics['temperature']?['min']?.toStringAsFixed(
                        1,
                      ) ??
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPatternsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Weather Patterns',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_weatherPatterns.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No patterns detected'),
                ),
              )
            else
              ..._weatherPatterns.map((pattern) => _buildPatternItem(pattern)),
          ],
        ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.analytics,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weather Data Analysis',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Detailed analysis of weather patterns and trends',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemperatureChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Temperature Trends',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Humidity Levels',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Precipitation Data',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.trending_up,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Historical Trends',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Compare current conditions with historical data',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Agricultural Recommendations',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'AI-powered recommendations based on weather analysis',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Management'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.cloud_upload),
              title: const Text('Upload Weather Data'),
              subtitle: const Text('Import weather data from CSV or API'),
              onTap: () {
                Navigator.pop(context);
                _showUploadDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Weather Data'),
              subtitle: const Text('Modify existing weather records'),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete Weather Data'),
              subtitle: const Text('Remove weather records'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Weather Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose upload method:'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _uploadFromCSV();
              },
              icon: const Icon(Icons.table_chart),
              label: const Text('Upload CSV File'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _uploadFromAPI();
              },
              icon: const Icon(Icons.api),
              label: const Text('Import from API'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _manualEntry();
              },
              icon: const Icon(Icons.edit),
              label: const Text('Manual Entry'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
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
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
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

        // Skip header row and process data
        for (int i = 1; i < rows.length; i++) {
          final row = rows[i];
          if (row.length < 9) continue;

          try {
            final weather = Weather(
              id: DateTime.now().millisecondsSinceEpoch.toString() + '_$i',
              dateTime: DateTime.parse(row[0].toString()),
              temperature: double.parse(row[1].toString()),
              humidity: double.parse(row[2].toString()),
              windSpeed: double.parse(row[3].toString()),
              pressure: double.parse(row[7].toString()),
              precipitation: row.length > 8
                  ? double.parse(row[8].toString())
                  : 0.0,
              condition: row[4].toString(),
              description: row[5].toString(),
              icon: row[6].toString(),
            );
            weatherData.add(weather);
          } catch (e) {
            // Skip invalid rows
            continue;
          }
        }

        // Store the data
        await _weatherService.storeMultipleWeatherData(weatherData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully uploaded ${weatherData.length} weather records',
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh the dashboard
          _loadDashboardData();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading CSV: $e'),
            backgroundColor: Colors.red,
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
            const SnackBar(
              content: Text('Successfully imported weather data from API'),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh the dashboard
          _loadDashboardData();
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
                    const SnackBar(
                      content: Text('Weather data entered successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Refresh the dashboard
                  _loadDashboardData();
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

    return recommendations;
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
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.dashboard, size: 48, color: Colors.white),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Farm Weather Dashboard',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Weather Data for Zimbabwe Farmers',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            context,
            'Farm Overview',
            Icons.home,
            () => _tabController.animateTo(0),
          ),
          _buildDrawerItem(
            context,
            'Weather Analysis',
            Icons.analytics,
            () => _tabController.animateTo(1),
          ),
          _buildDrawerItem(
            context,
            'Seasonal Trends',
            Icons.trending_up,
            () => _tabController.animateTo(2),
          ),
          _buildDrawerItem(
            context,
            'Farming Advice',
            Icons.lightbulb,
            () => _tabController.animateTo(3),
          ),
          const Divider(),
          _buildDrawerItem(
            context,
            'Upload Weather Data',
            Icons.cloud_upload,
            () {
              Navigator.pop(context);
              _showDataManagementDialog();
            },
          ),
          _buildDrawerItem(context, 'Download Reports', Icons.download, () {
            Navigator.pop(context);
            _showExportDialog();
          }),
          const Divider(),
          _buildDrawerItem(context, 'Refresh Weather Data', Icons.refresh, () {
            Navigator.pop(context);
            _loadDashboardData();
          }),
          _buildDrawerItem(context, 'Help & Support', Icons.help, () {
            Navigator.pop(context);
            _showHelpDialog();
          }),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
      selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help for Zimbabwe Farmers'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Farm Weather Dashboard Features:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text('• View current weather conditions for your farm'),
              Text('• Check weather alerts and warnings'),
              Text('• See seasonal weather trends'),
              Text('• Get farming advice based on weather'),
              Text('• Upload your own weather data'),
              Text('• Download weather reports'),
              SizedBox(height: 16),
              Text(
                'How to Use This App:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text('1. Check "Farm Overview" for today\'s weather'),
              Text('2. Look at "Weather Analysis" for detailed charts'),
              Text('3. View "Seasonal Trends" for long-term patterns'),
              Text('4. Read "Farming Advice" for crop recommendations'),
              Text('5. Use "Upload Data" to add your weather records'),
              SizedBox(height: 16),
              Text(
                'For Zimbabwe Farmers:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text('• Wet season: November to April'),
              Text('• Dry season: May to October'),
              Text('• Best planting time: October to December'),
              Text('• Harvest time: March to May'),
              Text('• Watch for drought warnings'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
