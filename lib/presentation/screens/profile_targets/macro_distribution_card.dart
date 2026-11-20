import 'package:flutter/material.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Card showing target macronutrient breakdown in grams for Protein, Fat, and Carbs.
class MacroDistributionCard extends StatelessWidget {
  const MacroDistributionCard({
    super.key,
    required this.target,
  });

  final MacroTarget target;

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
            'Target Macro Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMacroPill(
                  label: 'Protein',
                  grams: '${target.proteinGrams.toStringAsFixed(0)}g',
                  color: AppTheme.protein,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMacroPill(
                  label: 'Fat',
                  grams: '${target.fatGrams.toStringAsFixed(0)}g',
                  color: AppTheme.fat,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMacroPill(
                  label: 'Carbs',
                  grams: '${target.carbsGrams.toStringAsFixed(0)}g',
                  color: AppTheme.carbs,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroPill({
    required String label,
    required String grams,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              grams,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
