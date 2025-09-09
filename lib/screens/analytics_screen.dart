import 'package:agric_climatic/services/agro_climatic_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/weather_provider.dart';
import '../models/agro_climatic_prediction.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AgroPredictionService _predictionService = AgroPredictionService();
  List<HistoricalWeatherPattern> _patterns = [];
  bool _isLoading = false;
  String? _error;
  String _selectedTimeframe = '1 Year';

  final List<String> _timeframes = [
    '3 Months',
    '6 Months',
    '1 Year',
    '2 Years'
  ];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final weatherProvider = context.read<WeatherProvider>();
      final endDate = DateTime.now();
      final startDate = _getStartDateForTimeframe(_selectedTimeframe);

      final patterns = await _predictionService.analyzeSequentialPatterns(
        location: weatherProvider.currentLocation,
        startDate: startDate,
        endDate: endDate,
      );

      setState(() {
        _patterns = patterns;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  DateTime _getStartDateForTimeframe(String timeframe) {
    final now = DateTime.now();
    switch (timeframe) {
      case '3 Months':
        return now.subtract(const Duration(days: 90));
      case '6 Months':
        return now.subtract(const Duration(days: 180));
      case '1 Year':
        return now.subtract(const Duration(days: 365));
      case '2 Years':
        return now.subtract(const Duration(days: 730));
      default:
        return now.subtract(const Duration(days: 365));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Analytics'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedTimeframe = value;
              });
              _loadAnalytics();
            },
            itemBuilder: (context) => _timeframes.map((timeframe) {
              return PopupMenuItem<String>(
                value: timeframe,
                child: Text(timeframe),
              );
            }).toList(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedTimeframe),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _patterns.isEmpty
                  ? _buildEmptyState()
                  : _buildAnalyticsContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load analytics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAnalytics,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No analytics data available',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Historical weather data is needed to generate analytics',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary cards
            _buildSummaryCards(),

            const SizedBox(height: 16),

            // Temperature trend chart
            _buildTemperatureChart(),

            const SizedBox(height: 16),

            // Precipitation chart
            _buildPrecipitationChart(),

            const SizedBox(height: 16),

            // Seasonal patterns
            _buildSeasonalPatterns(),

            const SizedBox(height: 16),

            // Pattern analysis
            _buildPatternAnalysis(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    if (_patterns.isEmpty) return const SizedBox.shrink();

    final avgTemp =
        _patterns.map((p) => p.averageTemperature).reduce((a, b) => a + b) /
            _patterns.length;
    final totalPrecip =
        _patterns.map((p) => p.totalPrecipitation).reduce((a, b) => a + b);
    final avgHumidity =
        _patterns.map((p) => p.averageHumidity).reduce((a, b) => a + b) /
            _patterns.length;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Avg Temperature',
            '${avgTemp.toStringAsFixed(1)}°C',
            Icons.thermostat,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            'Total Precipitation',
            '${totalPrecip.toStringAsFixed(1)}mm',
            Icons.water_drop,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            'Avg Humidity',
            '${avgHumidity.toStringAsFixed(1)}%',
            Icons.water_drop,
            Colors.cyan,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
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
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}°C');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < _patterns.length) {
                            return Text(_patterns[value.toInt()].season);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _patterns.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(),
                            entry.value.averageTemperature);
                      }).toList(),
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
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

  Widget _buildPrecipitationChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Precipitation Patterns',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _patterns
                          .map((p) => p.totalPrecipitation)
                          .reduce((a, b) => a > b ? a : b) +
                      10,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}mm');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < _patterns.length) {
                            return Text(_patterns[value.toInt()].season);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  barGroups: _patterns.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.totalPrecipitation,
                          color: Colors.blue,
                          width: 20,
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

  Widget _buildSeasonalPatterns() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seasonal Patterns',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ..._patterns.map((pattern) => _buildSeasonalPatternItem(pattern)),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonalPatternItem(HistoricalWeatherPattern pattern) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                pattern.season.toUpperCase(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPatternTypeColor(pattern.patternType)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  pattern.patternType.replaceAll('_', ' ').toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getPatternTypeColor(pattern.patternType),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildPatternMetric('Temp',
                    '${pattern.averageTemperature.toStringAsFixed(1)}°C'),
              ),
              Expanded(
                child: _buildPatternMetric('Precip',
                    '${pattern.totalPrecipitation.toStringAsFixed(1)}mm'),
              ),
              Expanded(
                child: _buildPatternMetric('Humidity',
                    '${pattern.averageHumidity.toStringAsFixed(1)}%'),
              ),
            ],
          ),
          if (pattern.anomalies.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Anomalies: ${pattern.anomalies.join(', ')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red[600],
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPatternMetric(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildPatternAnalysis() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pattern Analysis',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ..._patterns.map((pattern) => _buildAnalysisItem(pattern)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisItem(HistoricalWeatherPattern pattern) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${pattern.season.toUpperCase()} Analysis',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            pattern.summary,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (pattern.trends.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Trends: ${pattern.trends.entries.map((e) => '${e.key}: ${e.value.toStringAsFixed(2)}').join(', ')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.blue[700],
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getPatternTypeColor(String patternType) {
    switch (patternType) {
      case 'hot_wet':
        return Colors.red;
      case 'hot_dry':
        return Colors.orange;
      case 'cool_wet':
        return Colors.blue;
      case 'cool_dry':
        return Colors.grey;
      case 'moderate':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
