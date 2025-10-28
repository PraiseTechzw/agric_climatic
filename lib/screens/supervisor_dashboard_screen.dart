import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/weather.dart';
import '../models/weather_pattern.dart';
import '../models/agricultural_recommendation.dart';
import '../providers/weather_provider.dart';
import '../services/historical_weather_service.dart';

class SupervisorDashboardScreen extends StatefulWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  State<SupervisorDashboardScreen> createState() =>
      _SupervisorDashboardScreenState();
}

class _SupervisorDashboardScreenState extends State<SupervisorDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final HistoricalWeatherService _weatherService = HistoricalWeatherService();

  String _selectedTimeRange = 'Month';
  String _selectedYear = DateTime.now().year.toString();
  List<Weather> _historicalData = [];
  List<WeatherPattern> _weatherPatterns = [];
  List<AgriculturalRecommendation> _recommendations = [];
  Map<String, dynamic> _climateStatistics = {};
  bool _isLoading = false;

  final List<String> _timeRanges = ['Week', 'Month', 'Season', 'Year'];
  final List<String> _years = ['2025', '2024', '2023', '2022', '2021', '2020'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      await _loadHistoricalData();
      await _loadWeatherPatterns();
      await _loadRecommendations();
      await _loadClimateStatistics();
    } catch (e) {
      _showErrorSnackBar('Failed to load supervisor dashboard: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadHistoricalData() async {
    try {
      final startDate = _getStartDateForRange(
        _selectedTimeRange,
        _selectedYear,
      );
      final endDate = DateTime.now();

      _historicalData = await _weatherService.getHistoricalWeatherData(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      print('Error loading historical data: $e');
    }
  }

  Future<void> _loadWeatherPatterns() async {
    try {
      final startDate = _getStartDateForRange(
        _selectedTimeRange,
        _selectedYear,
      );
      final endDate = DateTime.now();

      _weatherPatterns = await _weatherService.analyzeWeatherPatterns(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      print('Error loading weather patterns: $e');
    }
  }

  Future<void> _loadRecommendations() async {
    try {
      _recommendations = _generateSupervisorRecommendations();
    } catch (e) {
      print('Error loading recommendations: $e');
    }
  }

  Future<void> _loadClimateStatistics() async {
    try {
      final startDate = _getStartDateForRange(
        _selectedTimeRange,
        _selectedYear,
      );
      final endDate = DateTime.now();

      _climateStatistics = await _weatherService.getClimateStatistics(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      print('Error loading climate statistics: $e');
    }
  }

  DateTime _getStartDateForRange(String range, String year) {
    final yearInt = int.parse(year);
    switch (range) {
      case 'Week':
        return DateTime.now().subtract(const Duration(days: 7));
      case 'Month':
        return DateTime.now().subtract(const Duration(days: 30));
      case 'Season':
        return DateTime.now().subtract(const Duration(days: 90));
      case 'Year':
        return DateTime(yearInt, 1, 1);
      default:
        return DateTime.now().subtract(const Duration(days: 7));
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supervisor Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportSupervisorReport,
            tooltip: 'Export Report',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            Tab(icon: Icon(Icons.people), text: 'Farmers'),
            Tab(icon: Icon(Icons.assessment), text: 'Reports'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading supervisor data...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildAnalyticsTab(),
                _buildFarmersTab(),
                _buildReportsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSupervisorStatsCards(),
          const SizedBox(height: 20),
          _buildWeatherAlertsCard(),
          const SizedBox(height: 20),
          _buildRecentActivityCard(),
          const SizedBox(height: 20),
          _buildQuickActionsCard(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeatherTrendsChart(),
          const SizedBox(height: 20),
          _buildRegionalComparisonCard(),
          const SizedBox(height: 20),
          _buildCropPerformanceCard(),
          const SizedBox(height: 20),
          _buildClimateIndicatorsCard(),
        ],
      ),
    );
  }

  Widget _buildFarmersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFarmerStatsCard(),
          const SizedBox(height: 20),
          _buildActiveFarmersList(),
          const SizedBox(height: 20),
          _buildFarmerSupportCard(),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReportGenerationCard(),
          const SizedBox(height: 20),
          _buildHistoricalReportsCard(),
          const SizedBox(height: 20),
          _buildExportOptionsCard(),
        ],
      ),
    );
  }

  Widget _buildSupervisorStatsCards() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supervisor Statistics',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildStatCard(
                  'Active Farmers',
                  '156',
                  Icons.people,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Weather Stations',
                  '12',
                  Icons.location_on,
                  Colors.green,
                ),
                _buildStatCard(
                  'Alerts Sent',
                  '23',
                  Icons.warning,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Reports Generated',
                  '8',
                  Icons.assessment,
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherAlertsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weather Alerts & Warnings',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildAlertItem(
              'High Temperature Alert',
              'Temperatures above 35°C expected',
              Colors.red,
            ),
            const SizedBox(height: 8),
            _buildAlertItem(
              'Drought Warning',
              'Low rainfall in Bulawayo region',
              Colors.orange,
            ),
            const SizedBox(height: 8),
            _buildAlertItem(
              'Heavy Rain Forecast',
              'Expected in Mutare area',
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItem(String title, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildActivityItem(
              'Farmer John uploaded weather data',
              '2 hours ago',
              Icons.cloud_upload,
            ),
            const SizedBox(height: 8),
            _buildActivityItem(
              'Weather alert sent to 15 farmers',
              '4 hours ago',
              Icons.warning,
            ),
            const SizedBox(height: 8),
            _buildActivityItem(
              'Monthly report generated',
              '1 day ago',
              Icons.assessment,
            ),
            const SizedBox(height: 8),
            _buildActivityItem(
              'New farmer registered',
              '2 days ago',
              Icons.person_add,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String activity, String time, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(activity, style: const TextStyle(fontSize: 14)),
              Text(
                time,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _sendWeatherAlert,
                    icon: const Icon(Icons.warning),
                    label: const Text('Send Alert'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _generateReport,
                    icon: const Icon(Icons.assessment),
                    label: const Text('Generate Report'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _viewFarmers,
                    icon: const Icon(Icons.people),
                    label: const Text('View Farmers'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _exportData,
                    icon: const Icon(Icons.download),
                    label: const Text('Export Data'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherTrendsChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weather Trends Analysis',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}°C');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('Day ${value.toInt()}');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(0, 25),
                        const FlSpot(1, 27),
                        const FlSpot(2, 26),
                        const FlSpot(3, 28),
                        const FlSpot(4, 30),
                        const FlSpot(5, 29),
                        const FlSpot(6, 31),
                      ],
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
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

  Widget _buildRegionalComparisonCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Regional Weather Comparison',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildRegionItem('Harare', '26°C', '75%', '5mm', Colors.green),
            const SizedBox(height: 8),
            _buildRegionItem('Bulawayo', '28°C', '45%', '2mm', Colors.orange),
            const SizedBox(height: 8),
            _buildRegionItem('Mutare', '24°C', '85%', '8mm', Colors.blue),
            const SizedBox(height: 8),
            _buildRegionItem('Gweru', '27°C', '60%', '3mm', Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionItem(
    String region,
    String temp,
    String humidity,
    String rain,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              region,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            '$temp • $humidity • $rain',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCropPerformanceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Crop Performance by Region',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildCropItem('Maize', 'Harare', '85%', Colors.green),
            const SizedBox(height: 8),
            _buildCropItem('Wheat', 'Bulawayo', '72%', Colors.orange),
            const SizedBox(height: 8),
            _buildCropItem('Tobacco', 'Mutare', '91%', Colors.blue),
            const SizedBox(height: 8),
            _buildCropItem('Cotton', 'Gweru', '68%', Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildCropItem(
    String crop,
    String region,
    String performance,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text('$crop in $region')),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            performance,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClimateIndicatorsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Climate Risk Indicators',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildIndicatorItem(
                    'Drought Risk',
                    'Medium',
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildIndicatorItem('Flood Risk', 'Low', Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildIndicatorItem('Heat Stress', 'High', Colors.red),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildIndicatorItem(
                    'Pest Risk',
                    'Medium',
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorItem(String label, String level, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              level,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Farmer Statistics',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildFarmerStat('Total Farmers', '156', Icons.people),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFarmerStat('Active Today', '89', Icons.person),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildFarmerStat(
                    'New This Month',
                    '12',
                    Icons.person_add,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFarmerStat('Need Support', '8', Icons.help),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmerStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFarmersList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recently Active Farmers',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFarmerItem(
              'John Moyo',
              'Harare',
              '2 hours ago',
              Icons.location_on,
            ),
            const SizedBox(height: 8),
            _buildFarmerItem(
              'Sarah Ncube',
              'Bulawayo',
              '4 hours ago',
              Icons.location_on,
            ),
            const SizedBox(height: 8),
            _buildFarmerItem(
              'Peter Mutasa',
              'Mutare',
              '6 hours ago',
              Icons.location_on,
            ),
            const SizedBox(height: 8),
            _buildFarmerItem(
              'Grace Sibanda',
              'Gweru',
              '1 day ago',
              Icons.location_on,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmerItem(
    String name,
    String location,
    String lastActive,
    IconData icon,
  ) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(name[0], style: const TextStyle(color: Colors.white)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                location,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Icon(icon, size: 16, color: Colors.green),
            Text(
              lastActive,
              style: TextStyle(color: Colors.grey[600], fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFarmerSupportCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Farmer Support Actions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _sendSupportMessage,
                    icon: const Icon(Icons.message),
                    label: const Text('Send Message'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _scheduleTraining,
                    icon: const Icon(Icons.school),
                    label: const Text('Schedule Training'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _viewFarmerReports,
                    icon: const Icon(Icons.assessment),
                    label: const Text('View Reports'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _provideAdvice,
                    icon: const Icon(Icons.lightbulb),
                    label: const Text('Give Advice'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportGenerationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generate Reports',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _generateWeatherReport,
                    icon: const Icon(Icons.wb_sunny),
                    label: const Text('Weather Report'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _generateFarmerReport,
                    icon: const Icon(Icons.people),
                    label: const Text('Farmer Report'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _generateCropReport,
                    icon: const Icon(Icons.agriculture),
                    label: const Text('Crop Report'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _generateSummaryReport,
                    icon: const Icon(Icons.summarize),
                    label: const Text('Summary Report'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoricalReportsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Reports',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildReportItem(
              'Monthly Weather Summary',
              'December 2024',
              Icons.wb_sunny,
            ),
            const SizedBox(height: 8),
            _buildReportItem(
              'Farmer Activity Report',
              'December 2024',
              Icons.people,
            ),
            const SizedBox(height: 8),
            _buildReportItem(
              'Crop Performance Analysis',
              'November 2024',
              Icons.agriculture,
            ),
            const SizedBox(height: 8),
            _buildReportItem(
              'Climate Risk Assessment',
              'November 2024',
              Icons.warning,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportItem(String title, String date, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14)),
              Text(
                date,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.download),
          onPressed: () => _downloadReport(title),
        ),
      ],
    );
  }

  Widget _buildExportOptionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Options',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _exportToPDF,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Export PDF'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _exportToExcel,
                    icon: const Icon(Icons.table_chart),
                    label: const Text('Export Excel'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _exportToCSV,
                    icon: const Icon(Icons.file_download),
                    label: const Text('Export CSV'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _shareReport,
                    icon: const Icon(Icons.share),
                    label: const Text('Share Report'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Action methods
  void _sendWeatherAlert() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Weather alert sent to all farmers')),
    );
  }

  void _generateReport() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Report generation started')));
  }

  void _viewFarmers() {
    _tabController.animateTo(2);
  }

  void _exportData() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Data export started')));
  }

  void _sendSupportMessage() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Support message sent')));
  }

  void _scheduleTraining() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Training session scheduled')));
  }

  void _viewFarmerReports() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Farmer reports loaded')));
  }

  void _provideAdvice() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Advice provided to farmers')));
  }

  void _generateWeatherReport() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Weather report generated')));
  }

  void _generateFarmerReport() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Farmer report generated')));
  }

  void _generateCropReport() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Crop report generated')));
  }

  void _generateSummaryReport() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Summary report generated')));
  }

  void _downloadReport(String reportName) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Downloading $reportName')));
  }

  void _exportToPDF() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Exporting to PDF')));
  }

  void _exportToExcel() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Exporting to Excel')));
  }

  void _exportToCSV() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Exporting to CSV')));
  }

  void _shareReport() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Sharing report')));
  }

  void _exportSupervisorReport() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Supervisor report exported')));
  }

  List<AgriculturalRecommendation> _generateSupervisorRecommendations() {
    return [
      AgriculturalRecommendation(
        id: 'supervisor_1',
        title: 'Monitor Drought Conditions in Bulawayo',
        description:
            'Low rainfall detected in Bulawayo region. Advise farmers on water conservation.',
        category: 'Drought Management',
        priority: 'High',
        date: DateTime.now(),
        location: 'Bulawayo',
        cropType: 'All Crops',
        actions: [
          'Send drought warning to affected farmers',
          'Provide water conservation guidelines',
          'Monitor soil moisture levels',
          'Consider emergency irrigation support',
        ],
        conditions: {'rainfall': 'Below average', 'humidity': 'Low'},
        createdAt: DateTime.now(),
      ),
      AgriculturalRecommendation(
        id: 'supervisor_2',
        title: 'High Temperature Alert for Harare',
        description:
            'Temperatures above 35°C expected. Provide heat stress management advice.',
        category: 'Temperature Management',
        priority: 'Medium',
        date: DateTime.now(),
        location: 'Harare',
        cropType: 'All Crops',
        actions: [
          'Send heat warning to farmers',
          'Advise on irrigation timing',
          'Recommend shade protection',
          'Monitor crop stress symptoms',
        ],
        conditions: {'temperature': 'Above 35°C', 'uv_index': 'High'},
        createdAt: DateTime.now(),
      ),
    ];
  }
}
