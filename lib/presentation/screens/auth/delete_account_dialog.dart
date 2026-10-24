import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/domain/models/user_account.dart';
import 'package:sique/presentation/providers/auth_providers.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Provider-aware modal dialog for permanently deleting user account and session.
class DeleteAccountDialog extends ConsumerStatefulWidget {
  const DeleteAccountDialog({super.key, required this.user});

  final UserAccount user;

  static Future<bool?> show(BuildContext context, {required UserAccount user}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => DeleteAccountDialog(user: user),
    );
  }

  @override
  ConsumerState<DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<DeleteAccountDialog> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete() async {
    final isEmail = widget.user.authProvider == AuthProviderType.email;
    final password = _passwordController.text;

    if (isEmail && password.isEmpty) {
      setState(() =>
          _errorMessage = 'Please enter your password to confirm deletion.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success =
          await ref.read(authNotifierProvider.notifier).deleteAccount(
                password: isEmail ? password : null,
              );
      if (mounted) {
        if (success) {
          Navigator.of(context).pop(true);
        } else {
          final authState = ref.read(authNotifierProvider);
          setState(() {
            _errorMessage = (authState is AuthError)
                ? authState.message
                : 'Account deletion failed. Please re-authenticate and try again.';
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
    final isEmail = widget.user.authProvider == AuthProviderType.email;

    return AlertDialog(
      backgroundColor: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.calories, size: 24),
          SizedBox(width: 8),
          Text(
            'Delete Account',
            style: TextStyle(
              fontFamily: 'MacroSans',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEmail
                  ? 'Permanently delete your account (${widget.user.email}). All local workout, nutrition, and weight data will be permanently wiped. This cannot be undone. Enter your password to confirm:'
                  : 'Permanently delete your account (${widget.user.displayName}). All local workout, nutrition, and weight data will be permanently wiped. This cannot be undone. You may be prompted to re-authenticate with Google.',
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
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
            if (isEmail)
              TextFormField(
                key: const Key('delete_account_password_input'),
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Account Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded,
                      color: AppTheme.textSecondary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: AppTheme.cardElevated,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('delete_account_cancel_btn'),
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const Key('delete_account_confirm_btn'),
          onPressed: _isLoading ? null : _handleDelete,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.calories,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Permanently Delete'),
        ),
      ],
    );
  }
}
