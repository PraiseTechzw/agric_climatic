import 'dart:math';
import '../models/weather.dart';
import '../models/dashboard_data.dart';
import 'logging_service.dart';

class ClimateDashboardService {
  final Random _random = Random();

  // Generate comprehensive mock weather data for Zimbabwe
  Future<List<Weather>> getHistoricalWeatherData({
    required String location,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final weatherData = <Weather>[];
      final daysDifference = endDate.difference(startDate).inDays;
      
      // Zimbabwe climate characteristics by location
      final locationData = _getLocationClimateData(location);
      
      for (int i = 0; i <= daysDifference; i++) {
        final currentDate = startDate.add(Duration(days: i));
        final weather = _generateRealisticWeatherData(
          location: location,
          date: currentDate,
          locationData: locationData,
        );
        weatherData.add(weather);
      }
      
      LoggingService.info('Generated ${weatherData.length} weather data points for $location');
      return weatherData;
    } catch (e) {
      LoggingService.error('Failed to generate historical weather data', error: e);
      return [];
    }
  }

  // Get climate summary for the past 3-5 years
  Future<ClimateSummary> getClimateSummary({
    required String location,
    int yearsBack = 5,
  }) async {
    try {
      final endDate = DateTime.now();
      final startDate = DateTime(endDate.year - yearsBack, 1, 1);
      
      final weatherData = await getHistoricalWeatherData(
        location: location,
        startDate: startDate,
        endDate: endDate,
      );

      if (weatherData.isEmpty) {
        return ClimateSummary(
          location: location,
          startDate: startDate,
          endDate: endDate,
          overallAverageTemperature: 0.0,
          totalPrecipitation: 0.0,
          overallAverageHumidity: 0.0,
          totalRainyDays: 0,
          highestTemperature: 0.0,
          lowestTemperature: 0.0,
          monthlyAverages: {},
          yearlyTrends: {},
          climateAnomalies: [],
          climateSummary: 'No data available for the selected period.',
        );
      }

      // Calculate overall statistics
      final temperatures = weatherData.map((w) => w.temperature).toList();
      final precipitations = weatherData.map((w) => w.precipitation).toList();
      final humidities = weatherData.map((w) => w.humidity).toList();

      final overallAverageTemperature = temperatures.reduce((a, b) => a + b) / temperatures.length;
      final totalPrecipitation = precipitations.reduce((a, b) => a + b);
      final overallAverageHumidity = humidities.reduce((a, b) => a + b) / humidities.length;
      final totalRainyDays = weatherData.where((w) => w.precipitation > 0).length;
      final highestTemperature = temperatures.reduce((a, b) => a > b ? a : b);
      final lowestTemperature = temperatures.reduce((a, b) => a < b ? a : b);

      // Calculate monthly averages
      final monthlyAverages = _calculateMonthlyAverages(weatherData);

      // Calculate yearly trends
      final yearlyTrends = _calculateYearlyTrends(weatherData);

      // Detect climate anomalies
      final climateAnomalies = _detectClimateAnomalies(weatherData);

      // Generate climate summary
      final climateSummary = _generateClimateSummary(
        overallAverageTemperature,
        totalPrecipitation,
        overallAverageHumidity,
        totalRainyDays,
        climateAnomalies,
      );

      return ClimateSummary(
        location: location,
        startDate: startDate,
        endDate: endDate,
        overallAverageTemperature: overallAverageTemperature,
        totalPrecipitation: totalPrecipitation,
        overallAverageHumidity: overallAverageHumidity,
        totalRainyDays: totalRainyDays,
        highestTemperature: highestTemperature,
        lowestTemperature: lowestTemperature,
        monthlyAverages: monthlyAverages,
        yearlyTrends: yearlyTrends,
        climateAnomalies: climateAnomalies,
        climateSummary: climateSummary,
      );
    } catch (e) {
      LoggingService.error('Failed to generate climate summary', error: e);
      return ClimateSummary(
        location: location,
        startDate: DateTime.now().subtract(Duration(days: 365 * yearsBack)),
        endDate: DateTime.now(),
        overallAverageTemperature: 0.0,
        totalPrecipitation: 0.0,
        overallAverageHumidity: 0.0,
        totalRainyDays: 0,
        highestTemperature: 0.0,
        lowestTemperature: 0.0,
        monthlyAverages: {},
        yearlyTrends: {},
        climateAnomalies: [],
        climateSummary: 'Error generating climate summary.',
      );
    }
  }

