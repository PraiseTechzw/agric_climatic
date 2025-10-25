import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/weather_provider.dart';
import '../widgets/location_dropdown.dart';
import '../services/rbswsa_algorithm.dart';

class EnhancedPredictionsScreen extends StatefulWidget {
  const EnhancedPredictionsScreen({super.key});

  @override
  State<EnhancedPredictionsScreen> createState() =>
      _EnhancedPredictionsScreenState();
}

class _EnhancedPredictionsScreenState extends State<EnhancedPredictionsScreen>
    with SingleTickerProviderStateMixin {
  String _selectedTimeframe = 'seasonal';
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _predictionData;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _generatePrediction();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _generatePrediction() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final predictionMonths = _selectedTimeframe == 'seasonal' ? 6 : 12;
      final prediction = await RBSWSAAlgorithm.generateSeasonalPrediction(
        location: 'Harare', // Default location
        climateZone: 'highveld', // Default climate zone
        predictionMonths: predictionMonths,
        ensoStatus: 'neutral', // Default ENSO status
      );

      setState(() {
        _predictionData = prediction;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _error = 'Failed to generate prediction: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seasonal Weather Predictions'),
        actions: [
          Consumer<WeatherProvider>(
            builder: (context, provider, child) {
              return LocationDropdown(
                selectedLocation: provider.currentLocation,
                onLocationChanged: (location) {
                  // Location change handling would be implemented here
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTimeframeSelector(),
          Expanded(child: _buildPredictionContent()),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTimeframeChip(
              'seasonal',
              'Seasonal (3-6 months)',
              Icons.calendar_month,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTimeframeChip(
              'annual',
              'Annual (1 year)',
              Icons.calendar_today,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeChip(String timeframe, String label, IconData icon) {
    final isSelected = _selectedTimeframe == timeframe;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected && _selectedTimeframe != timeframe) {
          setState(() {
            _selectedTimeframe = timeframe;
          });
          // Regenerate prediction with new timeframe
          _animationController.reset();
          _generatePrediction();
        }
      },
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
    );
  }

  Widget _buildPredictionContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generating RBSWSA predictions...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _generatePrediction(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _generatePrediction,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_predictionData != null) ...[
                _buildSmartInsights(),
                const SizedBox(height: 16),
                _buildPredictionSummary(),
                const SizedBox(height: 20),
                _buildTemperatureChart(),
                const SizedBox(height: 20),
                _buildRainfallChart(),
                const SizedBox(height: 20),
                _buildMonthlyPredictions(),
                const SizedBox(height: 20),
                _buildDroughtRiskAssessment(),
                const SizedBox(height: 20),
                _buildFarmingRecommendations(),
                const SizedBox(height: 20),
              ] else ...[
                _buildSeasonalPrediction(),
                const SizedBox(height: 24),
                _buildClimateTrends(),
                const SizedBox(height: 24),
                _buildFarmingRecommendations(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeasonalPrediction() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.wb_sunny,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Seasonal Weather Forecast',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPredictionCard(
              'Temperature Trends',
              'Expected temperature patterns for the next 3-6 months',
              _getTemperaturePrediction(),
              Icons.thermostat,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildPredictionCard(
              'Rainfall Patterns',
              'Predicted rainfall distribution and intensity',
              _getRainfallPrediction(),
              Icons.water_drop,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildPredictionCard(
              'Drought Risk',
              'Assessment of drought conditions and water availability',
              _getDroughtRiskPrediction(),
              Icons.warning,
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionCard(
    String title,
    String description,
    String prediction,
    IconData icon,
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
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  prediction,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClimateTrends() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Climate Trends & Patterns',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTrendItem(
              'El Niño/La Niña Status',
              'Neutral conditions expected',
              Icons.waves,
            ),
            _buildTrendItem(
              'Monsoon Patterns',
              'Normal onset expected in October',
              Icons.cloud,
            ),
            _buildTrendItem(
              'Temperature Anomaly',
              '+0.5°C above historical average',
              Icons.thermostat,
            ),
            _buildTrendItem(
              'Rainfall Variability',
              'Moderate variability expected',
              Icons.water_drop,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendItem(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmingRecommendations() {
    List<String> recommendations = [];

    if (_predictionData != null) {
      recommendations = List<String>.from(
        _predictionData!['farmingRecommendations'] ?? [],
      );
    } else {
      // Fallback recommendations
      recommendations = [
        'Focus on drought-tolerant varieties like sorghum and millet',
        'Delay planting by 2-3 weeks due to expected late rains',
        'Implement water conservation techniques and irrigation planning',
        'Apply organic matter to improve water retention',
      ];
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.agriculture,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _predictionData != null
                        ? 'RBSWSA Farming Recommendations'
                        : 'Seasonal Farming Recommendations',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recommendations
                .take(8)
                .map(
                  (rec) =>
                      _buildRecommendationItem(rec, Icons.lightbulb_outline),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  // Mock prediction data - in real app, this would come from the prediction service
  String _getTemperaturePrediction() {
    final month = DateTime.now().month;
    if (month >= 10 && month <= 12) {
      return 'Above average temperatures expected (28-32°C). Heat stress risk for sensitive crops.';
    } else if (month >= 1 && month <= 3) {
      return 'Normal to slightly below average temperatures (24-28°C). Good growing conditions.';
    } else if (month >= 4 && month <= 6) {
      return 'Cooler temperatures expected (20-25°C). Ideal for cool-season crops.';
    } else {
      return 'Moderate temperatures (22-26°C). Stable growing conditions.';
    }
  }

  String _getRainfallPrediction() {
    final month = DateTime.now().month;
    if (month >= 10 && month <= 12) {
      return 'Normal to above normal rainfall expected. Good for crop establishment.';
    } else if (month >= 1 && month <= 3) {
      return 'Heavy rainfall periods expected. Monitor for waterlogging.';
    } else if (month >= 4 && month <= 6) {
      return 'Below normal rainfall expected. Implement water conservation.';
    } else {
      return 'Variable rainfall patterns. Plan for both wet and dry periods.';
    }
  }

  String _getDroughtRiskPrediction() {
    final month = DateTime.now().month;
    if (month >= 4 && month <= 6) {
      return 'High drought risk. Implement water-saving measures and drought-tolerant crops.';
    } else if (month >= 10 && month <= 12) {
      return 'Low drought risk. Good conditions for crop establishment.';
    } else {
      return 'Moderate drought risk. Monitor soil moisture levels regularly.';
    }
  }

  // New UI components for RBSWSA predictions
  Widget _buildPredictionSummary() {
    if (_predictionData == null) return const SizedBox.shrink();

    final summary = _predictionData!['seasonalSummary'] as Map<String, dynamic>;

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Theme.of(context).colorScheme.secondary.withOpacity(0.02),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.insights,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Seasonal Outlook',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Avg Temperature',
                    '${summary['averageTemperature']?.toStringAsFixed(1) ?? 'N/A'}°C',
                    Icons.thermostat,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Total Rainfall',
                    '${summary['totalRainfall']?.toStringAsFixed(0) ?? 'N/A'}mm',
                    Icons.water_drop,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Avg Humidity',
                    '${summary['averageHumidity']?.toStringAsFixed(0) ?? 'N/A'}%',
                    Icons.water_drop,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Season Type',
                    summary['seasonalType'] ?? 'N/A',
                    Icons.calendar_month,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                summary['description'] ?? 'No description available',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyPredictions() {
    if (_predictionData == null) return const SizedBox.shrink();

    final monthlyPredictions =
        _predictionData!['monthlyPredictions'] as List<dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_view_month,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Monthly Predictions',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...monthlyPredictions.map(
              (monthData) => _buildMonthCard(monthData as Map<String, dynamic>),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthCard(Map<String, dynamic> monthData) {
    final temp = monthData['temperature'] as Map<String, dynamic>;
    final rain = monthData['rainfall'] as Map<String, dynamic>;
    final conditions = monthData['conditions'] as List<dynamic>;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                monthData['monthName'] ?? 'Unknown',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Confidence: ${(monthData['confidence'] * 100).toStringAsFixed(0)}%',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMonthMetric(
                  'Temperature',
                  '${temp['average']?.toStringAsFixed(1)}°C',
                  Icons.thermostat,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMonthMetric(
                  'Rainfall',
                  '${rain['total']?.toStringAsFixed(0)}mm',
                  Icons.water_drop,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: conditions
                .map(
                  (condition) => Chip(
                    label: Text(condition.toString()),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    labelStyle: Theme.of(context).textTheme.bodySmall,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthMetric(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '$label: $value',
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDroughtRiskAssessment() {
    if (_predictionData == null) return const SizedBox.shrink();

    final droughtRisk = _predictionData!['droughtRisk'] as Map<String, dynamic>;
    final riskLevel = droughtRisk['riskLevel'] as String;
    final overallRisk = droughtRisk['overallRisk'] as double;

    Color riskColor;
    IconData riskIcon;

    switch (riskLevel.toLowerCase()) {
      case 'high':
        riskColor = Colors.red;
        riskIcon = Icons.warning;
        break;
      case 'medium':
        riskColor = Colors.orange;
        riskIcon = Icons.info;
        break;
      default:
        riskColor = Colors.green;
        riskIcon = Icons.check_circle;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(riskIcon, color: riskColor),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Drought Risk Assessment',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: riskColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Overall Risk Level',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        riskLevel.toUpperCase(),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: riskColor,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: overallRisk,
                    backgroundColor: riskColor.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Risk Score: ${(overallRisk * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Recommendations:',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...(droughtRisk['recommendations'] as List<dynamic>).map(
              (rec) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: Theme.of(context).textTheme.bodyMedium),
                    Expanded(
                      child: Text(
                        rec.toString(),
                        style: Theme.of(context).textTheme.bodyMedium,
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

  // Temperature Chart
  Widget _buildTemperatureChart() {
    if (_predictionData == null) return const SizedBox.shrink();

    final monthlyPredictions =
        _predictionData!['monthlyPredictions'] as List<dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.thermostat, color: Colors.orange, size: 24),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Temperature Trend',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(color: Colors.grey[300]!, strokeWidth: 1);
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < monthlyPredictions.length) {
                            final month =
                                monthlyPredictions[value.toInt()]['monthName']
                                    as String;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                month.substring(0, 3),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}°C',
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  minX: 0,
                  maxX: (monthlyPredictions.length - 1).toDouble(),
                  minY: 10,
                  maxY: 35,
                  lineBarsData: [
                    LineChartBarData(
                      spots: monthlyPredictions.asMap().entries.map((entry) {
                        final temp =
                            entry.value['temperature'] as Map<String, dynamic>;
                        return FlSpot(
                          entry.key.toDouble(),
                          (temp['average'] as double),
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.orange,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.orange.withOpacity(0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final monthData = monthlyPredictions[spot.x.toInt()];
                          return LineTooltipItem(
                            '${monthData['monthName']}\n${spot.y.toStringAsFixed(1)}°C',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Rainfall Chart
  Widget _buildRainfallChart() {
    if (_predictionData == null) return const SizedBox.shrink();

    final monthlyPredictions =
        _predictionData!['monthlyPredictions'] as List<dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.water_drop, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Rainfall Forecast',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxRainfall(monthlyPredictions) * 1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final monthData = monthlyPredictions[group.x.toInt()];
                        return BarTooltipItem(
                          '${monthData['monthName']}\n${rod.toY.toStringAsFixed(0)}mm',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < monthlyPredictions.length) {
                            final month =
                                monthlyPredictions[value.toInt()]['monthName']
                                    as String;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                month.substring(0, 3),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}mm',
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  barGroups: monthlyPredictions.asMap().entries.map((entry) {
                    final rain =
                        entry.value['rainfall'] as Map<String, dynamic>;
                    final total = (rain['total'] as double);
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: total,
                          color: Colors.blue,
                          width: 16,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: _getMaxRainfall(monthlyPredictions) * 1.2,
                            color: Colors.blue.withOpacity(0.1),
                          ),
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

  double _getMaxRainfall(List<dynamic> monthlyPredictions) {
    double max = 0;
    for (final month in monthlyPredictions) {
      final rain = month['rainfall'] as Map<String, dynamic>;
      final total = (rain['total'] as double);
      if (total > max) max = total;
    }
    return max;
  }

  // Smart Insights - Intelligent analysis of predictions
  Widget _buildSmartInsights() {
    if (_predictionData == null) return const SizedBox.shrink();

    final summary = _predictionData!['seasonalSummary'] as Map<String, dynamic>;
    final droughtRisk = _predictionData!['droughtRisk'] as Map<String, dynamic>;
    final avgTemp = summary['averageTemperature'] as double;
    final totalRainfall = summary['totalRainfall'] as double;

    // Generate intelligent insights
    final insights = <Map<String, dynamic>>[];

    // Timeframe-specific context
    final timeframeText = _selectedTimeframe == 'annual'
        ? 'over the next 12 months'
        : 'over the next 3-6 months';

    // Temperature insight
    if (avgTemp > 23) {
      insights.add({
        'icon': Icons.wb_sunny,
        'color': Colors.orange,
        'title': 'Warmer Period Ahead',
        'message':
            'Temperatures will be above average $timeframeText. Plan for increased irrigation and heat-tolerant varieties.',
      });
    } else if (avgTemp < 18) {
      insights.add({
        'icon': Icons.ac_unit,
        'color': Colors.blue,
        'title': 'Cooler Conditions',
        'message':
            'Lower temperatures expected $timeframeText. Ideal for cool-season crops like wheat and barley.',
      });
    }

    // Rainfall insight - adjusted thresholds based on timeframe
    final rainfallThresholdHigh = _selectedTimeframe == 'annual' ? 800 : 450;
    final rainfallThresholdLow = _selectedTimeframe == 'annual' ? 600 : 300;

    if (totalRainfall > rainfallThresholdHigh) {
      insights.add({
        'icon': Icons.water_drop,
        'color': Colors.blue,
        'title': 'Good Rainfall Expected',
        'message':
            'Above-average rainfall predicted $timeframeText. Excellent for crop establishment and growth.',
      });
    } else if (totalRainfall < rainfallThresholdLow) {
      insights.add({
        'icon': Icons.water_drop_outlined,
        'color': Colors.orange,
        'title': 'Low Rainfall Alert',
        'message':
            'Below-average rainfall $timeframeText. Water conservation and drought management are critical.',
      });
    }

    // Drought risk insight
    if (droughtRisk['overallRisk'] > 0.6) {
      insights.add({
        'icon': Icons.warning_amber,
        'color': Colors.red,
        'title': 'High Drought Risk',
        'message':
            'Significant drought risk detected. Prioritize drought-tolerant crops and implement water-saving techniques.',
      });
    } else if (droughtRisk['overallRisk'] > 0.4) {
      insights.add({
        'icon': Icons.info_outline,
        'color': Colors.amber,
        'title': 'Moderate Drought Risk',
        'message':
            'Some drought risk present. Monitor soil moisture and prepare backup irrigation systems.',
      });
    }

    // Seasonal timing insight
    final currentMonth = DateTime.now().month;
    if (currentMonth >= 10 && currentMonth <= 12) {
      insights.add({
        'icon': Icons.agriculture,
        'color': Colors.green,
        'title': 'Planting Season Active',
        'message':
            'Optimal time for planting. Prepare fields and select varieties suited to predicted conditions.',
      });
    } else if (currentMonth >= 3 && currentMonth <= 5) {
      insights.add({
        'icon': Icons.grass,
        'color': Colors.brown,
        'title': 'Harvest Season',
        'message':
            'Harvest period approaching. Plan storage and post-harvest management based on predictions.',
      });
    }

    // Annual-specific insight
    if (_selectedTimeframe == 'annual') {
      insights.add({
        'icon': Icons.timeline,
        'color': Colors.purple,
        'title': 'Long-term Planning',
        'message':
            'Annual forecast enables strategic planning: crop rotation, input procurement, and market timing.',
      });
    }

    if (insights.isEmpty) {
      insights.add({
        'icon': Icons.check_circle,
        'color': Colors.green,
        'title': 'Normal Conditions',
        'message':
            'Weather patterns appear normal for the season. Standard farming practices recommended.',
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb, color: Colors.amber, size: 24),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Smart Insights',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...insights.map(
          (insight) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (insight['color'] as Color).withOpacity(0.1),
                    (insight['color'] as Color).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (insight['color'] as Color).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: insight['color'] as Color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      insight['icon'] as IconData,
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
                          insight['title'] as String,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          insight['message'] as String,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[700]),
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
