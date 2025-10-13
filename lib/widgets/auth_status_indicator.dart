import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';

class AuthStatusIndicator extends StatelessWidget {
  const AuthStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isAuthenticated) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: authProvider.isAnonymous
                ? Colors.orange.withOpacity(0.1)
                : Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: authProvider.isAnonymous
                  ? Colors.orange
                  : Colors.green,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                authProvider.isAnonymous
                    ? Icons.person_outline
                    : Icons.verified_user,
                size: 16,
                color: authProvider.isAnonymous
                    ? Colors.orange
                    : Colors.green,
              ),
              const SizedBox(width: 4),
              Text(
                authProvider.isAnonymous
                    ? 'Guest User'
                    : 'Authenticated',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: authProvider.isAnonymous
                      ? Colors.orange[700]
                      : Colors.green[700],
                ),
              ),
              if (!authProvider.isAnonymous && !AuthService.isEmailVerified) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.warning_amber,
                  size: 14,
                  color: Colors.orange[700],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}


