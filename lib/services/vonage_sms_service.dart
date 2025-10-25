import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'logging_service.dart';

/// Vonage SMS Service for sending SMS messages via Vonage API
class VonageSMSService {
  static const String _baseUrl = 'https://rest.nexmo.com';
  static const String _smsEndpoint = '/sms/json';

  // Vonage API credentials (these should be set in environment service)
  static String? _apiKey;
  static String? _apiSecret;
  static String? _fromNumber;

  /// Initialize Vonage SMS service with credentials
  static Future<void> initialize({
    required String apiKey,
    required String apiSecret,
    String? fromNumber,
  }) async {
    _apiKey = apiKey;
    _apiSecret = apiSecret;
    _fromNumber = fromNumber;

    LoggingService.info(
      'Vonage SMS service initialized with credentials',
      extra: {
        'api_key': apiKey,
        'api_secret': apiSecret,
        'from_number': fromNumber,
        'api_key_length': apiKey.length,
        'api_secret_length': apiSecret.length,
        'api_key_configured': apiKey.isNotEmpty,
        'api_secret_configured': apiSecret.isNotEmpty,
        'from_number_configured': fromNumber?.isNotEmpty ?? false,
      },
    );
  }

  /// Send SMS message using Vonage API
  static Future<VonageSMSResponse> sendSMS({
    required String to,
    required String text,
    String? from,
    String? clientRef,
    bool statusReportReq = true,
    String? callback,
    int? ttl,
    String type = 'text',
  }) async {
    try {
      // Validate configuration
      if (_apiKey == null || _apiSecret == null) {
        throw VonageSMSException(
          'Vonage SMS service not initialized. Call initialize() first.',
          errorCode: 'NOT_INITIALIZED',
        );
      }

      // Validate phone number format (E.164)
      final formattedTo = _formatPhoneNumber(to);
      if (formattedTo == null) {
        throw VonageSMSException(
          'Invalid phone number format: $to',
          errorCode: 'INVALID_PHONE_NUMBER',
        );
      }

      // Use provided from or default - Vonage sender ID
      final senderId = from ?? _fromNumber ?? 'Vonage APIs';

      // Prepare request body - using correct Vonage API parameter names
      final requestBody = {
        'api_key': _apiKey!,
        'api_secret': _apiSecret!,
        'from': senderId,
        'to': formattedTo,
        'text': text,
      };

      // Add optional parameters
      if (clientRef != null) {
        requestBody['client-ref'] = clientRef;
      }

      LoggingService.info(
        'Sending SMS via Vonage with stored credentials',
        extra: {
          'to': formattedTo,
          'from': senderId,
          'text_length': text.length,
          'stored_api_key': _apiKey!,
          'stored_api_secret': _apiSecret!,
          'stored_from_number': _fromNumber,
          'api_key_length': _apiKey!.length,
          'api_secret_length': _apiSecret!.length,
          'client_ref': clientRef,
        },
      );

      // Log the actual request body being sent
      LoggingService.info(
        'Vonage API request body',
        extra: {
          'url': '$_baseUrl$_smsEndpoint',
          'request_body': requestBody,
          'api_key_in_request': requestBody['api_key'],
          'api_secret_in_request': requestBody['api_secret'],
          'from_in_request': requestBody['from'],
          'to_in_request': requestBody['to'],
        },
      );

      // Make API request
      final response = await http
          .post(
            Uri.parse('$_baseUrl$_smsEndpoint'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: requestBody,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw VonageSMSException(
                'SMS request timeout',
                errorCode: 'TIMEOUT',
              );
            },
          );

      // Parse response
      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        final smsResponse = VonageSMSResponse.fromJson(responseData);

        // Check if any message failed
        final hasFailedMessages = smsResponse.messages.any(
          (msg) => msg.status != '0',
        );

        if (hasFailedMessages) {
          final failedMessage = smsResponse.messages.firstWhere(
            (msg) => msg.status != '0',
          );
          LoggingService.warning(
            'Vonage SMS failed',
            extra: {
              'status': failedMessage.status,
              'error_description': _getVonageStatusDescription(
                failedMessage.status,
              ),
              'message_id': failedMessage.messageId,
            },
          );

          throw VonageSMSException(
            'SMS send failed: ${_getVonageStatusDescription(failedMessage.status)}',
            errorCode: failedMessage.status,
          );
        }

        LoggingService.info(
          'SMS sent successfully via Vonage',
          extra: {
            'message_count': smsResponse.messageCount,
            'status': smsResponse.messages.isNotEmpty
                ? smsResponse.messages.first.status
                : 'unknown',
            'message_id': smsResponse.messages.isNotEmpty
                ? smsResponse.messages.first.messageId
                : 'unknown',
          },
        );

        return smsResponse;
      } else {
        // Handle error response
        final errorMessage = responseData['error-text'] ?? 'Unknown error';
        final errorCode = responseData['error-code']?.toString() ?? 'UNKNOWN';

        LoggingService.error(
          'Vonage SMS API error',
          extra: {
            'status_code': response.statusCode,
            'error_code': errorCode,
            'error_message': errorMessage,
            'response_body': response.body,
          },
        );

        throw VonageSMSException(
          'SMS send failed: $errorMessage',
          errorCode: errorCode,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      LoggingService.error('Failed to send SMS via Vonage', error: e);

      if (e is VonageSMSException) {
        rethrow;
      } else {
        throw VonageSMSException(
          'SMS send failed: ${e.toString()}',
          errorCode: 'NETWORK_ERROR',
        );
      }
    }
  }

  /// Send SMS with retry logic
  static Future<VonageSMSResponse> sendSMSWithRetry({
    required String to,
    required String text,
    String? from,
    String? clientRef,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts < maxRetries) {
      try {
        return await sendSMS(
          to: to,
          text: text,
          from: from,
          clientRef: clientRef,
        );
      } catch (e) {
        lastException = e as Exception;
        attempts++;

        if (attempts < maxRetries) {
          LoggingService.warning(
            'SMS send attempt $attempts failed, retrying in ${retryDelay.inSeconds}s',
            extra: {'error': e.toString()},
          );
          await Future.delayed(retryDelay);
        }
      }
    }

    LoggingService.error(
      'SMS send failed after $maxRetries attempts',
      extra: {'last_error': lastException.toString()},
    );

    throw lastException ??
        VonageSMSException(
          'SMS send failed after $maxRetries attempts',
          errorCode: 'MAX_RETRIES_EXCEEDED',
        );
  }

  /// Send bulk SMS messages
  static Future<List<VonageSMSResponse>> sendBulkSMS({
    required List<String> recipients,
    required String text,
    String? from,
    String? clientRef,
    int maxConcurrent = 5,
  }) async {
    final results = <VonageSMSResponse>[];
    final semaphore = Semaphore(maxConcurrent);

    try {
      final futures = recipients.map((recipient) async {
        await semaphore.acquire();
        try {
          return await sendSMS(
            to: recipient,
            text: text,
            from: from,
            clientRef: clientRef,
          );
        } finally {
          semaphore.release();
        }
      });

      results.addAll(await Future.wait(futures));

      LoggingService.info(
        'Bulk SMS completed',
        extra: {
          'total_recipients': recipients.length,
          'successful_sends': results.length,
        },
      );

      return results;
    } catch (e) {
      LoggingService.error('Bulk SMS failed', error: e);
      rethrow;
    }
  }

  /// Format phone number to E.164 format
  static String? _formatPhoneNumber(String phoneNumber) {
    try {
      // Remove all non-digit characters except +
      String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      // Handle different formats
      if (cleaned.startsWith('+')) {
        // Already in international format
        return cleaned;
      } else if (cleaned.startsWith('263')) {
        // Zimbabwe number without +
        return '+$cleaned';
      } else if (cleaned.startsWith('0')) {
        // Local format, convert to international
        return '+263${cleaned.substring(1)}';
      } else if (cleaned.length >= 9) {
        // Assume it's a local number without country code
        return '+263$cleaned';
      }

      return null;
    } catch (e) {
      LoggingService.warning(
        'Failed to format phone number: $phoneNumber',
        extra: {'error': e.toString()},
      );
      return null;
    }
  }

  /// Check if service is initialized
  static bool get isInitialized => _apiKey != null && _apiSecret != null;

  /// Get human-readable description for Vonage status codes
  static String _getVonageStatusDescription(String status) {
    switch (status) {
      case '0':
        return 'Success';
      case '1':
        return 'Throttled';
      case '2':
        return 'Missing params';
      case '3':
        return 'Invalid params';
      case '4':
        return 'Invalid credentials';
      case '5':
        return 'Internal error';
      case '6':
        return 'Invalid message';
      case '7':
        return 'Number barred';
      case '8':
        return 'Partner account barred';
      case '9':
        return 'Partner quota exceeded';
      case '10':
        return 'Account not enabled for REST';
      case '11':
        return 'Message too long';
      case '12':
        return 'Communication failed';
      case '13':
        return 'Invalid signature';
      case '14':
        return 'Invalid sender address';
      case '15':
        return 'Invalid TTL';
      case '16':
        return 'Facility not allowed';
      case '17':
        return 'Invalid message class';
      case '18':
        return 'Bad callback';
      case '19':
        return 'Invalid client reference';
      case '20':
        return 'Invalid destination address';
      case '21':
        return 'Invalid source address';
      case '22':
        return 'Invalid message type';
      case '23':
        return 'Invalid message class';
      case '24':
        return 'Invalid message class';
      case '25':
        return 'Invalid message class';
      case '26':
        return 'Invalid message class';
      case '27':
        return 'Invalid message class';
      case '28':
        return 'Invalid message class';
      case '29':
        return 'Invalid message class';
      case '30':
        return 'Invalid message class';
      default:
        return 'Unknown error (Status: $status)';
    }
  }

  /// Get service status
  static Map<String, dynamic> getServiceStatus() {
    return {
      'initialized': isInitialized,
      'api_key_configured': _apiKey?.isNotEmpty ?? false,
      'api_secret_configured': _apiSecret?.isNotEmpty ?? false,
      'from_number_configured': _fromNumber?.isNotEmpty ?? false,
      'base_url': _baseUrl,
    };
  }
}

/// Vonage SMS Response model
class VonageSMSResponse {
  final String messageCount;
  final List<VonageSMSMessage> messages;

