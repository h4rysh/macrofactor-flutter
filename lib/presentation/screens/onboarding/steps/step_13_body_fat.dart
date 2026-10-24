import 'package:flutter/material.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

/// Step 13: Estimated Body Fat Range Selection
class Step13BodyFat extends StatefulWidget {
  const Step13BodyFat({
    super.key,
    this.initialBodyFatRange,
    required this.isMale,
    required this.onNext,
  });

  final String? initialBodyFatRange;
  final bool isMale;
  final ValueChanged<String> onNext;

  @override
  State<Step13BodyFat> createState() => _Step13BodyFatState();
}

class _Step13BodyFatState extends State<Step13BodyFat> {
  late String _selectedRange;

  @override
  void initState() {
    super.initState();
    _selectedRange =
        widget.initialBodyFatRange ?? (widget.isMale ? '15-19%' : '22-26%');
  }

  List<String> get _ranges => widget.isMale
      ? ['< 10%', '10 – 14%', '15 – 19%', '20 – 24%', '25%+']
      : ['< 18%', '18 – 22%', '23 – 27%', '28 – 32%', '33%+'];

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'Body Fat Estimate',
      subtitle:
          'An approximate estimate helps refine baseline lean mass and protein targets.',
      icon: Icons.pie_chart_outline_rounded,
      continueKey: const Key('step_13_continue_btn'),
      onContinue: () => widget.onNext(_selectedRange),
      child: Column(
        children: [
          const SizedBox(height: 12),
          for (final range in _ranges) ...[
            AppleTactileCard(
              onTap: () => setState(() => _selectedRange = range),
              backgroundColor: _selectedRange == range
                  ? AppTheme.activeBlue.withValues(alpha: 0.12)
                  : AppTheme.cardSurface,
              border: Border.all(
                color: _selectedRange == range
                    ? AppTheme.activeBlue
                    : AppTheme.cardBorder,
                width: _selectedRange == range ? 2 : 1,
              ),
              borderRadius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    range,
                    style: TextStyle(
                      fontFamily: 'MacroSans',
                      fontSize: 16,
                      fontWeight: _selectedRange == range
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: _selectedRange == range
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                  ),
                  if (_selectedRange == range)
                    const Icon(Icons.check_circle_rounded,
                        color: AppTheme.activeBlue, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
