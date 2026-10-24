import 'package:flutter/material.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

/// Step 16: Protein Target Intake Preference
class Step16ProteinPreference extends StatefulWidget {
  const Step16ProteinPreference({
    super.key,
    required this.currentWeightKg,
    required this.initialPreference,
    required this.onNext,
  });

  final double currentWeightKg;
  final ProteinPreference initialPreference;
  final ValueChanged<ProteinPreference> onNext;

  @override
  State<Step16ProteinPreference> createState() =>
      _Step16ProteinPreferenceState();
}

class _Step16ProteinPreferenceState extends State<Step16ProteinPreference> {
  late ProteinPreference _pref;

  @override
  void initState() {
    super.initState();
    _pref = widget.initialPreference;
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'Protein Intake',
      subtitle:
          'Protein spares muscle mass during deficits and fuels hypertrophic remodeling.',
      icon: Icons.egg_outlined,
      continueKey: const Key('step_16_continue_btn'),
      onContinue: () => widget.onNext(_pref),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _ProteinOptionCard(
            key: const Key('step_16_moderate_tile'),
            title: 'Moderate (1.6 g/kg)',
            subtitle:
                'Recommended baseline for general health and recreational resistance training.',
            grams: (widget.currentWeightKg * 1.6).round(),
            isSelected: _pref == ProteinPreference.moderate,
            onTap: () => setState(() => _pref = ProteinPreference.moderate),
          ),
          const SizedBox(height: 14),
          _ProteinOptionCard(
            key: const Key('step_16_high_tile'),
            title: 'High (2.0 g/kg)',
            subtitle:
                'Optimal evidence-based threshold for muscle preservation in hypocaloric diets.',
            grams: (widget.currentWeightKg * 2.0).round(),
            isSelected: _pref == ProteinPreference.high,
            onTap: () => setState(() => _pref = ProteinPreference.high),
          ),
          const SizedBox(height: 14),
          _ProteinOptionCard(
            key: const Key('step_16_extra_high_tile'),
            title: 'Extra High (2.4 g/kg)',
            subtitle:
                'Maximum satiety and muscle protection for lean athletes during deep deficits.',
            grams: (widget.currentWeightKg * 2.4).round(),
            isSelected: _pref == ProteinPreference.extraHigh,
            onTap: () => setState(() => _pref = ProteinPreference.extraHigh),
          ),
        ],
      ),
    );
  }
}

class _ProteinOptionCard extends StatelessWidget {
  const _ProteinOptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.grams,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final int grams;
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
      padding: const EdgeInsets.all(18),
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
                      style: const TextStyle(
                        fontFamily: 'MacroSans',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '$grams g/day',
                      style: const TextStyle(
                        fontFamily: 'MacroSans',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.protein,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
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
        ],
      ),
    );
  }
}
