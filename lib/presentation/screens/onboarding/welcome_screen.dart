import 'package:flutter/material.dart';
import 'package:macro_factor_app/presentation/screens/onboarding/auth_gate_screen.dart';
import 'package:macro_factor_app/presentation/screens/onboarding/strategy_setup_wizard.dart';
import 'package:macro_factor_app/presentation/theme/app_theme.dart';
import 'package:macro_factor_app/presentation/widgets/apple_tactile_card.dart';

/// First-launch Welcome Screen introducing MacroFactor's Adherence-Neutral philosophy.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              // Header Brand Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.calories, Color(0xFFFF8A65)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.calories.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'MACROFACTOR',
                    style: TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Hero Typography
              const Text(
                'Smarter Nutrition.\nZero Guilt.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  letterSpacing: -0.5,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'MacroFactor reverse-engineers your metabolism and dynamically adapts your targets — no matter what you eat.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'MacroSans',
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 36),
              // 3 Adherence-Neutral Pillars
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: const [
                    _FeatureTile(
                      icon: Icons.favorite_border_rounded,
                      iconColor: AppTheme.calories,
                      title: 'Adherence-Neutral Coaching',
                      description:
                          'No guilt, no red numbers, no streaks. Eat more or less than planned, and the algorithm adapts without judgment.',
                    ),
                    SizedBox(height: 16),
                    _FeatureTile(
                      icon: Icons.trending_up_rounded,
                      iconColor: AppTheme.expenditure,
                      title: 'Dynamic Bayesian Expenditure',
                      description:
                          'Continuous energy expenditure estimation that decodes your actual metabolic burn from daily weights and nutrition logs.',
                    ),
                    SizedBox(height: 16),
                    _FeatureTile(
                      icon: Icons.tune_rounded,
                      iconColor: AppTheme.carbs,
                      title: 'Strategic Day Calorie Shifting',
                      description:
                          'Shift carbs and calories into heavy workout days while keeping weekly energy balance invariant.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Primary CTA: Configure Strategy
              AppleTactileCard(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const StrategySetupWizard(),
                    ),
                  );
                },
                backgroundColor: AppTheme.calories,
                borderRadius: 16,
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Configure My Strategy',
                      style: TextStyle(
                        fontFamily: 'MacroSans',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Secondary CTA: Skip to Auth Gate
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AuthGateScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Already have an account? Sign In',
                  style: TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              SizedBox(height: bottomPadding > 0 ? bottomPadding : 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.35,
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
