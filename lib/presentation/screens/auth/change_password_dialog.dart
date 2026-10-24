import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/presentation/providers/auth_providers.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Dialog allowing email users to change their password with current password verification.
class ChangePasswordDialog extends ConsumerStatefulWidget {
  const ChangePasswordDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => const ChangePasswordDialog(),
    );
  }

  @override
  ConsumerState<ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success =
          await ref.read(authNotifierProvider.notifier).changePassword(
                currentPassword: _currentPasswordController.text,
                newPassword: _newPasswordController.text,
              );
      if (mounted) {
        if (success) {
          Navigator.of(context).pop(true);
        } else {
          final authState = ref.read(authNotifierProvider);
          setState(() {
            _errorMessage = (authState is AuthError)
                ? authState.message
                : 'Failed to change password. Check your current password.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e
              .toString()
              .replaceFirst(RegExp(r'^(Exception|StateError):\s*'), '');
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Change Password',
                      style: TextStyle(
                        fontFamily: 'MacroSans',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
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
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.calories.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.calories.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 12,
                        color: AppTheme.calories,
                      ),
                    ),
                  ),
                TextFormField(
                  key: const Key('change_password_current_input'),
                  controller: _currentPasswordController,
                  obscureText: _obscureCurrent,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Current password is required'
                      : null,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        color: AppTheme.textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrent
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: AppTheme.textSecondary,
                      ),
                      onPressed: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                    filled: true,
                    fillColor: AppTheme.cardElevated,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('change_password_new_input'),
                  controller: _newPasswordController,
                  obscureText: _obscureNew,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'New password is required';
                    }
                    if (v.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.vpn_key_outlined,
                        color: AppTheme.textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNew
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: AppTheme.textSecondary,
                      ),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                    filled: true,
                    fillColor: AppTheme.cardElevated,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('change_password_confirm_input'),
                  controller: _confirmPasswordController,
                  obscureText: _obscureNew,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  validator: (v) {
                    if (v != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: const Icon(Icons.check_circle_outline_rounded,
                        color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.cardElevated,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  key: const Key('change_password_submit_btn'),
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
                      : const Text(
                          'Update Password',
                          style: TextStyle(
                            fontFamily: 'MacroSans',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
