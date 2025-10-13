import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'logging_service.dart';

class ErrorHandlerService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void initialize() {
    // Set up global error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _logError('Flutter Error', details.exception, details.stack);
    };

    // Set up platform error handling
    PlatformDispatcher.instance.onError = (error, stack) {
      _logError('Platform Error', error, stack);
      return true;
    };
  }

  static void _logError(String type, Object error, StackTrace? stack) {
    LoggingService.logErrorWithContext(
      'Unhandled $type',
      error,
      stackTrace: stack,
      context: 'Global Error Handler',
    );
  }

  static void handleError(
    BuildContext context,
    Object error, {
    String? message,
    StackTrace? stackTrace,
    VoidCallback? onRetry,
    bool showSnackBar = true,
  }) {
    final errorMessage = message ?? _getErrorMessage(error);

    LoggingService.logErrorWithContext(
      'Handled Error',
      error,
      stackTrace: stackTrace,
      context: 'Error Handler',
      extra: {'user_message': errorMessage},
    );

    if (showSnackBar && context.mounted) {
      _showErrorSnackBar(context, errorMessage, onRetry);
    }
  }

  static void handleApiError(
    BuildContext context,
    Object error, {
    String? message,
    int? statusCode,
    VoidCallback? onRetry,
  }) {
    String errorMessage;

    if (statusCode != null) {
      switch (statusCode) {
        case 400:
          errorMessage = 'Invalid request. Please check your input.';
          break;
        case 401:
          errorMessage = 'Authentication failed. Please log in again.';
          break;
        case 403:
          errorMessage =
              'Access denied. You don\'t have permission to perform this action.';
          break;
        case 404:
          errorMessage = 'The requested resource was not found.';
          break;
        case 408:
          errorMessage =
              'Request timeout. Please check your internet connection.';
          break;
        case 429:
          errorMessage = 'Too many requests. Please try again later.';
          break;
        case 500:
          errorMessage = 'Server error. Please try again later.';
          break;
        case 502:
        case 503:
        case 504:
          errorMessage =
              'Service temporarily unavailable. Please try again later.';
          break;
        default:
          errorMessage = message ?? 'An error occurred. Please try again.';
      }
    } else {
      errorMessage = message ?? _getErrorMessage(error);
    }

    LoggingService.logErrorWithContext(
      'API Error',
      error,
      context: 'API Error Handler',
      extra: {'status_code': statusCode, 'user_message': errorMessage},
    );

    if (context.mounted) {
      _showErrorSnackBar(context, errorMessage, onRetry);
    }
  }

  static void handleNetworkError(
    BuildContext context,
    Object error, {
    VoidCallback? onRetry,
  }) {
    const errorMessage =
        'Network error. Please check your internet connection and try again.';

    LoggingService.logErrorWithContext(
      'Network Error',
      error,
      context: 'Network Error Handler',
      extra: {'user_message': errorMessage},
    );

    if (context.mounted) {
      _showErrorSnackBar(context, errorMessage, onRetry);
    }
  }

  static void handleFirebaseError(
    BuildContext context,
    Object error, {
    String? message,
    VoidCallback? onRetry,
  }) {
    final errorMessage = message ?? _getFirebaseErrorMessage(error);

    LoggingService.logErrorWithContext(
      'Firebase Error',
      error,
      context: 'Firebase Error Handler',
      extra: {'user_message': errorMessage},
    );

    if (context.mounted) {
      _showErrorSnackBar(context, errorMessage, onRetry);
    }
  }

  // Supabase removed

  static void _showErrorSnackBar(
    BuildContext context,
    String message,
    VoidCallback? onRetry,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Theme.of(context).colorScheme.onError,
                onPressed: onRetry,
              )
            : null,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  static String _getErrorMessage(Object error) {
    if (error.toString().contains('SocketException')) {
      return 'Network error. Please check your internet connection.';
    } else if (error.toString().contains('TimeoutException')) {
      return 'Request timeout. Please try again.';
    } else if (error.toString().contains('FormatException')) {
      return 'Data format error. Please try again.';
    } else if (error.toString().contains('NoSuchMethodError')) {
      return 'Application error. Please restart the app.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  static String _getFirebaseErrorMessage(Object error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network')) {
      return 'Network error. Please check your internet connection.';
    } else if (errorString.contains('permission')) {
      return 'Permission denied. Please check your account settings.';
    } else if (errorString.contains('not-found')) {
      return 'Data not found. Please try again.';
    } else if (errorString.contains('already-exists')) {
      return 'Data already exists. Please check your input.';
    } else if (errorString.contains('unavailable')) {
      return 'Service temporarily unavailable. Please try again later.';
    } else {
      return 'Firebase error. Please try again.';
    }
  }

  // Supabase removed

  static void showErrorDialog(
    BuildContext context,
    String title,
    String message, {
    VoidCallback? onRetry,
    VoidCallback? onCancel,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          if (onCancel != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onCancel();
              },
              child: const Text('Cancel'),
            ),
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void showCriticalErrorDialog(
    BuildContext context,
    String message, {
    VoidCallback? onRestart,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Critical Error'),
        content: Text(message),
        actions: [
          if (onRestart != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRestart();
              },
              child: const Text('Restart App'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              SystemNavigator.pop();
            },
            child: const Text('Exit App'),
          ),
        ],
      ),
    );
  }
}
