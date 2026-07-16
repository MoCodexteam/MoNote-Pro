// lib/features/auth/presentation/screens/signup_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:formz/formz.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_notifier.dart';
import '../providers/auth_state.dart';
import '../widgets/auth_text_form_field.dart';

/// Flutter version of the React RegisterScreen / Signup screen
/// Modern UI with Riverpod + Formz validation + loading state + error handling
class SignupScreen extends ConsumerStatefulWidget {
  final VoidCallback onNavigateToLogin;

  const SignupScreen({
    super.key,
    required this.onNavigateToLogin,
  });

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Formz inputs
  FullName _fullName = FullName.pure();
  Email _email = Email.pure();
  Password _password = Password.pure();

  bool _isObscure = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isFormValid =>
      Formz.validate([_fullName, _email, _password]);

  Future<void> _handleRegister() async {
    // Mark all fields dirty to trigger validation
    setState(() {
      _fullName = FullName.dirty(_fullNameController.text);
      _email = Email.dirty(_emailController.text);
      _password = Password.dirty(_passwordController.text);
    });

    if (!_isFormValid) return;

    final notifier = ref.read(authNotifierProvider.notifier);

    await notifier.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      fullName: _fullNameController.text.trim(),
    );
  }


  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo & Welcome
                _buildHeader(context),

                const SizedBox(height: 48),

                // Form
                _buildForm(context, authState),

                const SizedBox(height: 32),


                const SizedBox(height: 32),

                // Login link
                _buildLoginLink(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'lib/assets/images/logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Create Account',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Join ${AppConstants.appName} and start organizing',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, AuthState authState) {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthTextFormField(
            controller: _fullNameController,
            label: 'Full Name',
            hint: 'Enter Your Full Name',
            prefixIcon: Icons.person_outline,
            keyboardType: TextInputType.name,
            errorText: _fullName.displayError,
            onChanged: (value) => setState(() {
              _fullName = FullName.dirty(value);
            }),
          ),
          const SizedBox(height: 20),
          AuthTextFormField(
            controller: _emailController,
            label: 'Email',
            hint: 'Enter Email',
            prefixIcon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            errorText: _email.displayError,
            onChanged: (value) => setState(() {
              _email = Email.dirty(value);
            }),
          ),
          const SizedBox(height: 20),
          AuthTextFormField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Create a strong password',
            prefixIcon: Icons.lock_outline,
            obscureText: _isObscure,
            suffixIcon: IconButton(
              icon: Icon(
                _isObscure ? Icons.visibility_off : Icons.visibility,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              onPressed: () => setState(() => _isObscure = !_isObscure),
            ),
            errorText: _password.displayError,
            onChanged: (value) => setState(() {
              _password = Password.dirty(value);
            }),
          ),
          const SizedBox(height: 8),
          Text(
            'Must be at least 6 characters',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: authState.isLoading ? null : _handleRegister,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: authState.isLoading
                  ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
                  : const Text(
                'Create Account',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: widget.onNavigateToLogin,
          child: const Text(
            'Sign in',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}