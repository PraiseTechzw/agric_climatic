import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../widgets/animated_background.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_button.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import '../services/user_profile_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final PhoneNumber _initialPhone = PhoneNumber(isoCode: 'ZW');

  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _showPasswordResetDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: emailController,
              labelText: 'Email',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isNotEmpty) {
                Navigator.of(context).pop();
                try {
                  await AuthService.sendPasswordResetEmail(
                    emailController.text,
                  );
                  _showSuccess('Password reset email sent! Check your inbox.');
                } catch (e) {
                  _showError(AuthService.getErrorMessage(e.toString()));
                }
              }
            },
            child: const Text('Send Reset Email'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Logo and Title
                      _buildHeader(),
                      const SizedBox(height: 40),
                      // Auth Form
                      _buildAuthForm(),
                      const SizedBox(height: 24),
                      // Help Text
                      _buildHelpText(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.agriculture, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            'AgriClimatic',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agricultural Climate Prediction & Analysis',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAuthForm() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Text(
                  _isLogin ? 'Welcome Back' : 'Create Account',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin
                      ? 'Sign in to access your agricultural insights'
                      : 'Sign up to get started with agricultural predictions',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Email Field
                CustomTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _emailController.text.trim().isEmpty
                        ? ' '
                        : _emailController.text.trim(),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 20),
                if (!_isLogin) ...[
                  // Phone (with country code) - required on Sign Up only
                  InternationalPhoneNumberInput(
                    onInputChanged: (PhoneNumber number) {},
                    selectorConfig: const SelectorConfig(
                      selectorType: PhoneInputSelectorType.DROPDOWN,
                    ),
                    initialValue: _initialPhone,
                    textFieldController: _phoneController,
                    inputDecoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                    ),
                    formatInput: true,
                    maxLength: 15,
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: false,
                      decimal: false,
                    ),
                    validator: (value) {
                      if (!_isLogin) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                ],
                // Password Field
                CustomTextField(
                  controller: _passwordController,
                  labelText: 'Password',
                  prefixIcon: Icons.lock_outlined,
                  obscureText: _obscurePassword,
                  suffixIcon: _obscurePassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                  onSuffixIconPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _passwordController.text.isEmpty
                        ? ' '
                        : '•' * _passwordController.text.length,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ),
                // Confirm Password Field (only for sign up)
                if (!_isLogin) ...[
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: _confirmPasswordController,
                    labelText: 'Confirm Password',
                    prefixIcon: Icons.lock_outlined,
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: _obscureConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                    onSuffixIconPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 32),
                // Sign In/Up Button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return LoadingButton(
                      text: _isLogin ? 'Sign In' : 'Sign Up',
                      isLoading: authProvider.isLoading,
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;

                        if (_isLogin) {
                          await authProvider.signInWithEmailAndPassword(
                            _emailController.text,
                            _passwordController.text,
                          );
                        } else {
                          if (_passwordController.text !=
                              _confirmPasswordController.text) {
                            _showError('Passwords do not match');
                            return;
                          }
                          await authProvider.createUserWithEmailAndPassword(
                            _emailController.text,
                            _passwordController.text,
                          );
                          // Save phone to Firestore in E.164
                          try {
                            final parsed = await PhoneNumber.getParsableNumber(
                              PhoneNumber(
                                phoneNumber: _phoneController.text,
                                isoCode: _initialPhone.isoCode,
                              ),
                            );
                            await UserProfileService.savePhoneNumber(parsed);
                          } catch (_) {}
                        }

                        if (!mounted) return;
                        if (authProvider.errorMessage != null) {
                          _showError(authProvider.errorMessage!);
                        } else {
                          _showSuccess(
                            _isLogin
                                ? 'Signed in successfully'
                                : 'Account created successfully',
                          );
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),
                // Toggle between Sign In and Sign Up
                TextButton(
                  onPressed: _toggleAuthMode,
                  child: Text(
                    _isLogin
                        ? "Don't have an account? Sign Up"
                        : "Already have an account? Sign In",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Forgot Password (only for login)
                if (_isLogin) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _showPasswordResetDialog,
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpText() {
    return Text(
      'By continuing, you agree to our Terms of Service and Privacy Policy',
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
      textAlign: TextAlign.center,
    );
  }
}
