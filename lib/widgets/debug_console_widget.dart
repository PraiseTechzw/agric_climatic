import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/logging_service.dart';
// import '../services/performance_service.dart';
import '../services/environment_service.dart';
// import '../services/zimbabwe_api_service.dart';
// import '../services/firebase_ai_service.dart';
import '../services/ai_debug_service.dart';

class DebugConsoleWidget extends StatefulWidget {
  const DebugConsoleWidget({super.key});

  @override
  State<DebugConsoleWidget> createState() => _DebugConsoleWidgetState();
}

class _DebugConsoleWidgetState extends State<DebugConsoleWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _logScrollController = ScrollController();
  final TextEditingController _commandController = TextEditingController();

  List<LogEntry> _logs = [];
  Map<String, dynamic> _apiStatus = {};
  Map<String, dynamic> _performanceMetrics = {};
  Map<String, dynamic> _aiStatus = {};
  Map<String, dynamic> _aiDebugStatus = {};
  bool _isLoggingEnabled = true;
  String _selectedLogLevel = 'ALL';
  String _selectedService = 'ALL';

  Timer? _refreshTimer;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initializeDebugConsole();
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _logScrollController.dispose();
    _commandController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _initializeDebugConsole() {
    // Initialize with current system status
    _updateApiStatus();
    _updatePerformanceMetrics();
    _updateAiStatus();
    _updateAiDebugStatus();
    _loadRecentLogs();
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _updateApiStatus();
        _updatePerformanceMetrics();
        _updateAiStatus();
        _updateAiDebugStatus();
      }
    });
  }

  void _updateApiStatus() {
    setState(() {
      _apiStatus = {
        'open_meteo_forecast': 'https://api.open-meteo.com/v1/forecast',
        'open_meteo_archive': 'https://archive-api.open-meteo.com/v1/archive',
        'open_meteo_soil': 'https://api.open-meteo.com/v1/soil',
        'openepi_soil': 'https://api.openepi.io/soil/soil-properties',
        'firebase_ai': 'Firebase AI (Gemini)',
        'environment': EnvironmentService.currentEnvironment.name,
        'debug_mode': EnvironmentService.isDevelopment,
        'api_logging': EnvironmentService.enableApiLogging,
        'performance_logging': EnvironmentService.enablePerformanceLogging,
      };
    });
  }

  void _updatePerformanceMetrics() {
    setState(() {
      _performanceMetrics = {
        'memory_usage': _getMemoryUsage(),
        'active_timers': _getActiveTimers(),
        'slow_operations': _getSlowOperations(),
        'api_response_times': _getApiResponseTimes(),
        'cache_hit_rate': _getCacheHitRate(),
      };
    });
  }

  void _updateAiStatus() {
    setState(() {
      _aiStatus = {
        'firebase_ai_initialized': false, // Will be updated by actual check
        'ai_model': 'gemini-1.5-flash',
        'ai_requests_today': _getAiRequestCount(),
        'ai_error_rate': _getAiErrorRate(),
        'ai_response_time': _getAiResponseTime(),
      };
    });
  }

  void _updateAiDebugStatus() {
    setState(() {
      _aiDebugStatus = {
        'ai_debug_initialized': AIDebugService.instance
            .getServiceStats()['initialized'],
        'reported_issues': AIDebugService.instance
            .getServiceStats()['reported_issues_count'],
        'unresolved_issues': AIDebugService.instance
            .getServiceStats()['unresolved_issues_count'],
        'health_score': AIDebugService.instance
            .getServiceStats()['health_score'],
        'last_analysis': AIDebugService.instance
            .getServiceStats()['last_analysis_time'],
      };
    });
  }

  void _loadRecentLogs() {
    // Load actual logs from logging service
    setState(() {
      final logData = LoggingService.getRecentLogs(limit: 10);
      _logs = logData
          .map(
            (log) => LogEntry(
              timestamp: DateTime.parse(log['timestamp']),
              level: LogLevel.values.firstWhere(
                (level) => level.name == log['level'],
                orElse: () => LogLevel.info,
              ),
              service: log['service'] ?? 'Unknown',
              message: log['message'] ?? '',
              data: log['data'] ?? {},
            ),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!EnvironmentService.enableDebugMenu) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isExpanded ? 400 : 60,
      child: Card(
        margin: const EdgeInsets.all(8),
        child: Column(
          children: [_buildHeader(), if (_isExpanded) _buildExpandedContent()],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.bug_report,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Debug Console',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          _buildStatusIndicator(),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    final hasErrors = _logs.any(
      (log) => log.level == LogLevel.error || log.level == LogLevel.critical,
    );
    final hasWarnings = _logs.any((log) => log.level == LogLevel.warning);

    Color statusColor;
    IconData statusIcon;

    if (hasErrors) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
    } else if (hasWarnings) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    }

    return Icon(statusIcon, color: statusColor, size: 16);
  }

  Widget _buildExpandedContent() {
    return Expanded(
      child: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLogsTab(),
                _buildApiStatusTab(),
                _buildPerformanceTab(),
                _buildAiTab(),
                _buildAiDebugTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabs: const [
        Tab(text: 'Logs', icon: Icon(Icons.list, size: 16)),
        Tab(text: 'API Status', icon: Icon(Icons.api, size: 16)),
        Tab(text: 'Performance', icon: Icon(Icons.speed, size: 16)),
        Tab(text: 'AI Status', icon: Icon(Icons.psychology, size: 16)),
        Tab(text: 'AI Debug', icon: Icon(Icons.auto_fix_high, size: 16)),
      ],
    );
  }

  Widget _buildLogsTab() {
    return Column(
      children: [
        _buildLogControls(),
        Expanded(
          child: ListView.builder(
            controller: _logScrollController,
            itemCount: _logs.length,
            itemBuilder: (context, index) {
              final log = _logs[index];
              return _buildLogEntry(log);
            },
          ),
        ),
        _buildCommandInput(),
      ],
    );
  }

  Widget _buildLogControls() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          DropdownButton<String>(
            value: _selectedLogLevel,
            items: ['ALL', 'DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL']
                .map(
                  (level) => DropdownMenuItem(value: level, child: Text(level)),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedLogLevel = value!;
              });
            },
          ),
          const SizedBox(width: 16),
          DropdownButton<String>(
            value: _selectedService,
            items: ['ALL', 'API', 'AI', 'PERFORMANCE', 'USER', 'SYSTEM']
                .map(
                  (service) =>
                      DropdownMenuItem(value: service, child: Text(service)),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedService = value!;
              });
            },
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearLogs,
            tooltip: 'Clear logs',
          ),
          IconButton(
            icon: Icon(_isLoggingEnabled ? Icons.pause : Icons.play_arrow),
            onPressed: _toggleLogging,
            tooltip: _isLoggingEnabled ? 'Pause logging' : 'Resume logging',
          ),
        ],
      ),
    );
  }

  Widget _buildLogEntry(LogEntry log) {
    final filteredLogs = _logs.where((l) {
      final levelMatch =
          _selectedLogLevel == 'ALL' || l.level.name == _selectedLogLevel;
      final serviceMatch =
          _selectedService == 'ALL' || l.service == _selectedService;
      return levelMatch && serviceMatch;
    }).toList();

    if (!filteredLogs.contains(log)) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _getLogColor(log.level).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(width: 3, color: _getLogColor(log.level)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '[${log.timestamp.toString().substring(11, 19)}]',
                style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: _getLogColor(log.level),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  log.level.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '[${log.service}]',
                style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
              ),
              const Spacer(),
              if (log.data != null)
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 16),
                  onPressed: () => _showLogDetails(log),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(log.message, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCommandInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commandController,
              decoration: const InputDecoration(
                hintText: 'Enter debug command...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
              ),
              onSubmitted: _executeCommand,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => _executeCommand(_commandController.text),
          ),
        ],
      ),
    );
  }

  Widget _buildApiStatusTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'API Endpoints Status',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: _apiStatus.entries.map((entry) {
                return _buildStatusItem(entry.key, entry.value);
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _testAllApis,
            child: const Text('Test All APIs'),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Metrics',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: _performanceMetrics.entries.map((entry) {
                return _buildMetricItem(entry.key, entry.value);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Service Status',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: _aiStatus.entries.map((entry) {
                return _buildStatusItem(entry.key, entry.value);
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(
                onPressed: _testAiService,
                child: const Text('Test AI Service'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _generateAiInsights,
                child: const Text('Generate AI Insights'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiDebugTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI-Powered Debug Assistant',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildAiDebugStatusCard(),
                const SizedBox(height: 16),
                _buildAiDebugActionsCard(),
                const SizedBox(height: 16),
                _buildAiDebugRecommendationsCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiDebugStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_fix_high,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'AI Debug Status',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._aiDebugStatus.entries.map((entry) {
              return _buildStatusItem(entry.key, entry.value);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAiDebugActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.play_circle_outline,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'AI Debug Actions',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _analyzeSystemHealth,
                  icon: const Icon(Icons.health_and_safety, size: 16),
                  label: const Text('Analyze Health'),
                ),
                ElevatedButton.icon(
                  onPressed: _diagnoseIssues,
                  icon: const Icon(Icons.bug_report, size: 16),
                  label: const Text('Diagnose Issues'),
                ),
                ElevatedButton.icon(
                  onPressed: _getPerformanceRecommendations,
                  icon: const Icon(Icons.speed, size: 16),
                  label: const Text('Performance Tips'),
                ),
                ElevatedButton.icon(
                  onPressed: _generateTestScenarios,
                  icon: const Icon(Icons.science, size: 16),
                  label: const Text('Generate Tests'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiDebugRecommendationsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'AI Recommendations',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'AI-powered recommendations will appear here after running analysis.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String key, dynamic value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              key.replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              color: _getValueColor(value),
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String key, dynamic value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            key.replaceAll('_', ' ').toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          if (value is Map)
            ...value.entries.map(
              (e) => Text(
                '  ${e.key}: ${e.value}',
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            )
          else
            Text(
              value.toString(),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
        ],
      ),
    );
  }

  Color _getLogColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.blue;
      case LogLevel.info:
        return Colors.green;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.critical:
        return Colors.purple;
    }
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

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  void _toggleLogging() {
    setState(() {
      _isLoggingEnabled = !_isLoggingEnabled;
    });
  }

  void _executeCommand(String command) {
    if (command.trim().isEmpty) return;

    _commandController.clear();

    // Add command to logs
    setState(() {
      _logs.add(
        LogEntry(
          timestamp: DateTime.now(),
          level: LogLevel.info,
          service: 'CONSOLE',
          message: 'Executing: $command',
        ),
      );
    });

    // Execute command
    _processCommand(command);
  }

  void _processCommand(String command) {
    final parts = command.split(' ');
    final cmd = parts[0].toLowerCase();

    switch (cmd) {
      case 'clear':
        _clearLogs();
        break;
      case 'test':
        if (parts.length > 1) {
          _testSpecificApi(parts[1]);
        } else {
          _testAllApis();
        }
        break;
      case 'ai':
        _testAiService();
        break;
      case 'performance':
        _updatePerformanceMetrics();
        break;
      case 'help':
        _showHelp();
        break;
      default:
        _addLog(LogLevel.warning, 'CONSOLE', 'Unknown command: $cmd');
    }
  }

  void _testAllApis() {
    _addLog(LogLevel.info, 'API', 'Testing all API endpoints...');
    // Implement API testing logic
  }

  void _testSpecificApi(String api) {
    _addLog(LogLevel.info, 'API', 'Testing $api API...');
    // Implement specific API testing
  }

  void _testAiService() {
    _addLog(LogLevel.info, 'AI', 'Testing AI service...');
    // Implement AI service testing
  }

  void _generateAiInsights() {
    _addLog(LogLevel.info, 'AI', 'Generating AI insights...');
    // Implement AI insights generation
  }

  // AI Debug action methods
  Future<void> _analyzeSystemHealth() async {
    _addLog(LogLevel.info, 'AI_DEBUG', 'Analyzing system health...');

    try {
      final result = await AIDebugService.instance.analyzeSystemHealth();
      _addLog(
        LogLevel.info,
        'AI_DEBUG',
        'System health analysis completed',
        data: result,
      );

      // Show results in a dialog
      _showAnalysisResults('System Health Analysis', result);
    } catch (e) {
      _addLog(LogLevel.error, 'AI_DEBUG', 'System health analysis failed: $e');
    }
  }

  Future<void> _diagnoseIssues() async {
    _addLog(LogLevel.info, 'AI_DEBUG', 'Starting issue diagnosis...');

    // Show input dialog for issue description
    final issueDescription = await _showIssueInputDialog();
    if (issueDescription != null && issueDescription.isNotEmpty) {
      try {
        final result = await AIDebugService.instance.diagnoseIssue(
          issueDescription,
        );
        _addLog(
          LogLevel.info,
          'AI_DEBUG',
          'Issue diagnosis completed',
          data: result,
        );

        // Show results in a dialog
        _showAnalysisResults('Issue Diagnosis', result);
      } catch (e) {
        _addLog(LogLevel.error, 'AI_DEBUG', 'Issue diagnosis failed: $e');
      }
    }
  }

  Future<void> _getPerformanceRecommendations() async {
    _addLog(
      LogLevel.info,
      'AI_DEBUG',
      'Getting performance recommendations...',
    );

    try {
      final result = await AIDebugService.instance
          .getPerformanceRecommendations();
      _addLog(
        LogLevel.info,
        'AI_DEBUG',
        'Performance recommendations generated',
        data: result,
      );

      // Show results in a dialog
      _showAnalysisResults('Performance Recommendations', result);
    } catch (e) {
      _addLog(
        LogLevel.error,
        'AI_DEBUG',
        'Performance recommendations failed: $e',
      );
    }
  }

  Future<void> _generateTestScenarios() async {
    _addLog(LogLevel.info, 'AI_DEBUG', 'Generating test scenarios...');

    try {
      final scenarios = await AIDebugService.instance.generateTestScenarios();
      _addLog(
        LogLevel.info,
        'AI_DEBUG',
        'Test scenarios generated: ${scenarios.length} scenarios',
        data: {'count': scenarios.length},
      );

      // Show results in a dialog
      _showTestScenarios(scenarios);
    } catch (e) {
      _addLog(
        LogLevel.error,
        'AI_DEBUG',
        'Test scenario generation failed: $e',
      );
    }
  }

  Future<String?> _showIssueInputDialog() async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Describe the Issue'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Describe the issue you\'re experiencing...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Diagnose'),
          ),
        ],
      ),
    );
  }

  void _showAnalysisResults(String title, Map<String, dynamic> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (results['health_score'] != null)
                Text('Health Score: ${results['health_score']}%'),
              if (results['severity'] != null)
                Text('Severity: ${results['severity']}'),
              if (results['root_cause'] != null)
                Text('Root Cause: ${results['root_cause']}'),
              if (results['recommendations'] != null) ...[
                const SizedBox(height: 8),
                const Text(
                  'Recommendations:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...(results['recommendations'] as List).map(
                  (rec) => Text('• ${rec.toString()}'),
                ),
              ],
              if (results['immediate_steps'] != null) ...[
                const SizedBox(height: 8),
                const Text(
                  'Immediate Steps:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...(results['immediate_steps'] as List).map(
                  (step) => Text('• ${step.toString()}'),
                ),
              ],
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

  void _showTestScenarios(List<Map<String, dynamic>> scenarios) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Generated Test Scenarios (${scenarios.length})'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: scenarios.length,
            itemBuilder: (context, index) {
              final scenario = scenarios[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scenario['name'] ?? 'Unnamed Scenario',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (scenario['description'] != null)
                        Text(scenario['description']),
                      if (scenario['priority'] != null)
                        Text('Priority: ${scenario['priority']}'),
                      if (scenario['estimated_time'] != null)
                        Text('Time: ${scenario['estimated_time']}'),
                    ],
                  ),
                ),
              );
            },
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

  void _showLogDetails(LogEntry log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Log Details - ${log.level.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Timestamp: ${log.timestamp}'),
            Text('Service: ${log.service}'),
            Text('Message: ${log.message}'),
            if (log.data != null) ...[
              const SizedBox(height: 8),
              const Text(
                'Data:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                const JsonEncoder.withIndent('  ').convert(log.data),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ],
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

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Console Commands'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Available commands:'),
            SizedBox(height: 8),
            Text('• clear - Clear all logs'),
            Text('• test - Test all APIs'),
            Text('• test <api> - Test specific API'),
            Text('• ai - Test AI service'),
            Text('• performance - Update performance metrics'),
            Text('• help - Show this help'),
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

  void _addLog(
    LogLevel level,
    String service,
    String message, {
    Map<String, dynamic>? data,
  }) {
    setState(() {
      _logs.add(
        LogEntry(
          timestamp: DateTime.now(),
          level: level,
          service: service,
          message: message,
          data: data,
        ),
      );
    });

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Helper methods for performance metrics
  String _getMemoryUsage() {
    // Simulate memory usage
    return '${(DateTime.now().millisecondsSinceEpoch % 1000)} MB';
  }

  List<String> _getActiveTimers() {
    return ['weather_fetch', 'ai_processing', 'data_sync'];
  }

  List<String> _getSlowOperations() {
    return ['api_call_weather', 'ai_generation'];
  }

  Map<String, int> _getApiResponseTimes() {
    return {'weather': 1200, 'soil': 800, 'ai': 2500};
  }

  double _getCacheHitRate() {
    return 0.85;
  }

  int _getAiRequestCount() {
    return 42;
  }

  double _getAiErrorRate() {
    return 0.02;
  }

  String _getAiResponseTime() {
    return '2.3s';
  }
}

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String service;
  final String message;
  final Map<String, dynamic>? data;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.service,
    required this.message,
    this.data,
  });
}
