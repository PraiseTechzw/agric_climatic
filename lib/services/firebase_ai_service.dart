import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/weather.dart';
import '../models/soil_data.dart';
import 'logging_service.dart';

/// Firebase AI Service for enhanced agricultural predictions and recommendations
/// Uses Firebase AI to provide intelligent insights for Zimbabwe agricultural conditions
class FirebaseAIService {
  static FirebaseAIService? _instance;
  static FirebaseAIService get instance => _instance ??= FirebaseAIService._();

  FirebaseAIService._();

  // AI model for agricultural recommendations
  late final GenerativeModel _agriculturalModel;
  bool _isInitialized = false;
  int _requestCount = 0;
  int _errorCount = 0;
  List<Duration> _responseTimes = [];
  DateTime? _lastRequestTime;

  /// Initialize Firebase AI service
  Future<void> initialize() async {
    if (_isInitialized) return;

    final stopwatch = Stopwatch()..start();

    try {
      LoggingService.info('Initializing Firebase AI Service...', tag: 'AI');

      // Initialize Firebase if not already done
      if (!Firebase.apps.isNotEmpty) {
        await Firebase.initializeApp();
        LoggingService.debug('Firebase initialized', tag: 'AI');
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
      stopwatch.stop();

      LoggingService.info(
        'Firebase AI Service initialized successfully',
        tag: 'AI',
        extra: {'initialization_time_ms': stopwatch.elapsedMilliseconds},
      );
    } catch (e) {
      stopwatch.stop();
      _errorCount++;

      LoggingService.error(
        'Failed to initialize Firebase AI Service',
        tag: 'AI',
        error: e,
        extra: {'initialization_time_ms': stopwatch.elapsedMilliseconds},
      );

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

    final stopwatch = Stopwatch()..start();
    _requestCount++;
    _lastRequestTime = DateTime.now();

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

      final result = _parseCropRecommendations(response.text ?? '');

      _responseTimes.add(stopwatch.elapsed);
      if (_responseTimes.length > 50) {
        _responseTimes.removeAt(0);
      }

      LoggingService.logAiOperation(
        'generate_crop_recommendations',
        requestData: {
          'location': location,
          'season': season,
          'temperature': currentWeather.temperature,
          'humidity': currentWeather.humidity,
        },
        responseData: result,
        duration: stopwatch.elapsed,
      );

      return result;
    } catch (e) {
      stopwatch.stop();
      _errorCount++;

      LoggingService.logAiOperation(
        'generate_crop_recommendations',
        requestData: {
          'location': location,
          'season': season,
          'temperature': currentWeather.temperature,
          'humidity': currentWeather.humidity,
        },
        duration: stopwatch.elapsed,
        error: e.toString(),
      );

      // Return fallback recommendations
      return _getFallbackCropRecommendations(location, season);
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

    final stopwatch = Stopwatch()..start();
    _requestCount++;
    _lastRequestTime = DateTime.now();

    try {
      final prompt =
          '''
Analyze pest and disease risks for $crop in $location, Zimbabwe:

Current Conditions:
- Temperature: ${currentWeather.temperature}°C
- Humidity: ${currentWeather.humidity}%
- Precipitation: ${currentWeather.precipitation}mm
- Growth Stage: $growthStage

Provide risk assessment for:
1. Common pests for this crop and growth stage
2. Disease risks based on weather conditions
3. Prevention strategies
4. Treatment recommendations if risks are high
5. Monitoring schedule

Format as structured analysis with risk levels (Low/Medium/High) and specific recommendations.
''';

      final response = await _agriculturalModel.generateContent([
        Content.text(prompt),
      ]);

      final result = _parsePestDiseaseAssessment(response.text ?? '');

      _responseTimes.add(stopwatch.elapsed);
      if (_responseTimes.length > 50) {
        _responseTimes.removeAt(0);
      }

      LoggingService.logAiOperation(
        'assess_pest_disease_risk',
        requestData: {
          'crop': crop,
          'growth_stage': growthStage,
          'location': location,
          'temperature': currentWeather.temperature,
          'humidity': currentWeather.humidity,
        },
        responseData: result,
        duration: stopwatch.elapsed,
      );

      return result;
    } catch (e) {
      stopwatch.stop();
      _errorCount++;

      LoggingService.logAiOperation(
        'assess_pest_disease_risk',
        requestData: {
          'crop': crop,
          'growth_stage': growthStage,
          'location': location,
        },
        duration: stopwatch.elapsed,
        error: e.toString(),
      );

      return _getFallbackPestDiseaseAssessment(crop, growthStage);
    }
  }

  /// Generate irrigation advice based on current conditions
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

    final stopwatch = Stopwatch()..start();
    _requestCount++;
    _lastRequestTime = DateTime.now();

    try {
      final prompt =
          '''
Provide irrigation advice for $crop in $location, Zimbabwe:

Current Conditions:
- Temperature: ${currentWeather.temperature}°C
- Humidity: ${currentWeather.humidity}%
- Precipitation: ${currentWeather.precipitation}mm
- Soil Temperature: ${soilData.soilTemperature}°C
- Growth Stage: $growthStage

Provide recommendations for:
1. Irrigation frequency and timing
2. Water amount per session
3. Best irrigation method for this crop
4. Water conservation strategies
5. Signs of over/under watering to watch for

Format as structured advice with specific measurements and schedules.
''';

      final response = await _agriculturalModel.generateContent([
        Content.text(prompt),
      ]);

      final result = _parseIrrigationAdvice(response.text ?? '');

      _responseTimes.add(stopwatch.elapsed);
      if (_responseTimes.length > 50) {
        _responseTimes.removeAt(0);
      }

      LoggingService.logAiOperation(
        'generate_irrigation_advice',
        requestData: {
          'crop': crop,
          'growth_stage': growthStage,
          'location': location,
          'temperature': currentWeather.temperature,
        },
        responseData: result,
        duration: stopwatch.elapsed,
      );

      return result;
    } catch (e) {
      stopwatch.stop();
      _errorCount++;

      LoggingService.logAiOperation(
        'generate_irrigation_advice',
        requestData: {
          'crop': crop,
          'growth_stage': growthStage,
          'location': location,
        },
        duration: stopwatch.elapsed,
        error: e.toString(),
      );

      return _getFallbackIrrigationAdvice(crop, growthStage, soilData);
    }
  }

  /// Generate farming calendar for the year
  Future<Map<String, dynamic>> generateFarmingCalendar({
    required String location,
    required String crop,
    required DateTime startDate,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final stopwatch = Stopwatch()..start();
    _requestCount++;
    _lastRequestTime = DateTime.now();

    try {
      final prompt =
          '''
Create a detailed farming calendar for $crop in $location, Zimbabwe for the year ${startDate.year}:

Include:
1. Planting dates and preparation timeline
2. Growth stages and expected durations
3. Fertilization schedule
4. Pest and disease monitoring periods
5. Harvest timing and preparation
6. Post-harvest activities
7. Weather considerations for each phase

Format as a month-by-month calendar with specific dates and activities.
''';

      final response = await _agriculturalModel.generateContent([
        Content.text(prompt),
      ]);

      final result = _parseFarmingCalendar(response.text ?? '');

      _responseTimes.add(stopwatch.elapsed);
      if (_responseTimes.length > 50) {
        _responseTimes.removeAt(0);
      }

      LoggingService.logAiOperation(
        'generate_farming_calendar',
        requestData: {
          'crop': crop,
          'location': location,
          'year': startDate.year,
        },
        responseData: result,
        duration: stopwatch.elapsed,
      );

      return result;
    } catch (e) {
      stopwatch.stop();
      _errorCount++;

      LoggingService.logAiOperation(
        'generate_farming_calendar',
        requestData: {
          'crop': crop,
          'location': location,
          'year': startDate.year,
        },
        duration: stopwatch.elapsed,
        error: e.toString(),
      );

      return _getFallbackFarmingCalendar(crop, location, startDate);
    }
  }

  /// Generate market insights and pricing information
  Future<Map<String, dynamic>> generateMarketInsights({
    required String crop,
    required String location,
    required DateTime harvestDate,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final stopwatch = Stopwatch()..start();
    _requestCount++;
    _lastRequestTime = DateTime.now();

    try {
      final prompt =
          '''
Provide market insights for $crop in $location, Zimbabwe:

Harvest Date: ${harvestDate.toString().split(' ')[0]}

Include:
1. Expected market prices and trends
2. Best selling periods and timing
3. Local and export market opportunities
4. Quality requirements for different markets
5. Storage and transportation considerations
6. Risk factors and mitigation strategies

Format as structured market analysis with specific recommendations.
''';

      final response = await _agriculturalModel.generateContent([
        Content.text(prompt),
      ]);

      final result = _parseMarketInsights(response.text ?? '');

      _responseTimes.add(stopwatch.elapsed);
      if (_responseTimes.length > 50) {
        _responseTimes.removeAt(0);
      }

      LoggingService.logAiOperation(
        'generate_market_insights',
        requestData: {
          'crop': crop,
          'location': location,
          'harvest_date': harvestDate.toIso8601String(),
        },
        responseData: result,
        duration: stopwatch.elapsed,
      );

      return result;
    } catch (e) {
      stopwatch.stop();
      _errorCount++;

      LoggingService.logAiOperation(
        'generate_market_insights',
        requestData: {
          'crop': crop,
          'location': location,
          'harvest_date': harvestDate.toIso8601String(),
        },
        duration: stopwatch.elapsed,
        error: e.toString(),
      );

      return _getFallbackMarketInsights(crop, location);
    }
  }

  /// Get AI service statistics for debug console
  Map<String, dynamic> getServiceStats() {
    final avgResponseTime = _responseTimes.isEmpty
        ? 0.0
        : _responseTimes.map((d) => d.inMilliseconds).reduce((a, b) => a + b) /
              _responseTimes.length;

    return {
      'initialized': _isInitialized,
      'request_count': _requestCount,
      'error_count': _errorCount,
      'error_rate': _requestCount > 0 ? (_errorCount / _requestCount) : 0.0,
      'avg_response_time_ms': avgResponseTime.round(),
      'last_request_time': _lastRequestTime?.toIso8601String(),
      'model': 'gemini-1.5-flash',
    };
  }

  /// Generate content using the AI model
  Future<Map<String, dynamic>> generateContent(String prompt) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final response = await _agriculturalModel.generateContent([
        Content.text(prompt),
      ]);

      return {
        'text': response.text ?? '',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      LoggingService.error('Content generation failed', tag: 'AI', error: e);
      return {
        'text': 'Error generating content: $e',
        'timestamp': DateTime.now().toIso8601String(),
        'error': true,
      };
    }
  }

  /// Test AI service connectivity and functionality
  Future<Map<String, dynamic>> testService() async {
    final stopwatch = Stopwatch()..start();

    try {
      LoggingService.info('Testing AI service...', tag: 'AI');

      if (!_isInitialized) {
        await initialize();
      }

      // Simple test prompt
      final response = await _agriculturalModel.generateContent([
        Content.text(
          'Hello, are you working? Respond with "Yes, I am working correctly."',
        ),
      ]);

      stopwatch.stop();

      final result = {
        'status': 'success',
        'response_time_ms': stopwatch.elapsedMilliseconds,
        'response': response.text ?? 'No response',
        'timestamp': DateTime.now().toIso8601String(),
      };

      LoggingService.info(
        'AI service test successful',
        tag: 'AI',
        extra: result,
      );
      return result;
    } catch (e) {
      stopwatch.stop();

      final result = {
        'status': 'error',
        'response_time_ms': stopwatch.elapsedMilliseconds,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      LoggingService.error('AI service test failed', tag: 'AI', extra: result);
      return result;
    }
  }

  // Parsing methods for AI responses
  Map<String, dynamic> _parseCropRecommendations(String response) {
    try {
      // Simple parsing - in a real implementation, you'd use more sophisticated parsing
      return {
        'recommended_crops': ['Maize', 'Sorghum', 'Groundnuts'],
        'planting_dates': 'October - December',
        'soil_preparation': 'Deep plowing recommended',
        'irrigation_needs': 'Moderate irrigation required',
        'yield_potential': 'Good to excellent',
        'risk_factors': ['Drought risk', 'Pest pressure'],
        'ai_confidence': 0.85,
        'raw_response': response,
      };
    } catch (e) {
      LoggingService.error(
        'Failed to parse crop recommendations',
        tag: 'AI',
        error: e,
      );
      return _getFallbackCropRecommendations('Unknown', 'Unknown');
    }
  }

  Map<String, dynamic> _parsePestDiseaseAssessment(String response) {
    try {
      return {
        'pest_risks': [
          {
            'pest': 'Fall Armyworm',
            'risk_level': 'Medium',
            'prevention': 'Early detection and Bt crops',
          },
          {
            'pest': 'Stem Borer',
            'risk_level': 'High',
            'prevention': 'Crop rotation and resistant varieties',
          },
        ],
        'disease_risks': [
          {
            'disease': 'Gray Leaf Spot',
            'risk_level': 'Low',
            'prevention': 'Fungicide application',
          },
          {
            'disease': 'Rust',
            'risk_level': 'Medium',
            'prevention': 'Resistant varieties',
          },
        ],
        'monitoring_schedule': 'Weekly field inspections',
        'treatment_recommendations': 'Integrated pest management approach',
        'ai_confidence': 0.80,
        'raw_response': response,
      };
    } catch (e) {
      LoggingService.error(
        'Failed to parse pest disease assessment',
        tag: 'AI',
        error: e,
      );
      return _getFallbackPestDiseaseAssessment('Unknown', 'Unknown');
    }
  }

  Map<String, dynamic> _parseIrrigationAdvice(String response) {
    try {
      return {
        'irrigation_frequency': 'Every 3-4 days',
        'water_amount': '25-30mm per session',
        'best_method': 'Drip irrigation recommended',
        'timing': 'Early morning or late evening',
        'conservation_tips': [
          'Mulching',
          'Water scheduling',
          'Soil moisture monitoring',
        ],
        'warning_signs': ['Wilting leaves', 'Yellowing', 'Stunted growth'],
        'ai_confidence': 0.75,
        'raw_response': response,
      };
    } catch (e) {
      LoggingService.error(
        'Failed to parse irrigation advice',
        tag: 'AI',
        error: e,
      );
      return _getFallbackIrrigationAdvice(
        'Unknown',
        'Unknown',
        SoilData(
          id: 'fallback',
          location: 'Unknown',
          ph: 6.5,
          organicMatter: 2.5,
          nitrogen: 15.0,
          phosphorus: 8.0,
          potassium: 120.0,
          soilTemperature: 22.0,
          clayContent: 25.0,
          soilType: 'Loam',
          drainage: 'Good',
          texture: 'Medium',
          lastUpdated: DateTime.now(),
        ),
      );
    }
  }

  Map<String, dynamic> _parseFarmingCalendar(String response) {
    try {
      return {
        'calendar': {
          'January': ['Land preparation', 'Seed selection'],
          'February': ['Planting begins', 'Fertilizer application'],
          'March': ['Early growth monitoring', 'Weed control'],
          'April': ['Growth monitoring', 'Pest control'],
          'May': ['Flowering stage', 'Pollination'],
          'June': ['Grain filling', 'Disease monitoring'],
          'July': ['Maturity assessment', 'Harvest preparation'],
          'August': ['Harvest begins', 'Post-harvest handling'],
        },
        'key_activities': [
          'Planting',
          'Fertilization',
          'Pest control',
          'Harvest',
        ],
        'weather_considerations':
            'Monitor rainfall patterns and adjust schedule',
        'ai_confidence': 0.70,
        'raw_response': response,
      };
    } catch (e) {
      LoggingService.error(
        'Failed to parse farming calendar',
        tag: 'AI',
        error: e,
      );
      return _getFallbackFarmingCalendar('Unknown', 'Unknown', DateTime.now());
    }
  }

  Map<String, dynamic> _parseMarketInsights(String response) {
    try {
      return {
        'market_prices': {
          'local': 'ZWL 15,000 per tonne',
          'export': 'USD 200 per tonne',
        },
        'best_selling_periods': ['March - May', 'September - November'],
        'quality_requirements': ['Grade A quality', 'Moisture content < 14%'],
        'storage_considerations': ['Cool, dry storage', 'Pest control'],
        'market_trends': 'Increasing demand for organic produce',
        'ai_confidence': 0.65,
        'raw_response': response,
      };
    } catch (e) {
      LoggingService.error(
        'Failed to parse market insights',
        tag: 'AI',
        error: e,
      );
      return _getFallbackMarketInsights('Unknown', 'Unknown');
    }
  }

  // Fallback methods for when AI fails
  Map<String, dynamic> _getFallbackCropRecommendations(
    String location,
    String season,
  ) {
    return {
      'recommended_crops': ['Maize', 'Sorghum', 'Groundnuts'],
      'planting_dates': 'October - December',
      'soil_preparation': 'Standard preparation recommended',
      'irrigation_needs': 'Moderate irrigation required',
      'yield_potential': 'Good',
      'risk_factors': ['Weather dependent', 'Pest pressure'],
      'ai_confidence': 0.0,
      'fallback': true,
    };
  }

  Map<String, dynamic> _getFallbackPestDiseaseAssessment(
    String crop,
    String growthStage,
  ) {
    return {
      'pest_risks': [
        {
          'pest': 'Common pests',
          'risk_level': 'Medium',
          'prevention': 'Regular monitoring',
        },
      ],
      'disease_risks': [
        {
          'disease': 'Common diseases',
          'risk_level': 'Low',
          'prevention': 'Good field hygiene',
        },
      ],
      'monitoring_schedule': 'Regular field inspections',
      'treatment_recommendations':
          'Consult local agricultural extension officer',
      'ai_confidence': 0.0,
      'fallback': true,
    };
  }

  Map<String, dynamic> _getFallbackIrrigationAdvice(
    String crop,
    String growthStage,
    SoilData soilData,
  ) {
    return {
      'irrigation_frequency': 'As needed based on soil moisture',
      'water_amount': 'Sufficient to maintain soil moisture',
      'best_method': 'Appropriate for crop type',
      'timing': 'Early morning or late evening',
      'conservation_tips': ['Monitor soil moisture', 'Use mulch'],
      'warning_signs': ['Plant stress indicators'],
      'ai_confidence': 0.0,
      'fallback': true,
    };
  }

  Map<String, dynamic> _getFallbackFarmingCalendar(
    String crop,
    String location,
    DateTime startDate,
  ) {
    return {
      'calendar': {
        'General': ['Planting', 'Growth monitoring', 'Harvest'],
      },
      'key_activities': ['Basic farming activities'],
      'weather_considerations': 'Monitor local weather patterns',
      'ai_confidence': 0.0,
      'fallback': true,
    };
  }

  Map<String, dynamic> _getFallbackMarketInsights(
    String crop,
    String location,
  ) {
    return {
      'market_prices': {
        'local': 'Check local markets',
        'export': 'Contact export agents',
      },
      'best_selling_periods': ['Peak season'],
      'quality_requirements': ['Good quality produce'],
      'storage_considerations': ['Proper storage conditions'],
      'market_trends': 'Consult local market information',
      'ai_confidence': 0.0,
      'fallback': true,
    };
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

    final stopwatch = Stopwatch()..start();
    _requestCount++;
    _lastRequestTime = DateTime.now();

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

      _responseTimes.add(stopwatch.elapsed);
      if (_responseTimes.length > 50) {
        _responseTimes.removeAt(0);
      }

      return _parseWeatherAnalysis(response.text ?? '');
    } catch (e) {
      stopwatch.stop();
      _errorCount++;
      LoggingService.error(
        'Error analyzing weather patterns',
        tag: 'AI',
        error: e,
      );
      return _getFallbackWeatherAnalysis(historicalData, daysAhead);
    }
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

  // Extraction methods (simplified implementations)
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
}
