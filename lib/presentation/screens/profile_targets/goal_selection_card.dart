import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/domain/validation/domain_validator.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Card allowing selection between Fat Loss, Maintenance, and Muscle Gain,
/// with real-time rate-of-change slider clamped by domain validator.
class GoalSelectionCard extends StatelessWidget {
  const GoalSelectionCard({
    super.key,
    required this.ref,
    required this.profile,
  });

  final WidgetRef ref;
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Goal & Strategy',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: GoalType.values.map((goal) {
              final isSelected = profile.goalType == goal;
              final name = switch (goal) {
                GoalType.fatLoss => 'Fat Loss',
                GoalType.maintenance => 'Maintain',
                GoalType.muscleGain => 'Muscle Gain',
              };
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppTheme.activeBlue,
                    backgroundColor: AppTheme.cardElevated,
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.activeBlue
                          : AppTheme.cardBorder,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(userProfileProvider.notifier).updateProfile(
                              profile.copyWith(goalType: goal),
                            );
                      }
                    },
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Weekly Rate of Change',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${profile.weeklyRateOfChangePct >= 0 ? "+" : ""}${profile.weeklyRateOfChangePct.toStringAsFixed(2)}% / wk',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.trendWeight,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.trendWeight,
              inactiveTrackColor: AppTheme.cardBorder,
              thumbColor: AppTheme.trendWeight,
              trackHeight: 4,
            ),
            child: Slider(
              value: DomainValidator.clampRateOfChange(
                profile.weeklyRateOfChangePct,
                profile.goalType,
              ).clamp(-1.5, 1.0),
              min: -1.5,
              max: 1.0,
              divisions: 50,
              onChanged: (val) {
                final safeRate =
                    DomainValidator.clampRateOfChange(val, profile.goalType);
                ref.read(userProfileProvider.notifier).updateProfile(
                      profile.copyWith(weeklyRateOfChangePct: safeRate),
                    );
              },
            ),
          ),
        ],
      ),
    );
  }
}
