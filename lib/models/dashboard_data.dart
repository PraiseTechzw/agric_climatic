class ClimateDashboardData {
  final String id;
  final String location;
  final DateTime date;
  final double averageTemperature;
  final double totalPrecipitation;
  final double averageHumidity;
  final double averageWindSpeed;
  final int rainyDays;
  final double maxTemperature;
  final double minTemperature;
  final Map<String, dynamic> trends;
  final List<String> anomalies;
  final String period; // 'yearly', 'monthly', 'daily'

  ClimateDashboardData({
    required this.id,
    required this.location,
    required this.date,
    required this.averageTemperature,
    required this.totalPrecipitation,
    required this.averageHumidity,
    required this.averageWindSpeed,
    required this.rainyDays,
    required this.maxTemperature,
    required this.minTemperature,
    required this.trends,
    required this.anomalies,
    required this.period,
  });

  factory ClimateDashboardData.fromJson(Map<String, dynamic> json) {
    return ClimateDashboardData(
      id: json['id'] ?? '',
      location: json['location'] ?? '',
      date: DateTime.parse(json['date']),
      averageTemperature: (json['averageTemperature'] ?? 0.0).toDouble(),
      totalPrecipitation: (json['totalPrecipitation'] ?? 0.0).toDouble(),
      averageHumidity: (json['averageHumidity'] ?? 0.0).toDouble(),
      averageWindSpeed: (json['averageWindSpeed'] ?? 0.0).toDouble(),
      rainyDays: json['rainyDays'] ?? 0,
      maxTemperature: (json['maxTemperature'] ?? 0.0).toDouble(),
      minTemperature: (json['minTemperature'] ?? 0.0).toDouble(),
      trends: Map<String, dynamic>.from(json['trends'] ?? {}),
      anomalies: List<String>.from(json['anomalies'] ?? []),
      period: json['period'] ?? 'yearly',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location': location,
      'date': date.toIso8601String(),
      'averageTemperature': averageTemperature,
      'totalPrecipitation': totalPrecipitation,
      'averageHumidity': averageHumidity,
      'averageWindSpeed': averageWindSpeed,
      'rainyDays': rainyDays,
      'maxTemperature': maxTemperature,
      'minTemperature': minTemperature,
      'trends': trends,
      'anomalies': anomalies,
      'period': period,
    };
  }
}

class ClimateSummary {
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final double overallAverageTemperature;
  final double totalPrecipitation;
  final double overallAverageHumidity;
  final int totalRainyDays;
  final double highestTemperature;
  final double lowestTemperature;
  final Map<String, double> monthlyAverages;
  final Map<String, double> yearlyTrends;
  final List<String> climateAnomalies;
  final String climateSummary;

  ClimateSummary({
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.overallAverageTemperature,
    required this.totalPrecipitation,
    required this.overallAverageHumidity,
    required this.totalRainyDays,
    required this.highestTemperature,
    required this.lowestTemperature,
    required this.monthlyAverages,
    required this.yearlyTrends,
    required this.climateAnomalies,
    required this.climateSummary,
  });

  factory ClimateSummary.fromJson(Map<String, dynamic> json) {
    return ClimateSummary(
      location: json['location'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      overallAverageTemperature: (json['overallAverageTemperature'] ?? 0.0).toDouble(),
      totalPrecipitation: (json['totalPrecipitation'] ?? 0.0).toDouble(),
      overallAverageHumidity: (json['overallAverageHumidity'] ?? 0.0).toDouble(),
      totalRainyDays: json['totalRainyDays'] ?? 0,
      highestTemperature: (json['highestTemperature'] ?? 0.0).toDouble(),
      lowestTemperature: (json['lowestTemperature'] ?? 0.0).toDouble(),
      monthlyAverages: Map<String, double>.from(json['monthlyAverages'] ?? {}),
      yearlyTrends: Map<String, double>.from(json['yearlyTrends'] ?? {}),
      climateAnomalies: List<String>.from(json['climateAnomalies'] ?? []),
      climateSummary: json['climateSummary'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': location,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'overallAverageTemperature': overallAverageTemperature,
      'totalPrecipitation': totalPrecipitation,
      'overallAverageHumidity': overallAverageHumidity,
      'totalRainyDays': totalRainyDays,
      'highestTemperature': highestTemperature,
      'lowestTemperature': lowestTemperature,
      'monthlyAverages': monthlyAverages,
      'yearlyTrends': yearlyTrends,
      'climateAnomalies': climateAnomalies,
      'climateSummary': climateSummary,
    };
  }
}

class ChartDataPoint {
  final String label;
  final double value;
  final DateTime date;
  final Map<String, dynamic> metadata;

  ChartDataPoint({
    required this.label,
    required this.value,
    required this.date,
    this.metadata = const {},
  });

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
    return ChartDataPoint(
      label: json['label'] ?? '',
      value: (json['value'] ?? 0.0).toDouble(),
      date: DateTime.parse(json['date']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
      'date': date.toIso8601String(),
      'metadata': metadata,
    };
  }
}

class DashboardFilter {
  final String location;
  final DateTime? startDate;
  final DateTime? endDate;
  final String period; // 'yearly', 'monthly', 'daily'
  final List<String> metrics; // ['temperature', 'precipitation', 'humidity', 'wind']
  final bool showAnomalies;
  final bool showTrends;

  DashboardFilter({
    required this.location,
    this.startDate,
    this.endDate,
    this.period = 'yearly',
    this.metrics = const ['temperature', 'precipitation', 'humidity'],
    this.showAnomalies = true,
    this.showTrends = true,
  });

  DashboardFilter copyWith({
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    String? period,
    List<String>? metrics,
    bool? showAnomalies,
    bool? showTrends,
  }) {
    return DashboardFilter(
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      period: period ?? this.period,
      metrics: metrics ?? this.metrics,
      showAnomalies: showAnomalies ?? this.showAnomalies,
      showTrends: showTrends ?? this.showTrends,
    );
  }
}
