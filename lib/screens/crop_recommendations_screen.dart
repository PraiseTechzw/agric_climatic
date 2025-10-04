import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../models/soil_data.dart';
import '../services/soil_data_service.dart';
import '../services/agro_prediction_service.dart';

class CropRecommendationsScreen extends StatefulWidget {
  const CropRecommendationsScreen({super.key});

  @override
  State<CropRecommendationsScreen> createState() =>
      _CropRecommendationsScreenState();
}

class _CropRecommendationsScreenState extends State<CropRecommendationsScreen> {
  final SoilDataService _soilService = SoilDataService();
  final AgroPredictionService _predictionService = AgroPredictionService();
  SoilData? _soilData;
  bool _isLoading = false;
  String _selectedSeason = 'Current';
  String _selectedRegion = 'Harare';

  final List<String> _seasons = [
    'Current',
    'Spring',
    'Summer',
    'Autumn',
    'Winter',
  ];
  final List<String> _regions = [
    'Harare',
    'Bulawayo',
    'Gweru',
    'Mutare',
    'Kwekwe',
    'Chitungwiza',
  ];

  List<CropRecommendation> _cropRecommendations = [];

  @override
  void initState() {
    super.initState();
    _loadSoilData();
  }

  Future<void> _loadSoilData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final weatherProvider = context.read<WeatherProvider>();
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

      // Get crop recommendations based on soil data and weather
      final recommendations = await _getCropRecommendations(
        soilData,
        weatherProvider,
      );

