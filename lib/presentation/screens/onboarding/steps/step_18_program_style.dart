import 'package:flutter/material.dart';
import 'package:sique/domain/models/macro_program.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

/// Step 18: Macro Distribution Style
class Step18ProgramStyle extends StatefulWidget {
  const Step18ProgramStyle({
    super.key,
    required this.initialStyle,
    required this.onNext,
  });

  final MacroProgramStyle initialStyle;
  final ValueChanged<MacroProgramStyle> onNext;

  @override
  State<Step18ProgramStyle> createState() => _Step18ProgramStyleState();
}

class _Step18ProgramStyleState extends State<Step18ProgramStyle> {
  late MacroProgramStyle _style;

  @override
  void initState() {
    super.initState();
    _style = widget.initialStyle;
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'Macro Distribution',
      subtitle:
          'Choose how your non-protein calories are split between carbohydrates and fats.',
      icon: Icons.donut_small_rounded,
      continueKey: const Key('step_18_continue_btn'),
      onContinue: () => widget.onNext(_style),
      child: Column(
        children: [
          const SizedBox(height: 12),
          for (final s in MacroProgramStyle.values) ...[
            AppleTactileCard(
              onTap: () => setState(() => _style = s),
              backgroundColor: _style == s
                  ? AppTheme.activeBlue.withValues(alpha: 0.12)
                  : AppTheme.cardSurface,
              border: Border.all(
                color: _style == s ? AppTheme.activeBlue : AppTheme.cardBorder,
                width: _style == s ? 2 : 1,
              ),
              borderRadius: 16,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.displayName,
                          style: const TextStyle(
                            fontFamily: 'MacroSans',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.description,
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
                  if (_style == s)
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
