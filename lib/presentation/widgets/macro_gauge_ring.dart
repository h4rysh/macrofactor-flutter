import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:macro_factor_app/domain/models/food_models.dart';
import 'package:macro_factor_app/domain/models/user_profile.dart';
import 'package:macro_factor_app/presentation/theme/app_theme.dart';

/// Radial Calorie & Macro Gauge with Adherence-Neutral feedback.
class MacroGaugeRing extends StatelessWidget {
  const MacroGaugeRing({
    super.key,
    required this.consumed,
    required this.targets,
  });

  final NutritionalValues consumed;
  final MacroTarget targets;

  @override
  Widget build(BuildContext context) {
    final calorieRatio = targets.calories > 0
        ? (consumed.calories / targets.calories).clamp(0.0, 1.5)
        : 0.0;
    final remainingCalories = (targets.calories - consumed.calories).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Circular Ring Gauge
            SizedBox(
              height: 180,
              width: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(180, 180),
                    painter: _RingPainter(
                      progress: calorieRatio,
                      trackColor: AppTheme.cardBorder,
                      progressColor: AppTheme.calories,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        consumed.calories.round().toString(),
                        style: const TextStyle(
                          fontFamily: 'MacroSans',
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const Text(
                        'CALORIES CONSUMED',
                        style: TextStyle(
                          fontFamily: 'MacroSans',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: AppTheme.cardBorder, width: 1),
                        ),
                        child: Text(
                          remainingCalories >= 0
                              ? '$remainingCalories left'
                              : '+${remainingCalories.abs()} over',
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: remainingCalories >= 0
                                ? AppTheme.calories
                                : AppTheme.neutralInfo,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Macro Bars: Protein, Fat, Carbs
            Row(
              children: [
                Expanded(
                  child: _MacroProgressItem(
                    label: 'PROTEIN',
                    consumedGrams: consumed.protein,
                    targetGrams: targets.proteinGrams,
                    color: AppTheme.protein,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MacroProgressItem(
                    label: 'FAT',
                    consumedGrams: consumed.fat,
                    targetGrams: targets.fatGrams,
                    color: AppTheme.fat,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MacroProgressItem(
                    label: 'CARBS',
                    consumedGrams: consumed.carbs,
                    targetGrams: targets.carbsGrams,
                    color: AppTheme.carbs,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroProgressItem extends StatelessWidget {
  const _MacroProgressItem({
    required this.label,
    required this.consumedGrams,
    required this.targetGrams,
    required this.color,
  });

  final String label;
  final double consumedGrams;
  final double targetGrams;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio =
        targetGrams > 0 ? (consumedGrams / targetGrams).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'MacroSans',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              '${consumedGrams.round()}/${targetGrams.round()}g',
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: AppTheme.cardBorder,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    // Draw background track (-220 deg to +40 deg)
    const startAngle = -math.pi * 1.25;
    const sweepAngle = math.pi * 1.5;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Draw progress arc
    final currentSweep = sweepAngle * progress.clamp(0.0, 1.0);
    if (currentSweep > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        currentSweep,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.progressColor != progressColor;
}
