import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/presentation/providers/auth_providers.dart';
import 'package:sique/presentation/screens/auth/email_auth_dialog.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

/// Step 21: Account Setup & Authentication Gate
class Step21AuthGate extends ConsumerStatefulWidget {
  const Step21AuthGate({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  ConsumerState<Step21AuthGate> createState() => _Step21AuthGateState();
}

class _Step21AuthGateState extends ConsumerState<Step21AuthGate> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final success =
          await ref.read(authNotifierProvider.notifier).signInWithGoogle();
      if (success && mounted) {
        widget.onNext();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDemoAthlete() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authNotifierProvider.notifier).signInWithDemoAthlete();
      if (mounted) widget.onNext();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authRepo = ref.watch(authRepositoryProvider);
    final isConfigured = authRepo.isConfigured;
    final authState = ref.watch(authNotifierProvider);

    return OnboardingStepScaffold(
      title: 'Account & Identity',
      subtitle:
          'Sign in to link Google Health Connect and sync your training data across devices.',
      icon: Icons.lock_person_rounded,
      continueLabel: 'Continue as Guest',
      continueKey: const Key('step_21_guest_btn'),
      onContinue: widget.onNext,
      banner: !isConfigured
          ? Container(
              key: const Key('step_21_unconfigured_banner'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppTheme.warning, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sign-in unavailable: Firebase not configured',
                      style: TextStyle(
                        fontFamily: 'MacroSans',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.warning,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
      child: Column(
        children: [
          const SizedBox(height: 12),
          if (authState.isAuthenticated) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppTheme.success.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppTheme.success, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Signed in as ${authState.user.displayName}',
                          style: const TextStyle(
                            fontFamily: 'MacroSans',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          authState.user.email,
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          AppleTactileCard(
            key: const Key('step_21_google_btn'),
            onTap: (_isLoading || !isConfigured) ? null : _handleGoogleSignIn,
            backgroundColor:
                isConfigured ? Colors.white : AppTheme.cardElevated,
            borderRadius: 16,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black87),
                  )
                else ...[
                  const Icon(Icons.g_mobiledata_rounded,
                      color: Color(0xFF4285F4), size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isConfigured
                          ? Colors.black87
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppleTactileCard(
            key: const Key('step_21_email_btn'),
            onTap: (_isLoading || !isConfigured)
                ? null
                : () => EmailAuthDialog.show(context, onSuccess: widget.onNext),
            backgroundColor: AppTheme.cardSurface,
            border: Border.all(color: AppTheme.cardBorder),
            borderRadius: 16,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.email_outlined,
                  color: isConfigured
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Continue with Email',
                  style: TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isConfigured
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppleTactileCard(
            key: const Key('step_21_demo_btn'),
            onTap: _isLoading ? null : _handleDemoAthlete,
            backgroundColor: AppTheme.cardSurface,
            border: Border.all(color: AppTheme.cardBorder),
            borderRadius: 16,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fitness_center_rounded,
                    color: AppTheme.expenditure, size: 20),
                SizedBox(width: 10),
                Text(
                  'Try Demo Athlete Profile',
                  style: TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
