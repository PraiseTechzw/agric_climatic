import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'logging_service.dart';
import 'environment_service.dart';

class PerformanceService {
  static final Map<String, Stopwatch> _timers = {};
  static final Map<String, List<Duration>> _performanceMetrics = {};
  static final List<PerformanceEvent> _events = [];
  static Timer? _metricsTimer;
  static bool _isInitialized = false;
  
  // Performance thresholds
  static const Duration _slowOperationThreshold = Duration(milliseconds: 1000);
  static const Duration _verySlowOperationThreshold = Duration(milliseconds: 3000);
  static const int _maxEvents = 1000;
  static const Duration _metricsInterval = Duration(minutes: 5);
  
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Start metrics collection timer
      _metricsTimer = Timer.periodic(_metricsInterval, (_) {
        _collectMetrics();
      });
      
      _isInitialized = true;
      LoggingService.info('Performance service initialized');
    } catch (e) {
      LoggingService.error('Failed to initialize performance service', error: e);
    }
  }
  
  static void dispose() {
    _metricsTimer?.cancel();
    _timers.clear();
    _performanceMetrics.clear();
    _events.clear();
    _isInitialized = false;
  }
  
  // Start timing an operation
  static void startTimer(String operation) {
    if (!EnvironmentService.enablePerformanceLogging) return;
    
    _timers[operation] = Stopwatch()..start();
    LoggingService.debug('Started timer for operation: $operation');
  }
  
  // Stop timing an operation
  static Duration? stopTimer(String operation) {
    if (!EnvironmentService.enablePerformanceLogging) return null;
    
    final timer = _timers.remove(operation);
    if (timer == null) return null;
    
    timer.stop();
    final duration = timer.elapsed;
    
    // Record the performance metric
    _recordPerformanceMetric(operation, duration);
    
    // Log performance
    _logPerformance(operation, duration);
    
    return duration;
  }
  
  // Record a performance metric
  static void _recordPerformanceMetric(String operation, Duration duration) {
    _performanceMetrics.putIfAbsent(operation, () => []);
    _performanceMetrics[operation]!.add(duration);
    
    // Keep only the last 100 measurements per operation
    if (_performanceMetrics[operation]!.length > 100) {
      _performanceMetrics[operation]!.removeAt(0);
    }
  }
  
  // Log performance information
  static void _logPerformance(String operation, Duration duration) {
    if (duration > _verySlowOperationThreshold) {
      LoggingService.warning('Very slow operation: $operation took ${duration.inMilliseconds}ms');
    } else if (duration > _slowOperationThreshold) {
      LoggingService.warning('Slow operation: $operation took ${duration.inMilliseconds}ms');
    } else {
      LoggingService.debug('Operation completed: $operation took ${duration.inMilliseconds}ms');
    }
  }
  
  // Record a performance event
  static void recordEvent(String event, {Map<String, dynamic>? data}) {
    if (!EnvironmentService.enablePerformanceLogging) return;
    
    final performanceEvent = PerformanceEvent(
      event: event,
      timestamp: DateTime.now(),
      data: data ?? {},
    );
    
    _events.add(performanceEvent);
    
    // Keep only the last N events
    if (_events.length > _maxEvents) {
      _events.removeAt(0);
    }
    
    LoggingService.debug('Performance event recorded: $event', extra: data);
  }
  
  // Get performance metrics for an operation
  static PerformanceMetrics? getMetrics(String operation) {
    final durations = _performanceMetrics[operation];
    if (durations == null || durations.isEmpty) return null;
    
    durations.sort();
    
    return PerformanceMetrics(
      operation: operation,
      count: durations.length,
      min: durations.first,
      max: durations.last,
      average: Duration(
        milliseconds: (durations.map((d) => d.inMilliseconds).reduce((a, b) => a + b) / durations.length).round(),
      ),
      median: durations[durations.length ~/ 2],
      p95: durations[(durations.length * 0.95).round() - 1],
      p99: durations[(durations.length * 0.99).round() - 1],
    );
  }
  
  // Get all performance metrics
  static Map<String, PerformanceMetrics> getAllMetrics() {
    final metrics = <String, PerformanceMetrics>{};
    
    for (final operation in _performanceMetrics.keys) {
      final operationMetrics = getMetrics(operation);
      if (operationMetrics != null) {
        metrics[operation] = operationMetrics;
      }
    }
    
    return metrics;
  }
  
  // Get performance events
  static List<PerformanceEvent> getEvents({String? event, int? limit}) {
    var events = _events;
    
    if (event != null) {
      events = events.where((e) => e.event == event).toList();
    }
    
    if (limit != null && limit > 0) {
      events = events.take(limit).toList();
    }
    
    return events;
  }
  
  // Collect and log metrics
  static void _collectMetrics() {
    if (!EnvironmentService.enablePerformanceLogging) return;
    
    final metrics = getAllMetrics();
    if (metrics.isEmpty) return;
    
    LoggingService.info('Performance metrics collected', extra: {
      'operation_count': metrics.length,
      'total_events': _events.length,
    });
    
    // Log slow operations
    for (final entry in metrics.entries) {
      final operation = entry.key;
      final metric = entry.value;
      
      if (metric.average > _slowOperationThreshold) {
        LoggingService.warning('Slow operation detected', extra: {
          'operation': operation,
          'average_duration_ms': metric.average.inMilliseconds,
          'max_duration_ms': metric.max.inMilliseconds,
          'count': metric.count,
        });
      }
    }
  }
  
  // Clear all metrics
  static void clearMetrics() {
    _timers.clear();
    _performanceMetrics.clear();
    _events.clear();
    LoggingService.info('Performance metrics cleared');
  }
  
  // Get memory usage
  static Future<MemoryUsage> getMemoryUsage() async {
    try {
      // This is a simplified memory usage calculation
      // In a real implementation, you would use platform-specific APIs
      final runtime = ProcessInfo.currentRss;
      
      return MemoryUsage(
        used: runtime,
        available: 0, // Would need platform-specific implementation
        total: 0, // Would need platform-specific implementation
      );
    } catch (e) {
      LoggingService.error('Failed to get memory usage', error: e);
      return MemoryUsage(used: 0, available: 0, total: 0);
    }
  }
  
  // Monitor memory usage
  static void startMemoryMonitoring() {
    if (!EnvironmentService.enablePerformanceLogging) return;
    
    Timer.periodic(const Duration(minutes: 1), (_) async {
      final memoryUsage = await getMemoryUsage();
      
      if (memoryUsage.used > 100 * 1024 * 1024) { // 100MB
        LoggingService.warning('High memory usage detected', extra: {
          'used_mb': memoryUsage.used / (1024 * 1024),
        });
      }
    });
  }
  
  // Optimize performance
  static void optimizePerformance() {
    // Clear old events
    if (_events.length > _maxEvents * 0.8) {
      final toRemove = _events.length - (_maxEvents * 0.5).round();
      _events.removeRange(0, toRemove);
    }
    
    // Clear old metrics
    for (final operation in _performanceMetrics.keys) {
      final durations = _performanceMetrics[operation]!;
      if (durations.length > 50) {
        durations.removeRange(0, durations.length - 50);
      }
    }
    
    LoggingService.info('Performance optimization completed');
  }
}

