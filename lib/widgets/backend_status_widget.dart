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
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isConnected
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isConnected
              ? Colors.green.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          if (_isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              _isConnected ? Icons.cloud_done : Icons.cloud_off,
              color: _isConnected ? Colors.green : Colors.orange,
              size: 16,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isLoading
                  ? 'Checking backend connection...'
                  : _isConnected
                  ? 'Backend connected successfully'
                  : 'Backend offline - using local data',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _isConnected ? Colors.green[700] : Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (!_isLoading && !_isConnected)
            TextButton(onPressed: _checkConnection, child: const Text('Retry')),
        ],
      ),
    );
  }
}
