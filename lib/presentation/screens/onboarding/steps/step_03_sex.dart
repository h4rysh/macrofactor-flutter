import 'package:flutter/material.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

/// Step 3: Biological Sex Selection
class Step03Sex extends StatefulWidget {
  const Step03Sex({
    super.key,
    required this.initialIsMale,
    required this.onNext,
  });

  final bool initialIsMale;
  final ValueChanged<bool> onNext;

  @override
  State<Step03Sex> createState() => _Step03SexState();
}

class _Step03SexState extends State<Step03Sex> {
  late bool _isMale;

  @override
  void initState() {
    super.initState();
    _isMale = widget.initialIsMale;
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'Biological Sex',
      subtitle:
          'Required to initialize resting metabolic rate (Mifflin-St Jeor formula).',
      icon: Icons.wc_rounded,
      continueKey: const Key('step_03_continue_btn'),
      onContinue: () => widget.onNext(_isMale),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _SexOptionTile(
            key: const Key('step_03_male_tile'),
            title: 'Male',
            icon: Icons.male_rounded,
            isSelected: _isMale,
            onTap: () => setState(() => _isMale = true),
          ),
          const SizedBox(height: 16),
          _SexOptionTile(
            key: const Key('step_03_female_tile'),
            title: 'Female',
            icon: Icons.female_rounded,
            isSelected: !_isMale,
            onTap: () => setState(() => _isMale = false),
          ),
        ],
      ),
    );
  }
}

class _SexOptionTile extends StatelessWidget {
  const _SexOptionTile({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Icon(
            icon,
            size: 28,
            color: isSelected ? AppTheme.activeBlue : AppTheme.textSecondary,
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'MacroSans',
              fontSize: 18,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
            ),
          ),
          const Spacer(),
          if (isSelected)
            const Icon(Icons.check_circle_rounded,
                color: AppTheme.activeBlue, size: 22),
        ],
      ),
    );
  }
}