  // Get yearly climate data for charts
  Future<List<ClimateDashboardData>> getYearlyClimateData({
    required String location,
    int yearsBack = 5,
  }) async {
    try {
      final endDate = DateTime.now();
      final startDate = DateTime(endDate.year - yearsBack, 1, 1);
      
      final weatherData = await getHistoricalWeatherData(
        location: location,
        startDate: startDate,
        endDate: endDate,
      );

      if (weatherData.isEmpty) return [];

      // Group data by year
      final yearlyData = <int, List<Weather>>{};
      for (final weather in weatherData) {
        final year = weather.dateTime.year;
        yearlyData[year] ??= [];
        yearlyData[year]!.add(weather);
      }

      final result = <ClimateDashboardData>[];
      for (final entry in yearlyData.entries) {
        final year = entry.key;
        final yearData = entry.value;

        final temperatures = yearData.map((w) => w.temperature).toList();
        final precipitations = yearData.map((w) => w.precipitation).toList();
        final humidities = yearData.map((w) => w.humidity).toList();
        final windSpeeds = yearData.map((w) => w.windSpeed).toList();

        final averageTemperature = temperatures.reduce((a, b) => a + b) / temperatures.length;
        final totalPrecipitation = precipitations.reduce((a, b) => a + b);
        final averageHumidity = humidities.reduce((a, b) => a + b) / humidities.length;
        final averageWindSpeed = windSpeeds.reduce((a, b) => a + b) / windSpeeds.length;
        final rainyDays = yearData.where((w) => w.precipitation > 0).length;
        final maxTemperature = temperatures.reduce((a, b) => a > b ? a : b);
        final minTemperature = temperatures.reduce((a, b) => a < b ? a : b);

        // Calculate trends (simplified)
        final trends = <String, double>{
          'temperature_trend': _calculateTrend(temperatures),
          'precipitation_trend': _calculateTrend(precipitations),
          'humidity_trend': _calculateTrend(humidities),
        };

        // Detect anomalies
        final anomalies = _detectAnomalies(yearData);

        result.add(ClimateDashboardData(
          id: '${location}_$year',
          location: location,
          date: DateTime(year),
          averageTemperature: averageTemperature,
          totalPrecipitation: totalPrecipitation,
          averageHumidity: averageHumidity,
          averageWindSpeed: averageWindSpeed,
          rainyDays: rainyDays,
          maxTemperature: maxTemperature,
          minTemperature: minTemperature,
          trends: trends,
          anomalies: anomalies,
          period: 'yearly',
        ));
      }

      return result..sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      LoggingService.error('Failed to get yearly climate data', error: e);
      return [];
    }
  }

  // Get monthly climate data for charts
  Future<List<ClimateDashboardData>> getMonthlyClimateData({
    required String location,
    required int year,
  }) async {
    try {
      final startDate = DateTime(year, 1, 1);
      final endDate = DateTime(year, 12, 31);
      
      final weatherData = await getHistoricalWeatherData(
        location: location,
        startDate: startDate,
        endDate: endDate,
      );

      if (weatherData.isEmpty) return [];

      // Group data by month
      final monthlyData = <int, List<Weather>>{};
      for (final weather in weatherData) {
        final month = weather.dateTime.month;
        monthlyData[month] ??= [];
        monthlyData[month]!.add(weather);
      }

      final result = <ClimateDashboardData>[];
      for (final entry in monthlyData.entries) {
        final month = entry.key;
        final monthData = entry.value;

        final temperatures = monthData.map((w) => w.temperature).toList();
        final precipitations = monthData.map((w) => w.precipitation).toList();
        final humidities = monthData.map((w) => w.humidity).toList();
        final windSpeeds = monthData.map((w) => w.windSpeed).toList();

        final averageTemperature = temperatures.reduce((a, b) => a + b) / temperatures.length;
        final totalPrecipitation = precipitations.reduce((a, b) => a + b);
        final averageHumidity = humidities.reduce((a, b) => a + b) / humidities.length;
        final averageWindSpeed = windSpeeds.reduce((a, b) => a + b) / windSpeeds.length;
        final rainyDays = monthData.where((w) => w.precipitation > 0).length;
        final maxTemperature = temperatures.reduce((a, b) => a > b ? a : b);
        final minTemperature = temperatures.reduce((a, b) => a < b ? a : b);

        // Calculate trends
        final trends = <String, double>{
          'temperature_trend': _calculateTrend(temperatures),
          'precipitation_trend': _calculateTrend(precipitations),
          'humidity_trend': _calculateTrend(humidities),
        };

        // Detect anomalies
        final anomalies = _detectAnomalies(monthData);

        result.add(ClimateDashboardData(
          id: '${location}_${year}_$month',
          location: location,
          date: DateTime(year, month),
          averageTemperature: averageTemperature,
          totalPrecipitation: totalPrecipitation,
          averageHumidity: averageHumidity,
          averageWindSpeed: averageWindSpeed,
          rainyDays: rainyDays,
          maxTemperature: maxTemperature,
          minTemperature: minTemperature,
          trends: trends,
          anomalies: anomalies,
          period: 'monthly',
        ));
      }

      return result..sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      LoggingService.error('Failed to get monthly climate data', error: e);
      return [];
    }
  }

