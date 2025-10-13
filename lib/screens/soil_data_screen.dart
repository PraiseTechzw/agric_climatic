import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/soil_data_service.dart';
import '../models/soil_data.dart';
import '../providers/weather_provider.dart';

class SoilDataScreen extends StatefulWidget {
  const SoilDataScreen({super.key});

  @override
  State<SoilDataScreen> createState() => _SoilDataScreenState();
}

class _SoilDataScreenState extends State<SoilDataScreen> {
  final SoilDataService _soilService = SoilDataService();
  SoilData? _soilData;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSoilData();
  }

  Future<void> _loadSoilData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final weatherProvider = Provider.of<WeatherProvider>(
        context,
        listen: false,
      );

      double latitude = -17.8252; // Harare default
      double longitude = 31.0335;

      if (weatherProvider.locationService.currentPosition != null) {
        latitude = weatherProvider.locationService.currentPosition!.latitude;
        longitude = weatherProvider.locationService.currentPosition!.longitude;
      }

      final soilData = await _soilService.getSoilData(
        latitude: latitude,
        longitude: longitude,
      );

      setState(() {
        _soilData = soilData;
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
                Icons.terrain,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Soil Analysis',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                Navigator.pushNamed(context, '/notifications');
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
          ? _buildErrorWidget()
          : _soilData != null
          ? RefreshIndicator(
              onRefresh: _loadSoilData,
              child: _buildSoilDataContent(),
            )
          : RefreshIndicator(
              onRefresh: _loadSoilData,
              child: _buildEmptyState(),
            ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 4),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Analyzing Soil Data...',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Fetching pH, nutrients, and soil conditions',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to Load Soil Data',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Unknown error occurred',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadSoilData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.terrain_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No Soil Data Available',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap refresh to analyze soil conditions and get recommendations',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadSoilData,
              icon: const Icon(Icons.terrain),
              label: const Text('Analyze Soil'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoilDataContent() {
    final soilData = _soilData!;
    final healthScore = _soilService.getSoilHealthScore(soilData);
    final recommendations = _soilService.getSoilRecommendations(soilData);

    return RefreshIndicator(
      onRefresh: _loadSoilData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Soil Health Overview
            _buildSoilHealthCard(soilData, healthScore),

            const SizedBox(height: 20),

            // pH and Basic Properties
            _buildBasicPropertiesCard(soilData),

            const SizedBox(height: 20),

            // Nutrient Levels
            _buildNutrientLevelsCard(soilData),

            const SizedBox(height: 20),

            // Soil Conditions
            _buildSoilConditionsCard(soilData),

            const SizedBox(height: 20),

            // Recommendations
            if (recommendations.isNotEmpty) ...[
              _buildRecommendationsCard(recommendations),
              const SizedBox(height: 20),
            ],

            // Last Updated
            _buildLastUpdatedCard(soilData),
          ],
        ),
      ),
    );
  }

  Widget _buildSoilHealthCard(SoilData soilData, double healthScore) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.eco,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Soil Health Overview',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Health Score',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${healthScore.toStringAsFixed(1)}/100',
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getHealthScoreColor(healthScore),
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _getHealthScoreColor(healthScore).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Center(
                  child: Text(
                    soilData.getSoilHealth(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getHealthScoreColor(healthScore),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicPropertiesCard(SoilData soilData) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Properties',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPropertyItem(
                  'pH Level',
                  soilData.ph.toStringAsFixed(1),
                  soilData.phDescription,
                  _getPHColor(soilData.ph),
                  Icons.science,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPropertyItem(
                  'Soil Type',
                  soilData.soilType,
                  soilData.texture,
                  Colors.brown,
                  Icons.terrain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPropertyItem(
                  'Drainage',
                  soilData.drainage,
                  'Quality',
                  _getDrainageColor(soilData.drainage),
                  Icons.water_drop,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPropertyItem(
                  'Organic Matter',
                  '${soilData.organicMatter.toStringAsFixed(1)}%',
                  'Content',
                  Colors.green,
                  Icons.eco,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientLevelsCard(SoilData soilData) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nutrient Levels',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildNutrientItem(
            'Nitrogen (N)',
            '${soilData.nitrogen.toStringAsFixed(0)} mg/kg',
            soilData.getNitrogenLevel(),
            Colors.blue,
            Icons.water_drop,
          ),
          const SizedBox(height: 12),
          _buildNutrientItem(
            'Phosphorus (P)',
            '${soilData.phosphorus.toStringAsFixed(0)} mg/kg',
            soilData.getPhosphorusLevel(),
            Colors.orange,
            Icons.local_fire_department,
          ),
          const SizedBox(height: 12),
          _buildNutrientItem(
            'Potassium (K)',
            '${soilData.potassium.toStringAsFixed(0)} mg/kg',
            soilData.getPotassiumLevel(),
            Colors.purple,
            Icons.electrical_services,
          ),
        ],
      ),
    );
  }

  Widget _buildSoilConditionsCard(SoilData soilData) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Conditions',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildConditionItem(
            'Temperature',
            '${soilData.soilTemperature.toStringAsFixed(1)}°C',
            'Soil Temp',
            Colors.red,
            Icons.thermostat,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard(List<String> recommendations) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.blue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.green[600], size: 24),
              const SizedBox(width: 8),
              Text(
                'Recommendations',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recommendations.map(
            (recommendation) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green[600],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recommendation,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdatedCard(SoilData soilData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.update,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Last updated: ${_formatDateTime(soilData.lastUpdated)}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyItem(
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

  Widget _buildNutrientItem(
    String label,
    String value,
    String level,
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
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              level.toUpperCase(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionItem(
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

  Color _getHealthScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getPHColor(double ph) {
    if (ph < 5.5) return Colors.red;
    if (ph < 6.5) return Colors.orange;
    if (ph < 7.5) return Colors.green;
    if (ph < 8.5) return Colors.blue;
    return Colors.purple;
  }

  Color _getDrainageColor(String drainage) {
    switch (drainage.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.blue;
      case 'moderate':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
