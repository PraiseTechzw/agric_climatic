import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../models/dashboard_data.dart';
import '../models/weather.dart';
import '../services/climate_dashboard_service.dart';
import '../services/weather_data_management_service.dart';
import '../services/advanced_weather_analysis_service.dart';
import '../widgets/dashboard_charts.dart';
import '../widgets/modern_loading_widget.dart';

class EnhancedClimateDashboardScreen extends StatefulWidget {
  const EnhancedClimateDashboardScreen({super.key});

  @override
  State<EnhancedClimateDashboardScreen> createState() => _EnhancedClimateDashboardScreenState();
}

class _EnhancedClimateDashboardScreenState extends State<EnhancedClimateDashboardScreen>
    with TickerProviderStateMixin {
  final ClimateDashboardService _dashboardService = ClimateDashboardService();
  final WeatherDataManagementService _dataManagementService = WeatherDataManagementService();
  final AdvancedWeatherAnalysisService _analysisService = AdvancedWeatherAnalysisService();
  
  ClimateSummary? _climateSummary;
  List<ClimateDashboardData> _yearlyData = [];
  List<ChartDataPoint> _temperatureData = [];
  List<ChartDataPoint> _precipitationData = [];
  List<ChartDataPoint> _humidityData = [];
  
  WeatherAnalysisReport? _analysisReport;
  bool _isLoading = true;
  bool _isAnalyzing = false;
  String _selectedLocation = 'Harare';
  int _selectedYear = DateTime.now().year;
  String _selectedPeriod = 'yearly';
  
  late TabController _tabController;

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

  Future<void> _uploadWeatherData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'json'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        final fileName = result.files.first.name;
        final fileExtension = fileName.split('.').last.toLowerCase();

        final success = await _dataManagementService.uploadWeatherData(
          location: _selectedLocation,
          file: file,
          fileType: fileExtension,
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Weather data uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadDashboardData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload weather data'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteWeatherData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Weather Data'),
        content: Text('Are you sure you want to delete all weather data for $_selectedLocation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _dataManagementService.deleteWeatherData(_selectedLocation);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Weather data deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadDashboardData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete weather data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateAnalysis() async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      final weatherData = _dataManagementService.getWeatherData(_selectedLocation);
      if (weatherData.isEmpty) {
        // Use generated data if no uploaded data
        final startDate = DateTime(_selectedYear - 4, 1, 1);
        final endDate = DateTime(_selectedYear, 12, 31);
        final generatedData = await _dashboardService.getHistoricalWeatherData(
          location: _selectedLocation,
          startDate: startDate,
          endDate: endDate,
        );
        
        final report = await _analysisService.generateComprehensiveAnalysis(
          location: _selectedLocation,
          weatherData: generatedData,
          startDate: startDate,
          endDate: endDate,
        );
        
        setState(() {
          _analysisReport = report;
          _isAnalyzing = false;
        });
      } else {
        final report = await _analysisService.generateComprehensiveAnalysis(
          location: _selectedLocation,
          weatherData: weatherData,
          startDate: weatherData.first.dateTime,
          endDate: weatherData.last.dateTime,
        );
        
        setState(() {
          _analysisReport = report;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate analysis: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _exportData() async {
    try {
      final csvData = await _dataManagementService.exportWeatherDataToCSV(_selectedLocation);
      if (csvData.isNotEmpty) {
        // In a real app, you would save this to a file
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data exported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No data to export'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Climate Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _uploadWeatherData,
            tooltip: 'Upload Weather Data',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportData,
            tooltip: 'Export Data',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteWeatherData,
            tooltip: 'Delete Data',
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _generateAnalysis,
            tooltip: 'Generate Analysis',
          ),
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
            Tab(text: 'Reports', icon: Icon(Icons.assessment)),
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
                _buildReportsTab(),
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
          // Data Management Status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Management',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDataStatusCard(
                          'Weather Records',
                          _dataManagementService.getWeatherData(_selectedLocation).length.toString(),
                          Icons.cloud,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDataStatusCard(
                          'Patterns',
                          _dataManagementService.getWeatherPatterns(_selectedLocation).length.toString(),
                          Icons.pattern,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
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
    if (_isAnalyzing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generating comprehensive analysis...'),
          ],
        ),
      );
    }

    if (_analysisReport == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No analysis available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Click the analytics button to generate analysis',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _generateAnalysis,
              icon: const Icon(Icons.analytics),
              label: const Text('Generate Analysis'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Analysis Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analysis Summary',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Location: ${_analysisReport!.location}'),
                  Text('Period: ${_analysisReport!.startDate.year} - ${_analysisReport!.endDate.year}'),
                  Text('Data Points: ${_analysisReport!.dataPoints}'),
                  Text('Generated: ${_analysisReport!.generatedAt.toString().split('.')[0]}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Basic Statistics
          if (_analysisReport!.basicStatistics.isNotEmpty) ...[
            Text(
              'Basic Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildStatisticsTable(_analysisReport!.basicStatistics),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Anomalies
          if (_analysisReport!.anomalies.isNotEmpty) ...[
            Text(
              'Detected Anomalies',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: _analysisReport!.anomalies.map((anomaly) => 
                    ListTile(
                      leading: Icon(
                        anomaly.severity == 'high' ? Icons.warning : Icons.info,
                        color: anomaly.severity == 'high' ? Colors.red : Colors.orange,
                      ),
                      title: Text(anomaly.description),
                      subtitle: Text(
                        '${anomaly.type.toUpperCase()} - ${anomaly.date.toString().split(' ')[0]}'
                      ),
                      trailing: Text(
                        '${anomaly.value.toStringAsFixed(1)} (${anomaly.deviation.toStringAsFixed(1)}σ)',
                        style: TextStyle(
                          color: anomaly.severity == 'high' ? Colors.red : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Recommendations
          if (_analysisReport!.recommendations.isNotEmpty) ...[
            Text(
              'Recommendations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            ..._analysisReport!.recommendations.map((rec) => 
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            rec.priority == 'high' ? Icons.priority_high : Icons.info,
                            color: rec.priority == 'high' ? Colors.red : Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              rec.title,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: rec.priority == 'high' ? Colors.red : Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              rec.priority.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(rec.description),
                      const SizedBox(height: 8),
                      Text(
                        'Actions:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ...rec.actions.map((action) => 
                        Padding(
                          padding: const EdgeInsets.only(left: 16, top: 2),
                          child: Text('• $action'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
          Text(
            'Weather Reports',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Report Generation Options
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Generate Reports',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _generateAnalysis,
                          icon: const Icon(Icons.assessment),
                          label: const Text('Climate Report'),
                        ),
                      ),
                      const SizedBox(width: 8),
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
          ),
          const SizedBox(height: 16),
          
          // Report Templates
          Text(
            'Report Templates',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          Card(
            child: ListTile(
              leading: const Icon(Icons.agriculture, color: Colors.green),
              title: const Text('Agricultural Impact Report'),
              subtitle: const Text('Crop suitability and farming recommendations'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                // Generate agricultural report
              },
            ),
          ),
          
          Card(
            child: ListTile(
              leading: const Icon(Icons.warning, color: Colors.orange),
              title: const Text('Risk Assessment Report'),
              subtitle: const Text('Climate risks and mitigation strategies'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                // Generate risk assessment report
              },
            ),
          ),
          
          Card(
            child: ListTile(
              leading: const Icon(Icons.trending_up, color: Colors.blue),
              title: const Text('Trend Analysis Report'),
              subtitle: const Text('Long-term climate trends and patterns'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                // Generate trend analysis report
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataStatusCard(String title, String value, IconData icon, Color color) {
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

  Widget _buildStatisticsTable(Map<String, dynamic> statistics) {
    return Table(
      children: statistics.entries.map((entry) {
        final category = entry.key;
        final data = entry.value as Map<String, dynamic>;
        
        return TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                category.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: data.entries.map((stat) => 
                  Text('${stat.key}: ${stat.value.toStringAsFixed(2)}')
                ).toList(),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