  // Get chart data points for specific metrics
  Future<List<ChartDataPoint>> getChartData({
    required String location,
    required DateTime startDate,
    required DateTime endDate,
    required String metric, // 'temperature', 'precipitation', 'humidity', 'wind'
    required String period, // 'yearly', 'monthly', 'daily'
  }) async {
    try {
      final weatherData = await getHistoricalWeatherData(
        location: location,
        startDate: startDate,
        endDate: endDate,
      );

      if (weatherData.isEmpty) return [];

      final result = <ChartDataPoint>[];
      
      if (period == 'yearly') {
        final yearlyData = <int, List<Weather>>{};
        for (final weather in weatherData) {
          final year = weather.dateTime.year;
          yearlyData[year] ??= [];
          yearlyData[year]!.add(weather);
        }

        for (final entry in yearlyData.entries) {
          final year = entry.key;
          final yearData = entry.value;
          final value = _getMetricValue(yearData, metric);
          
          result.add(ChartDataPoint(
            label: year.toString(),
            value: value,
            date: DateTime(year),
            metadata: {'year': year, 'dataPoints': yearData.length},
          ));
        }
      } else if (period == 'monthly') {
        final monthlyData = <String, List<Weather>>{};
        for (final weather in weatherData) {
          final key = '${weather.dateTime.year}-${weather.dateTime.month.toString().padLeft(2, '0')}';
          monthlyData[key] ??= [];
          monthlyData[key]!.add(weather);
        }

        for (final entry in monthlyData.entries) {
          final monthData = entry.value;
          final value = _getMetricValue(monthData, metric);
          final date = monthData.first.dateTime;
          
          result.add(ChartDataPoint(
            label: '${date.year}-${date.month.toString().padLeft(2, '0')}',
            value: value,
            date: DateTime(date.year, date.month),
            metadata: {'month': date.month, 'year': date.year, 'dataPoints': monthData.length},
          ));
        }
      }

      return result..sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      LoggingService.error('Failed to get chart data', error: e);
      return [];
    }
  }

  // Helper methods
  Map<String, double> _calculateMonthlyAverages(List<Weather> weatherData) {
    final monthlyAverages = <String, double>{};
    final monthlyData = <int, List<Weather>>{};

    for (final weather in weatherData) {
      final month = weather.dateTime.month;
      monthlyData[month] ??= [];
      monthlyData[month]!.add(weather);
    }

    for (final entry in monthlyData.entries) {
      final month = entry.key;
      final monthData = entry.value;
      final avgTemp = monthData.map((w) => w.temperature).reduce((a, b) => a + b) / monthData.length;
      monthlyAverages[_getMonthName(month)] = avgTemp;
    }

    return monthlyAverages;
  }

  Map<String, double> _calculateYearlyTrends(List<Weather> weatherData) {
    final yearlyTrends = <String, double>{};
    final yearlyData = <int, List<Weather>>{};

    for (final weather in weatherData) {
      final year = weather.dateTime.year;
      yearlyData[year] ??= [];
      yearlyData[year]!.add(weather);
    }

    final years = yearlyData.keys.toList()..sort();
    if (years.length < 2) return yearlyTrends;

    // Calculate temperature trend
    final temperatures = years.map((year) {
      final yearData = yearlyData[year]!;
      return yearData.map((w) => w.temperature).reduce((a, b) => a + b) / yearData.length;
    }).toList();
    yearlyTrends['temperature_trend'] = _calculateTrend(temperatures);

    // Calculate precipitation trend
    final precipitations = years.map((year) {
      final yearData = yearlyData[year]!;
      return yearData.map((w) => w.precipitation).reduce((a, b) => a + b);
    }).toList();
    yearlyTrends['precipitation_trend'] = _calculateTrend(precipitations);

    return yearlyTrends;
  }

