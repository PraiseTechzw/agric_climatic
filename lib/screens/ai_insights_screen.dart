import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../models/soil_data.dart';
import '../services/agro_prediction_service.dart';

class AIInsightsScreen extends StatefulWidget {
  const AIInsightsScreen({super.key});

  @override
  State<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends State<AIInsightsScreen> {
  final AgroPredictionService _predictionService = AgroPredictionService();
  Map<String, dynamic>? _aiInsights;
  Map<String, dynamic>? _weatherAnalysis;
  bool _isLoading = false;
  String _selectedCrop = 'maize';
  String _selectedGrowthStage = 'vegetative';
  String _selectedLocation = 'Harare';

  final List<String> _crops = [
    'maize',
    'wheat',
    'sorghum',
    'cotton',
    'tobacco',
  ];
  final List<String> _growthStages = [
    'planting',
    'vegetative',
    'flowering',
    'fruiting',
    'harvesting',
  ];
  final List<String> _locations = [
    'Harare',
    'Bulawayo',
    'Gweru',
    'Mutare',
    'Kwekwe',
  ];

  @override
  void initState() {
    super.initState();
    _loadAIInsights();
  }

  Future<void> _loadAIInsights() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current weather data
      final weatherProvider = Provider.of<WeatherProvider>(
        context,
        listen: false,
      );
      final currentWeather = weatherProvider.currentWeather;

      if (currentWeather != null) {
        // Create sample soil data
        final soilData = SoilData(
          id: '${_selectedLocation}_soil_${DateTime.now().millisecondsSinceEpoch}',
          location: _selectedLocation,
          ph: 6.5,
          organicMatter: 2.5,
          nitrogen: 15.0,
          phosphorus: 8.0,
          potassium: 120.0,
          soilMoisture: 65.0,
          soilTemperature: currentWeather.temperature,
          soilType: 'Loam',
          drainage: 'Good',
          texture: 'Medium',
          lastUpdated: DateTime.now(),
        );

        // Get AI insights
        final insights = await _predictionService.getAIInsights(
          location: _selectedLocation,
          currentWeather: currentWeather,
          soilData: soilData,
          crop: _selectedCrop,
          growthStage: _selectedGrowthStage,
        );

        // Get weather analysis
        final historicalData = weatherProvider.dailyForecast;
        final weatherAnalysis = await _predictionService.getAIWeatherAnalysis(
          location: _selectedLocation,
          historicalData: historicalData,
          daysAhead: 7,
        );

        setState(() {
          _aiInsights = insights;
          _weatherAnalysis = weatherAnalysis;
        });
      }
    } catch (e) {
      print('Error loading AI insights: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading AI insights: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Agricultural Insights'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAIInsights,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildControlPanel(),
                  const SizedBox(height: 20),
                  if (_aiInsights != null) ...[
                    _buildCropRecommendations(),
                    const SizedBox(height: 20),
                    _buildPestDiseaseAssessment(),
                    const SizedBox(height: 20),
                    _buildIrrigationAdvice(),
                    const SizedBox(height: 20),
                    _buildFarmingCalendar(),
                    const SizedBox(height: 20),
                    _buildMarketInsights(),
                  ],
                  if (_weatherAnalysis != null) ...[_buildWeatherAnalysis()],
                ],
              ),
            ),
    );
  }

  Widget _buildControlPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Analysis Parameters',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCrop,
                    decoration: const InputDecoration(labelText: 'Crop'),
                    items: _crops.map((crop) {
                      return DropdownMenuItem(
                        value: crop,
                        child: Text(crop.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCrop = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedGrowthStage,
                    decoration: const InputDecoration(
                      labelText: 'Growth Stage',
                    ),
                    items: _growthStages.map((stage) {
                      return DropdownMenuItem(
                        value: stage,
                        child: Text(stage.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedGrowthStage = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedLocation,
              decoration: const InputDecoration(labelText: 'Location'),
              items: _locations.map((location) {
                return DropdownMenuItem(value: location, child: Text(location));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLocation = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loadAIInsights,
                icon: const Icon(Icons.psychology),
                label: const Text('Get AI Insights'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropRecommendations() {
    final recommendations =
        _aiInsights?['crop_recommendations'] as Map<String, dynamic>?;
    if (recommendations == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Crop Recommendations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Recommended Crops',
              (recommendations['recommended_crops'] as List?)?.join(', ') ??
                  'N/A',
            ),
            _buildInfoRow(
              'Planting Dates',
              recommendations['planting_dates']?.toString() ?? 'N/A',
            ),
            _buildInfoRow(
              'Soil Preparation',
              recommendations['soil_preparation']?.toString() ?? 'N/A',
            ),
            _buildInfoRow(
              'Irrigation Needs',
              recommendations['irrigation_needs']?.toString() ?? 'N/A',
            ),
            _buildInfoRow(
              'Yield Potential',
              recommendations['yield_potential']?.toString() ?? 'N/A',
            ),
            if (recommendations['ai_insights'] != null) ...[
              const SizedBox(height: 12),
              const Text(
                'AI Insights:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                recommendations['ai_insights'].toString(),
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPestDiseaseAssessment() {
    final assessment =
        _aiInsights?['pest_disease_assessment'] as Map<String, dynamic>?;
    if (assessment == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pest & Disease Risk Assessment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'High Risk Pests',
              (assessment['high_risk_pests'] as List?)?.join(', ') ??
                  'None identified',
            ),
            _buildInfoRow(
              'Disease Risks',
              (assessment['disease_risks'] as List?)?.join(', ') ?? 'Low risk',
            ),
            _buildInfoRow(
              'Prevention Strategies',
              (assessment['prevention_strategies'] as List?)?.join(', ') ??
                  'Regular monitoring',
            ),
            _buildInfoRow(
              'Monitoring Schedule',
              assessment['monitoring_schedule']?.toString() ?? 'Weekly',
            ),
            if (assessment['ai_insights'] != null) ...[
              const SizedBox(height: 12),
              const Text(
                'AI Assessment:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                assessment['ai_insights'].toString(),
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIrrigationAdvice() {
    final advice = _aiInsights?['irrigation_advice'] as Map<String, dynamic>?;
    if (advice == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Irrigation Recommendations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Frequency',
              advice['frequency']?.toString() ?? 'N/A',
            ),
            _buildInfoRow('Timing', advice['timing']?.toString() ?? 'N/A'),
            _buildInfoRow(
              'Water Quantity',
              advice['quantity']?.toString() ?? 'N/A',
            ),
            _buildInfoRow(
              'Methods',
              (advice['methods'] as List?)?.join(', ') ?? 'N/A',
            ),
            _buildInfoRow(
              'Conservation Strategies',
              (advice['conservation_strategies'] as List?)?.join(', ') ?? 'N/A',
            ),
            if (advice['ai_insights'] != null) ...[
              const SizedBox(height: 12),
              const Text(
                'AI Advice:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                advice['ai_insights'].toString(),
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFarmingCalendar() {
    final calendar = _aiInsights?['farming_calendar'] as Map<String, dynamic>?;
    if (calendar == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Farming Calendar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Land Preparation',
              calendar['land_preparation']?.toString() ?? 'N/A',
            ),
            _buildInfoRow(
              'Planting Schedule',
              calendar['planting_schedule']?.toString() ?? 'N/A',
            ),
            _buildInfoRow(
              'Fertilization',
              calendar['fertilization_schedule']?.toString() ?? 'N/A',
            ),
            _buildInfoRow(
              'Pest Control',
              calendar['pest_control_timeline']?.toString() ?? 'N/A',
            ),
            _buildInfoRow(
              'Irrigation Schedule',
              calendar['irrigation_schedule']?.toString() ?? 'N/A',
            ),
            _buildInfoRow(
              'Harvesting',
              calendar['harvesting_timeline']?.toString() ?? 'N/A',
            ),
            if (calendar['ai_insights'] != null) ...[
              const SizedBox(height: 12),
              const Text(
                'AI Calendar:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                calendar['ai_insights'].toString(),
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMarketInsights() {
    final insights = _aiInsights?['market_insights'] as Map<String, dynamic>?;
    if (insights == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Market Insights',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Market Prices',
              insights['market_prices']?.toString() ?? 'N/A',
            ),
            _buildInfoRow(
              'Best Selling Periods',
              insights['selling_periods']?.toString() ?? 'N/A',
            ),
            _buildInfoRow(
              'Storage Recommendations',
              insights['storage_recommendations']?.toString() ?? 'N/A',
            ),
            _buildInfoRow(
              'Processing Opportunities',
              insights['processing_opportunities']?.toString() ?? 'N/A',
            ),
            _buildInfoRow(
              'Export Potential',
              insights['export_potential']?.toString() ?? 'N/A',
            ),
            _buildInfoRow(
              'Cost-Benefit Analysis',
              insights['cost_benefit_analysis']?.toString() ?? 'N/A',
            ),
            if (insights['ai_insights'] != null) ...[
              const SizedBox(height: 12),
              const Text(
                'AI Market Analysis:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                insights['ai_insights'].toString(),
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherAnalysis() {
    final analysis =
        _weatherAnalysis?['weather_analysis'] as Map<String, dynamic>?;
    if (analysis == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Weather Pattern Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Data Points',
              _weatherAnalysis?['data_points']?.toString() ?? 'N/A',
            ),
            _buildInfoRow(
              'Days Analyzed',
              _weatherAnalysis?['days_ahead']?.toString() ?? 'N/A',
            ),
            _buildInfoRow(
              'Trends',
              (analysis['trends'] as Map?)?.values.join(', ') ?? 'N/A',
            ),
            _buildInfoRow(
              'Predictions',
              (analysis['predictions'] as Map?)?.values.join(', ') ?? 'N/A',
            ),
            _buildInfoRow(
              'Agricultural Implications',
              analysis['agricultural_implications']?.toString() ?? 'N/A',
            ),
            _buildInfoRow(
              'Risk Assessment',
              analysis['risk_assessment']?.toString() ?? 'N/A',
            ),
            if (analysis['ai_insights'] != null) ...[
              const SizedBox(height: 12),
              const Text(
                'AI Weather Analysis:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                analysis['ai_insights'].toString(),
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
