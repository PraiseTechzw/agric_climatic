import 'package:firebase_auth/firebase_auth.dart';
import '../services/logging_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Check if user is authenticated
  static bool get isAuthenticated => _auth.currentUser != null;

  // Check if user is anonymous
  static bool get isAnonymous => _auth.currentUser?.isAnonymous ?? false;

  // Check if email is verified
  static bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Get user ID
  static String? get userId => _auth.currentUser?.uid;

  // Get user email
  static String? get userEmail => _auth.currentUser?.email;

  // Get user display name
  static String? get displayName => _auth.currentUser?.displayName;

  // Sign in with email and password
  static Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      LoggingService.info('Attempting to sign in with email: $email');

      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      LoggingService.info('Successfully signed in: ${credential.user?.uid}');
      return credential;
    } on FirebaseAuthException catch (e) {
      LoggingService.error('Sign in failed: ${e.code}', error: e);
      rethrow;
    } catch (e) {
      LoggingService.error('Unexpected error during sign in', error: e);
      rethrow;
    }
  }

  // Create user with email and password
  static Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      LoggingService.info('Attempting to create user with email: $email');

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Send email verification
      if (credential.user != null && !credential.user!.emailVerified) {
        await credential.user!.sendEmailVerification();
        LoggingService.info(
          'Email verification sent to: ${credential.user!.email}',
        );
      }

      LoggingService.info('Successfully created user: ${credential.user?.uid}');
      return credential;
    } on FirebaseAuthException catch (e) {
      LoggingService.error('User creation failed: ${e.code}', error: e);
      rethrow;
    } catch (e) {
      LoggingService.error('Unexpected error during user creation', error: e);
      rethrow;
    }
  }

  // Sign in anonymously
  static Future<UserCredential?> signInAnonymously() async {
    try {
      LoggingService.info('Attempting anonymous sign in');

      final credential = await _auth.signInAnonymously();

      LoggingService.info(
        'Successfully signed in anonymously: ${credential.user?.uid}',
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      LoggingService.error('Anonymous sign in failed: ${e.code}', error: e);
      rethrow;
    } catch (e) {
      LoggingService.error(
        'Unexpected error during anonymous sign in',
        error: e,
      );
      rethrow;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      LoggingService.info('Attempting to sign out');

      await _auth.signOut();

      LoggingService.info('Successfully signed out');
    } catch (e) {
      LoggingService.error('Sign out failed', error: e);
      rethrow;
    }
  }

  // Send password reset email
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      LoggingService.info('Sending password reset email to: $email');

      await _auth.sendPasswordResetEmail(email: email.trim());

      LoggingService.info('Password reset email sent successfully');
    } on FirebaseAuthException catch (e) {
      LoggingService.error('Password reset failed: ${e.code}', error: e);
      rethrow;
    } catch (e) {
      LoggingService.error('Unexpected error during password reset', error: e);
      rethrow;
    }
  }

  // Send email verification
  static Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        LoggingService.info('Sending email verification to: ${user.email}');

        await user.sendEmailVerification();

        LoggingService.info('Email verification sent successfully');
      }
    } catch (e) {
      LoggingService.error('Email verification failed', error: e);
      rethrow;
    }
  }

  // Reload user data
  static Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
      LoggingService.info('User data reloaded');
    } catch (e) {
      LoggingService.error('Failed to reload user data', error: e);
      rethrow;
    }
  }

  // Delete user account
  static Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        LoggingService.info('Deleting user account: ${user.uid}');

        await user.delete();

        LoggingService.info('User account deleted successfully');
      }
    } catch (e) {
      LoggingService.error('Account deletion failed', error: e);
      rethrow;
    }
  }

  // Update user profile
  static Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        LoggingService.info('Updating user profile: ${user.uid}');

        await user.updateDisplayName(displayName);
        if (photoURL != null) {
          await user.updatePhotoURL(photoURL);
        }

        LoggingService.info('User profile updated successfully');
      }
    } catch (e) {
      LoggingService.error('Profile update failed', error: e);
      rethrow;
    }
  }

  // Get error message from Firebase Auth exception
  static String getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'invalid-credential':
        return 'The credential is invalid or has expired.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email address but different sign-in credentials.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please sign in again.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'invalid-verification-code':
        return 'Invalid verification code.';
      case 'invalid-verification-id':
        return 'Invalid verification ID.';
      case 'missing-verification-code':
        return 'Verification code is required.';
      case 'missing-verification-id':
        return 'Verification ID is required.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  // Listen to auth state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Listen to user changes
  static Stream<User?> get userChanges => _auth.userChanges();
}


