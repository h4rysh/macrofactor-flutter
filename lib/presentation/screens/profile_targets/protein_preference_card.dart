import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Card for selecting protein intake preference (Moderate, High, Extra High).
class ProteinPreferenceCard extends StatelessWidget {
  const ProteinPreferenceCard({
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
            'Protein Target Strategy',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Protein intake protects lean body mass during energy deficits and supports muscle protein synthesis.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ProteinPreference.values.map((pref) {
              final isSelected = profile.proteinPreference == pref;
              return ChoiceChip(
                label: Text(
                  pref.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppTheme.protein,
                backgroundColor: AppTheme.cardElevated,
                side: BorderSide(
                  color: isSelected ? AppTheme.protein : AppTheme.cardBorder,
                ),
                onSelected: (selected) {
                  if (selected) {
                    ref.read(userProfileProvider.notifier).updateProfile(
                          profile.copyWith(proteinPreference: pref),
                        );
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