  VonageSMSResponse({required this.messageCount, required this.messages});

  factory VonageSMSResponse.fromJson(Map<String, dynamic> json) {
    final messagesList = json['messages'] as List<dynamic>? ?? [];
    final messages = messagesList
        .map((msg) => VonageSMSMessage.fromJson(msg as Map<String, dynamic>))
        .toList();

    return VonageSMSResponse(
      messageCount: json['message-count']?.toString() ?? '0',
      messages: messages,
    );
  }

  bool get isSuccess => messages.isNotEmpty && messages.first.status == '0';

  String? get firstMessageId =>
      messages.isNotEmpty ? messages.first.messageId : null;

  String? get firstStatus => messages.isNotEmpty ? messages.first.status : null;
}

/// Vonage SMS Message model
class VonageSMSMessage {
  final String to;
  final String messageId;
  final String status;
  final String? remainingBalance;
  final String? messagePrice;
  final String? network;
  final String? clientRef;
  final String? accountRef;

  VonageSMSMessage({
    required this.to,
    required this.messageId,
    required this.status,
    this.remainingBalance,
    this.messagePrice,
    this.network,
    this.clientRef,
    this.accountRef,
  });

  factory VonageSMSMessage.fromJson(Map<String, dynamic> json) {
    return VonageSMSMessage(
      to: json['to'] ?? '',
      messageId: json['message-id'] ?? '',
      status: json['status'] ?? '',
      remainingBalance: json['remaining-balance'],
      messagePrice: json['message-price'],
      network: json['network'],
      clientRef: json['client-ref'],
      accountRef: json['account-ref'],
    );
  }

  bool get isDelivered => status == '0';
  bool get isFailed => status != '0';
}

/// Vonage SMS Exception
class VonageSMSException implements Exception {
  final String message;
  final String errorCode;
  final int? statusCode;

  VonageSMSException(this.message, {required this.errorCode, this.statusCode});

  @override
  String toString() => 'VonageSMSException: $message (Code: $errorCode)';
}

/// Semaphore for controlling concurrent operations
class Semaphore {
  final int maxCount;
  int _currentCount;
  final List<Completer<void>> _waitingQueue = [];

  Semaphore(this.maxCount) : _currentCount = maxCount;

  Future<void> acquire() async {
    if (_currentCount > 0) {
      _currentCount--;
      return;
    }

    final completer = Completer<void>();
    _waitingQueue.add(completer);
    return completer.future;
  }

  void release() {
    if (_waitingQueue.isNotEmpty) {
      final completer = _waitingQueue.removeAt(0);
      completer.complete();
    } else {
      _currentCount++;
    }
  }
}
