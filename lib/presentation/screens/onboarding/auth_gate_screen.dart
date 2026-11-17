import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/presentation/screens/auth/email_auth_dialog.dart';
import 'package:sique/presentation/screens/onboarding/onboarding_flow_screen.dart';
import 'package:sique/presentation/widgets/auth_legal_footer.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../scaffold_with_nav_bar.dart';
import '../../widgets/apple_tactile_card.dart';

/// Screen presented after Strategy Questionnaire where users authenticate or continue as guest.
class AuthGateScreen extends ConsumerStatefulWidget {
  const AuthGateScreen({super.key, this.onProceed});

  final VoidCallback? onProceed;

  @override
  ConsumerState<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends ConsumerState<AuthGateScreen> {
  bool _isLoading = false;

  void _proceed() {
    if (widget.onProceed != null) {
      widget.onProceed!();
      return;
    }

    final db = ref.read(databaseProvider);
    final isCompleted =
        db.getSetting('onboarding_completed', 'false').toLowerCase() == 'true';

    if (!mounted) return;
    if (isCompleted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ScaffoldWithNavBar()),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingFlowScreen()),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final success =
          await ref.read(authNotifierProvider.notifier).signInWithGoogle();
      if (!mounted) return;
      if (success) {
        _proceed();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Sign-In was cancelled or incomplete.'),
            backgroundColor: AppTheme.surface,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign-in error: $e'),
          backgroundColor: AppTheme.calories,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleContinueAsGuest() {
    _proceed();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(flex: 1),
                        // Lock / Account Badge
                        Center(
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.activeBlue.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    AppTheme.activeBlue.withValues(alpha: 0.35),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.lock_person_rounded,
                              color: AppTheme.activeBlue,
                              size: 36,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Account & Cloud Sync',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Connect your Google account to automatically sync workouts from Hevy & Health Connect, or explore in guest mode.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const Spacer(flex: 2),

                        if (!ref
                            .watch(authRepositoryProvider)
                            .isConfigured) ...[
                          Container(
                            key: const Key('auth_gate_unconfigured_banner'),
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.warning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.warning.withValues(alpha: 0.4),
                                width: 1,
                              ),
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
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Button 1: Google Sign-In
                        AppleTactileCard(
                          key: const Key('auth_gate_google_btn'),
                          onTap: (_isLoading ||
                                  !ref
                                      .watch(authRepositoryProvider)
                                      .isConfigured)
                              ? null
                              : _handleGoogleSignIn,
                          backgroundColor:
                              ref.watch(authRepositoryProvider).isConfigured
                                  ? Colors.white
                                  : AppTheme.cardElevated,
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
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.black87),
                                  ),
                                )
                              else ...[
                                const Icon(Icons.g_mobiledata_rounded,
                                    color: Color(0xFF4285F4), size: 28),
                                const SizedBox(width: 8),
                                Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: ref
                                            .watch(authRepositoryProvider)
                                            .isConfigured
                                        ? Colors.black87
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Button 2: Email Sign-In / Register
                        AppleTactileCard(
                          key: const Key('auth_gate_email_btn'),
                          onTap: (_isLoading ||
                                  !ref
                                      .watch(authRepositoryProvider)
                                      .isConfigured)
                              ? null
                              : () => EmailAuthDialog.show(
                                    context,
                                    onSuccess: _proceed,
                                  ),
                          backgroundColor: AppTheme.cardSurface,
                          borderRadius: 16,
                          border:
                              Border.all(color: AppTheme.cardBorder, width: 1),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.email_outlined,
                                color: ref
                                        .watch(authRepositoryProvider)
                                        .isConfigured
                                    ? AppTheme.textPrimary
                                    : AppTheme.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Continue with Email',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: ref
                                          .watch(authRepositoryProvider)
                                          .isConfigured
                                      ? AppTheme.textPrimary
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Button 3: Continue as Guest
                        TextButton(
                          key: const Key('auth_gate_guest_btn'),
                          onPressed: _isLoading ? null : _handleContinueAsGuest,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Continue as Guest (Offline Mode)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const AuthLegalFooter(),
                        SizedBox(
                            height: bottomPadding > 0 ? bottomPadding : 16),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
