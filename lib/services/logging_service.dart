import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

class LoggingService {
  static const String _tag = 'AgriClimatic';
  
  static void log(
    String message, {
    LogLevel level = LogLevel.info,
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    final logTag = tag ?? _tag;
    final timestamp = DateTime.now().toIso8601String();
    final levelString = level.name.toUpperCase();
    
    final logMessage = '[$timestamp] [$levelString] [$logTag] $message';
    
    if (kDebugMode) {
      // In debug mode, use developer.log for better formatting
      developer.log(
        logMessage,
        name: logTag,
        level: _getLogLevelValue(level),
        error: error,
        stackTrace: stackTrace,
      );
      
      if (extra != null) {
        developer.log('Extra data: $extra', name: logTag);
      }
    } else {
      // In release mode, use print for basic logging
      print(logMessage);
      if (error != null) {
        print('Error: $error');
      }
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
      if (extra != null) {
        print('Extra data: $extra');
      }
    }
  }
  
  static void debug(String message, {String? tag, Map<String, dynamic>? extra}) {
    log(message, level: LogLevel.debug, tag: tag, extra: extra);
  }
  
  static void info(String message, {String? tag, Map<String, dynamic>? extra}) {
    log(message, level: LogLevel.info, tag: tag, extra: extra);
  }
  
  static void warning(String message, {String? tag, Object? error, Map<String, dynamic>? extra}) {
    log(message, level: LogLevel.warning, tag: tag, error: error, extra: extra);
  }
  
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace, Map<String, dynamic>? extra}) {
    log(message, level: LogLevel.error, tag: tag, error: error, stackTrace: stackTrace, extra: extra);
  }
  
  static void critical(String message, {String? tag, Object? error, StackTrace? stackTrace, Map<String, dynamic>? extra}) {
    log(message, level: LogLevel.critical, tag: tag, error: error, stackTrace: stackTrace, extra: extra);
  }
  
  static int _getLogLevelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.critical:
        return 1200;
    }
  }
  
  // Log API calls
  static void logApiCall(String method, String url, {Map<String, dynamic>? requestData, Map<String, dynamic>? responseData, int? statusCode, Duration? duration}) {
    final extra = <String, dynamic>{
      'method': method,
      'url': url,
      'duration_ms': duration?.inMilliseconds,
      'status_code': statusCode,
    };
    
    if (requestData != null) {
      extra['request_data'] = requestData;
    }
    
    if (responseData != null) {
      extra['response_data'] = responseData;
    }
    
    if (statusCode != null && statusCode >= 400) {
      error('API call failed', tag: 'API', extra: extra);
    } else {
      info('API call completed', tag: 'API', extra: extra);
    }
  }
  
  // Log user actions
  static void logUserAction(String action, {String? screen, Map<String, dynamic>? data}) {
    final extra = <String, dynamic>{
      'action': action,
      'screen': screen,
    };
    
    if (data != null) {
      extra.addAll(data);
    }
    
    info('User action: $action', tag: 'USER', extra: extra);
  }
  
  // Log performance metrics
  static void logPerformance(String operation, Duration duration, {Map<String, dynamic>? metrics}) {
    final extra = <String, dynamic>{
      'operation': operation,
      'duration_ms': duration.inMilliseconds,
    };
    
    if (metrics != null) {
      extra.addAll(metrics);
    }
    
    if (duration.inMilliseconds > 1000) {
      warning('Slow operation: $operation', tag: 'PERFORMANCE', extra: extra);
    } else {
      info('Operation completed: $operation', tag: 'PERFORMANCE', extra: extra);
    }
  }
  
  // Log errors with context
  static void logErrorWithContext(
    String message,
    Object error, {
    String? tag,
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? extra,
  }) {
    final errorExtra = <String, dynamic>{
      'error_type': error.runtimeType.toString(),
      'error_message': error.toString(),
      'context': context,
    };
    
    if (extra != null) {
      errorExtra.addAll(extra);
    }
    
    critical(message, tag: tag, error: error, stackTrace: stackTrace, extra: errorExtra);
  }
}
