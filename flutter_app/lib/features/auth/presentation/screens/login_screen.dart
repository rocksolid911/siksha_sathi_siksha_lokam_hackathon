import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'phone_login_screen.dart';
import 'package:shiksha_saathi/l10n/app_localizations.dart';

/// Login screen with Email/Password and Google Sign-In
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_isLogin) {
      context.read<AuthBloc>().add(AuthEmailLoginRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ));
    } else {
      context.read<AuthBloc>().add(AuthEmailRegisterRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
          ));
    }
  }

  void _signInWithGoogle() {
    context.read<AuthBloc>().add(const AuthGoogleLoginRequested());
  }

  void _navigateToPhoneLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.sos,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppConstants.spacingLg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: AppConstants.spacingXxl),

                    // Logo and Title
                    _buildHeader(),

                    SizedBox(height: AppConstants.spacingXxl),

                    // Name field (only for registration)
                    if (!_isLogin) ...[
                      _buildNameField(),
                      SizedBox(height: AppConstants.spacingMd),
                    ],

                    // Email field
                    _buildEmailField(),
                    SizedBox(height: AppConstants.spacingMd),

                    // Password field
                    _buildPasswordField(),
                    SizedBox(height: AppConstants.spacingLg),

                    // Submit button
                    _buildSubmitButton(isLoading),
                    SizedBox(height: AppConstants.spacingMd),

                    // Toggle login/register
                    _buildToggleButton(),

                    SizedBox(height: AppConstants.spacingXl),

                    // Divider
                    _buildDivider(),

                    SizedBox(height: AppConstants.spacingXl),

                    // Social login buttons
                    _buildGoogleButton(isLoading),
                    SizedBox(height: AppConstants.spacingMd),
                    _buildPhoneButton(isLoading),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // App icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.school_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        SizedBox(height: AppConstants.spacingLg),
        Text(
          AppLocalizations.of(context)!.appName,
          style: GoogleFonts.notoSans(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _isLogin
              ? AppLocalizations.of(context)!.welcomeBack
              : AppLocalizations.of(context)!.createAccountSubtitle,
          style: GoogleFonts.notoSans(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: _nameController,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: l10n.fullName,
        hintText: l10n.enterName,
        prefixIcon: const Icon(Icons.person_outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        ),
      ),
      validator: (value) {
        if (!_isLogin && (value == null || value.trim().isEmpty)) {
          return l10n.enterName;
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: l10n.email,
        hintText: l10n.enterEmail,
        prefixIcon: const Icon(Icons.email_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.enterEmail;
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return l10n.validEmail;
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: l10n.password,
        hintText: l10n.enterPassword,
        prefixIcon: const Icon(Icons.lock_outlined),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return l10n.enterPassword;
        }
        if (value.length < 6) {
          return l10n.passwordLength;
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton(bool isLoading) {
    return ElevatedButton(
      onPressed: isLoading ? null : _submit,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: AppConstants.spacingMd),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              _isLogin
                  ? AppLocalizations.of(context)!.signIn
                  : AppLocalizations.of(context)!.createAccount,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
    );
  }

  Widget _buildToggleButton() {
    final l10n = AppLocalizations.of(context)!;
    return TextButton(
      onPressed: _toggleMode,
      child: Text(
        _isLogin ? l10n.dontHaveAccount : l10n.alreadyHaveAccount,
      ),
    );
  }

  Widget _buildDivider() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingMd),
          child: Text(
            l10n.or,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildGoogleButton(bool isLoading) {
    return OutlinedButton.icon(
      onPressed: isLoading ? null : _signInWithGoogle,
      icon: Image.network(
        'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
        height: 24,
        width: 24,
        errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 24),
      ),
      label: Text(AppLocalizations.of(context)!.continueWithGoogle),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: AppConstants.spacingMd),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        ),
      ),
    );
  }

  Widget _buildPhoneButton(bool isLoading) {
    return OutlinedButton.icon(
      onPressed: isLoading ? null : _navigateToPhoneLogin,
      icon: const Icon(Icons.phone_outlined),
      label: Text(AppLocalizations.of(context)!.continueWithPhone),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: AppConstants.spacingMd),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        ),
      ),
    );
  }
}
