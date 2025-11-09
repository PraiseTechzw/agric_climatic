import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/logging_service.dart';
import '../services/user_profile_service.dart';
import '../services/firebase_config.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get isAuthenticated => _user != null;
  bool get isAnonymous => _user?.isAnonymous ?? false;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
      LoggingService.info('Auth state changed: ${user?.uid ?? 'No user'}');
    });
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();
      _clearSuccess();

      if (!FirebaseConfig.isInitialized) {
        await FirebaseConfig.initializeWithFallback();
      }

      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // Ensure phone is saved if missing
      try {
        final profile = await UserProfileService.getCurrentUserProfile();
        if (profile == null ||
            (profile['phone_e164'] as String?)?.isEmpty == true) {
          // No-op: UI should prompt user to add phone; handled in screen level
        }
      } catch (_) {}

      _user = credential.user;
      _setSuccess('Signed in successfully');
      LoggingService.info('User signed in: ${_user?.uid}');
    } on FirebaseAuthException catch (e) {
      final message =
          (e.code == 'unknown' &&
              (e.message ?? '').toUpperCase().contains(
                'CONFIGURATION_NOT_FOUND',
              ))
          ? 'Service configuration missing. Please try again later.'
          : _getErrorMessage(e.code);
      _setError(message);
      LoggingService.error('Sign in failed', error: e);
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      LoggingService.error('Sign in failed', error: e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      _setLoading(true);
      _clearError();
      _clearSuccess();

      if (!FirebaseConfig.isInitialized) {
        await FirebaseConfig.initializeWithFallback();
      }

      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

      _user = credential.user;

      // Send email verification
      if (_user != null && !_user!.emailVerified) {
        try {
          await _user!.sendEmailVerification();
          _setSuccess('Account created! Please check your email to verify your account.');
          LoggingService.info('Email verification sent to: ${_user!.email}');
        } catch (e) {
          _setSuccess('Account created successfully!');
          LoggingService.warning('Could not send verification email', error: e);
        }
      } else {
        _setSuccess('Account created successfully!');
      }

      LoggingService.info('User created: ${_user?.uid}');
    } on FirebaseAuthException catch (e) {
      final message =
          (e.code == 'unknown' &&
              (e.message ?? '').toUpperCase().contains(
                'CONFIGURATION_NOT_FOUND',
              ))
          ? 'Service configuration missing. Please try again later.'
          : _getErrorMessage(e.code);
      _setError(message);
      LoggingService.error('Sign up failed', error: e);
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      LoggingService.error('Sign up failed', error: e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInAnonymously() async {
    try {
      _setLoading(true);
      _clearError();
      _clearSuccess();

      if (!FirebaseConfig.isInitialized) {
        await FirebaseConfig.initializeWithFallback();
      }

      final credential = await FirebaseAuth.instance.signInAnonymously();
      _user = credential.user;
      _setSuccess('Signed in as guest');
      LoggingService.info('Anonymous user signed in: ${_user?.uid}');
    } catch (e) {
      _setError('Failed to sign in anonymously. Please try again.');
      LoggingService.error('Anonymous sign in failed', error: e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      _clearError();
      _clearSuccess();

      await FirebaseAuth.instance.signOut();
      _user = null;
      _setSuccess('Signed out successfully');
      LoggingService.info('User signed out');
    } catch (e) {
      _setError('Failed to sign out. Please try again.');
      LoggingService.error('Sign out failed', error: e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      _clearError();
      _clearSuccess();

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      _setSuccess('Password reset email sent! Please check your inbox.');
      LoggingService.info('Password reset email sent to: $email');
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e.code));
      LoggingService.error('Password reset failed', error: e);
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      LoggingService.error('Password reset failed', error: e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resendEmailVerification() async {
    try {
      _setLoading(true);
      _clearError();
      _clearSuccess();

      if (_user != null && !_user!.emailVerified) {
        await _user!.sendEmailVerification();
        _setSuccess('Verification email sent! Please check your inbox.');
        LoggingService.info('Email verification resent to: ${_user!.email}');
      } else {
        _setError('Email is already verified.');
      }
    } catch (e) {
      _setError('Failed to resend verification email. Please try again.');
      LoggingService.error('Resend verification failed', error: e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteAccount() async {
    try {
      if (_user != null) {
        await _user!.delete();
        _user = null;
        LoggingService.info('User account deleted');
      }
    } catch (e) {
      _setError('Failed to delete account. Please try again.');
      LoggingService.error('Delete account failed', error: e);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _successMessage = null;
    notifyListeners();
  }

  void _setSuccess(String success) {
    _successMessage = success;
    _errorMessage = null;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  String _getErrorMessage(String errorCode) {
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
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
