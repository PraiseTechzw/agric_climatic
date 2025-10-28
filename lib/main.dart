import 'package:agric_climatic/providers/agro_climatic_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/firebase_config.dart';
import 'services/error_handler_service.dart';
import 'services/logging_service.dart';
import 'services/environment_service.dart';
import 'services/offline_service.dart';
import 'services/performance_service.dart';
import 'services/notification_service.dart';
import 'widgets/auth_wrapper.dart';
import 'widgets/auth_guard.dart';
import 'widgets/auth_status_indicator.dart';
import 'screens/enhanced_climate_dashboard_screen.dart';
import 'screens/weather_screen.dart';
import 'screens/weather_alerts_screen.dart';
import 'screens/enhanced_predictions_screen.dart';
import 'screens/recommendations_screen.dart';
import 'screens/irrigation_schedule_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/soil_data_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/ai_insights_screen.dart';
import 'screens/help_screen.dart';
import 'providers/weather_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/auth_provider.dart';
import 'services/firebase_ai_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment configuration
  EnvironmentService.initialize();

  // Initialize error handling
  ErrorHandlerService.initialize();

  // Initialize offline service
  await OfflineService.initialize();

  // Initialize performance service
  await PerformanceService.initialize();

  // Initialize notification service
  await NotificationService.initialize();

  // Initialize Firebase AI early (non-blocking)
  try {
    await FirebaseAIService.instance.initialize();
  } catch (_) {}

  LoggingService.info('Starting AgriClimatic app');

  // Validate configuration
  if (!EnvironmentService.validateConfiguration()) {
    LoggingService.critical('Configuration validation failed');
    return;
  }

  // Initialize Firebase (with duplicate check)
  try {
    await FirebaseConfig.initializeWithFallback();
    LoggingService.info('Firebase initialized successfully');
  } catch (e) {
    LoggingService.warning(
      'Firebase initialization failed, continuing in offline mode',
      error: e,
    );
  }

  // Supabase removed — app now uses Firebase only

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => AgroClimaticProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'AgriClimatic',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2E7D32), // Rich forest green
            brightness: Brightness.light,
            primary: const Color(0xFF2E7D32),
            secondary: const Color(0xFF4CAF50),
            tertiary: const Color(0xFF81C784),
            surface: const Color(0xFFFAFAFA),
            surfaceContainerHighest: const Color(0xFFF5F5F5),
            outline: const Color(0xFFE0E0E0),
            outlineVariant: const Color(0xFFF0F0F0),
          ),
          useMaterial3: true,
          fontFamily: 'Inter',
          textTheme: const TextTheme(
            displayLarge: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            displayMedium: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.25,
            ),
            displaySmall: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
            headlineLarge: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
            headlineMedium: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            headlineSmall: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            titleLarge: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            titleMedium: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            titleSmall: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            bodySmall: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
            labelLarge: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            labelMedium: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            labelSmall: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          appBarTheme: AppBarTheme(
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            foregroundColor: const Color(0xFF2E7D32),
            titleTextStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E7D32),
            ),
            iconTheme: const IconThemeData(
              color: Color(0xFF2E7D32),
              size: 24,
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.black.withOpacity(0.08),
            color: Colors.white,
            margin: const EdgeInsets.all(8),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              elevation: 0,
              shadowColor: Colors.transparent,
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              side: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
              foregroundColor: const Color(0xFF2E7D32),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              foregroundColor: const Color(0xFF2E7D32),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            shape: CircleBorder(),
            elevation: 8,
            backgroundColor: Color(0xFF2E7D32),
            foregroundColor: Colors.white,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            selectedItemColor: Color(0xFF2E7D32),
            unselectedItemColor: Color(0xFF9E9E9E),
            selectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE53E3E)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            labelStyle: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            hintStyle: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 14,
            ),
          ),
          chipTheme: ChipThemeData(
            backgroundColor: const Color(0xFFF3F4F6),
            selectedColor: const Color(0xFF2E7D32),
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          dividerTheme: const DividerThemeData(
            color: Color(0xFFE5E7EB),
            thickness: 1,
            space: 1,
          ),
          listTileTheme: const ListTileThemeData(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            tileColor: Colors.transparent,
            selectedTileColor: Color(0xFFE8F5E8),
          ),
        ),
        home: const AuthWrapper(),
        routes: {'/notifications': (context) => const NotificationsScreen()},
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const EnhancedClimateDashboardScreen(), // 0 - Dashboard
    const WeatherAlertsScreen(),           // 1 - Alerts  
    const EnhancedPredictionsScreen(),     // 2 - Predictions
    const RecommendationsScreen(),         // 3 - Recommendations
    const IrrigationScheduleScreen(),      // 4 - Irrigation
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final weatherProvider = context.read<WeatherProvider>();
      final notificationProvider = context.read<NotificationProvider>();

      weatherProvider.refreshAll();
      notificationProvider.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthGuard(
      child: Scaffold(
        extendBody: true,
        drawer: _buildDrawer(context),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.05),
                Theme.of(context).colorScheme.surface,
                Theme.of(
                  context,
                ).colorScheme.secondaryContainer.withOpacity(0.05),
              ],
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ),
                    ),
                child: child,
              );
            },
            child: Container(
              key: ValueKey(_selectedIndex),
              child: _screens[_selectedIndex],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.95),
                Colors.white.withOpacity(0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E7D32).withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              selectedItemColor: const Color(0xFF2E7D32),
              unselectedItemColor: const Color(0xFF9CA3AF),
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              elevation: 0,
              items: [
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: _selectedIndex == 0
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF2E7D32).withOpacity(0.2),
                                const Color(0xFF4CAF50).withOpacity(0.1),
                              ],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      border: _selectedIndex == 0
                          ? Border.all(
                              color: const Color(0xFF2E7D32).withOpacity(0.3),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Icon(
                      _selectedIndex == 0
                          ? Icons.dashboard
                          : Icons.dashboard_outlined,
                      size: 24,
                    ),
                  ),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: _selectedIndex == 1
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFFE53E3E).withOpacity(0.2),
                                const Color(0xFFF56565).withOpacity(0.1),
                              ],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      border: _selectedIndex == 1
                          ? Border.all(
                              color: const Color(0xFFE53E3E).withOpacity(0.3),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Icon(
                      _selectedIndex == 1
                          ? Icons.warning
                          : Icons.warning_outlined,
                      size: 24,
                    ),
                  ),
                  label: 'Alerts',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: _selectedIndex == 2
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF3182CE).withOpacity(0.2),
                                const Color(0xFF63B3ED).withOpacity(0.1),
                              ],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      border: _selectedIndex == 2
                          ? Border.all(
                              color: const Color(0xFF3182CE).withOpacity(0.3),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Icon(
                      _selectedIndex == 2
                          ? Icons.analytics
                          : Icons.analytics_outlined,
                      size: 24,
                    ),
                  ),
                  label: 'Predictions',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: _selectedIndex == 3
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFFD69E2E).withOpacity(0.2),
                                const Color(0xFFF6E05E).withOpacity(0.1),
                              ],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      border: _selectedIndex == 3
                          ? Border.all(
                              color: const Color(0xFFD69E2E).withOpacity(0.3),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Icon(
                      _selectedIndex == 3
                          ? Icons.lightbulb
                          : Icons.lightbulb_outline,
                      size: 24,
                    ),
                  ),
                  label: 'Recommendations',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: _selectedIndex == 4
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF3182CE).withOpacity(0.2),
                                const Color(0xFF63B3ED).withOpacity(0.1),
                              ],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      border: _selectedIndex == 4
                          ? Border.all(
                              color: const Color(0xFF3182CE).withOpacity(0.3),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Icon(
                      _selectedIndex == 4
                          ? Icons.water_drop
                          : Icons.water_drop_outlined,
                      size: 24,
                    ),
                  ),
                  label: 'Irrigation',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.agriculture, size: 48, color: Colors.white),
                    const Spacer(),
                    const AuthStatusIndicator(),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'AgriClimatic',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Agricultural Climate Prediction',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          _buildDrawerItem(context, 'Climate Dashboard', Icons.dashboard, 0),
          _buildDrawerItem(context, 'Weather Alerts', Icons.warning, 1),
          _buildDrawerItem(context, 'Predictions', Icons.analytics, 2),
          _buildDrawerItem(context, 'Recommendations', Icons.lightbulb, 3),
          _buildDrawerItem(context, 'Irrigation Schedule', Icons.water_drop, 4),
          const Divider(),
          _buildDrawerItem(context, 'Weather', Icons.wb_sunny, -1, const WeatherScreen()),
          _buildDrawerItem(context, 'Analytics', Icons.trending_up, -1, const AnalyticsScreen()),
          _buildDrawerItem(context, 'Soil Data', Icons.terrain, -1, const SoilDataScreen()),
          _buildDrawerItem(context, 'AI Insights', Icons.psychology, -1, const AIInsightsScreen()),
          _buildDrawerItem(context, 'Help & Support', Icons.help, -1, const HelpScreen()),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            onTap: () {
              Navigator.pop(context);
              _showSignOutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    String title,
    IconData icon,
    int index, [
    Widget? screen,
  ]) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: _selectedIndex == index,
      selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      onTap: () {
        Navigator.pop(context);
        if (index >= 0) {
          // Bottom navigation screens
          setState(() {
            _selectedIndex = index;
          });
        } else if (screen != null) {
          // Additional screens - navigate directly
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        }
      },
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Sign out using AuthProvider
              final authProvider = context.read<AuthProvider>();
              await authProvider.signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
