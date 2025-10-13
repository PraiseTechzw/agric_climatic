import 'package:flutter/material.dart';
import '../widgets/debug_console_widget.dart';
import '../services/environment_service.dart';
import '../services/logging_service.dart';
import '../services/performance_service.dart';
import '../services/firebase_ai_service.dart';
import '../services/zimbabwe_api_service.dart';
import '../services/network_service.dart';
import '../services/auth_test_service.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  bool _isInitialized = false;
  Map<String, dynamic> _systemInfo = {};
  final Map<String, dynamic> _apiTestResults = {};
  bool _isTestingApis = false;

  @override
  void initState() {
    super.initState();
    _initializeDebugScreen();
  }

  Future<void> _initializeDebugScreen() async {
    if (_isInitialized) return;

    try {
      LoggingService.info('Initializing debug screen...', tag: 'DEBUG');

      // Initialize performance service
      await PerformanceService.initialize();

      // Initialize AI service
      try {
        await FirebaseAIService.instance.initialize();
        LoggingService.info(
          'AI service initialized successfully',
          tag: 'DEBUG',
        );
      } catch (e) {
        LoggingService.warning(
          'AI service initialization failed: $e',
          tag: 'DEBUG',
        );
      }

      // Gather system information
      _gatherSystemInfo();

      setState(() {
        _isInitialized = true;
      });

      LoggingService.info(
        'Debug screen initialized successfully',
        tag: 'DEBUG',
      );
    } catch (e) {
      LoggingService.error(
        'Failed to initialize debug screen',
        tag: 'DEBUG',
        error: e,
      );
    }
  }

  void _gatherSystemInfo() {
    setState(() {
      _systemInfo = {
        'app_version': EnvironmentService.appVersion,
        'build_number': EnvironmentService.appBuildNumber,
        'environment': EnvironmentService.currentEnvironment.name,
        'debug_mode': EnvironmentService.isDevelopment,
        'api_logging_enabled': EnvironmentService.enableApiLogging,
        'performance_logging_enabled':
            EnvironmentService.enablePerformanceLogging,
        'zimbabwe_features_enabled':
            EnvironmentService.enableZimbabweWeatherData,
        'ai_service_initialized': FirebaseAIService.instance
            .getServiceStats()['initialized'],
        'timestamp': DateTime.now().toIso8601String(),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!EnvironmentService.enableDebugMenu) {
      return Scaffold(
        appBar: AppBar(title: const Text('Debug Console')),
        body: const Center(
          child: Text(
            'Debug console is only available in development mode',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Console'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDebugInfo,
            tooltip: 'Refresh debug information',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showDebugSettings,
            tooltip: 'Debug settings',
          ),
        ],
      ),
      body: _isInitialized
          ? _buildDebugContent()
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing debug console...'),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _runAllTests,
        icon: _isTestingApis
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.play_arrow),
        label: Text(_isTestingApis ? 'Testing...' : 'Run All Tests'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildDebugContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSystemInfoCard(),
          const SizedBox(height: 16),
          _buildAuthTestCard(),
          const SizedBox(height: 16),
          _buildApiTestCard(),
          const SizedBox(height: 16),
          _buildDebugConsoleCard(),
          const SizedBox(height: 16),
          _buildQuickActionsCard(),
        ],
      ),
    );
  }

  Widget _buildSystemInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'System Information',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._systemInfo.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      entry.value.toString(),
                      style: TextStyle(
                        color: _getValueColor(entry.value),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthTestCard() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.security, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Authentication Status',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _testAuthentication,
                      child: const Text('Test Auth'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildAuthStatusRow('Authenticated', authProvider.isAuthenticated),
                _buildAuthStatusRow('Anonymous', authProvider.isAnonymous),
                _buildAuthStatusRow('Loading', authProvider.isLoading),
                if (authProvider.user != null) ...[
                  _buildAuthStatusRow('User ID', authProvider.user!.uid),
                  _buildAuthStatusRow('Email', authProvider.user!.email ?? 'N/A'),
                  _buildAuthStatusRow('Email Verified', authProvider.user!.emailVerified),
                ],
                if (authProvider.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Error: ${authProvider.errorMessage}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAuthStatusRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getAuthValueColor(value),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value.toString(),
              style: TextStyle(
                color: _getAuthTextColor(value),
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getAuthValueColor(dynamic value) {
    if (value is bool) {
      return value ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2);
    }
    return Colors.blue.withOpacity(0.2);
  }

  Color _getAuthTextColor(dynamic value) {
    if (value is bool) {
      return value ? Colors.green[700]! : Colors.red[700]!;
    }
    return Colors.blue[700]!;
  }

  Future<void> _testAuthentication() async {
    try {
      LoggingService.info('Starting authentication test...', tag: 'DEBUG');
      final result = await AuthTestService.testAuthentication();
      
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication test passed!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication test failed!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      LoggingService.error('Authentication test error: $e', tag: 'DEBUG');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Authentication test error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildApiTestCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.api, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'API Test Results',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isTestingApis ? null : _testAllApis,
                  child: _isTestingApis
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Test APIs'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_apiTestResults.isEmpty)
              const Text('No API tests run yet. Click "Test APIs" to start.')
            else
              ..._apiTestResults.entries.map((entry) {
                return _buildApiTestResult(entry.key, entry.value);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildApiTestResult(String apiName, Map<String, dynamic> result) {
    final isSuccess = result['status'] == 'success';
    final responseTime = result['response_time_ms'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSuccess
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSuccess ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                apiName.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${responseTime}ms',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ],
          ),
          if (result['error'] != null) ...[
            const SizedBox(height: 4),
            Text(
              'Error: ${result['error']}',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDebugConsoleCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.terminal, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Debug Console',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const DebugConsoleWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickActionButton(
                  'Test Network',
                  Icons.wifi,
                  () => _testSpecificApi('network'),
                ),
                _buildQuickActionButton(
                  'Test Weather API',
                  Icons.wb_sunny,
                  () => _testSpecificApi('weather'),
                ),
                _buildQuickActionButton(
                  'Test Soil API',
                  Icons.terrain,
                  () => _testSpecificApi('soil'),
                ),
                _buildQuickActionButton(
                  'Test AI Service',
                  Icons.psychology,
                  () => _testSpecificApi('ai'),
                ),
                _buildQuickActionButton(
                  'Clear Logs',
                  Icons.clear_all,
                  () => _clearAllLogs(),
                ),
                _buildQuickActionButton(
                  'Export Logs',
                  Icons.download,
                  () => _exportLogs(),
                ),
                _buildQuickActionButton(
                  'Performance Report',
                  Icons.analytics,
                  () => _showPerformanceReport(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Color _getValueColor(dynamic value) {
    if (value is bool) {
      return value ? Colors.green : Colors.red;
    }
    if (value is String && value.contains('error')) {
      return Colors.red;
    }
    return Colors.black;
  }

  Future<void> _refreshDebugInfo() async {
    setState(() {
      _isInitialized = false;
    });

    await _initializeDebugScreen();
  }

  Future<void> _testAllApis() async {
    setState(() {
      _isTestingApis = true;
      _apiTestResults.clear();
    });

    try {
      LoggingService.info('Starting API tests...', tag: 'DEBUG');

      // Test Network Connectivity
      await _testNetworkConnectivity();

      // Test Weather API
      await _testWeatherApi();

      // Test Soil API
      await _testSoilApi();

      // Test AI Service
      await _testAiService();

      LoggingService.info('All API tests completed', tag: 'DEBUG');
    } catch (e) {
      LoggingService.error('API testing failed', tag: 'DEBUG', error: e);
    } finally {
      setState(() {
        _isTestingApis = false;
      });
    }
  }

  Future<void> _testNetworkConnectivity() async {
    final stopwatch = Stopwatch()..start();

    try {
      final networkInfo = await NetworkService.getNetworkInfo();
      stopwatch.stop();

      setState(() {
        _apiTestResults['network'] = {
          'status': 'success',
          'response_time_ms': stopwatch.elapsedMilliseconds,
          'has_internet': networkInfo['has_internet'],
          'connectivity_status': networkInfo['connectivity_status'],
          'is_wifi': networkInfo['is_wifi'],
          'is_mobile': networkInfo['is_mobile'],
          'timestamp': DateTime.now().toIso8601String(),
        };
      });

      LoggingService.info('Network connectivity test successful', tag: 'DEBUG');
    } catch (e) {
      stopwatch.stop();

      setState(() {
        _apiTestResults['network'] = {
          'status': 'error',
          'response_time_ms': stopwatch.elapsedMilliseconds,
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        };
      });

      LoggingService.error(
        'Network connectivity test failed',
        tag: 'DEBUG',
        error: e,
      );
    }
  }

  Future<void> _testWeatherApi() async {
    final stopwatch = Stopwatch()..start();

    try {
      await ZimbabweApiService.getCurrentWeather('Harare');
      stopwatch.stop();

      setState(() {
        _apiTestResults['weather'] = {
          'status': 'success',
          'response_time_ms': stopwatch.elapsedMilliseconds,
          'timestamp': DateTime.now().toIso8601String(),
        };
      });

      LoggingService.info('Weather API test successful', tag: 'DEBUG');
    } catch (e) {
      stopwatch.stop();

      setState(() {
        _apiTestResults['weather'] = {
          'status': 'error',
          'response_time_ms': stopwatch.elapsedMilliseconds,
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        };
      });

      LoggingService.error('Weather API test failed', tag: 'DEBUG', error: e);
    }
  }

  Future<void> _testSoilApi() async {
    final stopwatch = Stopwatch()..start();

    try {
      await ZimbabweApiService.getZimbabweSoilData('Harare');
      stopwatch.stop();

      setState(() {
        _apiTestResults['soil'] = {
          'status': 'success',
          'response_time_ms': stopwatch.elapsedMilliseconds,
          'timestamp': DateTime.now().toIso8601String(),
        };
      });

      LoggingService.info('Soil API test successful', tag: 'DEBUG');
    } catch (e) {
      stopwatch.stop();

      setState(() {
        _apiTestResults['soil'] = {
          'status': 'error',
          'response_time_ms': stopwatch.elapsedMilliseconds,
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        };
      });

      LoggingService.error('Soil API test failed', tag: 'DEBUG', error: e);
    }
  }

  Future<void> _testAiService() async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await FirebaseAIService.instance.testService();
      stopwatch.stop();

      setState(() {
        _apiTestResults['ai'] = {
          'status': result['status'],
          'response_time_ms': stopwatch.elapsedMilliseconds,
          'response': result['response'],
          'timestamp': DateTime.now().toIso8601String(),
        };
      });

      LoggingService.info('AI service test successful', tag: 'DEBUG');
    } catch (e) {
      stopwatch.stop();

      setState(() {
        _apiTestResults['ai'] = {
          'status': 'error',
          'response_time_ms': stopwatch.elapsedMilliseconds,
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        };
      });

      LoggingService.error('AI service test failed', tag: 'DEBUG', error: e);
    }
  }

  Future<void> _testSpecificApi(String apiName) async {
    switch (apiName.toLowerCase()) {
      case 'network':
        await _testNetworkConnectivity();
        break;
      case 'weather':
        await _testWeatherApi();
        break;
      case 'soil':
        await _testSoilApi();
        break;
      case 'ai':
        await _testAiService();
        break;
    }
  }

  Future<void> _runAllTests() async {
    await _testAllApis();

    // Show completion dialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Tests Completed'),
          content: Text(
            'API tests completed. Check the results above.\n\n'
            'Successful: ${_apiTestResults.values.where((r) => r['status'] == 'success').length}\n'
            'Failed: ${_apiTestResults.values.where((r) => r['status'] == 'error').length}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _clearAllLogs() {
    LoggingService.clearLogs();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All logs cleared'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _exportLogs() {
    // In a real implementation, you would export logs to a file
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Log export feature coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showPerformanceReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Performance Report'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Performance metrics are being collected...'),
              const SizedBox(height: 16),
              const Text(
                'This feature will show detailed performance analytics including:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• API response times'),
              const Text('• Memory usage patterns'),
              const Text('• Slow operations'),
              const Text('• Cache hit rates'),
              const Text('• Error rates'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDebugSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Debug settings are configured in EnvironmentService.'),
            const SizedBox(height: 16),
            const Text('Current settings:'),
            Text('• Debug Menu: ${EnvironmentService.enableDebugMenu}'),
            Text('• API Logging: ${EnvironmentService.enableApiLogging}'),
            Text(
              '• Performance Logging: ${EnvironmentService.enablePerformanceLogging}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
