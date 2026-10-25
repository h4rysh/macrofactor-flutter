import 'package:flutter/material.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

/// Step 22: Protein Target Preference Selection (Moderate, High, Extra High)
class Step22ProteinPreference extends StatefulWidget {
  const Step22ProteinPreference({
    super.key,
    required this.currentWeightKg,
    required this.initialPreference,
    required this.onNext,
  });

  final double currentWeightKg;
  final ProteinPreference initialPreference;
  final ValueChanged<ProteinPreference> onNext;

  @override
  State<Step22ProteinPreference> createState() =>
      _Step22ProteinPreferenceState();
}

class _Step22ProteinPreferenceState extends State<Step22ProteinPreference> {
  late ProteinPreference _selectedPref;

  @override
  void initState() {
    super.initState();
    _selectedPref = widget.initialPreference;
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'Protein Target',
      subtitle:
          'Adequate protein preserves nitrogen balance and skeletal muscle during caloric shifts.',
      icon: Icons.fitness_center_rounded,
      continueKey: const Key('step_22_continue_btn'),
      onContinue: () => widget.onNext(_selectedPref),
      child: Column(
        children: [
          _ProteinCard(
            key: const Key('step_22_pref_moderate'),
            title: 'Moderate (1.6 g/kg)',
            gramsText:
                '~${(widget.currentWeightKg * 1.6).round()}g protein / day',
            desc:
                'Ideal for general fitness, endurance training, and active wellness.',
            isSelected: _selectedPref == ProteinPreference.moderate,
            onTap: () =>
                setState(() => _selectedPref = ProteinPreference.moderate),
          ),
          const SizedBox(height: 12),
          _ProteinCard(
            key: const Key('step_22_pref_high'),
            title: 'High (2.0 g/kg)',
            gramsText:
                '~${(widget.currentWeightKg * 2.0).round()}g protein / day',
            desc:
                'Recommended for resistance training, muscle hypertrophy, and athletic body recomposition.',
            isSelected: _selectedPref == ProteinPreference.high,
            onTap: () => setState(() => _selectedPref = ProteinPreference.high),
          ),
          const SizedBox(height: 12),
          _ProteinCard(
            key: const Key('step_22_pref_extra_high'),
            title: 'Extra High (2.4 g/kg)',
            gramsText:
                '~${(widget.currentWeightKg * 2.4).round()}g protein / day',
            desc:
                'Aggressive muscle retention during deep caloric deficits and pre-competition prep.',
            isSelected: _selectedPref == ProteinPreference.extraHigh,
            onTap: () =>
                setState(() => _selectedPref = ProteinPreference.extraHigh),
          ),
        ],
      ),
    );
  }
}

class _ProteinCard extends StatelessWidget {
  const _ProteinCard({
    super.key,
    required this.title,
    required this.gramsText,
    required this.desc,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String gramsText;
  final String desc;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppleTactileCard(
      onTap: onTap,
      backgroundColor: isSelected
          ? AppTheme.protein.withValues(alpha: 0.12)
          : AppTheme.cardSurface,
      border: Border.all(
        color: isSelected ? AppTheme.protein : AppTheme.cardBorder,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    Text(
                      gramsText,
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.protein,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
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
                  color: AppTheme.protein, size: 20),
            ),
        ],
      ),
    );
  }
}
