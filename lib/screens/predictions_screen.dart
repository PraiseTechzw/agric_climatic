import 'package:agric_climatic/services/agro_climatic_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../models/agro_climatic_prediction.dart';
import '../widgets/agro_prediction_card.dart';

class PredictionsScreen extends StatefulWidget {
  const PredictionsScreen({super.key});

  @override
  State<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionsScreenState extends State<PredictionsScreen> {
  final AgroPredictionService _predictionService = AgroPredictionService();
  AgroClimaticPrediction? _currentPrediction;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generatePrediction();
  }

  Future<void> _generatePrediction() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final weatherProvider = context.read<WeatherProvider>();
      final prediction = await _predictionService.generateLongTermPrediction(
        location: weatherProvider.currentLocation,
        startDate: DateTime.now(),
        daysAhead: 30,
      );

      setState(() {
        _currentPrediction = prediction;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agro-Climatic Predictions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _generatePrediction,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _currentPrediction != null
                  ? _buildPredictionContent()
                  : _buildEmptyState(),
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
            'Failed to generate prediction',
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
            onPressed: _generatePrediction,
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
            'No predictions available',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the refresh button to generate new predictions',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _generatePrediction,
            child: const Text('Generate Prediction'),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionContent() {
    final prediction = _currentPrediction!;

    return RefreshIndicator(
      onRefresh: _generatePrediction,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main prediction card
            AgroPredictionCard(prediction: prediction),

            const SizedBox(height: 16),

            // Crop recommendation
            _buildCropRecommendationCard(prediction),

            const SizedBox(height: 16),

            // Risk assessment
            _buildRiskAssessmentCard(prediction),

            const SizedBox(height: 16),

            // Weather alerts
            if (prediction.weatherAlerts.isNotEmpty) ...[
              _buildWeatherAlertsCard(prediction),
              const SizedBox(height: 16),
            ],

            // Soil conditions
            _buildSoilConditionsCard(prediction),

            const SizedBox(height: 16),

            // Climate indicators
            _buildClimateIndicatorsCard(prediction),
          ],
        ),
      ),
    );
  }

  Widget _buildCropRecommendationCard(AgroClimaticPrediction prediction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.agriculture,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Crop Recommendation',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              prediction.cropRecommendation.toUpperCase(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Expected Yield: ${prediction.yieldPrediction.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: prediction.yieldColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            _buildAdviceItem('Planting', prediction.plantingAdvice, Icons.eco),
            const SizedBox(height: 8),
            _buildAdviceItem(
                'Harvesting', prediction.harvestingAdvice, Icons.agriculture),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskAssessmentCard(AgroClimaticPrediction prediction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text(
                  'Risk Assessment',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildRiskItem(
                    'Pest Risk',
                    prediction.pestRisk,
                    prediction.pestRiskColor,
                    Icons.bug_report,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildRiskItem(
                    'Disease Risk',
                    prediction.diseaseRisk,
                    prediction.diseaseRiskColor,
                    Icons.health_and_safety,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskItem(String label, String risk, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 2),
          Text(
            risk.toUpperCase(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherAlertsCard(AgroClimaticPrediction prediction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications, color: Colors.red[600]),
                const SizedBox(width: 8),
                Text(
                  'Weather Alerts',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...prediction.weatherAlerts.map((alert) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber,
                          color: Colors.red[600], size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          alert,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSoilConditionsCard(AgroClimaticPrediction prediction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.terrain, color: Colors.brown[600]),
                const SizedBox(width: 8),
                Text(
                  'Soil Conditions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildConditionItem(
                    'Moisture',
                    '${prediction.soilMoisture.toStringAsFixed(1)}%',
                    prediction.soilMoistureColor,
                    Icons.water_drop,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildConditionItem(
                    'pH Level',
                    '${prediction.soilConditions['ph_level']}',
                    Colors.green,
                    Icons.science,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildAdviceItem(
                'Irrigation', prediction.irrigationAdvice, Icons.water),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionItem(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildClimateIndicatorsCard(AgroClimaticPrediction prediction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  'Climate Indicators',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildIndicatorItem('Temperature Trend',
                prediction.climateIndicators['temperature_trend']),
            _buildIndicatorItem('Precipitation Trend',
                prediction.climateIndicators['precipitation_trend']),
            _buildIndicatorItem('Humidity Trend',
                prediction.climateIndicators['humidity_trend']),
            _buildIndicatorItem('Climate Risk Index',
                '${(prediction.climateIndicators['climate_risk_index'] * 100).toStringAsFixed(1)}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorItem(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceItem(String title, String advice, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  advice,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
