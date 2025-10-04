import 'package:flutter/material.dart';
import '../services/app_icon_service.dart';
import '../services/logging_service.dart';
import '../services/environment_service.dart';
import 'auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  String _statusMessage = 'Initializing...';
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      LoggingService.info('Starting app initialization');

      // Update status message
      setState(() {
        _statusMessage = 'Loading configuration...';
      });

      // Wait a bit for the animation to start
      await Future.delayed(const Duration(milliseconds: 500));

      // Update status message
      setState(() {
        _statusMessage = 'Connecting to services...';
      });

      // Wait a bit more
      await Future.delayed(const Duration(milliseconds: 500));

      // Update status message
      setState(() {
        _statusMessage = 'Loading data...';
      });

      // Wait a bit more
      await Future.delayed(const Duration(milliseconds: 500));

      // Update status message
      setState(() {
        _statusMessage = 'Almost ready...';
      });

      // Wait a bit more
      await Future.delayed(const Duration(milliseconds: 500));

      // Mark as initialized
      setState(() {
        _isInitialized = true;
        _statusMessage = 'Ready!';
      });

      LoggingService.info('App initialization completed');

      // Wait a bit before navigating
      await Future.delayed(const Duration(milliseconds: 500));

      // Navigate to auth screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      }
    } catch (e) {
      LoggingService.error('App initialization failed', error: e);
      setState(() {
        _hasError = true;
        _statusMessage = 'Initialization failed. Please restart the app.';
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppIconService.backgroundColor,
              AppIconService.backgroundColor.withOpacity(0.8),
              AppIconService.primaryColor.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App icon with animation
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: AppIconService.getSplashIcon(size: 120),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // App name with animation
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Text(
                        'AgriClimatic',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppIconService.primaryColor,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),

                // App description with animation
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Text(
                        'Zimbabwe Agricultural Climate Prediction',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppIconService.primaryColor.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 48),

                // Status message with animation
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Column(
                        children: [
                          if (_hasError)
                            AppIconService.getErrorIcon(size: 48)
                          else if (_isInitialized)
                            AppIconService.getSuccessIcon(size: 48)
                          else
                            AppIconService.getLoadingIndicator(
                              message: _statusMessage,
                              color: AppIconService.primaryColor,
                            ),

                          const SizedBox(height: 16),

                          Text(
                            _statusMessage,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppIconService.primaryColor.withOpacity(
                                0.8,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Version info
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Text(
                        'Version ${EnvironmentService.appVersion} (${EnvironmentService.appBuildNumber})',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppIconService.primaryColor.withOpacity(0.6),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Environment info (debug only)
                if (EnvironmentService.isDevelopment)
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppIconService.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppIconService.primaryColor.withOpacity(
                                0.3,
                              ),
                            ),
                          ),
                          child: Text(
                            'Development Mode',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppIconService.primaryColor.withOpacity(
                                0.8,
                              ),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
