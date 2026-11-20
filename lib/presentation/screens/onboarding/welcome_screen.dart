import 'package:flutter/material.dart';
import 'package:sique/presentation/screens/onboarding/auth_gate_screen.dart';
import 'package:sique/presentation/screens/onboarding/onboarding_flow_screen.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';
import 'package:sique/presentation/widgets/sique_frosted_chrome.dart';

/// First-launch Welcome Screen introducing Sique's Adherence-Neutral philosophy.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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

    final primaryCta = AppleTactileCard(
      key: const Key('welcome_configure_strategy_btn'),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const OnboardingFlowScreen(),
          ),
        );
      },
      backgroundColor: const Color(0xFFFAFAFA),
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Build my strategy — 2 min',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF09090B),
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_rounded,
              color: Color(0xFF09090B),
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
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      child: const Text(
        'Already have a backup or account? Sign in / Restore',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable feature highlights
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                children: [
                  const SizedBox(height: 24),
                  headerBadge,
                  const SizedBox(height: 28),
                  heroTitle,
                  const SizedBox(height: 12),
                  heroSubtitle,
                  const SizedBox(height: 28),

                  // Feature 1
                  const _FeatureTile(
                    icon: Icons.favorite_border_rounded,
                    iconColor: AppTheme.calories,
                    title: 'Adherence-Neutral Coaching',
                    description:
                        'No guilt, no red numbers, no streaks. Eat more or less than planned, and the algorithm adapts without judgment.',
                  ),
                  const SizedBox(height: 14),

                  // Feature 2: Live Mini Preview Card (Expenditure Curve + Macro Ring)
                  const _LiveMiniPreviewCard(),
                  const SizedBox(height: 14),

                  // Feature 3
                  const _FeatureTile(
                    icon: Icons.tune_rounded,
                    iconColor: AppTheme.carbs,
                    title: 'Strategic Day Calorie Shifting',
                    description:
                        'Shift carbs and calories into heavy workout days while keeping weekly energy balance invariant.',
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Pinned Frosted Bottom Bar (CTA never scrolls away)
            SiqueFrostedChrome(
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: double.infinity, child: primaryCta),
                      const SizedBox(height: 6),
                      secondaryCta,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveMiniPreviewCard extends StatelessWidget {
  const _LiveMiniPreviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.expenditure.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: AppTheme.expenditure,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Dynamic Bayesian Expenditure',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.cardElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Mini Macro Ring
                SizedBox(
                  width: 44,
                  height: 44,
                  child: CustomPaint(
                    painter: _MiniMacroRingPainter(),
                  ),
                ),
                const SizedBox(width: 14),
                // Expenditure Curve & Stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              '2,420 kcal/day',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '±28 kcal conf.',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.expenditure,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Mini Curve Canvas
                      SizedBox(
                        height: 20,
                        child: CustomPaint(
                          size: const Size(double.infinity, 20),
                          painter: _MiniCurvePainter(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Continuous Kalman-filter expenditure decodes your true metabolic burn from daily weigh-ins and food logs.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMacroRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    final bgPaint = Paint()
      ..color = AppTheme.cardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = AppTheme.calories
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.57,
      4.2,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.expenditure
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.cubicTo(
      size.width * 0.3,
      size.height * 0.8,
      size.width * 0.6,
      size.height * 0.2,
      size.width,
      size.height * 0.35,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
