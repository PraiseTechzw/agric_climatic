import 'package:flutter/material.dart';
import '../screens/enhanced_climate_dashboard_screen.dart';
import '../screens/weather_screen.dart';
import '../screens/weather_alerts_screen.dart';
import '../screens/enhanced_predictions_screen.dart';
import '../screens/recommendations_screen.dart';
import '../screens/irrigation_schedule_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/soil_data_screen.dart';
import '../screens/ai_insights_screen.dart';
import '../screens/help_screen.dart';

class NavigationHelper {
  // Bottom Navigation Screens (main tabs)
  static const List<Widget> bottomNavScreens = [
    EnhancedClimateDashboardScreen(), // 0 - Dashboard
    WeatherAlertsScreen(),           // 1 - Alerts  
    EnhancedPredictionsScreen(),     // 2 - Predictions
    RecommendationsScreen(),         // 3 - Recommendations
    IrrigationScheduleScreen(),      // 4 - Irrigation
  ];

  // Additional Screens (accessible via drawer)
  static const Map<String, Widget> additionalScreens = {
    'Weather': WeatherScreen(),
    'Analytics': AnalyticsScreen(),
    'Soil Data': SoilDataScreen(),
    'AI Insights': AIInsightsScreen(),
    'Help & Support': HelpScreen(),
  };

  // Navigation items for bottom navigation
  static List<BottomNavigationBarItem> getBottomNavItems(BuildContext context) {
    return [
      BottomNavigationBarItem(
        icon: _buildNavIcon(context, Icons.dashboard, Icons.dashboard_outlined, 0),
        label: 'Dashboard',
      ),
      BottomNavigationBarItem(
        icon: _buildNavIcon(context, Icons.warning, Icons.warning_outlined, 1),
        label: 'Alerts',
      ),
      BottomNavigationBarItem(
        icon: _buildNavIcon(context, Icons.analytics, Icons.analytics_outlined, 2),
        label: 'Predictions',
      ),
      BottomNavigationBarItem(
        icon: _buildNavIcon(context, Icons.lightbulb, Icons.lightbulb_outline, 3),
        label: 'Recommendations',
      ),
      BottomNavigationBarItem(
        icon: _buildNavIcon(context, Icons.water_drop, Icons.water_drop_outlined, 4),
        label: 'Irrigation',
      ),
    ];
  }

  // Navigation items for drawer
  static List<Widget> getDrawerItems(BuildContext context, int selectedIndex, Function(int) onBottomNavTap, Function(Widget) onAdditionalScreenTap) {
    return [
      _buildDrawerItem(context, 'Climate Dashboard', Icons.dashboard, 0, selectedIndex, onBottomNavTap),
      _buildDrawerItem(context, 'Weather Alerts', Icons.warning, 1, selectedIndex, onBottomNavTap),
      _buildDrawerItem(context, 'Predictions', Icons.analytics, 2, selectedIndex, onBottomNavTap),
      _buildDrawerItem(context, 'Recommendations', Icons.lightbulb, 3, selectedIndex, onBottomNavTap),
      _buildDrawerItem(context, 'Irrigation Schedule', Icons.water_drop, 4, selectedIndex, onBottomNavTap),
      const Divider(),
      ...additionalScreens.entries.map((entry) => 
        _buildDrawerItem(context, entry.key, _getIconForScreen(entry.key), -1, selectedIndex, null, entry.value, onAdditionalScreenTap)
      ).toList(),
    ];
  }

  static Widget _buildNavIcon(BuildContext context, IconData selectedIcon, IconData unselectedIcon, int index) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: _getGradientForIndex(index),
        borderRadius: BorderRadius.circular(16),
        border: _getBorderForIndex(index),
      ),
      child: Icon(
        selectedIcon,
        size: 24,
      ),
    );
  }

  static Widget _buildDrawerItem(
    BuildContext context,
    String title,
    IconData icon,
    int index,
    int selectedIndex,
    Function(int)? onBottomNavTap,
    [Widget? screen,
    Function(Widget)? onAdditionalScreenTap]
  ) {
    final isSelected = index >= 0 && index == selectedIndex;
    
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: isSelected,
      selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      onTap: () {
        Navigator.pop(context);
        if (index >= 0 && onBottomNavTap != null) {
          // Bottom navigation screens
          onBottomNavTap(index);
        } else if (screen != null && onAdditionalScreenTap != null) {
          // Additional screens - navigate directly
          onAdditionalScreenTap(screen);
        }
      },
    );
  }

  static IconData _getIconForScreen(String screenName) {
    switch (screenName) {
      case 'Weather':
        return Icons.wb_sunny;
      case 'Analytics':
        return Icons.trending_up;
      case 'Soil Data':
        return Icons.terrain;
      case 'AI Insights':
        return Icons.psychology;
      case 'Help & Support':
        return Icons.help;
      default:
        return Icons.info;
    }
  }

  static Gradient? _getGradientForIndex(int index) {
    switch (index) {
      case 0:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2E7D32).withOpacity(0.2),
            const Color(0xFF4CAF50).withOpacity(0.1),
          ],
        );
      case 1:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE53E3E).withOpacity(0.2),
            const Color(0xFFF56565).withOpacity(0.1),
          ],
        );
      case 2:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3182CE).withOpacity(0.2),
            const Color(0xFF63B3ED).withOpacity(0.1),
          ],
        );
      case 3:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFD69E2E).withOpacity(0.2),
            const Color(0xFFF6E05E).withOpacity(0.1),
          ],
        );
      case 4:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3182CE).withOpacity(0.2),
            const Color(0xFF63B3ED).withOpacity(0.1),
          ],
        );
      default:
        return null;
    }
  }

  static Border? _getBorderForIndex(int index) {
    switch (index) {
      case 0:
        return Border.all(
          color: const Color(0xFF2E7D32).withOpacity(0.3),
          width: 1,
        );
      case 1:
        return Border.all(
          color: const Color(0xFFE53E3E).withOpacity(0.3),
          width: 1,
        );
      case 2:
        return Border.all(
          color: const Color(0xFF3182CE).withOpacity(0.3),
          width: 1,
        );
      case 3:
        return Border.all(
          color: const Color(0xFFD69E2E).withOpacity(0.3),
          width: 1,
        );
      case 4:
        return Border.all(
          color: const Color(0xFF3182CE).withOpacity(0.3),
          width: 1,
        );
      default:
        return null;
    }
  }

  // Helper method to navigate to additional screens
  static void navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  // Helper method to get screen by index
  static Widget getScreenByIndex(int index) {
    if (index >= 0 && index < bottomNavScreens.length) {
      return bottomNavScreens[index];
    }
    return bottomNavScreens[0]; // Default to dashboard
  }

  // Helper method to get screen name by index
  static String getScreenNameByIndex(int index) {
    switch (index) {
      case 0:
        return 'Climate Dashboard';
      case 1:
        return 'Weather Alerts';
      case 2:
        return 'Predictions';
      case 3:
        return 'Recommendations';
      case 4:
        return 'Irrigation Schedule';
      default:
        return 'Unknown';
    }
  }
}
