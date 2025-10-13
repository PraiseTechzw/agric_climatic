import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'logging_service.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  static const Duration _timeout = Duration(seconds: 30);
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  // Cache for internet connection check
  static bool? _cachedInternetStatus;
  static DateTime? _lastInternetCheckTime;
  static const Duration _cacheValidDuration = Duration(seconds: 30);

  /// Get a configured HTTP client with proper timeouts and headers
  static http.Client getHttpClient() {
    return http.Client();
  }

  /// Make an HTTP GET request with retry logic
  static Future<http.Response> get(
    String url, {
    Map<String, String>? headers,
    int? maxRetries,
  }) async {
    final retries = maxRetries ?? _maxRetries;
    Exception? lastException;

    for (int attempt = 0; attempt < retries; attempt++) {
      try {
        LoggingService.info(
          'Making HTTP GET request',
          extra: {'url': url, 'attempt': attempt + 1, 'max_retries': retries},
        );

        final client = getHttpClient();
        final response = await client
            .get(Uri.parse(url), headers: _getDefaultHeaders(headers))
            .timeout(_timeout);

        client.close();

        LoggingService.info(
          'HTTP GET request completed',
          extra: {
            'url': url,
            'status_code': response.statusCode,
            'attempt': attempt + 1,
          },
        );

        return response;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        LoggingService.warning(
          'HTTP GET request failed',
          extra: {'url': url, 'attempt': attempt + 1, 'error': e.toString()},
        );

        if (attempt < retries - 1) {
          await Future.delayed(_retryDelay * (attempt + 1));
        }
      }
    }

    throw lastException ??
        Exception('HTTP GET request failed after $retries attempts');
  }

  /// Make an HTTP POST request with retry logic
  static Future<http.Response> post(
    String url, {
    Map<String, String>? headers,
    Object? body,
    int? maxRetries,
  }) async {
    final retries = maxRetries ?? _maxRetries;
    Exception? lastException;

    for (int attempt = 0; attempt < retries; attempt++) {
      try {
        LoggingService.info(
          'Making HTTP POST request',
          extra: {'url': url, 'attempt': attempt + 1, 'max_retries': retries},
        );

        final client = getHttpClient();
        final response = await client
            .post(
              Uri.parse(url),
              headers: _getDefaultHeaders(headers),
              body: body,
            )
            .timeout(_timeout);

        client.close();

        LoggingService.info(
          'HTTP POST request completed',
          extra: {
            'url': url,
            'status_code': response.statusCode,
            'attempt': attempt + 1,
          },
        );

        return response;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        LoggingService.warning(
          'HTTP POST request failed',
          extra: {'url': url, 'attempt': attempt + 1, 'error': e.toString()},
        );

        if (attempt < retries - 1) {
          await Future.delayed(_retryDelay * (attempt + 1));
        }
      }
    }

    throw lastException ??
        Exception('HTTP POST request failed after $retries attempts');
  }

  /// Check if the device has internet connectivity
  static Future<bool> hasInternetConnection() async {
    try {
      // Return cached result if still valid
      if (_cachedInternetStatus != null && _lastInternetCheckTime != null) {
        final timeSinceLastCheck = DateTime.now().difference(
          _lastInternetCheckTime!,
        );
        if (timeSinceLastCheck < _cacheValidDuration) {
          return _cachedInternetStatus!;
        }
      }

      final connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        _cachedInternetStatus = false;
        _lastInternetCheckTime = DateTime.now();
        return false;
      }

      // Just trust the connectivity check without pinging external server
      // This avoids excessive network requests and warnings
      _cachedInternetStatus = true;
      _lastInternetCheckTime = DateTime.now();

      return true;
    } catch (e) {
      // Silently fail and assume no connection
      _cachedInternetStatus = false;
      _lastInternetCheckTime = DateTime.now();
      return false;
    }
  }

  /// Check if the device is connected to WiFi
  static Future<bool> isConnectedToWifi() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult == ConnectivityResult.wifi;
    } catch (e) {
      LoggingService.error('WiFi connectivity check failed', error: e);
      return false;
    }
  }

  /// Check if the device is connected to mobile data
  static Future<bool> isConnectedToMobile() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult == ConnectivityResult.mobile;
    } catch (e) {
      LoggingService.error('Mobile connectivity check failed', error: e);
      return false;
    }
  }

  /// Get the current connectivity status
  static Future<ConnectivityResult> getConnectivityStatus() async {
    try {
      final results = await Connectivity().checkConnectivity();
      // Return the first result or none if empty
      return results.isNotEmpty ? results.first : ConnectivityResult.none;
    } catch (e) {
      LoggingService.error('Connectivity status check failed', error: e);
      return ConnectivityResult.none;
    }
  }

  /// Get default headers for HTTP requests
  static Map<String, String> _getDefaultHeaders(
    Map<String, String>? customHeaders,
  ) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'AgriClimatic/1.0.8 (Android)',
    };

    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    return headers;
  }

  /// Validate if a URL is accessible
  static Future<bool> isUrlAccessible(String url) async {
    try {
      final client = getHttpClient();
      final response = await client
          .head(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      client.close();

      return response.statusCode >= 200 && response.statusCode < 400;
    } catch (e) {
      LoggingService.warning(
        'URL accessibility check failed',
        extra: {'url': url, 'error': e.toString()},
      );
      return false;
    }
  }

  /// Get network information
  static Future<Map<String, dynamic>> getNetworkInfo() async {
    try {
      final connectivity = await getConnectivityStatus();
      final hasInternet = await hasInternetConnection();
      final isWifi = await isConnectedToWifi();
      final isMobile = await isConnectedToMobile();

      return {
        'connectivity_status': connectivity.toString(),
        'has_internet': hasInternet,
        'is_wifi': isWifi,
        'is_mobile': isMobile,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      LoggingService.error('Failed to get network info', error: e);
      return {
        'connectivity_status': 'unknown',
        'has_internet': false,
        'is_wifi': false,
        'is_mobile': false,
        'timestamp': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }
}
