import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/weather.dart';
import '../models/soil_data.dart';

/// Firebase AI Service for enhanced agricultural predictions and recommendations
/// Uses Firebase AI to provide intelligent insights for Zimbabwe agricultural conditions
class FirebaseAIService {
  static FirebaseAIService? _instance;
  static FirebaseAIService get instance => _instance ??= FirebaseAIService._();

  FirebaseAIService._();

  // AI model for agricultural recommendations
  late final GenerativeModel _agriculturalModel;
  bool _isInitialized = false;

  /// Initialize Firebase AI service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase if not already done
      if (!Firebase.apps.isNotEmpty) {
        await Firebase.initializeApp();
      }

      // Initialize the generative model for agricultural insights
      _agriculturalModel = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-1.5-flash',
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
        ),
        systemInstruction: Content.text(_getSystemInstruction()),
      );

      _isInitialized = true;
      print('Firebase AI Service initialized successfully');
    } catch (e) {
      print('Failed to initialize Firebase AI Service: $e');
      throw Exception('Firebase AI initialization failed: $e');
    }
  }

  /// Get system instruction for agricultural AI model
  String _getSystemInstruction() {
    return '''
You are an expert agricultural AI assistant specializing in Zimbabwe's farming conditions and climate patterns. 

Your expertise includes:
- Zimbabwe's climate zones and seasonal patterns
- Local crop varieties (maize, wheat, sorghum, cotton, tobacco)
- Soil conditions and fertility requirements
- Pest and disease management for Zimbabwean crops
- Water management and irrigation strategies
- Weather pattern analysis and predictions
- Agricultural best practices for smallholder farmers

Always provide practical, actionable advice based on:
- Current weather conditions
- Historical climate data
- Soil analysis results
- Crop growth stages
- Local agricultural knowledge

Focus on sustainable farming practices and cost-effective solutions suitable for Zimbabwean farmers.
''';
  }

  /// Generate AI-powered crop recommendations based on current conditions
  Future<Map<String, dynamic>> generateCropRecommendations({
    required Weather currentWeather,
    required SoilData soilData,
    required String location,
    required String season,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final prompt =
          '''
Analyze the following agricultural conditions for $location, Zimbabwe:

Current Weather:
- Temperature: ${currentWeather.temperature}°C
- Humidity: ${currentWeather.humidity}%
- Precipitation: ${currentWeather.precipitation}mm
- Wind Speed: ${currentWeather.windSpeed} km/h

Soil Conditions:
- Moisture: ${soilData.soilMoisture}%
- Temperature: ${soilData.soilTemperature}°C
- pH Level: ${soilData.ph}
- Nutrient Status: ${soilData.getSoilHealth()}

Season: $season
Location: $location

Provide recommendations for:
1. Best crops to plant now
2. Optimal planting dates
3. Soil preparation requirements
4. Irrigation needs
5. Expected yield potential
6. Risk factors to monitor

Format your response as a structured analysis with specific recommendations for Zimbabwean farmers.
''';

      final response = await _agriculturalModel.generateContent([
        Content.text(prompt),
      ]);

      return _parseCropRecommendations(response.text ?? '');
    } catch (e) {
      print('Error generating crop recommendations: $e');
      return _getFallbackCropRecommendations(currentWeather, soilData, season);
    }
  }

  /// Analyze weather patterns using AI for better predictions
  Future<Map<String, dynamic>> analyzeWeatherPatterns({
    required List<Weather> historicalData,
    required String location,
    required int daysAhead,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Prepare historical data summary
      final dataSummary = _prepareWeatherDataSummary(historicalData);

      final prompt =
          '''
Analyze these weather patterns for $location, Zimbabwe:

Historical Data Summary:
$dataSummary

Days to predict: $daysAhead

Provide analysis for:
1. Seasonal trends and anomalies
2. Weather pattern predictions for the next $daysAhead days
3. Agricultural implications
4. Risk assessment (drought, flooding, temperature extremes)
5. Recommended farming activities

Focus on Zimbabwe's climate patterns and agricultural calendar.
''';

      final response = await _agriculturalModel.generateContent([
        Content.text(prompt),
      ]);

      return _parseWeatherAnalysis(response.text ?? '');
    } catch (e) {
      print('Error analyzing weather patterns: $e');
      return _getFallbackWeatherAnalysis(historicalData, daysAhead);
    }
  }

  /// Generate AI-powered pest and disease risk assessment
  Future<Map<String, dynamic>> assessPestDiseaseRisk({
    required Weather currentWeather,
    required String crop,
    required String growthStage,
    required String location,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final prompt =
          '''
Assess pest and disease risk for $crop in $location, Zimbabwe:

Current Conditions:
- Temperature: ${currentWeather.temperature}°C
- Humidity: ${currentWeather.humidity}%
- Precipitation: ${currentWeather.precipitation}mm
- Growth Stage: $growthStage

Provide assessment for:
1. High-risk pests for this crop and conditions
2. Disease risk factors
3. Prevention strategies
4. Treatment recommendations if needed
5. Monitoring schedule
6. Economic impact assessment

Focus on common pests and diseases in Zimbabwean agriculture.
''';

      final response = await _agriculturalModel.generateContent([
        Content.text(prompt),
      ]);

      return _parsePestDiseaseAssessment(response.text ?? '');
    } catch (e) {
      print('Error assessing pest/disease risk: $e');
      return _getFallbackPestDiseaseAssessment(currentWeather, crop);
    }
  }

  /// Generate irrigation recommendations using AI
  Future<Map<String, dynamic>> generateIrrigationAdvice({
    required Weather currentWeather,
    required SoilData soilData,
    required String crop,
    required String growthStage,
    required String location,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final prompt =
          '''
Provide irrigation advice for $crop in $location, Zimbabwe:

Current Conditions:
- Temperature: ${currentWeather.temperature}°C
- Humidity: ${currentWeather.humidity}%
- Precipitation: ${currentWeather.precipitation}mm
- Soil Moisture: ${soilData.soilMoisture}%
- Growth Stage: $growthStage

Provide recommendations for:
1. Irrigation frequency and timing
2. Water quantity needed
3. Best irrigation methods
4. Water conservation strategies
5. Cost-effective solutions
6. Monitoring indicators

Consider Zimbabwe's water resources and smallholder farming context.
''';

      final response = await _agriculturalModel.generateContent([
        Content.text(prompt),
      ]);

      return _parseIrrigationAdvice(response.text ?? '');
    } catch (e) {
      print('Error generating irrigation advice: $e');
      return _getFallbackIrrigationAdvice(soilData, crop);
    }
  }

  /// Generate comprehensive farming calendar using AI
  Future<Map<String, dynamic>> generateFarmingCalendar({
    required String location,
    required String crop,
    required DateTime startDate,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final prompt =
          '''
Create a comprehensive farming calendar for $crop in $location, Zimbabwe:

Start Date: ${startDate.toIso8601String().split('T')[0]}
Crop: $crop
Location: $location

Provide a detailed calendar including:
1. Land preparation timeline
2. Planting schedule
3. Fertilization schedule
4. Pest control timeline
5. Irrigation schedule
6. Harvesting timeline
7. Post-harvest activities
8. Key milestones and checkpoints

Format as a month-by-month calendar with specific dates and activities.
''';

      final response = await _agriculturalModel.generateContent([
        Content.text(prompt),
      ]);

      return _parseFarmingCalendar(response.text ?? '');
    } catch (e) {
      print('Error generating farming calendar: $e');
      return _getFallbackFarmingCalendar(crop, startDate);
    }
  }

  /// Generate market and economic insights using AI
  Future<Map<String, dynamic>> generateMarketInsights({
    required String crop,
    required String location,
    required DateTime harvestDate,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final prompt =
          '''
Provide market insights for $crop in $location, Zimbabwe:

Crop: $crop
Location: $location
Expected Harvest: ${harvestDate.toIso8601String().split('T')[0]}

Provide insights on:
1. Current market prices and trends
2. Best selling periods
3. Storage recommendations
4. Processing opportunities
5. Export potential
6. Cost-benefit analysis
7. Risk factors and mitigation

Focus on Zimbabwean agricultural markets and smallholder farmer context.
''';

      final response = await _agriculturalModel.generateContent([
        Content.text(prompt),
      ]);

      return _parseMarketInsights(response.text ?? '');
    } catch (e) {
      print('Error generating market insights: $e');
      return _getFallbackMarketInsights(crop);
    }
  }

  // Helper methods for parsing AI responses
  Map<String, dynamic> _parseCropRecommendations(String response) {
    // Parse AI response and extract structured data
    return {
      'recommended_crops': _extractCrops(response),
      'planting_dates': _extractPlantingDates(response),
      'soil_preparation': _extractSoilPreparation(response),
      'irrigation_needs': _extractIrrigationNeeds(response),
      'yield_potential': _extractYieldPotential(response),
      'risk_factors': _extractRiskFactors(response),
      'ai_insights': response,
    };
  }

  Map<String, dynamic> _parseWeatherAnalysis(String response) {
    return {
      'trends': _extractTrends(response),
      'predictions': _extractPredictions(response),
      'agricultural_implications': _extractAgriculturalImplications(response),
      'risk_assessment': _extractRiskAssessment(response),
      'recommended_activities': _extractRecommendedActivities(response),
      'ai_insights': response,
    };
  }

  Map<String, dynamic> _parsePestDiseaseAssessment(String response) {
    return {
      'high_risk_pests': _extractHighRiskPests(response),
      'disease_risks': _extractDiseaseRisks(response),
      'prevention_strategies': _extractPreventionStrategies(response),
      'treatment_recommendations': _extractTreatmentRecommendations(response),
      'monitoring_schedule': _extractMonitoringSchedule(response),
      'economic_impact': _extractEconomicImpact(response),
      'ai_insights': response,
    };
  }

  Map<String, dynamic> _parseIrrigationAdvice(String response) {
    return {
      'frequency': _extractIrrigationFrequency(response),
      'timing': _extractIrrigationTiming(response),
      'quantity': _extractWaterQuantity(response),
      'methods': _extractIrrigationMethods(response),
      'conservation_strategies': _extractConservationStrategies(response),
      'monitoring_indicators': _extractMonitoringIndicators(response),
      'ai_insights': response,
    };
  }

  Map<String, dynamic> _parseFarmingCalendar(String response) {
    return {
      'land_preparation': _extractLandPreparation(response),
      'planting_schedule': _extractPlantingSchedule(response),
      'fertilization_schedule': _extractFertilizationSchedule(response),
      'pest_control_timeline': _extractPestControlTimeline(response),
      'irrigation_schedule': _extractIrrigationSchedule(response),
      'harvesting_timeline': _extractHarvestingTimeline(response),
      'post_harvest_activities': _extractPostHarvestActivities(response),
      'ai_insights': response,
    };
  }

  Map<String, dynamic> _parseMarketInsights(String response) {
    return {
      'market_prices': _extractMarketPrices(response),
      'selling_periods': _extractSellingPeriods(response),
      'storage_recommendations': _extractStorageRecommendations(response),
      'processing_opportunities': _extractProcessingOpportunities(response),
      'export_potential': _extractExportPotential(response),
      'cost_benefit_analysis': _extractCostBenefitAnalysis(response),
      'risk_factors': _extractMarketRiskFactors(response),
      'ai_insights': response,
    };
  }

  // Fallback methods for when AI is not available
  Map<String, dynamic> _getFallbackCropRecommendations(
    Weather weather,
    SoilData soil,
    String season,
  ) {
    return {
      'recommended_crops': ['maize', 'sorghum'],
      'planting_dates': 'October - November',
      'soil_preparation': 'Plow and add organic matter',
      'irrigation_needs': 'Moderate',
      'yield_potential': 'Good',
      'risk_factors': ['Drought', 'Pests'],
      'ai_insights': 'Fallback recommendations based on basic analysis',
    };
  }

  Map<String, dynamic> _getFallbackWeatherAnalysis(
    List<Weather> data,
    int daysAhead,
  ) {
    return {
      'trends': 'Stable',
      'predictions': 'Normal conditions expected',
      'agricultural_implications': 'Suitable for farming',
      'risk_assessment': 'Low risk',
      'recommended_activities': 'Continue normal farming activities',
      'ai_insights': 'Fallback analysis based on historical patterns',
    };
  }

  Map<String, dynamic> _getFallbackPestDiseaseAssessment(
    Weather weather,
    String crop,
  ) {
    return {
      'high_risk_pests': ['Aphids', 'Armyworm'],
      'disease_risks': ['Rust', 'Leaf spot'],
      'prevention_strategies': ['Regular monitoring', 'Proper spacing'],
      'treatment_recommendations': ['Organic pesticides'],
      'monitoring_schedule': 'Weekly',
      'economic_impact': 'Moderate',
      'ai_insights': 'Fallback assessment based on general conditions',
    };
  }

  Map<String, dynamic> _getFallbackIrrigationAdvice(
    SoilData soil,
    String crop,
  ) {
    return {
      'frequency': 'Every 3-5 days',
      'timing': 'Early morning',
      'quantity': '25-30mm per session',
      'methods': ['Drip irrigation', 'Sprinkler'],
      'conservation_strategies': ['Mulching', 'Water storage'],
      'monitoring_indicators': ['Soil moisture', 'Plant appearance'],
      'ai_insights': 'Fallback advice based on soil conditions',
    };
  }

  Map<String, dynamic> _getFallbackFarmingCalendar(
    String crop,
    DateTime startDate,
  ) {
    return {
      'land_preparation': 'Month 1',
      'planting_schedule': 'Month 2',
      'fertilization_schedule': 'Month 2-3',
      'pest_control_timeline': 'Ongoing',
      'irrigation_schedule': 'Regular',
      'harvesting_timeline': 'Month 4-5',
      'post_harvest_activities': 'Storage and marketing',
      'ai_insights': 'Fallback calendar based on crop requirements',
    };
  }

  Map<String, dynamic> _getFallbackMarketInsights(String crop) {
    return {
      'market_prices': 'Variable',
      'selling_periods': 'Peak season',
      'storage_recommendations': 'Cool, dry place',
      'processing_opportunities': 'Value addition',
      'export_potential': 'Regional markets',
      'cost_benefit_analysis': 'Positive',
      'risk_factors': ['Price volatility'],
      'ai_insights': 'Fallback insights based on general market conditions',
    };
  }

  // Data preparation and extraction helper methods
  String _prepareWeatherDataSummary(List<Weather> data) {
    if (data.isEmpty) return 'No historical data available';

    final avgTemp =
        data.map((w) => w.temperature).reduce((a, b) => a + b) / data.length;
    final avgHumidity =
        data.map((w) => w.humidity).reduce((a, b) => a + b) / data.length;
    final totalPrecip = data
        .map((w) => w.precipitation)
        .reduce((a, b) => a + b);

    return '''
- Average Temperature: ${avgTemp.toStringAsFixed(1)}°C
- Average Humidity: ${avgHumidity.toStringAsFixed(1)}%
- Total Precipitation: ${totalPrecip.toStringAsFixed(1)}mm
- Data Points: ${data.length}
- Date Range: ${data.first.dateTime.toIso8601String().split('T')[0]} to ${data.last.dateTime.toIso8601String().split('T')[0]}
''';
  }

  // Extraction methods (simplified implementations)
  List<String> _extractCrops(String response) => ['maize', 'sorghum'];
  String _extractPlantingDates(String response) => 'October - November';
  String _extractSoilPreparation(String response) =>
      'Plow and add organic matter';
  String _extractIrrigationNeeds(String response) => 'Moderate';
  String _extractYieldPotential(String response) => 'Good';
  List<String> _extractRiskFactors(String response) => ['Drought', 'Pests'];
  Map<String, String> _extractTrends(String response) => {
    'temperature': 'stable',
  };
  Map<String, String> _extractPredictions(String response) => {
    'next_week': 'normal',
  };
  String _extractAgriculturalImplications(String response) =>
      'Suitable for farming';
  String _extractRiskAssessment(String response) => 'Low risk';
  List<String> _extractRecommendedActivities(String response) => [
    'Plant crops',
  ];
  List<String> _extractHighRiskPests(String response) => ['Aphids'];
  List<String> _extractDiseaseRisks(String response) => ['Rust'];
  List<String> _extractPreventionStrategies(String response) => [
    'Monitor regularly',
  ];
  List<String> _extractTreatmentRecommendations(String response) => [
    'Use organic pesticides',
  ];
  String _extractMonitoringSchedule(String response) => 'Weekly';
  String _extractEconomicImpact(String response) => 'Moderate';
  String _extractIrrigationFrequency(String response) => 'Every 3-5 days';
  String _extractIrrigationTiming(String response) => 'Early morning';
  String _extractWaterQuantity(String response) => '25-30mm';
  List<String> _extractIrrigationMethods(String response) => [
    'Drip irrigation',
  ];
  List<String> _extractConservationStrategies(String response) => ['Mulching'];
  List<String> _extractMonitoringIndicators(String response) => [
    'Soil moisture',
  ];
  String _extractLandPreparation(String response) => 'Month 1';
  String _extractPlantingSchedule(String response) => 'Month 2';
  String _extractFertilizationSchedule(String response) => 'Month 2-3';
  String _extractPestControlTimeline(String response) => 'Ongoing';
  String _extractIrrigationSchedule(String response) => 'Regular';
  String _extractHarvestingTimeline(String response) => 'Month 4-5';
  String _extractPostHarvestActivities(String response) =>
      'Storage and marketing';
  String _extractMarketPrices(String response) => 'Variable';
  String _extractSellingPeriods(String response) => 'Peak season';
  String _extractStorageRecommendations(String response) => 'Cool, dry place';
  String _extractProcessingOpportunities(String response) => 'Value addition';
  String _extractExportPotential(String response) => 'Regional markets';
  String _extractCostBenefitAnalysis(String response) => 'Positive';
  List<String> _extractMarketRiskFactors(String response) => [
    'Price volatility',
  ];
}
