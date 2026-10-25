import 'package:flutter/material.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

/// Step 8: Body Fat Range Estimation (Optional)
class Step08BodyFat extends StatefulWidget {
  const Step08BodyFat({
    super.key,
    required this.initialBodyFatRange,
    required this.isMale,
    required this.onNext,
  });

  final String initialBodyFatRange;
  final bool isMale;
  final ValueChanged<String> onNext;

  @override
  State<Step08BodyFat> createState() => _Step08BodyFatState();
}

class _Step08BodyFatState extends State<Step08BodyFat> {
  late String _selectedRange;

  static const List<String> _maleRanges = [
    '5 – 9%',
    '10 – 14%',
    '15 – 19%',
    '20 – 24%',
    '25 – 29%',
    '30%+',
    'Not sure',
  ];

  static const List<String> _femaleRanges = [
    '12 – 16%',
    '17 – 21%',
    '22 – 26%',
    '27 – 31%',
    '32 – 36%',
    '37%+',
    'Not sure',
  ];

  @override
  void initState() {
    super.initState();
    _selectedRange = widget.initialBodyFatRange;
  }

  @override
  Widget build(BuildContext context) {
    final ranges = widget.isMale ? _maleRanges : _femaleRanges;

    return OnboardingStepScaffold(
      title: 'Body Fat Range',
      subtitle:
          'Optional. Helps calibrate Cunningham lean-mass metabolic equations if known.',
      icon: Icons.accessibility_new_rounded,
      continueKey: const Key('step_08_continue_btn'),
      onContinue: () => widget.onNext(_selectedRange),
      child: Column(
        children: ranges.map((range) {
          final isSelected = _selectedRange == range;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppleTactileCard(
              onTap: () => setState(() => _selectedRange = range),
              backgroundColor: isSelected
                  ? AppTheme.activeBlue.withValues(alpha: 0.14)
                  : AppTheme.cardSurface,
              border: Border.all(
                color: isSelected ? AppTheme.activeBlue : AppTheme.cardBorder,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: 14,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Text(
                    range,
                    style: TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded,
                        color: AppTheme.activeBlue, size: 20),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