      setState(() {
        _soilData = soilData;
        _cropRecommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading soil data and recommendations: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Recommendations'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : RefreshIndicator(
              onRefresh: _loadSoilData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with filters
                    _buildHeaderCard(),

                    const SizedBox(height: 20),

                    // Soil conditions summary
                    if (_soilData != null) ...[
                      _buildSoilConditionsCard(),
                      const SizedBox(height: 20),
                    ],

                    // Crop recommendations
                    _buildCropRecommendationsList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 4),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Analyzing Conditions...',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Getting personalized crop recommendations',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.agriculture,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Personalized Crop Recommendations',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildFilterChip('Season', _selectedSeason)),
                const SizedBox(width: 12),
                Expanded(child: _buildFilterChip('Region', _selectedRegion)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Based on current weather conditions and soil analysis',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoilConditionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.terrain, color: Colors.brown[600], size: 24),
                const SizedBox(width: 12),
                Text(
                  'Soil Conditions',
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
                  child: _buildSoilMetric(
                    'Temperature',
                    '${_soilData!.soilTemperature.toStringAsFixed(1)}°C',
                    Icons.thermostat,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSoilMetric(
                    'pH Level',
                    '${_soilData!.phLevel.toStringAsFixed(1)}',
                    Icons.science,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSoilMetric(
                    'Clay Content',
                    '${_soilData!.clayContent.toStringAsFixed(1)}%',
                    Icons.grain,
                    Colors.brown,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSoilMetric(
                    'Organic Matter',
                    '${_soilData!.organicMatter.toStringAsFixed(1)}%',
                    Icons.eco,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoilMetric(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
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
        ],
      ),
    );
  }

  Widget _buildCropRecommendationsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended Crops',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ..._cropRecommendations.map((crop) => _buildCropCard(crop)),
      ],
    );
  }

  Widget _buildCropCard(CropRecommendation crop) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showCropDetails(crop),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getSuitabilityColor(
                        crop.suitability,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.agriculture,
                      color: _getSuitabilityColor(crop.suitability),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          crop.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          crop.variety,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getSuitabilityColor(
                        crop.suitability,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getSuitabilityColor(
                          crop.suitability,
                        ).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '${crop.suitability}%',
                      style: TextStyle(
                        color: _getSuitabilityColor(crop.suitability),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                crop.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildCropInfo(
                      'Yield',
                      crop.yield,
                      Icons.trending_up,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCropInfo(
                      'Planting',
                      crop.plantingDate,
                      Icons.calendar_today,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildCropInfo(
                      'Harvest',
                      crop.harvestDate,
                      Icons.agriculture,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCropInfo(
                      'Requirements',
                      crop.requirements,
                      Icons.info,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCropInfo(
    String label,
    String value,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Color _getSuitabilityColor(int suitability) {
    if (suitability >= 80) return Colors.green;
    if (suitability >= 60) return Colors.orange;
    return Colors.red;
  }

  void _showCropDetails(CropRecommendation crop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getSuitabilityColor(
                        crop.suitability,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.agriculture,
                      color: _getSuitabilityColor(crop.suitability),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          crop.name,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          crop.variety,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Description',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                crop.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              Text(
                'Benefits',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...crop.benefits.map(
                (benefit) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Text(benefit),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Challenges',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...crop.challenges.map(
                (challenge) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Text(challenge),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Recommendations'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedSeason,
              decoration: const InputDecoration(labelText: 'Season'),
              items: _seasons.map((season) {
                return DropdownMenuItem(value: season, child: Text(season));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSeason = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRegion,
              decoration: const InputDecoration(labelText: 'Region'),
              items: _regions.map((region) {
                return DropdownMenuItem(value: region, child: Text(region));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRegion = value!;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadSoilData();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Future<List<CropRecommendation>> _getCropRecommendations(
    SoilData? soilData,
    WeatherProvider weatherProvider,
  ) async {
    try {
      if (soilData == null || weatherProvider.currentWeather == null) {
        return [];
      }

      // Get AI insights for crop recommendations
      final insights = await _predictionService.getAIInsights(
        location: _selectedRegion,
        currentWeather: weatherProvider.currentWeather!,
        soilData: soilData,
        crop: 'general',
        growthStage: 'planning',
      );

      // Parse crop recommendations from AI insights
      final recommendations =
          insights['crop_recommendations'] as Map<String, dynamic>?;
      if (recommendations == null) {
        return [];
      }

      final recommendedCrops =
          recommendations['recommended_crops'] as List? ?? [];
      final List<CropRecommendation> cropList = [];

      for (var crop in recommendedCrops) {
        if (crop is String) {
          cropList.add(
            _createCropRecommendation(crop, soilData, weatherProvider),
          );
        }
      }

      return cropList;
    } catch (e) {
      print('Error getting crop recommendations: $e');
      return [];
    }
  }

  CropRecommendation _createCropRecommendation(
    String cropName,
    SoilData soilData,
    WeatherProvider weatherProvider,
  ) {
    // Create basic crop recommendation based on crop name and conditions
    switch (cropName.toLowerCase()) {
      case 'maize':
        return CropRecommendation(
          name: 'Maize',
          variety: 'SC 403',
          plantingDate: 'October - November',
          harvestDate: 'March - April',
          yield: '4-6 tons/ha',
          suitability: _calculateSuitability(
            cropName,
            soilData,
            weatherProvider,
          ),
          description:
              'High-yielding hybrid maize suitable for Zimbabwean conditions',
          requirements: 'Well-drained soil, moderate rainfall',
          benefits: [
            'High yield potential',
            'Drought tolerant',
            'Good market demand',
          ],
          challenges: [
            'Requires good soil fertility',
            'Susceptible to stalk borer',
          ],
        );
      case 'wheat':
        return CropRecommendation(
          name: 'Wheat',
          variety: 'SC Nduna',
          plantingDate: 'May - June',
          harvestDate: 'September - October',
          yield: '2-4 tons/ha',
          suitability: _calculateSuitability(
            cropName,
            soilData,
            weatherProvider,
          ),
          description: 'Winter wheat variety adapted to Zimbabwean climate',
          requirements: 'Cool temperatures, adequate moisture',
          benefits: [
            'Good for rotation',
            'High protein content',
            'Stable yields',
          ],
          challenges: ['Requires cold weather', 'Sensitive to heat stress'],
        );
      case 'sorghum':
        return CropRecommendation(
          name: 'Sorghum',
          variety: 'Macia',
          plantingDate: 'November - December',
          harvestDate: 'April - May',
          yield: '2-3 tons/ha',
          suitability: _calculateSuitability(
            cropName,
            soilData,
            weatherProvider,
          ),
          description: 'Drought-resistant cereal crop ideal for dry regions',
          requirements: 'Low rainfall, well-drained soil',
          benefits: [
            'Drought tolerant',
            'Low input requirements',
            'Good for food security',
          ],
          challenges: ['Lower market value', 'Bird damage risk'],
        );
      case 'cotton':
        return CropRecommendation(
          name: 'Cotton',
          variety: 'SJ 2',
          plantingDate: 'November - December',
          harvestDate: 'May - June',
          yield: '1-2 tons/ha',
          suitability: _calculateSuitability(
            cropName,
            soilData,
            weatherProvider,
          ),
          description: 'Cash crop with good export potential',
          requirements: 'Warm temperatures, adequate rainfall',
          benefits: [
            'High value crop',
            'Export potential',
            'Good for rotation',
          ],
          challenges: ['High input costs', 'Pest management required'],
        );
      case 'tobacco':
        return CropRecommendation(
          name: 'Tobacco',
          variety: 'Virginia',
          plantingDate: 'September - October',
          harvestDate: 'February - March',
          yield: '2-3 tons/ha',
          suitability: _calculateSuitability(
            cropName,
            soilData,
            weatherProvider,
          ),
          description: 'High-value cash crop for export markets',
          requirements: 'Warm climate, fertile soil',
          benefits: ['High value', 'Export market', 'Good returns'],
          challenges: [
            'High input costs',
            'Labor intensive',
            'Market volatility',
          ],
        );
      default:
        return CropRecommendation(
          name: cropName,
          variety: 'Local variety',
          plantingDate: 'Season dependent',
          harvestDate: 'Season dependent',
          yield: 'Variable',
          suitability: _calculateSuitability(
            cropName,
            soilData,
            weatherProvider,
          ),
          description: 'Crop recommendation based on current conditions',
          requirements: 'Check specific requirements',
          benefits: ['Suitable for current conditions'],
          challenges: ['Monitor growing conditions'],
        );
    }
  }

  int _calculateSuitability(
    String cropName,
    SoilData soilData,
    WeatherProvider weatherProvider,
  ) {
    // Basic suitability calculation based on soil and weather conditions
    int baseScore = 50;

    // Adjust based on soil pH
    if (soilData.ph >= 6.0 && soilData.ph <= 7.5) {
      baseScore += 20;
    } else if (soilData.ph >= 5.5 && soilData.ph <= 8.0) {
      baseScore += 10;
    }

    // Adjust based on organic matter
    if (soilData.organicMatter >= 2.0) {
      baseScore += 15;
    }

    // Adjust based on temperature
    if (weatherProvider.currentWeather != null) {
      final temp = weatherProvider.currentWeather!.temperature;
      if (temp >= 20 && temp <= 30) {
        baseScore += 15;
      } else if (temp >= 15 && temp <= 35) {
        baseScore += 10;
      }
    }

    return baseScore.clamp(0, 100);
  }
}

class CropRecommendation {
  final String name;
  final String variety;
  final String plantingDate;
  final String harvestDate;
  final String yield;
  final int suitability;
  final String description;
  final String requirements;
  final List<String> benefits;
  final List<String> challenges;

  CropRecommendation({
    required this.name,
    required this.variety,
    required this.plantingDate,
    required this.harvestDate,
    required this.yield,
    required this.suitability,
    required this.description,
    required this.requirements,
    required this.benefits,
    required this.challenges,
  });
}