  List<String> _detectClimateAnomalies(List<Weather> weatherData) {
    final anomalies = <String>[];
    if (weatherData.isEmpty) return anomalies;

    final temperatures = weatherData.map((w) => w.temperature).toList();
    final precipitations = weatherData.map((w) => w.precipitation).toList();
    final humidities = weatherData.map((w) => w.humidity).toList();

    final avgTemp = temperatures.reduce((a, b) => a + b) / temperatures.length;
    final avgPrecip = precipitations.reduce((a, b) => a + b) / precipitations.length;
    final avgHumidity = humidities.reduce((a, b) => a + b) / humidities.length;

    final maxTemp = temperatures.reduce((a, b) => a > b ? a : b);
    final minTemp = temperatures.reduce((a, b) => a < b ? a : b);
    final maxPrecip = precipitations.reduce((a, b) => a > b ? a : b);

    if (maxTemp > avgTemp + 10) anomalies.add('Extreme high temperature');
    if (minTemp < avgTemp - 10) anomalies.add('Extreme low temperature');
    if (maxPrecip > avgPrecip * 3) anomalies.add('Heavy rainfall event');
    if (avgHumidity > 85) anomalies.add('High humidity period');
    if (avgHumidity < 30) anomalies.add('Low humidity period');

    return anomalies;
  }

  String _generateClimateSummary(
    double avgTemp,
    double totalPrecip,
    double avgHumidity,
    int rainyDays,
    List<String> anomalies,
  ) {
    final tempDesc = avgTemp > 25 ? 'warm' : avgTemp < 15 ? 'cool' : 'moderate';
    final precipDesc = totalPrecip > 1000 ? 'wet' : totalPrecip < 500 ? 'dry' : 'moderate';
    
    String summary = 'The climate is generally $tempDesc and $precipDesc with an average temperature of ${avgTemp.toStringAsFixed(1)}°C. ';
    summary += 'Total precipitation: ${totalPrecip.toStringAsFixed(1)}mm over $rainyDays rainy days. ';
    summary += 'Average humidity: ${avgHumidity.toStringAsFixed(1)}%. ';
    
    if (anomalies.isNotEmpty) {
      summary += 'Notable anomalies: ${anomalies.join(', ')}.';
    }

    return summary;
  }

  double _calculateTrend(List<double> values) {
    if (values.length < 2) return 0.0;
    
    final n = values.length;
    final x = List.generate(n, (i) => i.toDouble());
    
    final sumX = x.reduce((a, b) => a + b);
    final sumY = values.reduce((a, b) => a + b);
    final sumXY = x.asMap().entries.map((e) => e.key * values[e.key]).reduce((a, b) => a + b);
    final sumXX = x.map((x) => x * x).reduce((a, b) => a + b);
    
    final slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
    return slope;
  }

  List<String> _detectAnomalies(List<Weather> data) {
    final anomalies = <String>[];
    if (data.isEmpty) return anomalies;

    final temps = data.map((w) => w.temperature).toList();
    final avgTemp = temps.reduce((a, b) => a + b) / temps.length;
    final maxTemp = temps.reduce((a, b) => a > b ? a : b);
    final minTemp = temps.reduce((a, b) => a < b ? a : b);

    if (maxTemp > avgTemp + 8) anomalies.add('High temperature spike');
    if (minTemp < avgTemp - 8) anomalies.add('Low temperature drop');

    return anomalies;
  }

