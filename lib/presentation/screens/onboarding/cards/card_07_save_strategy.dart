import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/domain/models/macro_program.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/sique_controls.dart';
import 'package:sique/presentation/widgets/sique_frosted_chrome.dart';
import 'package:sique/presentation/widgets/sique_tonal_card.dart';
import '../steps/step_24_program_ready.dart';

/// Card 7: 'Save Your Strategy' & Dashboard Launch.
///
/// Features:
/// - Endowment headline celebrating personalized calibrated targets.
/// - Daily baseline target with macro donut chart and nutrient breakdown.
/// - Separated 100% on-device Health Connect sync card.
/// - Separated optional Google Account backup card.
/// - Pinned frosted sticky CTA bar for zero-scroll dashboard launch.
class Card07SaveStrategy extends ConsumerStatefulWidget {
  const Card07SaveStrategy({
    super.key,
    required this.program,
    required this.onFinish,
  });

  final WeeklyMacroProgram program;
  final VoidCallback onFinish;

  @override
  ConsumerState<Card07SaveStrategy> createState() => _Card07SaveStrategyState();
}

class _Card07SaveStrategyState extends ConsumerState<Card07SaveStrategy> {
  bool _healthConnectEnabled = true;

  void _finishAndLaunch() {
    final db = ref.read(databaseProvider);
    db.setSetting('onboarding_completed', 'true');
    db.setSetting('onboarding_step', '0');
    AppHaptics.mediumImpact();
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final monday = widget.program.days.first;
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final isAuthenticated = authState.isAuthenticated;

    return Step24ProgramReady(
      program: widget.program,
      onCompleted: widget.onFinish,
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
            children: [
              const Text(
                'Program Ready',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.activeBlue,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your Blueprint is Live.',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your initial adaptive coaching targets have been calibrated to your metabolic rate and body goal.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),

              // Hero Target Card
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
                  borderRadius: AppRadii.xlBorderRadius,
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
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Calories / day',
                      style: TextStyle(
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

              // Adherence Neutral Card
              const SiqueTonalCard(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        color: AppTheme.activeBlue, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Adherence-Neutral: Sique never judges food choices. Log what you actually eat, and the Bayesian Kalman filter will continuously refine your metabolic rate.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 1. Health Connect Integration Card (Local First)
              SiqueTonalCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.favorite_rounded,
                            color: AppTheme.calories, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Google Health Connect',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '100% on-device sync. Automatically ingest scale weights and workouts from Health Connect, smart scales, and third-party apps.',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.3),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Enable Automatic Ingestion',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          key: const Key('onboarding_health_connect_toggle'),
                          value: _healthConnectEnabled,
                          activeTrackColor: AppTheme.activeBlue,
                          onChanged: (val) {
                            setState(() => _healthConnectEnabled = val);
                            if (val) {
                              ref
                                  .read(healthConnectSyncProvider.notifier)
                                  .requestPermissions();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Optional Sique Account Card
              SiqueTonalCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.account_circle_outlined,
                            color: AppTheme.activeBlue, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Optional Sique Account',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Local-first storage today; reserves your identity for future sync.',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.3),
                    ),
                    const SizedBox(height: 14),
                    if (isAuthenticated) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.activeBlue.withValues(alpha: 0.12),
                          borderRadius: AppRadii.mdBorderRadius,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.account_circle_rounded,
                                color: AppTheme.activeBlue, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Signed in as ${user.displayName.isNotEmpty ? user.displayName : (user.email.isNotEmpty ? user.email : "Athlete")}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          key: const Key('onboarding_google_sign_in_btn'),
                          onPressed: () {
                            AppHaptics.lightImpact();
                            ref
                                .read(authNotifierProvider.notifier)
                                .signInWithGoogle();
                          },
                          icon:
                              const Icon(Icons.g_mobiledata_rounded, size: 22),
                          label: const Text('Sign in with Google'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textPrimary,
                            side: const BorderSide(color: AppTheme.cardBorder),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: const RoundedRectangleBorder(
                              borderRadius: AppRadii.mdBorderRadius,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // Pinned Frosted Sticky Bottom CTA Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SiqueFrostedChrome(
              child: SizedBox(
                width: double.infinity,
                child: SiqueButton(
                  key: const Key('step_24_continue_btn'),
                  label: 'Enter Sique Dashboard',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: _finishAndLaunch,
                ),
              ),
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
    final proteinCal = (proteinGrams * 4.0).round();
    final carbsCal = (carbsGrams * 4.0).round();
    final fatCal = (fatGrams * 9.0).round();
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return SizedBox(
      width: 100,
      height: 100,
      child: Semantics(
        label:
            'Calorie distribution: $proteinCal kcal protein, $carbsCal kcal carbs, $fatCal kcal fat',
        container: true,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: disableAnimations
              ? Duration.zero
              : const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, progress, child) {
            return CustomPaint(
              painter: _DonutChartPainter(
                protein: (proteinGrams * 4.0) * progress,
                carbs: (carbsGrams * 4.0) * progress,
                fat: (fatGrams * 9.0) * progress,
              ),
            );
          },
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
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
