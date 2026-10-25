import 'package:flutter/material.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

/// Step 7: Recent Weight Trend (Seeds Bayesian Kalman Filter Prior)
class Step07WeightTrend extends StatefulWidget {
  const Step07WeightTrend({
    super.key,
    required this.initialTrend,
    required this.onNext,
  });

  final String initialTrend;
  final ValueChanged<String> onNext;

  @override
  State<Step07WeightTrend> createState() => _Step07WeightTrendState();
}

class _Step07WeightTrendState extends State<Step07WeightTrend> {
  late String _selectedTrend;

  @override
  void initState() {
    super.initState();
    _selectedTrend = widget.initialTrend;
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'Recent Weight Trend',
      subtitle:
          'Over the past 4 to 8 weeks, how has your body weight been trending?',
      icon: Icons.trending_up_rounded,
      continueKey: const Key('step_07_continue_btn'),
      onContinue: () => widget.onNext(_selectedTrend),
      child: Column(
        children: [
          _TrendOptionTile(
            key: const Key('step_07_trend_losing'),
            title: 'Losing Weight',
            subtitle:
                'Steadily dropping weight or in an active caloric deficit.',
            icon: Icons.trending_down_rounded,
            isSelected: _selectedTrend == 'losing',
            onTap: () => setState(() => _selectedTrend = 'losing'),
          ),
          const SizedBox(height: 12),
          _TrendOptionTile(
            key: const Key('step_07_trend_stable'),
            title: 'Stable / Maintaining',
            subtitle:
                'Weight fluctuates within 1-2 kg without a clear upward or downward trend.',
            icon: Icons.trending_flat_rounded,
            isSelected: _selectedTrend == 'stable',
            onTap: () => setState(() => _selectedTrend = 'stable'),
          ),
          const SizedBox(height: 12),
          _TrendOptionTile(
            key: const Key('step_07_trend_gaining'),
            title: 'Gaining Weight',
            subtitle:
                'Steadily increasing weight or in an active caloric surplus.',
            icon: Icons.trending_up_rounded,
            isSelected: _selectedTrend == 'gaining',
            onTap: () => setState(() => _selectedTrend = 'gaining'),
          ),
          const SizedBox(height: 12),
          _TrendOptionTile(
            key: const Key('step_07_trend_not_sure'),
            title: 'Not Sure',
            subtitle:
                'Infrequent weigh-ins. Seeds a wider uncertainty variance (σ_E0 = 450 kcal) for faster discovery.',
            icon: Icons.help_outline_rounded,
            isSelected: _selectedTrend == 'not_sure',
            onTap: () => setState(() => _selectedTrend = 'not_sure'),
          ),
        ],
      ),
    );
  }
}

class _TrendOptionTile extends StatelessWidget {
  const _TrendOptionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.activeBlue.withValues(alpha: 0.2)
                  : AppTheme.cardElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 22,
              color: isSelected ? AppTheme.activeBlue : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 14),
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
                  subtitle,
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