  double _getMetricValue(List<Weather> data, String metric) {
    switch (metric) {
      case 'temperature':
        final temps = data.map((w) => w.temperature).toList();
        return temps.reduce((a, b) => a + b) / temps.length;
      case 'precipitation':
        return data.map((w) => w.precipitation).reduce((a, b) => a + b);
      case 'humidity':
        final humidities = data.map((w) => w.humidity).toList();
        return humidities.reduce((a, b) => a + b) / humidities.length;
      case 'wind':
        final windSpeeds = data.map((w) => w.windSpeed).toList();
        return windSpeeds.reduce((a, b) => a + b) / windSpeeds.length;
      default:
        return 0.0;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  // Zimbabwe location-specific climate data
  Map<String, dynamic> _getLocationClimateData(String location) {
    switch (location.toLowerCase()) {
      case 'harare':
        return {
          'baseTemp': 22.0,
          'tempRange': 8.0,
          'baseHumidity': 65.0,
          'humidityRange': 25.0,
          'basePrecipitation': 850.0, // mm/year
          'elevation': 1483, // meters
          'climate': 'subtropical_highland',
        };
      case 'bulawayo':
        return {
          'baseTemp': 20.0,
          'tempRange': 10.0,
          'baseHumidity': 55.0,
          'humidityRange': 30.0,
          'basePrecipitation': 600.0,
          'elevation': 1355,
          'climate': 'subtropical',
        };
      case 'gweru':
        return {
          'baseTemp': 21.0,
          'tempRange': 9.0,
          'baseHumidity': 60.0,
          'humidityRange': 28.0,
          'basePrecipitation': 750.0,
          'elevation': 1420,
          'climate': 'subtropical',
        };
      case 'mutare':
        return {
          'baseTemp': 23.0,
          'tempRange': 7.0,
          'baseHumidity': 70.0,
          'humidityRange': 20.0,
          'basePrecipitation': 1000.0,
          'elevation': 1120,
          'climate': 'subtropical',
        };
      case 'kwekwe':
        return {
          'baseTemp': 22.5,
          'tempRange': 8.5,
          'baseHumidity': 62.0,
          'humidityRange': 26.0,
          'basePrecipitation': 800.0,
          'elevation': 1200,
          'climate': 'subtropical',
        };
      default:
        return {
          'baseTemp': 22.0,
          'tempRange': 8.0,
          'baseHumidity': 65.0,
          'humidityRange': 25.0,
          'basePrecipitation': 850.0,
          'elevation': 1400,
          'climate': 'subtropical',
        };
    }
  }

  // Generate realistic weather data for a specific date
  Weather _generateRealisticWeatherData({
    required String location,
    required DateTime date,
    required Map<String, dynamic> locationData,
  }) {
    final month = date.month;
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    
    // Seasonal variations for Zimbabwe
    final seasonalData = _getSeasonalVariations(month, locationData);
    
    // Generate realistic temperature
    final baseTemp = seasonalData['baseTemp'] as double;
    final tempVariation = (sin(dayOfYear * 2 * pi / 365) * 3) + 
                         (_random.nextDouble() - 0.5) * 4;
    final temperature = (baseTemp + tempVariation).clamp(5.0, 40.0);
    
    // Generate realistic humidity
    final baseHumidity = seasonalData['baseHumidity'] as double;
    final humidityVariation = (cos(dayOfYear * 2 * pi / 365) * 10) + 
                             (_random.nextDouble() - 0.5) * 15;
    final humidity = (baseHumidity + humidityVariation).clamp(20.0, 95.0);
    
    // Generate realistic precipitation
    final precipitation = _generatePrecipitation(month, locationData);
    
    // Generate wind speed
    final windSpeed = 5.0 + (_random.nextDouble() * 15.0);
    
    // Generate pressure
    final pressure = 1013.25 + (_random.nextDouble() - 0.5) * 20.0;
    
    // Generate weather condition
    final condition = _getWeatherCondition(precipitation, temperature, humidity);
    
    return Weather(
      id: '${location}_${date.millisecondsSinceEpoch}',
      dateTime: date,
      temperature: temperature,
      humidity: humidity,
      windSpeed: windSpeed,
      condition: condition['condition'] as String,
      description: condition['description'] as String,
      icon: condition['icon'] as String,
      pressure: pressure,
      precipitation: precipitation,
      visibility: 10.0 + (_random.nextDouble() * 5.0),
      uvIndex: _getUVIndex(month, temperature),
      feelsLike: temperature + (_random.nextDouble() - 0.5) * 3.0,
      dewPoint: temperature - (_random.nextDouble() * 5.0),
      windGust: windSpeed + (_random.nextDouble() * 10.0),
      windDegree: (_random.nextDouble() * 360).round(),
      windDirection: _getWindDirection(),
      cloudCover: _getCloudCover(precipitation, humidity),
    );
  }

  // Seasonal variations for Zimbabwe climate
  Map<String, dynamic> _getSeasonalVariations(int month, Map<String, dynamic> locationData) {
    final baseTemp = locationData['baseTemp'] as double;
    final baseHumidity = locationData['baseHumidity'] as double;
    
    // Zimbabwe seasons: Summer (Dec-Feb), Autumn (Mar-May), Winter (Jun-Aug), Spring (Sep-Nov)
    double tempAdjustment = 0.0;
    double humidityAdjustment = 0.0;
    
    if (month >= 12 || month <= 2) {
      // Summer - hot and wet
      tempAdjustment = 3.0;
      humidityAdjustment = 10.0;
    } else if (month >= 3 && month <= 5) {
      // Autumn - cooling down
      tempAdjustment = -1.0;
      humidityAdjustment = 5.0;
    } else if (month >= 6 && month <= 8) {
      // Winter - cool and dry
      tempAdjustment = -4.0;
      humidityAdjustment = -15.0;
    } else {
      // Spring - warming up
      tempAdjustment = 1.0;
      humidityAdjustment = 0.0;
    }
    
    return {
      'baseTemp': baseTemp + tempAdjustment,
      'baseHumidity': baseHumidity + humidityAdjustment,
    };
  }

  // Generate realistic precipitation based on Zimbabwe rainfall patterns
  double _generatePrecipitation(int month, Map<String, dynamic> locationData) {
    final basePrecipitation = locationData['basePrecipitation'] as double;
    
    // Zimbabwe rainfall pattern: Wet season Nov-Mar, Dry season Apr-Oct
    double monthlyFactor = 0.0;
    
    if (month >= 11 || month <= 3) {
      // Wet season - higher chance of rain
      monthlyFactor = 0.8 + (_random.nextDouble() * 0.4);
    } else {
      // Dry season - lower chance of rain
      monthlyFactor = 0.1 + (_random.nextDouble() * 0.3);
    }
    
    // Daily precipitation calculation
    final dailyPrecipitation = (basePrecipitation / 365) * monthlyFactor;
    
    // Add some randomness
    final randomFactor = _random.nextDouble();
    if (randomFactor < 0.3) {
      // 30% chance of no rain
      return 0.0;
    } else if (randomFactor < 0.7) {
      // 40% chance of light rain
      return dailyPrecipitation * (0.5 + _random.nextDouble() * 0.5);
    } else {
      // 30% chance of heavy rain
      return dailyPrecipitation * (1.0 + _random.nextDouble() * 2.0);
    }
  }

  // Get weather condition based on precipitation, temperature, and humidity
  Map<String, String> _getWeatherCondition(double precipitation, double temperature, double humidity) {
    if (precipitation > 5.0) {
      return {
        'condition': 'Rain',
        'description': 'Heavy rain',
        'icon': '10d',
      };
    } else if (precipitation > 1.0) {
      return {
        'condition': 'Drizzle',
        'description': 'Light rain',
        'icon': '09d',
      };
    } else if (humidity > 80) {
      return {
        'condition': 'Mist',
        'description': 'Misty conditions',
        'icon': '50d',
      };
    } else if (temperature > 30) {
      return {
        'condition': 'Clear',
        'description': 'Hot and sunny',
        'icon': '01d',
      };
    } else if (temperature < 15) {
      return {
        'condition': 'Clouds',
        'description': 'Cool and cloudy',
        'icon': '04d',
      };
    } else {
      return {
        'condition': 'Clear',
        'description': 'Clear sky',
        'icon': '01d',
      };
    }
  }

  // Get UV index based on month and temperature
  double _getUVIndex(int month, double temperature) {
    // Higher UV in summer months and higher temperatures
    double baseUV = 5.0;
    
    if (month >= 11 || month <= 2) {
      baseUV = 8.0; // Summer
    } else if (month >= 3 && month <= 5) {
      baseUV = 6.0; // Autumn
    } else if (month >= 6 && month <= 8) {
      baseUV = 4.0; // Winter
    } else {
      baseUV = 7.0; // Spring
    }
    
    // Adjust based on temperature
    if (temperature > 30) {
      baseUV += 2.0;
    } else if (temperature < 15) {
      baseUV -= 1.0;
    }
    
    return baseUV.clamp(0.0, 11.0);
  }

  // Get wind direction
  String _getWindDirection() {
    final directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return directions[_random.nextInt(directions.length)];
  }

  // Get cloud cover based on precipitation and humidity
  double _getCloudCover(double precipitation, double humidity) {
    double cloudCover = 20.0;
    
    if (precipitation > 0) {
      cloudCover = 80.0 + (_random.nextDouble() * 20.0);
    } else if (humidity > 70) {
      cloudCover = 40.0 + (_random.nextDouble() * 30.0);
    } else {
      cloudCover = 10.0 + (_random.nextDouble() * 20.0);
    }
    
    return cloudCover.clamp(0.0, 100.0);
  }
}
