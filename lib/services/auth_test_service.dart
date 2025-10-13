import 'package:firebase_auth/firebase_auth.dart';
import '../services/logging_service.dart';

class AuthTestService {
  // Test email and password for testing purposes
  static const String testEmail = 'test@agriclimatic.com';
  static const String testPassword = 'testpassword123';

  // Test authentication functionality
  static Future<bool> testAuthentication() async {
    try {
      LoggingService.info('Starting authentication tests...');

      // Test 1: Check if Firebase Auth is initialized
      final auth = FirebaseAuth.instance;
      LoggingService.info('✓ Firebase Auth initialized');

      // Test 2: Test anonymous sign in
      try {
        final anonymousCredential = await auth.signInAnonymously();
        if (anonymousCredential.user != null) {
          LoggingService.info('✓ Anonymous sign in successful');
          
          // Sign out anonymous user
          await auth.signOut();
          LoggingService.info('✓ Anonymous sign out successful');
        } else {
          LoggingService.error('✗ Anonymous sign in failed - no user returned');
          return false;
        }
      } catch (e) {
        LoggingService.error('✗ Anonymous sign in failed: $e');
        return false;
      }

      // Test 3: Test email/password sign up (if not already exists)
      try {
        final signUpCredential = await auth.createUserWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );
        
        if (signUpCredential.user != null) {
          LoggingService.info('✓ Email/password sign up successful');
          
          // Test 4: Test sign out
          await auth.signOut();
          LoggingService.info('✓ Email/password sign out successful');
          
          // Test 5: Test sign in with created account
          final signInCredential = await auth.signInWithEmailAndPassword(
            email: testEmail,
            password: testPassword,
          );
          
          if (signInCredential.user != null) {
            LoggingService.info('✓ Email/password sign in successful');
            
            // Test 6: Test password reset
            await auth.sendPasswordResetEmail(email: testEmail);
            LoggingService.info('✓ Password reset email sent');
            
            // Clean up: Delete test account
            await signInCredential.user!.delete();
            LoggingService.info('✓ Test account deleted');
          } else {
            LoggingService.error('✗ Email/password sign in failed');
            return false;
          }
        } else {
          LoggingService.error('✗ Email/password sign up failed - no user returned');
          return false;
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          LoggingService.info('✓ Test account already exists, testing sign in...');
          
          // Try to sign in with existing account
          try {
            final signInCredential = await auth.signInWithEmailAndPassword(
              email: testEmail,
              password: testPassword,
            );
            
            if (signInCredential.user != null) {
              LoggingService.info('✓ Email/password sign in with existing account successful');
              
              // Clean up: Delete test account
              await signInCredential.user!.delete();
              LoggingService.info('✓ Test account deleted');
            } else {
              LoggingService.error('✗ Email/password sign in with existing account failed');
              return false;
            }
          } catch (signInError) {
            LoggingService.error('✗ Email/password sign in with existing account failed: $signInError');
            return false;
          }
        } else {
          LoggingService.error('✗ Email/password sign up failed: ${e.code}');
          return false;
        }
      } catch (e) {
        LoggingService.error('✗ Email/password authentication failed: $e');
        return false;
      }

      LoggingService.info('✓ All authentication tests passed!');
      return true;
    } catch (e) {
      LoggingService.error('✗ Authentication test suite failed: $e');
      return false;
    }
  }

  // Test auth state changes
  static Stream<bool> testAuthStateChanges() {
    return FirebaseAuth.instance.authStateChanges().map((user) {
      LoggingService.info('Auth state changed: ${user?.uid ?? 'No user'}');
      return user != null;
    });
  }

  // Test user properties
  static Future<Map<String, dynamic>> testUserProperties() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {'error': 'No user signed in'};
    }

    return {
      'uid': user.uid,
      'email': user.email,
      'emailVerified': user.emailVerified,
      'isAnonymous': user.isAnonymous,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'creationTime': user.metadata.creationTime?.toIso8601String(),
      'lastSignInTime': user.metadata.lastSignInTime?.toIso8601String(),
    };
  }

  // Test error handling
  static Future<void> testErrorHandling() async {
    try {
      // Test invalid email
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: 'invalid-email',
        password: 'password',
      );
    } on FirebaseAuthException catch (e) {
      LoggingService.info('✓ Invalid email error handled: ${e.code}');
    }

    try {
      // Test wrong password
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'wrongpassword',
      );
    } on FirebaseAuthException catch (e) {
      LoggingService.info('✓ Wrong password error handled: ${e.code}');
    }

    try {
      // Test weak password
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: 'test2@example.com',
        password: '123',
      );
    } on FirebaseAuthException catch (e) {
      LoggingService.info('✓ Weak password error handled: ${e.code}');
    }
  }
}
