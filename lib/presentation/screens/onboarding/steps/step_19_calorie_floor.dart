import 'package:flutter/material.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

/// Step 19: Calorie Floor Clinical Guardrail (Standard vs Aggressive vs Custom)
class Step19CalorieFloor extends StatefulWidget {
  const Step19CalorieFloor({
    super.key,
    required this.isMale,
    required this.initialFloorType,
    required this.onNext,
  });

  final bool isMale;
  final String initialFloorType;
  final ValueChanged<String> onNext;

  @override
  State<Step19CalorieFloor> createState() => _Step19CalorieFloorState();
}

class _Step19CalorieFloorState extends State<Step19CalorieFloor> {
  late String _floorType;

  @override
  void initState() {
    super.initState();
    _floorType = widget.initialFloorType;
  }

  @override
  Widget build(BuildContext context) {
    final standardCals = widget.isMale ? 1500 : 1200;
    final aggressiveCals = widget.isMale ? 1300 : 1000;

    return OnboardingStepScaffold(
      title: 'Calorie Safety Floor',
      subtitle:
          'A clinical threshold below which Sique coaching will never reduce your daily calories.',
      icon: Icons.shield_outlined,
      continueKey: const Key('step_19_continue_btn'),
      onContinue: () => widget.onNext(_floorType),
      child: Column(
        children: [
          _FloorCard(
            key: const Key('step_19_floor_standard'),
            title: 'Standard Clinical Floor ($standardCals kcal)',
            desc:
                'Evidence-based minimum to ensure essential micronutrient, electrolyte, and hormone sufficiency.',
            isSelected: _floorType == 'standard',
            onTap: () => setState(() => _floorType = 'standard'),
          ),
          const SizedBox(height: 12),
          _FloorCard(
            key: const Key('step_19_floor_aggressive'),
            title: 'Aggressive Athlete Floor ($aggressiveCals kcal)',
            desc:
                'Designed for shorter athletes or rapid pre-contest weight cuts under qualified supervision.',
            isSelected: _floorType == 'aggressive',
            onTap: () => setState(() => _floorType = 'aggressive'),
          ),
          const SizedBox(height: 12),
          _FloorCard(
            key: const Key('step_19_floor_disabled'),
            title: 'No Lower Bound (Uncapped)',
            desc:
                'Algorithm tracks pure thermodynamics without artificial lower intervention clamp.',
            isSelected: _floorType == 'disabled',
            onTap: () => setState(() => _floorType = 'disabled'),
          ),
        ],
      ),
    );
  }
}

class _FloorCard extends StatelessWidget {
  const _FloorCard({
    super.key,
    required this.title,
    required this.desc,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String desc;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppleTactileCard(
      onTap: onTap,
      backgroundColor: isSelected
          ? AppTheme.activeBlue.withValues(alpha: 0.14)
          : AppTheme.cardSurface,
      border: Border.all(
        color: isSelected ? AppTheme.activeBlue : AppTheme.cardBorder,
        width: isSelected ? 2 : 1,
      ),
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            const Padding(
              padding: EdgeInsets.only(top: 2, left: 8),
              child: Icon(Icons.check_circle_rounded,
                  color: AppTheme.activeBlue, size: 20),
            ),
        ],
      ),
    );
  }
}
