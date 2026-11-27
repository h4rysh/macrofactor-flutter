import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/domain/models/recipe_models.dart';
import 'package:sique/presentation/providers/recipes_providers.dart';
import 'package:sique/presentation/screens/nutrient_explorer_screen.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_sheet_grabber.dart';

/// Bottom sheet displaying aggregated daily micronutrient intake vs RDA
/// from sparse ICMR-NIN / USDA `food_nutrients` mappings.
class MicronutrientBreakdownSheet extends ConsumerWidget {
  const MicronutrientBreakdownSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MicronutrientBreakdownSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final micros = ref.watch(dailyMicronutrientsProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.80,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppTheme.cardBorder, width: 0.8),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppleSheetGrabber(margin: EdgeInsets.only(bottom: 10)),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Micronutrients & Electrolytes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context)
                          .push(NutrientExplorerScreen.route());
                    },
                    icon: const Icon(Icons.explore_outlined, size: 16),
                    label: const Text('36 Biomarkers'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Estimated from verified ICMR-NIN & USDA food entries logged today.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 14),
              if (micros.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Text(
                      'No micronutrient data yet. Log meals today to see your estimated vitamin, mineral, and electrolyte intake.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: micros.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) =>
                        _NutrientProgressRow(item: micros[idx]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NutrientProgressRow extends StatelessWidget {
  const _NutrientProgressRow({required this.item});

  final DailyMicronutrientIntake item;

  @override
  Widget build(BuildContext context) {
    final def = item.definition;
    final pct = item.percentOfRda;
    final progress = (pct / 100.0).clamp(0.0, 1.0);
    final Color barColor;
    if (item.exceedsUpperLimit) {
      barColor = AppTheme.calories;
    } else if (pct >= 90) {
      barColor = AppTheme.protein;
    } else if (pct >= 40) {
      barColor = AppTheme.activeBlue;
    } else {
      barColor = AppTheme.carbs;
    }

    final targetText = item.targetAmount != null
        ? '/ ${item.targetAmount!.toStringAsFixed(item.targetAmount! >= 100 ? 0 : 1)} ${def.unit}'
        : def.unit;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppRadii.mdBorderRadius,
        border: Border.all(color: AppTheme.cardBorder, width: 0.7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  def.displayName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Text(
                '${item.consumedAmount.toStringAsFixed(item.consumedAmount >= 100 ? 0 : 1)} $targetText (${pct.round()}%)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppTheme.cardBorder.withValues(alpha: 0.35),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}
