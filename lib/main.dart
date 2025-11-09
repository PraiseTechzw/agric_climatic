import 'package:agric_climatic/providers/agro_climatic_provider.dart';
import 'package:agric_climatic/screens/help_screen.dart';
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
import 'screens/climate_dashboard_screen.dart';
import 'screens/weather_screen.dart';
import 'screens/weather_alerts_screen.dart';
import 'screens/enhanced_predictions_screen.dart';
import 'screens/recommendations_screen.dart';
import 'screens/irrigation_schedule_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/supervisor_dashboard_screen.dart';
import 'providers/weather_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/auth_provider.dart';
import 'services/firebase_ai_service.dart';
import 'utils/toast_service.dart';

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
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.black.withOpacity(0.1),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              elevation: 0,
              shadowColor: Colors.transparent,
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            shape: CircleBorder(),
            elevation: 8,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
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
    const ClimateDashboardScreen(),
    const WeatherAlertsScreen(),
    const EnhancedPredictionsScreen(),
    const RecommendationsScreen(),
    const IrrigationScheduleScreen(),
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
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: Colors.grey[500],
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _selectedIndex == 0
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _selectedIndex == 0
                          ? Icons.wb_sunny
                          : Icons.wb_sunny_outlined,
                      size: 24,
                    ),
                  ),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _selectedIndex == 1
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _selectedIndex == 2
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _selectedIndex == 3
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _selectedIndex == 3
                          ? Icons.lightbulb
                          : Icons.lightbulb_outline,
                      size: 24,
                    ),
                  ),
                  label: 'Advice',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _selectedIndex == 4
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _selectedIndex == 4
                          ? Icons.water_drop
                          : Icons.water_drop_outlined,
                      size: 24,
                    ),
                  ),
                  label: 'Water',
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
          _buildDrawerItem(context, 'Weather Today', Icons.wb_sunny, -1),
          _buildDrawerItem(context, 'Weather Alerts', Icons.warning, 1),
          _buildDrawerItem(context, 'Crop Predictions', Icons.analytics, 2),
          _buildDrawerItem(context, 'Farming Advice', Icons.lightbulb, 3),
          _buildDrawerItem(context, 'Water Schedule', Icons.water_drop, 4),
          const Divider(),
          _buildDrawerItem(context, 'Climate Dashboard', Icons.dashboard, -1),
          _buildDrawerItem(
            context,
            'Supervisor Dashboard',
            Icons.admin_panel_settings,
            -1,
          ),
          _buildDrawerItem(context, 'Farm Analytics', Icons.trending_up, -1),
          _buildDrawerItem(context, 'Help & Support', Icons.help, -1),
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
    int index,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: _selectedIndex == index,
      selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      onTap: () {
        Navigator.pop(context);
        if (index >= 0) {
          setState(() {
            _selectedIndex = index;
          });
        } else {
          // Handle navigation to screens not in bottom navigation
          _navigateToScreen(context, title);
        }
      },
    );
  }

  void _navigateToScreen(BuildContext context, String screenName) {
    Widget? screen;
    switch (screenName) {
      case 'Climate Dashboard':
        screen = const ClimateDashboardScreen();
        break;
      case 'Weather Today':
        screen = const WeatherScreen();
        break;
      case 'Supervisor Dashboard':
        screen = const SupervisorDashboardScreen();
        break;
      case 'Farm Analytics':
        screen = const AnalyticsScreen();
        break;
      case 'Help & Support':
        screen = const HelpScreen();
        break;
    }

    if (screen != null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => screen!));
    }
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return ElevatedButton(
                onPressed: authProvider.isLoading
                    ? null
                    : () async {
                        Navigator.pop(dialogContext);
                        await authProvider.signOut();

                        if (!context.mounted) return;

                        if (authProvider.errorMessage != null) {
                          ToastService.showError(
                            context,
                            authProvider.errorMessage!,
                          );
                        } else if (authProvider.successMessage != null) {
                          ToastService.showSuccess(
                            context,
                            authProvider.successMessage!,
                            icon: Icons.logout,
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Colors.white,
                ),
                child: authProvider.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Sign Out'),
              );
            },
          ),
        ],
      ),
    );
  }
}
