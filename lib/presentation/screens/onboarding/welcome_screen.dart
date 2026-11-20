import 'package:flutter/material.dart';
import 'package:sique/presentation/screens/onboarding/auth_gate_screen.dart';
import 'package:sique/presentation/screens/onboarding/onboarding_flow_screen.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

/// First-launch Welcome Screen introducing Sique's Adherence-Neutral philosophy.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textScaler = MediaQuery.textScalerOf(context);
            final isConstrained =
                textScaler.scale(1.0) > 1.15 || constraints.maxHeight < 700;

            final headerBadge = Row(
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
                  'SIQUE',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            );

            const heroTitle = Text(
              'Smarter Nutrition.\nZero Guilt.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                height: 1.15,
                letterSpacing: -0.5,
                color: AppTheme.textPrimary,
              ),
            );

            const heroSubtitle = Text(
              'Sique reverse-engineers your metabolism and dynamically adapts your targets — no matter what you eat.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            );

            const featureTiles = [
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
            ];

            final primaryCta = AppleTactileCard(
              key: const Key('welcome_configure_strategy_btn'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const OnboardingFlowScreen(),
                  ),
                );
              },
              backgroundColor: AppTheme.calories,
              borderRadius: 16,
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Configure My Strategy',
                      style: TextStyle(
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
            );

            final secondaryCta = TextButton(
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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            );

            if (isConstrained) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    headerBadge,
                    const SizedBox(height: 24),
                    heroTitle,
                    const SizedBox(height: 12),
                    heroSubtitle,
                    const SizedBox(height: 28),
                    ...featureTiles,
                    const SizedBox(height: 24),
                    primaryCta,
                    const SizedBox(height: 12),
                    secondaryCta,
                    SizedBox(height: bottomPadding > 0 ? bottomPadding : 16),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  headerBadge,
                  const SizedBox(height: 32),
                  heroTitle,
                  const SizedBox(height: 12),
                  heroSubtitle,
                  const SizedBox(height: 36),
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
                  primaryCta,
                  const SizedBox(height: 12),
                  secondaryCta,
                  SizedBox(height: bottomPadding > 0 ? bottomPadding : 16),
                ],
              ),
            );
          },
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
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
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
