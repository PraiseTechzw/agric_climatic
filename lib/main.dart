import 'package:agric_climatic/providers/agro_climatic_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/firebase_config.dart';
import 'services/error_handler_service.dart';
import 'services/logging_service.dart';
import 'services/environment_service.dart';
import 'services/offline_service.dart';
import 'services/performance_service.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/weather_screen.dart';
import 'screens/predictions_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/soil_data_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/ai_insights_screen.dart';
import 'screens/debug_screen.dart';
import 'providers/weather_provider.dart';
import 'providers/notification_provider.dart';

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

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: EnvironmentService.supabaseUrl,
      anonKey: EnvironmentService.supabaseAnonKey,
    );
    LoggingService.info('Supabase initialized successfully');
  } catch (e) {
    LoggingService.error('Supabase initialization failed', error: e);
    // Continue without Supabase - app will work in offline mode
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
        home: const SplashScreen(),
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
    const WeatherScreen(),
    const PredictionsScreen(),
    const AnalyticsScreen(),
    const SoilDataScreen(),
    const AIInsightsScreen(),
    if (EnvironmentService.enableDebugMenu) const DebugScreen(),
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
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.05),
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
                    CurvedAnimation(parent: animation, curve: Curves.easeInOut),
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
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
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
                label: 'Weather',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 1
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _selectedIndex == 1
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
                    color: _selectedIndex == 2
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _selectedIndex == 2
                        ? Icons.trending_up
                        : Icons.trending_up_outlined,
                    size: 24,
                  ),
                ),
                label: 'Analytics',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 3
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _selectedIndex == 3
                        ? Icons.terrain
                        : Icons.terrain_outlined,
                    size: 24,
                  ),
                ),
                label: 'Soil',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 4
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _selectedIndex == 4
                        ? Icons.psychology
                        : Icons.psychology_outlined,
                    size: 24,
                  ),
                ),
                label: 'AI Insights',
              ),
              if (EnvironmentService.enableDebugMenu)
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _selectedIndex == 5
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _selectedIndex == 5
                          ? Icons.bug_report
                          : Icons.bug_report_outlined,
                      size: 24,
                    ),
                  ),
                  label: 'Debug',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
