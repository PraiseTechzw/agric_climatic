class SoilData {
  final String id;
  final String location;
  final double ph;
  final double organicMatter; // percentage
  final double nitrogen; // mg/kg
  final double phosphorus; // mg/kg
  final double potassium; // mg/kg
  final double soilMoisture; // percentage
  final double soilTemperature; // Celsius
  final String soilType;
  final String drainage;
  final String texture;
  final DateTime lastUpdated;

  SoilData({
    required this.id,
    required this.location,
    required this.ph,
    required this.organicMatter,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.soilMoisture,
    required this.soilTemperature,
    required this.soilType,
    required this.drainage,
    required this.texture,
    required this.lastUpdated,
  });

  factory SoilData.fromJson(Map<String, dynamic> json) {
    return SoilData(
      id: json['id'] ?? '',
      location: json['location'] ?? '',
      ph: (json['ph'] ?? 0.0).toDouble(),
      organicMatter: (json['organic_matter'] ?? 0.0).toDouble(),
      nitrogen: (json['nitrogen'] ?? 0.0).toDouble(),
      phosphorus: (json['phosphorus'] ?? 0.0).toDouble(),
      potassium: (json['potassium'] ?? 0.0).toDouble(),
      soilMoisture: (json['soil_moisture'] ?? 0.0).toDouble(),
      soilTemperature: (json['soil_temperature'] ?? 0.0).toDouble(),
      soilType: json['soil_type'] ?? '',
      drainage: json['drainage'] ?? '',
      texture: json['texture'] ?? '',
      lastUpdated: DateTime.parse(
        json['last_updated'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location': location,
      'ph': ph,
      'organic_matter': organicMatter,
      'nitrogen': nitrogen,
      'phosphorus': phosphorus,
      'potassium': potassium,
      'soil_moisture': soilMoisture,
      'soil_temperature': soilTemperature,
      'soil_type': soilType,
      'drainage': drainage,
      'texture': texture,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  // Get pH level description
  String get phDescription {
    if (ph < 5.5) return 'Very Acidic';
    if (ph < 6.5) return 'Acidic';
    if (ph < 7.5) return 'Neutral';
    if (ph < 8.5) return 'Alkaline';
    return 'Very Alkaline';
  }

  // Get pH color for UI
  String get phColor {
    if (ph < 5.5) return 'red';
    if (ph < 6.5) return 'orange';
    if (ph < 7.5) return 'green';
    if (ph < 8.5) return 'blue';
    return 'purple';
  }

  // Get soil moisture description
  String get moistureDescription {
    if (soilMoisture < 20) return 'Very Dry';
    if (soilMoisture < 40) return 'Dry';
    if (soilMoisture < 60) return 'Optimal';
    if (soilMoisture < 80) return 'Moist';
    return 'Wet';
  }

  // Get nutrient level descriptions
  String getNitrogenLevel() {
    if (nitrogen < 30) return 'Low';
    if (nitrogen < 60) return 'Medium';
    return 'High';
  }

  String getPhosphorusLevel() {
    if (phosphorus < 15) return 'Low';
    if (phosphorus < 40) return 'Medium';
    return 'High';
  }

  String getPotassiumLevel() {
    if (potassium < 150) return 'Low';
    if (potassium < 300) return 'Medium';
    return 'High';
  }

  // Get overall soil health
  String getSoilHealth() {
    final phScore = (ph >= 6.0 && ph <= 7.5) ? 1 : 0;
    final organicScore = organicMatter >= 3.0 ? 1 : 0;
    final nutrientScore =
        (nitrogen >= 50 ? 1 : 0) +
        (phosphorus >= 30 ? 1 : 0) +
        (potassium >= 200 ? 1 : 0);

    final totalScore = phScore + organicScore + (nutrientScore / 3);

    if (totalScore >= 2.5) return 'Excellent';
    if (totalScore >= 2.0) return 'Good';
    if (totalScore >= 1.5) return 'Fair';
    return 'Poor';
  }

  @override
  String toString() {
    return 'SoilData(id: $id, location: $location, ph: $ph, organicMatter: $organicMatter%)';
  }
}