// Performance event class
class PerformanceEvent {
  final String event;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  
  PerformanceEvent({
    required this.event,
    required this.timestamp,
    required this.data,
  });
  
  Map<String, dynamic> toJson() => {
    'event': event,
    'timestamp': timestamp.toIso8601String(),
    'data': data,
  };
}

// Performance metrics class
class PerformanceMetrics {
  final String operation;
  final int count;
  final Duration min;
  final Duration max;
  final Duration average;
  final Duration median;
  final Duration p95;
  final Duration p99;
  
  PerformanceMetrics({
    required this.operation,
    required this.count,
    required this.min,
    required this.max,
    required this.average,
    required this.median,
    required this.p95,
    required this.p99,
  });
  
  Map<String, dynamic> toJson() => {
    'operation': operation,
    'count': count,
    'min_ms': min.inMilliseconds,
    'max_ms': max.inMilliseconds,
    'average_ms': average.inMilliseconds,
    'median_ms': median.inMilliseconds,
    'p95_ms': p95.inMilliseconds,
    'p99_ms': p99.inMilliseconds,
  };
}

// Memory usage class
class MemoryUsage {
  final int used;
  final int available;
  final int total;
  
  MemoryUsage({
    required this.used,
    required this.available,
    required this.total,
  });
  
  Map<String, dynamic> toJson() => {
    'used': used,
    'available': available,
    'total': total,
  };
}
