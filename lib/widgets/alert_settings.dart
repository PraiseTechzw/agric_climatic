import 'package:flutter/material.dart';

class AlertSettingsDialog extends StatefulWidget {
  const AlertSettingsDialog({super.key});

  @override
  State<AlertSettingsDialog> createState() => _AlertSettingsDialogState();
}

class _AlertSettingsDialogState extends State<AlertSettingsDialog> {
  bool _smsEnabled = true;
  bool _pushEnabled = true;
  bool _emailEnabled = false;
  double _temperatureThreshold = 30.0;
  double _humidityThreshold = 80.0;
  double _windSpeedThreshold = 15.0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Alert Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification Types
            Text(
              'Notification Types',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('SMS Notifications'),
              subtitle: const Text('Receive alerts via SMS'),
              value: _smsEnabled,
              onChanged: (value) {
                setState(() {
                  _smsEnabled = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text('Receive alerts via push notifications'),
              value: _pushEnabled,
              onChanged: (value) {
                setState(() {
                  _pushEnabled = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Email Notifications'),
              subtitle: const Text('Receive alerts via email'),
              value: _emailEnabled,
              onChanged: (value) {
                setState(() {
                  _emailEnabled = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // Weather Thresholds
            Text(
              'Weather Thresholds',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            // Temperature Threshold
            Text(
                'Temperature Alert (°C): ${_temperatureThreshold.toStringAsFixed(1)}'),
            Slider(
              value: _temperatureThreshold,
              min: 0,
              max: 50,
              divisions: 50,
              onChanged: (value) {
                setState(() {
                  _temperatureThreshold = value;
                });
              },
            ),

            // Humidity Threshold
            Text(
                'Humidity Alert (%): ${_humidityThreshold.toStringAsFixed(1)}'),
            Slider(
              value: _humidityThreshold,
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: (value) {
                setState(() {
                  _humidityThreshold = value;
                });
              },
            ),

            // Wind Speed Threshold
            Text(
                'Wind Speed Alert (m/s): ${_windSpeedThreshold.toStringAsFixed(1)}'),
            Slider(
              value: _windSpeedThreshold,
              min: 0,
              max: 30,
              divisions: 30,
              onChanged: (value) {
                setState(() {
                  _windSpeedThreshold = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveSettings,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveSettings() {
    // TODO: Save settings to backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully!'),
      ),
    );
    Navigator.pop(context);
  }
}
