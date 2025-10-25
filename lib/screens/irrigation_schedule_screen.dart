import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../providers/notification_provider.dart';
import '../models/soil_data.dart';
import '../services/soil_data_service.dart';
import '../services/agro_prediction_service.dart';
import '../services/logging_service.dart';

class IrrigationScheduleScreen extends StatefulWidget {
  const IrrigationScheduleScreen({super.key});

  @override
  State<IrrigationScheduleScreen> createState() =>
      _IrrigationScheduleScreenState();
}

class _IrrigationScheduleScreenState extends State<IrrigationScheduleScreen> {
  final SoilDataService _soilService = SoilDataService();
  final AgroPredictionService _predictionService = AgroPredictionService();
  SoilData? _soilData;
  bool _isLoading = false;
  String _selectedCrop = 'Maize';
  String _selectedGrowthStage = 'Vegetative';

  final List<String> _crops = [
    'Maize',
    'Wheat',
    'Sorghum',
    'Cotton',
    'Tobacco',
  ];
  final List<String> _growthStages = [
    'Planting',
    'Vegetative',
    'Flowering',
    'Fruiting',
    'Maturity',
  ];

  List<IrrigationSchedule> _irrigationSchedules = [];

  @override
  void initState() {
    super.initState();
    _loadSoilData();
    _sendInitialNotification();
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

      // Get irrigation schedules based on soil data and weather
      final schedules = await _getIrrigationSchedules(
        soilData,
        weatherProvider,
      );

      setState(() {
        _soilData = soilData;
        _irrigationSchedules = schedules;
        _isLoading = false;
      });
    } catch (e) {
      LoggingService.error(
        'Error loading soil data and irrigation schedules',
        error: e,
      );
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

  // Send automatic notification when crop and stage are selected
  Future<void> _sendInitialNotification() async {
    await Future.delayed(
      const Duration(seconds: 2),
    ); // Small delay to ensure providers are ready
    await _sendIrrigationNotification();
  }

  // Send notification when crop or stage changes
  Future<void> _sendIrrigationNotification() async {
    try {
      final notificationProvider = context.read<NotificationProvider>();

      final recommendation = _getIrrigationRecommendation();

      await notificationProvider.sendLocalNotification(
        title: 'Irrigation Recommendation for $_selectedCrop',
        body: recommendation,
        type: 'irrigation',
        priority: 'high',
      );
    } catch (e) {
      LoggingService.error('Error sending irrigation notification', error: e);
    }
  }

  // Get irrigation recommendation based on selected crop and stage
  String _getIrrigationRecommendation() {
    final recommendations = {
      'Maize': {
        'Planting':
            'Water lightly every 2-3 days. Keep soil moist but not waterlogged.',
        'Vegetative':
            'Water deeply every 3-4 days. Ensure 1-2 inches of water per week.',
        'Flowering':
            'Increase watering to every 2-3 days. Critical stage for yield.',
        'Fruiting': 'Maintain consistent moisture. Water every 2-3 days.',
        'Maturity':
            'Reduce watering frequency. Allow soil to dry slightly between waterings.',
      },
      'Wheat': {
        'Planting':
            'Light watering to establish roots. Keep soil consistently moist.',
        'Vegetative':
            'Water every 4-5 days. Ensure adequate moisture for growth.',
        'Flowering': 'Critical watering period. Water every 2-3 days.',
        'Fruiting': 'Maintain soil moisture. Water every 3-4 days.',
        'Maturity':
            'Reduce watering as grain matures. Stop 2 weeks before harvest.',
      },
      'Sorghum': {
        'Planting': 'Light, frequent watering to establish seedlings.',
        'Vegetative': 'Water every 4-5 days. Sorghum is drought tolerant.',
        'Flowering': 'Increase watering frequency to every 3-4 days.',
        'Fruiting': 'Maintain consistent moisture for grain development.',
        'Maturity': 'Reduce watering. Allow natural drying for harvest.',
      },
      'Cotton': {
        'Planting':
            'Keep soil moist for germination. Light watering every 2-3 days.',
        'Vegetative': 'Water every 3-4 days. Cotton needs consistent moisture.',
        'Flowering':
            'Critical stage. Water every 2-3 days for good boll development.',
        'Fruiting': 'Maintain moisture for boll filling. Water every 2-3 days.',
        'Maturity': 'Reduce watering to promote boll opening.',
      },
      'Tobacco': {
        'Planting': 'Light, frequent watering for seedling establishment.',
        'Vegetative':
            'Water every 3-4 days. Tobacco needs consistent moisture.',
        'Flowering': 'Reduce watering slightly to control growth.',
        'Fruiting': 'Maintain moderate moisture. Avoid overwatering.',
        'Maturity': 'Reduce watering for proper curing preparation.',
      },
    };

    return recommendations[_selectedCrop]?[_selectedGrowthStage] ??
        'Water your $_selectedCrop plants appropriately for the $_selectedGrowthStage stage.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Irrigation Schedule'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddScheduleDialog,
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

                    // Current conditions
                    _buildCurrentConditionsCard(),

                    const SizedBox(height: 20),

                    // Irrigation recommendations
                    _buildIrrigationRecommendations(),

                    const SizedBox(height: 20),

                    // Schedule list
                    _buildScheduleList(),
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
            'Generating irrigation recommendations',
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
                  Icons.water_drop,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Smart Irrigation Schedule',
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
                Expanded(child: _buildFilterChip('Crop', _selectedCrop)),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFilterChip('Stage', _selectedGrowthStage),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Optimized based on weather conditions and soil analysis',
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
    return GestureDetector(
      onTap: () => _showSelectionDialog(label),
      child: Container(
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
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _showSelectionDialog(String label) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select $label'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: label == 'Crop'
              ? _crops
                    .map(
                      (crop) => ListTile(
                        title: Text(crop),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _selectedCrop = crop;
                          });
                          _sendIrrigationNotification();
                        },
                      ),
                    )
                    .toList()
              : _growthStages
                    .map(
                      (stage) => ListTile(
                        title: Text(stage),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _selectedGrowthStage = stage;
                          });
                          _sendIrrigationNotification();
                        },
                      ),
                    )
                    .toList(),
        ),
      ),
    );
  }

  Widget _buildCurrentConditionsCard() {
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
                Icon(Icons.thermostat, color: Colors.blue[600], size: 24),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Current Conditions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildConditionMetric(
                    'Temperature',
                    '28°C',
                    Icons.thermostat,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildConditionMetric(
                    'Humidity',
                    '65%',
                    Icons.opacity,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildConditionMetric(
                    'Rainfall',
                    '0mm',
                    Icons.water_drop,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildConditionMetric(
                    'Soil Temp',
                    '${_soilData?.soilTemperature.toStringAsFixed(1) ?? 'N/A'}°C',
                    Icons.terrain,
                    Colors.brown,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionMetric(
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

  Widget _buildIrrigationRecommendations() {
    final recommendation = _getIrrigationRecommendation();

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
                Icon(Icons.lightbulb, color: Colors.orange[600], size: 24),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Irrigation Recommendation',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'For $_selectedCrop in $_selectedGrowthStage stage',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Recommended Action',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recommendation,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This recommendation is based on your selected crop and growth stage. Tap the filters above to change selections.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleList() {
    final filteredSchedules = _irrigationSchedules.where((schedule) {
      return schedule.crop == _selectedCrop &&
          schedule.growthStage == _selectedGrowthStage;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Irrigation Schedule',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (filteredSchedules.isEmpty)
          _buildEmptyState()
        else
          ...filteredSchedules.map((schedule) => _buildScheduleCard(schedule)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.water_drop_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Schedule Available',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No irrigation schedule found for $_selectedCrop in $_selectedGrowthStage stage',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(IrrigationSchedule schedule) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showScheduleDetails(schedule),
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
                      color: _getPriorityColor(
                        schedule.priority,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.schedule,
                      color: _getPriorityColor(schedule.priority),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${schedule.crop} - ${schedule.growthStage}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          schedule.description,
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
                      color: _getPriorityColor(
                        schedule.priority,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getPriorityColor(
                          schedule.priority,
                        ).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      schedule.priority,
                      style: TextStyle(
                        color: _getPriorityColor(schedule.priority),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildScheduleInfo(
                      'Frequency',
                      schedule.frequency,
                      Icons.repeat,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildScheduleInfo(
                      'Duration',
                      schedule.duration,
                      Icons.timer,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildScheduleInfo(
                      'Amount',
                      schedule.amount,
                      Icons.water_drop,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildScheduleInfo(
                      'Time',
                      schedule.timeOfDay,
                      Icons.access_time,
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

  Widget _buildScheduleInfo(
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
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
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

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showScheduleDetails(IrrigationSchedule schedule) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
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
                      color: _getPriorityColor(
                        schedule.priority,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.schedule,
                      color: _getPriorityColor(schedule.priority),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${schedule.crop} - ${schedule.growthStage}',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          schedule.description,
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
                'Irrigation Details',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Frequency', schedule.frequency, Icons.repeat),
              _buildDetailRow('Duration', schedule.duration, Icons.timer),
              _buildDetailRow('Amount', schedule.amount, Icons.water_drop),
              _buildDetailRow(
                'Time of Day',
                schedule.timeOfDay,
                Icons.access_time,
              ),
              _buildDetailRow(
                'Priority',
                schedule.priority,
                Icons.priority_high,
              ),
              const SizedBox(height: 20),
              Text(
                'Tips',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...schedule.tips.map(
                (tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(tip)),
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

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showAddScheduleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Irrigation Schedule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedCrop,
              decoration: const InputDecoration(labelText: 'Crop'),
              items: _crops.map((crop) {
                return DropdownMenuItem(value: crop, child: Text(crop));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCrop = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedGrowthStage,
              decoration: const InputDecoration(labelText: 'Growth Stage'),
              items: _growthStages.map((stage) {
                return DropdownMenuItem(value: stage, child: Text(stage));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGrowthStage = value!;
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
              // Add logic to create new schedule
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<List<IrrigationSchedule>> _getIrrigationSchedules(
    SoilData? soilData,
    WeatherProvider weatherProvider,
  ) async {
    try {
      if (soilData == null || weatherProvider.currentWeather == null) {
        return [];
      }

      // Get AI insights for irrigation recommendations
      final insights = await _predictionService.getAIInsights(
        location: 'Harare', // Default location
        currentWeather: weatherProvider.currentWeather!,
        soilData: soilData,
        crop: _selectedCrop.toLowerCase(),
        growthStage: _selectedGrowthStage.toLowerCase(),
      );

      // Parse irrigation advice from AI insights
      final irrigationAdvice =
          insights['irrigation_advice'] as Map<String, dynamic>?;
      if (irrigationAdvice == null) {
        return [];
      }

      // Create irrigation schedules based on AI recommendations
      final List<IrrigationSchedule> schedules = [];

      // Generate schedules for different growth stages
      for (String stage in _growthStages) {
        schedules.add(
          _createIrrigationSchedule(
            _selectedCrop,
            stage,
            irrigationAdvice,
            soilData,
            weatherProvider,
          ),
        );
      }

      return schedules;
    } catch (e) {
      LoggingService.error('Error getting irrigation schedules', error: e);
      return [];
    }
  }

  IrrigationSchedule _createIrrigationSchedule(
    String crop,
    String growthStage,
    Map<String, dynamic> irrigationAdvice,
    SoilData soilData,
    WeatherProvider weatherProvider,
  ) {
    // Create irrigation schedule based on crop, growth stage, and conditions
    String frequency =
        irrigationAdvice['frequency']?.toString() ?? 'Every 3-4 days';
    String duration =
        irrigationAdvice['duration']?.toString() ?? '30-45 minutes';
    String amount = irrigationAdvice['quantity']?.toString() ?? '15-20mm';
    String timeOfDay = 'Early morning (6-8 AM)';
    String priority = 'Medium';
    String description =
        'Irrigation schedule for $crop during $growthStage stage';
    List<String> tips = [];

    // Adjust based on growth stage
    switch (growthStage.toLowerCase()) {
      case 'planting':
        frequency = 'Every 2-3 days';
        duration = '20-30 minutes';
        amount = '10-15mm';
        priority = 'High';
        description =
            'Critical for seed germination and early root development';
        tips = [
          'Ensure soil is moist but not waterlogged',
          'Water gently to avoid washing away seeds',
        ];
        break;
      case 'vegetative':
        frequency = 'Every 3-4 days';
        duration = '30-45 minutes';
        amount = '15-20mm';
        priority = 'High';
        description = 'Essential for rapid growth and leaf development';
        tips = [
          'Monitor soil moisture regularly',
          'Increase frequency during hot weather',
        ];
        break;
      case 'flowering':
        frequency = 'Every 2-3 days';
        duration = '45-60 minutes';
        amount = '20-25mm';
        priority = 'Critical';
        description =
            'Most critical stage - water stress can severely reduce yield';
        tips = [
          'Never let soil dry out during flowering',
          'Consider drip irrigation for efficiency',
        ];
        break;
      case 'fruiting':
        frequency = 'Every 3-4 days';
        duration = '30-45 minutes';
        amount = '15-20mm';
        priority = 'High';
        description = 'Important for grain filling and kernel development';
        tips = [
          'Reduce frequency as kernels mature',
          'Stop irrigation 2 weeks before harvest',
        ];
        break;
      case 'maturity':
        frequency = 'Every 5-7 days';
        duration = '20-30 minutes';
        amount = '10-15mm';
        priority = 'Low';
        description = 'Minimal irrigation for natural drying';
        tips = ['Reduce irrigation significantly', 'Allow natural maturation'];
        break;
    }

    // Adjust based on soil conditions
    if (soilData.ph < 6.0 || soilData.ph > 8.0) {
      tips.add('Monitor soil pH and adjust irrigation accordingly');
    }

    if (soilData.organicMatter < 2.0) {
      tips.add('Consider adding organic matter to improve water retention');
    }

    // Adjust based on weather
    if (weatherProvider.currentWeather != null) {
      final temp = weatherProvider.currentWeather!.temperature;
      if (temp > 30) {
        frequency = 'Every 2-3 days';
        tips.add('Increase frequency during hot weather');
      } else if (temp < 15) {
        frequency = 'Every 5-7 days';
        tips.add('Reduce frequency during cool weather');
      }
    }

    return IrrigationSchedule(
      crop: crop,
      growthStage: growthStage,
      frequency: frequency,
      duration: duration,
      amount: amount,
      timeOfDay: timeOfDay,
      priority: priority,
      description: description,
      tips: tips,
    );
  }
}

class IrrigationSchedule {
  final String crop;
  final String growthStage;
  final String frequency;
  final String duration;
  final String amount;
  final String timeOfDay;
  final String priority;
  final String description;
  final List<String> tips;

  IrrigationSchedule({
    required this.crop,
    required this.growthStage,
    required this.frequency,
    required this.duration,
    required this.amount,
    required this.timeOfDay,
    required this.priority,
    required this.description,
    required this.tips,
  });
}
