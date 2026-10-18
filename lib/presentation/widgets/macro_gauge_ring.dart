import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/models/food_models.dart';
import '../../domain/models/user_profile.dart';
import '../theme/app_theme.dart';
import 'animated_primitives.dart';

/// Radial Calorie & Macro Gauge with Apple Liquid Glass aesthetic,
/// animated radial sweep, smooth numeric odometers, and adherence-neutral feedback.
class MacroGaugeRing extends StatelessWidget {
  const MacroGaugeRing({
    super.key,
    required this.consumed,
    required this.targets,
    this.onTap,
  });

  final NutritionalValues consumed;
  final MacroTarget targets;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final calorieRatio = targets.calories > 0
        ? (consumed.calories / targets.calories).clamp(0.0, 1.5)
        : 0.0;
    final remainingCalories = (targets.calories - consumed.calories).round();

    return AppleTactileCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20.0),
      borderRadius: 22.0,
      backgroundColor: AppTheme.cardSurface.withValues(alpha: 0.85),
      child: Column(
        children: [
          // Circular Ring Gauge with animated sweep & count-up odometer
          SizedBox(
            height: 184,
            width: 184,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: calorieRatio),
                  duration: const Duration(milliseconds: 950),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedRatio, child) {
                    return CustomPaint(
                      size: const Size(184, 184),
                      painter: _AnimatedRingPainter(
                        progress: animatedRatio,
                        trackColor: AppTheme.cardBorder.withValues(alpha: 0.7),
                        progressColor: AppTheme.calories,
                      ),
                    );
                  },
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedCountText(
                      value: consumed.calories,
                      style: const TextStyle(
                        fontFamily: 'MacroSans',
                        fontSize: 36,
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
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.cardBorder.withValues(alpha: 0.8),
                          width: 0.8,
                        ),
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
          const SizedBox(height: 22),
          // Macro Bars: Protein, Fat, Carbs with animated fill and glowing caps
          Row(
            children: [
              Expanded(
                child: _AnimatedMacroProgressItem(
                  label: 'PROTEIN',
                  consumedGrams: consumed.protein,
                  targetGrams: targets.proteinGrams,
                  color: AppTheme.protein,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _AnimatedMacroProgressItem(
                  label: 'FAT',
                  consumedGrams: consumed.fat,
                  targetGrams: targets.fatGrams,
                  color: AppTheme.fat,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _AnimatedMacroProgressItem(
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
    );
  }
}

class _AnimatedMacroProgressItem extends StatelessWidget {
  const _AnimatedMacroProgressItem({
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
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
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
              const SizedBox(width: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedCountText(
                    value: consumedGrams,
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    '/${targetGrams.round()}g',
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        AnimatedMacroBar(
          ratio: ratio,
          color: color,
          height: 6.5,
        ),
      ],
    );
  }
}

class _AnimatedRingPainter extends CustomPainter {
  const _AnimatedRingPainter({
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
    final radius = (size.width - 18) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi * 1.25,
        endAngle: math.pi * 0.25,
        colors: [
          progressColor.withValues(alpha: 0.85),
          progressColor,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;

    // Draw background track (-225 deg to +45 deg)
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

    // If over target, draw an overflow accent arc
    if (progress > 1.0) {
      final overflowSweep = sweepAngle * (progress - 1.0).clamp(0.0, 0.5);
      final overflowPaint = Paint()
        ..color = AppTheme.neutralInfo
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        overflowSweep,
        false,
        overflowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_AnimatedRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.progressColor != progressColor;
}
