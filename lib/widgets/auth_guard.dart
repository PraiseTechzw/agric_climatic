import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../screens/auth_screen.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;
  final bool requireAuth;
  final bool requireEmailVerification;

  const AuthGuard({
    super.key,
    required this.child,
    this.requireAuth = true,
    this.requireEmailVerification = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Show loading screen while checking auth state
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Check if authentication is required
        if (requireAuth && !authProvider.isAuthenticated) {
          return const AuthScreen();
        }

        // Check if email verification is required
        if (requireEmailVerification &&
            authProvider.isAuthenticated &&
            !authProvider.isAnonymous &&
            !AuthService.isEmailVerified) {
          return _EmailVerificationScreen();
        }

        // Show the protected content
        return child;
      },
    );
  }
}

class _EmailVerificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.email_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Verify Your Email',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'We\'ve sent a verification link to your email address. Please check your inbox and click the link to verify your account.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: authProvider.isLoading
                            ? null
                            : () async {
                                await authProvider.resendEmailVerification();
                                if (authProvider.errorMessage != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(authProvider.errorMessage!),
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Verification email sent!'),
                                    ),
                                  );
                                }
                              },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Resend Verification Email'),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () async {
                          await authProvider.signOut();
                        },
                        child: const Text('Sign Out'),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
