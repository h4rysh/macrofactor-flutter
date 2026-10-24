import 'package:flutter/material.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

/// Reusable Apple Obsidian scaffold for individual onboarding steps.
class OnboardingStepScaffold extends StatelessWidget {
  const OnboardingStepScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.banner,
    required this.child,
    required this.onContinue,
    this.isContinueEnabled = true,
    this.continueLabel = 'Continue',
    this.continueKey,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? banner;
  final Widget child;
  final VoidCallback? onContinue;
  final bool isContinueEnabled;
  final String continueLabel;
  final Key? continueKey;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              if (icon != null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.activeBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.activeBlue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(icon, color: AppTheme.activeBlue, size: 24),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
              if (banner != null) ...[
                const SizedBox(height: 16),
                banner!,
              ],
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: child,
                ),
              ),
              const SizedBox(height: 12),
              AppleTactileCard(
                key: continueKey ?? const Key('onboarding_continue_btn'),
                onTap: isContinueEnabled ? onContinue : null,
                backgroundColor: isContinueEnabled
                    ? AppTheme.activeBlue
                    : AppTheme.cardElevated,
                borderRadius: 16,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      continueLabel,
                      style: TextStyle(
                        fontFamily: 'MacroSans',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isContinueEnabled
                            ? Colors.white
                            : AppTheme.textSecondary.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: isContinueEnabled
                          ? Colors.white
                          : AppTheme.textSecondary.withValues(alpha: 0.5),
                      size: 18,
                    ),
                  ],
                ),
              ),
              SizedBox(
                  height: bottomInset > 0
                      ? 12
                      : (bottomPadding > 0 ? bottomPadding : 16)),
            ],
          ),
        ),
      ),
    );
  }
}
