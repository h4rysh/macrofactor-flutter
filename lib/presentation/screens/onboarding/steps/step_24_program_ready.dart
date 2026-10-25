import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/domain/models/macro_program.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/screens/scaffold_with_nav_bar.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Step 24: Final Program Activation & Dashboard Launch
class Step24ProgramReady extends ConsumerWidget {
  const Step24ProgramReady({
    super.key,
    required this.program,
    this.onCompleted,
  });

  final WeeklyMacroProgram program;
  final VoidCallback? onCompleted;

  void _finishAndLaunch(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);
    db.setSetting('onboarding_completed', 'true');
    db.setSetting('onboarding_step', '0');

    if (onCompleted != null) {
      onCompleted!();
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ScaffoldWithNavBar()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monday = program.days.first;

    return OnboardingStepScaffold(
      title: 'Program Ready',
      subtitle:
          'Your initial adaptive coaching program has been synthesized and calibrated to your metabolism.',
      icon: Icons.check_circle_rounded,
      continueLabel: 'Enter Sique Dashboard',
      continueKey: const Key('step_24_continue_btn'),
      onContinue: () => _finishAndLaunch(context, ref),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.activeBlue.withValues(alpha: 0.12),
                  AppTheme.cardSurface,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.activeBlue.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'DAILY BASELINE TARGET',
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppTheme.activeBlue,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${monday.calories.round()}',
                  style: const TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 50,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Calories / day',
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: _MacroDonutChart(
                    proteinGrams: monday.proteinGrams,
                    carbsGrams: monday.carbsGrams,
                    fatGrams: monday.fatGrams,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _MacroPill(
                      label: 'Protein',
                      grams: monday.proteinGrams,
                      color: AppTheme.protein,
                    ),
                    _MacroPill(
                      label: 'Carbs',
                      grams: monday.carbsGrams,
                      color: AppTheme.carbs,
                    ),
                    _MacroPill(
                      label: 'Fat',
                      grams: monday.fatGrams,
                      color: AppTheme.fat,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    color: AppTheme.activeBlue, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Adherence-Neutral: Sique never judges food choices. Log what you actually eat, and the Bayesian Kalman filter will continuously refine your metabolic rate.',
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.35,
                    ),
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

class _MacroDonutChart extends StatelessWidget {
  const _MacroDonutChart({
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
  });

  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: CustomPaint(
        painter: _DonutChartPainter(
          protein: proteinGrams * 4.0,
          carbs: carbsGrams * 4.0,
          fat: fatGrams * 9.0,
        ),
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double protein;
  final double carbs;
  final double fat;

  @override
  void paint(Canvas canvas, Size size) {
    final total = protein + carbs + fat;
    const strokeWidth = 10.0;
    final radius = (size.width - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = AppTheme.cardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    if (total <= 0) return;

    final pRatio = protein / total;
    final cRatio = carbs / total;
    final fRatio = fat / total;

    var startAngle = -math.pi / 2;

    void drawSegment(double ratio, Color color) {
      if (ratio <= 0) return;
      final sweepAngle = 2 * math.pi * ratio;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }

    drawSegment(pRatio, AppTheme.protein);
    drawSegment(cRatio, AppTheme.carbs);
    drawSegment(fRatio, AppTheme.fat);
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) =>
      oldDelegate.protein != protein ||
      oldDelegate.carbs != carbs ||
      oldDelegate.fat != fat;
}

class _MacroPill extends StatelessWidget {
  const _MacroPill({
    required this.label,
    required this.grams,
    required this.color,
  });

  final String label;
  final double grams;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${grams.round()}g',
          style: TextStyle(
            fontFamily: 'MacroSans',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'DMSans',
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
