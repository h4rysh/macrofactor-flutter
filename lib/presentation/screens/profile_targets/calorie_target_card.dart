import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Card for customizing or resetting daily caloric targets.
class CalorieTargetCard extends StatelessWidget {
  const CalorieTargetCard({
    super.key,
    required this.ref,
    required this.profile,
    required this.expenditureKcal,
    required this.target,
  });

  final WidgetRef ref;
  final UserProfile profile;
  final double expenditureKcal;
  final MacroTarget target;

  @override
  Widget build(BuildContext context) {
    final isCustom = profile.customCalories != null;
    final currentTarget = target.calories;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Daily Caloric Target',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        isCustom
                            ? 'Custom Override Active'
                            : 'Calculated by Expenditure Engine',
                        style: TextStyle(
                          fontSize: 12,
                          color: isCustom
                              ? AppTheme.warning
                              : AppTheme.expenditure,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isCustom) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    ref.read(userProfileProvider.notifier).updateProfile(
                          profile.copyWith(clearCustom: true),
                        );
                  },
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Reset',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.activeBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    currentTarget.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.calories,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'kcal / day',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.calories,
              inactiveTrackColor: AppTheme.cardBorder,
              thumbColor: AppTheme.calories,
              trackHeight: 4,
            ),
            child: Slider(
              value: currentTarget.clamp(1200.0, 4000.0),
              min: 1200.0,
              max: 4000.0,
              divisions: 112,
              onChanged: (val) {
                ref.read(userProfileProvider.notifier).updateProfile(
                      profile.copyWith(customCalories: val.roundToDouble()),
                    );
              },
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('1,200 kcal',
                      style:
                          TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ),
              ),
              SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text('4,000 kcal',
                      style:
                          TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
