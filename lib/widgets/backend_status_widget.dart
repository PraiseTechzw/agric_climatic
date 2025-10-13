import 'dart:async';
import 'package:flutter/material.dart';
import '../services/firebase_config.dart';

class BackendStatusWidget extends StatefulWidget {
  const BackendStatusWidget({super.key});

  @override
  State<BackendStatusWidget> createState() => _BackendStatusWidgetState();
}

class _BackendStatusWidgetState extends State<BackendStatusWidget> {
  bool _isConnected = false;
  bool _isLoading = true;
  Timer? _connectionTimer;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    // Set up periodic connection check
    _connectionTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isDisposed) {
        _checkConnection();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _connectionTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    if (_isDisposed || !mounted) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final isConnected = await FirebaseConfig.testConnection();
      if (!_isDisposed && mounted) {
        setState(() {
          _isConnected = isConnected;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        setState(() {
          _isConnected = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Replace backend connectivity banner with a subtle status chip
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        margin: const EdgeInsets.only(right: 16, top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (_isConnected ? Colors.green : Colors.orange).withOpacity(
              0.4,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                _isConnected ? Icons.cloud_done : Icons.cloud_off,
                color: _isConnected ? Colors.green : Colors.orange,
                size: 16,
              ),
            const SizedBox(width: 6),
            Text(
              _isLoading
                  ? 'Syncing…'
                  : _isConnected
                  ? 'Online'
                  : 'Offline',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!_isLoading && !_isConnected)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: InkWell(
                  onTap: _checkConnection,
                  child: Text(
                    'Retry',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
