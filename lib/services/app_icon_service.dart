import 'package:flutter/material.dart';
import 'logging_service.dart';

class AppIconService {
  // Color scheme for the app
  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color backgroundColor = Color(0xFFF1F8E9);

  static void initialize() {
    LoggingService.info('App icon service initialized');
  }

  // Get app icon widget
  static Widget getAppIcon({
    double size = 64.0,
    Color? color,
    BoxFit fit = BoxFit.contain,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color ?? primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(Icons.agriculture, size: size * 0.6, color: Colors.white),
    );
  }

  // Get splash screen icon
  static Widget getSplashIcon({double size = 120.0, Color? color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color ?? primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(Icons.agriculture, size: size * 0.6, color: Colors.white),
    );
  }

  // Get app logo with text
  static Widget getAppLogo({
    double iconSize = 48.0,
    double textSize = 24.0,
    Color? color,
    bool showText = true,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        getAppIcon(size: iconSize, color: color),
        if (showText) ...[
          const SizedBox(width: 12),
          Text(
            'AgriClimatic',
            style: TextStyle(
              fontSize: textSize,
              fontWeight: FontWeight.bold,
              color: color ?? primaryColor,
            ),
          ),
        ],
      ],
    );
  }

  // Get splash screen widget
  static Widget getSplashScreen({String? message, Widget? child}) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            getSplashIcon(size: 120),
            const SizedBox(height: 24),
            Text(
              'AgriClimatic',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Zimbabwe Agricultural Climate Prediction',
              style: TextStyle(
                fontSize: 16,
                color: primaryColor.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: primaryColor.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (child != null) ...[const SizedBox(height: 32), child],
          ],
        ),
      ),
    );
  }

  // Get loading indicator
  static Widget getLoadingIndicator({String? message, Color? color}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(color ?? primaryColor),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 14, color: color ?? primaryColor),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  // Get error icon
  static Widget getErrorIcon({double size = 64.0, Color? color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color ?? Colors.red,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(Icons.error_outline, size: size * 0.6, color: Colors.white),
    );
  }

  // Get success icon
  static Widget getSuccessIcon({double size = 64.0, Color? color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color ?? Colors.green,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.check_circle_outline,
        size: size * 0.6,
        color: Colors.white,
      ),
    );
  }

  // Get warning icon
  static Widget getWarningIcon({double size = 64.0, Color? color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color ?? Colors.orange,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.warning_outlined,
        size: size * 0.6,
        color: Colors.white,
      ),
    );
  }

  // Get info icon
  static Widget getInfoIcon({double size = 64.0, Color? color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color ?? Colors.blue,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(Icons.info_outline, size: size * 0.6, color: Colors.white),
    );
  }

  // Get feature icon based on type
  static Widget getFeatureIcon(
    String feature, {
    double size = 32.0,
    Color? color,
  }) {
    IconData iconData;

    switch (feature.toLowerCase()) {
      case 'weather':
        iconData = Icons.wb_sunny;
        break;
      case 'predictions':
        iconData = Icons.analytics;
        break;
      case 'analytics':
        iconData = Icons.trending_up;
        break;
      case 'soil':
        iconData = Icons.terrain;
        break;
      case 'ai':
      case 'insights':
        iconData = Icons.psychology;
        break;
      case 'notifications':
        iconData = Icons.notifications;
        break;
      case 'settings':
        iconData = Icons.settings;
        break;
      case 'help':
        iconData = Icons.help;
        break;
      case 'about':
        iconData = Icons.info;
        break;
      default:
        iconData = Icons.agriculture;
    }

    return Icon(iconData, size: size, color: color ?? primaryColor);
  }

  // Get status icon based on status
  static Widget getStatusIcon(String status, {double size = 24.0}) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
      case 'active':
        return Icon(Icons.check_circle, size: size, color: Colors.green);
      case 'error':
      case 'failed':
      case 'inactive':
        return Icon(Icons.error, size: size, color: Colors.red);
      case 'warning':
      case 'pending':
        return Icon(Icons.warning, size: size, color: Colors.orange);
      case 'loading':
      case 'processing':
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        );
      default:
        return Icon(Icons.info, size: size, color: Colors.grey);
    }
  }

  // Get color scheme
  static ColorScheme getColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    );
  }

  // Get dark color scheme
  static ColorScheme getDarkColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    );
  }
}
