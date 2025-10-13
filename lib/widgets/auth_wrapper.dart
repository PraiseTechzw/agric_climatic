import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth_screen.dart';
import '../main.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading screen while checking auth state
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Show auth screen if not authenticated
        if (!authProvider.isAuthenticated) {
          return const AuthScreen();
        }

        // Show main app if authenticated
        return const MainScreen();
      },
    );
  }
}


