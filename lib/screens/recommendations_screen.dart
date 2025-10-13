import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../providers/agro_climatic_provider.dart';
import '../widgets/location_dropdown.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  String _selectedCategory = 'all';
  final Map<String, Set<int>> _completedActions = {}; // rec_title -> set of action indices

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather-Based Recommendations'),
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
      body: Consumer2<WeatherProvider, AgroClimaticProvider>(
        builder: (context, weatherProvider, agroProvider, child) {
          if (weatherProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (weatherProvider.error != null) {
            // Show offline recommendations instead of error
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.wifi_off, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Offline Mode',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Showing seasonal recommendations. Connect to internet for weather-based advice.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () => weatherProvider.refreshAll(),
                        tooltip: 'Retry',
                      ),
                    ],
                  ),
                ),
                _buildCategoryFilter(),
                Expanded(
                  child: _buildRecommendationsList(
                    weatherProvider,
                    agroProvider,
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              _buildCategoryFilter(),
              Expanded(
                child: _buildRecommendationsList(weatherProvider, agroProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _buildFilterChip('all', 'All', Icons.all_inclusive)),
          Expanded(
            child: _buildFilterChip(
              'irrigation',
              'Irrigation',
              Icons.water_drop,
            ),
          ),
          Expanded(
            child: _buildFilterChip('planting', 'Planting', Icons.agriculture),
          ),
          Expanded(
            child: _buildFilterChip('maintenance', 'Maintenance', Icons.build),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String category, String label, IconData icon) {
    final isSelected = _selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
        },
        selectedColor: Theme.of(context).colorScheme.primaryContainer,
        checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildRecommendationsList(
    WeatherProvider weatherProvider,
    AgroClimaticProvider agroProvider,
  ) {
    final recommendations = _getWeatherBasedRecommendations(weatherProvider);
    final filteredRecommendations = _filterRecommendations(recommendations);

    if (filteredRecommendations.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => weatherProvider.refreshAll(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredRecommendations.length,
        itemBuilder: (context, index) {
          final recommendation = filteredRecommendations[index];
          return _buildRecommendationCard(recommendation);
        },
      ),
    );
  }

  List<WeatherRecommendation> _getWeatherBasedRecommendations(
    WeatherProvider weatherProvider,
  ) {
    final currentWeather = weatherProvider.currentWeather;
    final recommendations = <WeatherRecommendation>[];

    // If no weather data, provide general seasonal recommendations
    if (currentWeather == null) {
      return _getSeasonalRecommendations();
    }

    // Temperature-based recommendations
    if (currentWeather.temperature > 30) {
      recommendations.add(
        WeatherRecommendation(
          title: 'High Temperature Alert',
          description: 'Temperatures are very high. Consider these actions:',
          category: 'irrigation',
          priority: 'high',
          icon: Icons.wb_sunny,
          color: Colors.orange,
          actions: [
            'Water crops early morning or late evening',
            'Apply mulch to retain soil moisture',
            'Consider shade nets for sensitive crops',
            'Increase irrigation frequency',
          ],
        ),
      );
    } else if (currentWeather.temperature < 10) {
      recommendations.add(
        WeatherRecommendation(
          title: 'Low Temperature Alert',
          description: 'Temperatures are low. Consider these actions:',
          category: 'maintenance',
          priority: 'high',
          icon: Icons.ac_unit,
          color: Colors.blue,
          actions: [
            'Protect sensitive crops with covers',
            'Reduce irrigation to prevent frost damage',
            'Consider planting cold-tolerant varieties',
            'Monitor for frost damage',
          ],
        ),
      );
    }

    // Rainfall-based recommendations
    if (currentWeather.precipitation > 20) {
      recommendations.add(
        WeatherRecommendation(
          title: 'Heavy Rainfall Expected',
          description:
              'Significant rainfall is expected. Take these precautions:',
          category: 'maintenance',
          priority: 'high',
          icon: Icons.water,
          color: Colors.blue,
          actions: [
            'Ensure proper drainage in fields',
            'Avoid planting in waterlogged areas',
            'Check for soil erosion',
            'Postpone fertilizer application',
          ],
        ),
      );
    } else if (currentWeather.precipitation < 5) {
      recommendations.add(
        WeatherRecommendation(
          title: 'Dry Conditions',
          description: 'Low rainfall expected. Consider these actions:',
          category: 'irrigation',
          priority: 'medium',
          icon: Icons.water_drop_outlined,
          color: Colors.orange,
          actions: [
            'Increase irrigation frequency',
            'Plant drought-tolerant crops',
            'Apply mulch to conserve moisture',
            'Consider drip irrigation systems',
          ],
        ),
      );
    }

    // Humidity-based recommendations
    if (currentWeather.humidity > 80) {
      recommendations.add(
        WeatherRecommendation(
          title: 'High Humidity Conditions',
          description: 'High humidity detected. Watch for these issues:',
          category: 'maintenance',
          priority: 'medium',
          icon: Icons.opacity,
          color: Colors.blue,
          actions: [
            'Monitor for fungal diseases',
            'Ensure good air circulation',
            'Avoid overhead watering',
            'Apply fungicides if needed',
          ],
        ),
      );
    }

    // Wind-based recommendations
    if (currentWeather.windSpeed > 15) {
      recommendations.add(
        WeatherRecommendation(
          title: 'Strong Winds Expected',
          description: 'High wind speeds detected. Take precautions:',
          category: 'maintenance',
          priority: 'medium',
          icon: Icons.air,
          color: Colors.grey,
          actions: [
            'Secure trellises and supports',
            'Avoid spraying in windy conditions',
            'Check for wind damage',
            'Consider windbreaks',
          ],
        ),
      );
    }

    // General seasonal recommendations
    final month = DateTime.now().month;
    if (month >= 10 && month <= 12) {
      recommendations.add(
        WeatherRecommendation(
          title: 'Rainy Season Preparation',
          description: 'Prepare for the upcoming rainy season:',
          category: 'planting',
          priority: 'medium',
          icon: Icons.cloud,
          color: Colors.green,
          actions: [
            'Prepare seedbeds for planting',
            'Clear drainage channels',
            'Stock up on seeds and fertilizers',
            'Plan crop rotation schedule',
          ],
        ),
      );
    } else if (month >= 4 && month <= 6) {
      recommendations.add(
        WeatherRecommendation(
          title: 'Dry Season Management',
          description: 'Manage crops during dry season:',
          category: 'irrigation',
          priority: 'medium',
          icon: Icons.wb_sunny,
          color: Colors.orange,
          actions: [
            'Implement water conservation measures',
            'Focus on drought-tolerant crops',
            'Use mulching techniques',
            'Monitor soil moisture levels',
          ],
        ),
      );
    }

    return recommendations;
  }

  List<WeatherRecommendation> _getSeasonalRecommendations() {
    final recommendations = <WeatherRecommendation>[];
    final month = DateTime.now().month;

    // Rainy season recommendations (October-March)
    if (month >= 10 || month <= 3) {
      recommendations.addAll([
        WeatherRecommendation(
          title: 'Rainy Season Farming',
          description: 'Optimize farming during the rainy season:',
          category: 'planting',
          priority: 'high',
          icon: Icons.cloud,
          color: Colors.green,
          actions: [
            'Plant moisture-loving crops like maize and tobacco',
            'Prepare seedbeds with good drainage',
            'Monitor for waterlogging in low-lying areas',
            'Apply fertilizers before heavy rains',
            'Weed regularly to prevent competition',
          ],
        ),
        WeatherRecommendation(
          title: 'Irrigation Management',
          description: 'Manage irrigation during rainy season:',
          category: 'irrigation',
          priority: 'medium',
          icon: Icons.water_drop,
          color: Colors.blue,
          actions: [
            'Reduce irrigation frequency during rainfall',
            'Check drainage systems regularly',
            'Harvest rainwater for dry period storage',
            'Monitor soil moisture to avoid oversaturation',
          ],
        ),
        WeatherRecommendation(
          title: 'Disease Prevention',
          description: 'High humidity increases disease risk:',
          category: 'maintenance',
          priority: 'high',
          icon: Icons.healing,
          color: Colors.orange,
          actions: [
            'Monitor for fungal diseases in humid conditions',
            'Ensure good air circulation between plants',
            'Apply preventive fungicides if necessary',
            'Remove infected plant material promptly',
          ],
        ),
      ]);
    }
    // Dry season recommendations (April-September)
    else {
      recommendations.addAll([
        WeatherRecommendation(
          title: 'Dry Season Management',
          description: 'Farming strategies for dry conditions:',
          category: 'irrigation',
          priority: 'high',
          icon: Icons.wb_sunny,
          color: Colors.orange,
          actions: [
            'Plant drought-tolerant crops like sorghum and millet',
            'Implement water conservation techniques',
            'Use mulch heavily to retain soil moisture',
            'Consider drip irrigation for efficiency',
            'Water early morning or late evening',
          ],
        ),
        WeatherRecommendation(
          title: 'Soil Preparation',
          description: 'Prepare soil for the next planting season:',
          category: 'planting',
          priority: 'medium',
          icon: Icons.terrain,
          color: Colors.brown,
          actions: [
            'Add organic matter to improve water retention',
            'Practice conservation tillage',
            'Plant cover crops to protect soil',
            'Test soil pH and nutrient levels',
          ],
        ),
        WeatherRecommendation(
          title: 'Crop Protection',
          description: 'Protect crops during hot dry weather:',
          category: 'maintenance',
          priority: 'high',
          icon: Icons.shield,
          color: Colors.red,
          actions: [
            'Monitor for heat stress in sensitive crops',
            'Provide shade for young plants if possible',
            'Check for pest infestations (more common when dry)',
            'Apply mulch to keep soil cool',
          ],
        ),
      ]);
    }

    // Add general year-round recommendations
    recommendations.add(
      WeatherRecommendation(
        title: 'General Best Practices',
        description: 'Year-round farming recommendations:',
        category: 'all',
        priority: 'medium',
        icon: Icons.agriculture,
        color: Colors.green,
        actions: [
          'Practice crop rotation to maintain soil health',
          'Keep detailed farming records',
          'Monitor weather forecasts regularly',
          'Maintain farming equipment properly',
          'Join farmer groups for knowledge sharing',
        ],
      ),
    );

    return recommendations;
  }

  List<WeatherRecommendation> _filterRecommendations(
    List<WeatherRecommendation> recommendations,
  ) {
    if (_selectedCategory == 'all') return recommendations;
    return recommendations
        .where((r) => r.category == _selectedCategory)
        .toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No recommendations available',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Weather data is needed to generate recommendations',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(WeatherRecommendation recommendation) {
    final completedSet = _completedActions[recommendation.title] ?? {};
    final completionRate = completedSet.length / recommendation.actions.length;
    
    // Get priority color
    Color priorityColor = recommendation.priority == 'high' 
        ? Colors.red 
        : recommendation.priority == 'medium'
            ? Colors.orange
            : Colors.blue;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: recommendation.color.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              recommendation.color.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with priority badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: recommendation.color.withOpacity(0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: recommendation.color,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: recommendation.color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      recommendation.icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                recommendation.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            // Priority badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: priorityColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    recommendation.priority == 'high'
                                        ? Icons.priority_high
                                        : Icons.info_outline,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    recommendation.priority.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recommendation.description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Progress indicator
            if (completedSet.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: completionRate,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                recommendation.color,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(completionRate * 100).toInt()}%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: recommendation.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            
            // Actions list with checkboxes
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.checklist, 
                        size: 18, 
                        color: Colors.grey[700]
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Action Items (${completedSet.length}/${recommendation.actions.length})',
                        style: Theme.of(
                          context,
                        ).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...recommendation.actions.asMap().entries.map(
                    (entry) {
                      final index = entry.key;
                      final action = entry.value;
                      final isCompleted = completedSet.contains(index);
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (!_completedActions.containsKey(recommendation.title)) {
                                _completedActions[recommendation.title] = {};
                              }
                              if (isCompleted) {
                                _completedActions[recommendation.title]!.remove(index);
                              } else {
                                _completedActions[recommendation.title]!.add(index);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isCompleted 
                                  ? recommendation.color.withOpacity(0.08)
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isCompleted
                                    ? recommendation.color.withOpacity(0.3)
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? recommendation.color
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: isCompleted
                                          ? recommendation.color
                                          : Colors.grey[400]!,
                                      width: 2,
                                    ),
                                  ),
                                  child: isCompleted
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 14,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    action,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      decoration: isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: isCompleted
                                          ? Colors.grey[600]
                                          : Colors.grey[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Quick action button
            if (completionRate < 1.0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Mark all as complete
                      setState(() {
                        _completedActions[recommendation.title] = 
                            Set.from(List.generate(
                              recommendation.actions.length, 
                              (index) => index,
                            ));
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('All actions marked complete for: ${recommendation.title}'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Mark All Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: recommendation.color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'All actions completed!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
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
}

class WeatherRecommendation {
  final String title;
  final String description;
  final String category;
  final String priority;
  final IconData icon;
  final Color color;
  final List<String> actions;

  WeatherRecommendation({
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.icon,
    required this.color,
    required this.actions,
  });
}
