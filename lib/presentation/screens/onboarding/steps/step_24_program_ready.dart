import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          // Save Your Strategy: Optional Google Sign-In & Health Connect Sync (AUD-38)
          const _SaveStrategyOptionsCard(),
        ],
      ),
    );
  }
}

class _SaveStrategyOptionsCard extends ConsumerStatefulWidget {
  const _SaveStrategyOptionsCard();

  @override
  ConsumerState<_SaveStrategyOptionsCard> createState() =>
      _SaveStrategyOptionsCardState();
}

class _SaveStrategyOptionsCardState
    extends ConsumerState<_SaveStrategyOptionsCard> {
  bool _healthConnectEnabled = true;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final isAuthenticated = authState.isAuthenticated;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.save_rounded, color: AppTheme.activeBlue, size: 20),
              SizedBox(width: 8),
              Text(
                'Save Your Strategy',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Connect Google Auth or Health Connect to sync workouts and body metrics.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          if (isAuthenticated) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.activeBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
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
                  HapticFeedback.lightImpact();
                  ref.read(authNotifierProvider.notifier).signInWithGoogle();
                },
                icon: const Icon(Icons.g_mobiledata_rounded, size: 22),
                label: const Text('Sign in with Google'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  side: const BorderSide(color: AppTheme.cardBorder),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.carbs.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.sync_rounded,
                    color: AppTheme.carbs, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Google Health Connect',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Auto-sync workouts (Health Connect, Hevy, Strava) & weights.',
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
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
    return SizedBox(
      width: 100,
      height: 100,
      child: Semantics(
        label:
            'Calorie distribution: $proteinCal kcal protein, $carbsCal kcal carbs, $fatCal kcal fat',
        container: true,
        child: CustomPaint(
          painter: _DonutChartPainter(
            protein: proteinGrams * 4.0,
            carbs: carbsGrams * 4.0,
            fat: fatGrams * 9.0,
          ),
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
