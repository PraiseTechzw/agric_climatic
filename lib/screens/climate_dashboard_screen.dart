import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import '../services/climate_dashboard_service.dart';
import '../widgets/dashboard_charts.dart';

class ClimateDashboardScreen extends StatefulWidget {
  const ClimateDashboardScreen({super.key});

  @override
  State<ClimateDashboardScreen> createState() => _ClimateDashboardScreenState();
}

class _ClimateDashboardScreenState extends State<ClimateDashboardScreen>
    with TickerProviderStateMixin {
  final ClimateDashboardService _dashboardService = ClimateDashboardService();
  
  ClimateSummary? _climateSummary;
  List<ClimateDashboardData> _yearlyData = [];
  List<ChartDataPoint> _temperatureData = [];
  List<ChartDataPoint> _precipitationData = [];
  List<ChartDataPoint> _humidityData = [];
  
  bool _isLoading = true;
  String _selectedLocation = 'Harare';
  int _selectedYear = DateTime.now().year;
  String _selectedPeriod = 'yearly';
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load climate summary
      final summary = await _dashboardService.getClimateSummary(
        location: _selectedLocation,
        yearsBack: 5,
      );

      // Load yearly data
      final yearlyData = await _dashboardService.getYearlyClimateData(
        location: _selectedLocation,
        yearsBack: 5,
      );


      // Load chart data
      final startDate = DateTime(_selectedYear - 4, 1, 1);
      final endDate = DateTime(_selectedYear, 12, 31);

      final temperatureData = await _dashboardService.getChartData(
        location: _selectedLocation,
        startDate: startDate,
        endDate: endDate,
        metric: 'temperature',
        period: _selectedPeriod,
      );

      final precipitationData = await _dashboardService.getChartData(
        location: _selectedLocation,
        startDate: startDate,
        endDate: endDate,
        metric: 'precipitation',
        period: _selectedPeriod,
      );

      final humidityData = await _dashboardService.getChartData(
        location: _selectedLocation,
        startDate: startDate,
        endDate: endDate,
        metric: 'humidity',
        period: _selectedPeriod,
      );

      setState(() {
        _climateSummary = summary;
        _yearlyData = yearlyData;
        _temperatureData = temperatureData;
        _precipitationData = precipitationData;
        _humidityData = humidityData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load dashboard data: $e'),
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
        title: const Text('Climate Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
          PopupMenuButton<String>(
            onSelected: (location) {
              setState(() {
                _selectedLocation = location;
              });
              _loadDashboardData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Harare', child: Text('Harare')),
              const PopupMenuItem(value: 'Bulawayo', child: Text('Bulawayo')),
              const PopupMenuItem(value: 'Gweru', child: Text('Gweru')),
              const PopupMenuItem(value: 'Mutare', child: Text('Mutare')),
              const PopupMenuItem(value: 'Kwekwe', child: Text('Kwekwe')),
            ],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on),
                  const SizedBox(width: 4),
                  Text(_selectedLocation),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Trends', icon: Icon(Icons.trending_up)),
            Tab(text: 'Analysis', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildTrendsTab(),
                _buildAnalysisTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    if (_climateSummary == null) {
      return const Center(child: Text('No data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Text(
            'Climate Summary (${_climateSummary!.startDate.year} - ${_climateSummary!.endDate.year})',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              SummaryCard(
                title: 'Average Temperature',
                value: _climateSummary!.overallAverageTemperature.toStringAsFixed(1),
                unit: '°C',
                icon: Icons.thermostat,
                color: Colors.orange,
                subtitle: 'Range: ${_climateSummary!.lowestTemperature.toStringAsFixed(1)}°C - ${_climateSummary!.highestTemperature.toStringAsFixed(1)}°C',
              ),
              SummaryCard(
                title: 'Total Precipitation',
                value: _climateSummary!.totalPrecipitation.toStringAsFixed(0),
                unit: 'mm',
                icon: Icons.water_drop,
                color: Colors.blue,
                subtitle: '${_climateSummary!.totalRainyDays} rainy days',
              ),
              SummaryCard(
                title: 'Average Humidity',
                value: _climateSummary!.overallAverageHumidity.toStringAsFixed(1),
                unit: '%',
                icon: Icons.water_drop,
                color: Colors.cyan,
              ),
              SummaryCard(
                title: 'Climate Trends',
                value: _climateSummary!.yearlyTrends.isNotEmpty ? 'Active' : 'Stable',
                unit: '',
                icon: Icons.trending_up,
                color: Colors.green,
                subtitle: _climateSummary!.climateAnomalies.isNotEmpty 
                    ? '${_climateSummary!.climateAnomalies.length} anomalies detected'
                    : 'No significant anomalies',
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Climate Summary Text
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Climate Summary',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _climateSummary!.climateSummary,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          
          if (_climateSummary!.climateAnomalies.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Climate Anomalies',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._climateSummary!.climateAnomalies.map((anomaly) => 
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.red, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(anomaly)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Selector
          Row(
            children: [
              Text(
                'Analysis Period:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _selectedPeriod,
                onChanged: (value) {
                  setState(() {
                    _selectedPeriod = value!;
                  });
                  _loadDashboardData();
                },
                items: const [
                  DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                ],
              ),
              const SizedBox(width: 16),
              DropdownButton<int>(
                value: _selectedYear,
                onChanged: (value) {
                  setState(() {
                    _selectedYear = value!;
                  });
                  _loadDashboardData();
                },
                items: List.generate(5, (index) {
                  final year = DateTime.now().year - index;
                  return DropdownMenuItem(value: year, child: Text(year.toString()));
                }),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Temperature Chart
          TemperatureLineChart(
            dataPoints: _temperatureData,
            title: 'Temperature Trends ($_selectedPeriod)',
          ),
          const SizedBox(height: 16),
          
          // Precipitation Chart
          PrecipitationBarChart(
            dataPoints: _precipitationData,
            title: 'Precipitation Trends ($_selectedPeriod)',
          ),
          const SizedBox(height: 16),
          
          // Humidity Chart
          HumidityLineChart(
            dataPoints: _humidityData,
            title: 'Humidity Trends ($_selectedPeriod)',
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisTab() {
    if (_yearlyData.isEmpty) {
      return const Center(child: Text('No yearly data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Yearly Climate Analysis',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Yearly Data Cards
          ..._yearlyData.map((yearData) => Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        yearData.date.year.toString(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (yearData.trends.isNotEmpty)
                        ClimateTrendIndicator(
                          label: 'Temp',
                          trend: yearData.trends['temperature_trend'] ?? 0.0,
                          unit: '°C/year',
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Temperature',
                          '${yearData.averageTemperature.toStringAsFixed(1)}°C',
                          Icons.thermostat,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricCard(
                          'Precipitation',
                          '${yearData.totalPrecipitation.toStringAsFixed(0)}mm',
                          Icons.water_drop,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Humidity',
                          '${yearData.averageHumidity.toStringAsFixed(1)}%',
                          Icons.water_drop,
                          Colors.cyan,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMetricCard(
                          'Rainy Days',
                          '${yearData.rainyDays}',
                          Icons.cloudy_snowing,
                          Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  if (yearData.anomalies.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Anomalies:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    ...yearData.anomalies.map((anomaly) => 
                      Text(
                        '• $anomaly',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
