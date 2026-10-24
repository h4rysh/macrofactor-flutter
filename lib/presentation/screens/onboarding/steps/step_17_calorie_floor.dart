import 'package:flutter/material.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

/// Step 17: Calorie Floor Safety Setting
class Step17CalorieFloor extends StatefulWidget {
  const Step17CalorieFloor({
    super.key,
    required this.isMale,
    required this.initialFloorType,
    required this.onNext,
  });

  final bool isMale;
  final String initialFloorType;
  final ValueChanged<String> onNext;

  @override
  State<Step17CalorieFloor> createState() => _Step17CalorieFloorState();
}

class _Step17CalorieFloorState extends State<Step17CalorieFloor> {
  late String _floorType;

  @override
  void initState() {
    super.initState();
    _floorType = widget.initialFloorType;
  }

  int get _standardFloorKcal => widget.isMale ? 1500 : 1200;

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'Safety Calorie Floor',
      subtitle:
          'Prevents metabolic targets from dipping below physiological safety thresholds.',
      icon: Icons.security_rounded,
      continueKey: const Key('step_17_continue_btn'),
      onContinue: () => widget.onNext(_floorType),
      child: Column(
        children: [
          const SizedBox(height: 12),
          AppleTactileCard(
            key: const Key('step_17_standard_tile'),
            onTap: () => setState(() => _floorType = 'standard'),
            backgroundColor: _floorType == 'standard'
                ? AppTheme.activeBlue.withValues(alpha: 0.12)
                : AppTheme.cardSurface,
            border: Border.all(
              color: _floorType == 'standard'
                  ? AppTheme.activeBlue
                  : AppTheme.cardBorder,
              width: _floorType == 'standard' ? 2 : 1,
            ),
            borderRadius: 16,
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Standard Safety Floor',
                            style: TextStyle(
                              fontFamily: 'MacroSans',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            '$_standardFloorKcal kcal/day',
                            style: const TextStyle(
                              fontFamily: 'MacroSans',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.activeBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enforces a hard limit of $_standardFloorKcal kcal (${widget.isMale ? "male" : "female"} guideline) to protect micronutrient density and endocrine function.',
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_floorType == 'standard') ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.check_circle_rounded,
                      color: AppTheme.activeBlue, size: 20),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppleTactileCard(
            key: const Key('step_17_custom_tile'),
            onTap: () => setState(() => _floorType = 'aggressive'),
            backgroundColor: _floorType == 'aggressive'
                ? AppTheme.warning.withValues(alpha: 0.12)
                : AppTheme.cardSurface,
            border: Border.all(
              color: _floorType == 'aggressive'
                  ? AppTheme.warning
                  : AppTheme.cardBorder,
              width: _floorType == 'aggressive' ? 2 : 1,
            ),
            borderRadius: 16,
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Adaptive Low Floor',
                            style: TextStyle(
                              fontFamily: 'MacroSans',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'Lower Limit',
                            style: TextStyle(
                              fontFamily: 'MacroSans',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.warning,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Permits targets down to 1000 kcal for smaller athletes during contest prep or rapid fat loss.',
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_floorType == 'aggressive') ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.check_circle_rounded,
                      color: AppTheme.warning, size: 20),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
