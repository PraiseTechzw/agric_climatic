import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeCard(context),

            const SizedBox(height: 24),

            // Quick Start Guide
            _buildSectionCard(
              context,
              'Quick Start Guide',
              Icons.play_circle_outline,
              [
                _buildHelpItem(
                  '1. Weather Monitoring',
                  'Check current weather conditions and forecasts for your location',
                  Icons.wb_sunny,
                ),
                _buildHelpItem(
                  '2. Crop Predictions',
                  'Get AI-powered crop recommendations based on weather and soil data',
                  Icons.agriculture,
                ),
                _buildHelpItem(
                  '3. Soil Analysis',
                  'Monitor soil conditions and get recommendations for improvement',
                  Icons.terrain,
                ),
                _buildHelpItem(
                  '4. Weather Alerts',
                  'Receive notifications about severe weather conditions',
                  Icons.notifications,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Features Overview
            _buildSectionCard(context, 'App Features', Icons.featured_play_list, [
              _buildFeatureItem(
                context,
                'Weather Forecast',
                'Detailed 7-day weather forecast with temperature, humidity, and precipitation data',
                Icons.wb_sunny,
              ),
              _buildFeatureItem(
                context,
                'Crop Recommendations',
                'AI-powered suggestions for the best crops to plant based on current conditions',
                Icons.eco,
              ),
              _buildFeatureItem(
                context,
                'Irrigation Schedule',
                'Smart irrigation recommendations based on weather and soil moisture',
                Icons.water_drop,
              ),
              _buildFeatureItem(
                context,
                'Weather Alerts',
                'Real-time notifications for severe weather conditions',
                Icons.warning,
              ),
              _buildFeatureItem(
                context,
                'Soil Analysis',
                'Comprehensive soil data including pH, temperature, and nutrient levels',
                Icons.terrain,
              ),
              _buildFeatureItem(
                context,
                'Analytics Dashboard',
                'Historical data analysis and trends for better decision making',
                Icons.analytics,
              ),
            ]),

            const SizedBox(height: 24),

            // Troubleshooting
            _buildSectionCard(context, 'Troubleshooting', Icons.build, [
              _buildTroubleshootItem(
                'Location not detected',
                'Make sure location services are enabled and GPS is turned on',
              ),
              _buildTroubleshootItem(
                'Weather data not loading',
                'Check your internet connection and try refreshing the app',
              ),
              _buildTroubleshootItem(
                'Notifications not working',
                'Go to app settings and enable notification permissions',
              ),
              _buildTroubleshootItem(
                'App crashes frequently',
                'Try restarting the app or reinstalling if the problem persists',
              ),
            ]),

            const SizedBox(height: 24),

            // Contact Support
            _buildContactCard(context),

            const SizedBox(height: 24),

            // FAQ
            _buildFAQCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.agriculture,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome to AgriClimatic',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your comprehensive agricultural climate prediction and analysis companion. Get started by exploring the features below.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    String title,
    String description,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootItem(String problem, String solution) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• $problem',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              solution,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.support_agent,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Contact Support',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Need more help? Contact our support team:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _buildContactButton(
              context,
              'Email Support',
              'support@agriclimatic.com',
              Icons.email,
              () => _launchEmail(),
            ),
            const SizedBox(height: 8),
            _buildContactButton(
              context,
              'Visit Website',
              'www.agriclimatic.com',
              Icons.web,
              () => _launchWebsite(),
            ),
            const SizedBox(height: 8),
            _buildContactButton(
              context,
              'Report Bug',
              'Report issues and bugs',
              Icons.bug_report,
              () => _launchBugReport(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.help_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Frequently Asked Questions',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              'How accurate are the weather predictions?',
              'Our weather predictions are based on multiple data sources and are generally accurate for 3-7 days ahead. Accuracy decreases for longer forecasts.',
            ),
            _buildFAQItem(
              'Can I use the app without internet?',
              'Some features work offline, but you need internet connection for real-time weather data and predictions.',
            ),
            _buildFAQItem(
              'How often is the data updated?',
              'Weather data is updated every hour, while soil and crop data is updated daily.',
            ),
            _buildFAQItem(
              'Is my data secure?',
              'Yes, we use industry-standard encryption and follow strict privacy policies to protect your data.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Q: $question',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'A: $answer',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@agriclimatic.com',
      query: 'subject=AgriClimatic Support Request',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchWebsite() async {
    final Uri websiteUri = Uri.parse('https://www.agriclimatic.com');

    if (await canLaunchUrl(websiteUri)) {
      await launchUrl(websiteUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchBugReport() async {
    final Uri bugReportUri = Uri(
      scheme: 'mailto',
      path: 'bugs@agriclimatic.com',
      query: 'subject=Bug Report - AgriClimatic App',
    );

    if (await canLaunchUrl(bugReportUri)) {
      await launchUrl(bugReportUri);
    }
  }
}
