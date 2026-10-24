import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/presentation/providers/auth_providers.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/auth_legal_footer.dart';

/// Modal dialog providing Email/Password Sign-In, Sign-Up, and Password Reset.
class EmailAuthDialog extends ConsumerStatefulWidget {
  const EmailAuthDialog({super.key, this.onSuccess});

  final VoidCallback? onSuccess;

  static Future<bool?> show(BuildContext context, {VoidCallback? onSuccess}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => EmailAuthDialog(onSuccess: onSuccess),
    );
  }

  @override
  ConsumerState<EmailAuthDialog> createState() => _EmailAuthDialogState();
}

enum _AuthMode { signIn, signUp, forgotPassword }

class _EmailAuthDialogState extends ConsumerState<EmailAuthDialog> {
  _AuthMode _mode = _AuthMode.signIn;
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _statusMessage;
  bool _isSuccessMessage = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_mode == _AuthMode.signUp &&
        _passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _statusMessage = 'Passwords do not match';
        _isSuccessMessage = false;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
      _isSuccessMessage = false;
    });

    final notifier = ref.read(authNotifierProvider.notifier);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    try {
      if (_mode == _AuthMode.signIn) {
        final success = await notifier.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (success && mounted) {
          Navigator.of(context).pop(true);
          widget.onSuccess?.call();
        }
      } else if (_mode == _AuthMode.signUp) {
        final success = await notifier.signUpWithEmailAndPassword(
          email: email,
          password: password,
          displayName: name.isNotEmpty ? name : null,
        );
        if (success && mounted) {
          Navigator.of(context).pop(true);
          widget.onSuccess?.call();
        }
      } else if (_mode == _AuthMode.forgotPassword) {
        final success = await notifier.sendPasswordResetEmail(email);
        if (mounted) {
          if (success) {
            setState(() {
              _statusMessage = 'Password reset email sent. Check your inbox.';
              _isSuccessMessage = true;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = e
              .toString()
              .replaceFirst(RegExp(r'^(Exception|StateError):\s*'), '');
          _isSuccessMessage = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth errors
    final authState = ref.watch(authNotifierProvider);
    final errorMessage = (authState is AuthError) ? authState.message : null;

    return Dialog(
      backgroundColor: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _mode == _AuthMode.signIn
                              ? 'Sign In with Email'
                              : _mode == _AuthMode.signUp
                                  ? 'Create Sique Account'
                                  : 'Reset Password',
                          style: const TextStyle(
                            fontFamily: 'MacroSans',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppTheme.textSecondary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_statusMessage != null || errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isSuccessMessage
                            ? AppTheme.success.withValues(alpha: 0.12)
                            : AppTheme.calories.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _isSuccessMessage
                              ? AppTheme.success.withValues(alpha: 0.4)
                              : AppTheme.calories.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        _statusMessage ?? errorMessage ?? '',
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 12,
                          color: _isSuccessMessage
                              ? AppTheme.success
                              : AppTheme.calories,
                        ),
                      ),
                    ),
                  if (_mode == _AuthMode.signUp) ...[
                    TextFormField(
                      key: const Key('auth_name_input'),
                      controller: _nameController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Display Name',
                        prefixIcon: const Icon(Icons.person_outline_rounded,
                            color: AppTheme.textSecondary),
                        filled: true,
                        fillColor: AppTheme.cardElevated,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    key: const Key('auth_email_input'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Email is required';
                      }
                      final emailRegex = RegExp(
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                      if (!emailRegex.hasMatch(v.trim())) {
                        return 'Invalid email address';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: const Icon(Icons.email_outlined,
                          color: AppTheme.textSecondary),
                      filled: true,
                      fillColor: AppTheme.cardElevated,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  if (_mode != _AuthMode.forgotPassword) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('auth_password_input'),
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Password is required';
                        }
                        if (v.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded,
                            color: AppTheme.textSecondary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: AppTheme.textSecondary,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: AppTheme.cardElevated,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    if (_mode == _AuthMode.signUp) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const Key('auth_confirm_password_input'),
                        controller: _confirmPasswordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (v != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock_reset_rounded,
                              color: AppTheme.textSecondary),
                          filled: true,
                          fillColor: AppTheme.cardElevated,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    key: const Key('auth_submit_btn'),
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.activeBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _mode == _AuthMode.signIn
                                ? 'Sign In'
                                : _mode == _AuthMode.signUp
                                    ? 'Create Account'
                                    : 'Send Reset Email',
                            style: const TextStyle(
                              fontFamily: 'MacroSans',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  if (_mode == _AuthMode.signIn) ...[
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        TextButton(
                          key: const Key('auth_switch_to_signup_btn'),
                          onPressed: () {
                            ref
                                .read(authNotifierProvider.notifier)
                                .clearError();
                            setState(() {
                              _mode = _AuthMode.signUp;
                              _statusMessage = null;
                            });
                          },
                          child: const Text('Create an account'),
                        ),
                        TextButton(
                          key: const Key('auth_switch_to_forgot_btn'),
                          onPressed: () {
                            ref
                                .read(authNotifierProvider.notifier)
                                .clearError();
                            setState(() {
                              _mode = _AuthMode.forgotPassword;
                              _statusMessage = null;
                            });
                          },
                          child: const Text('Forgot password?'),
                        ),
                      ],
                    ),
                  ] else ...[
                    Center(
                      child: TextButton(
                        key: const Key('auth_switch_to_signin_btn'),
                        onPressed: () {
                          ref.read(authNotifierProvider.notifier).clearError();
                          setState(() {
                            _mode = _AuthMode.signIn;
                            _statusMessage = null;
                          });
                        },
                        child: const Text('Back to Sign In'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const AuthLegalFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
