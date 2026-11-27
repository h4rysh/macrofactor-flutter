import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/data/local/dao/nutrient_explorer_dao.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// 36-Biomarker Nutrient Explorer with 7d/14d/30d rolling averages,
/// coverage transparency, top food contributors, and custom micro_goals.
class NutrientExplorerScreen extends ConsumerStatefulWidget {
  const NutrientExplorerScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute(builder: (_) => const NutrientExplorerScreen());

  @override
  ConsumerState<NutrientExplorerScreen> createState() =>
      _NutrientExplorerScreenState();
}

class _NutrientExplorerScreenState
    extends ConsumerState<NutrientExplorerScreen> {
  int _windowDays = 7;
  String _category = 'all';

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final profile = ref.watch(userProfileProvider);
    ref.watch(foodLogsRevisionProvider);
    final now = ref.watch(clockProvider)();

    final data = NutrientExplorerDao.loadWindow(
      db.rawDb,
      userId: db.currentUserId,
      windowDays: _windowDays,
      isFemale: !profile.isMale,
      referenceDate: now,
    );

    final filtered = _category == 'all'
        ? data.items
        : data.items.where((i) => i.category == _category).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Nutrient Explorer (36 Biomarkers)'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Window selector + Coverage Transparency
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final d in [7, 14, 30])
                ChoiceChip(
                  label: Text('${d}d'),
                  selected: _windowDays == d,
                  onSelected: (_) => setState(() => _windowDays = d),
                ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Text(
                  'Data coverage: ${data.coveragePct.round()}%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final cat in [
                  'all',
                  'vitamin',
                  'mineral',
                  'lipid',
                  'amino'
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat.toUpperCase(),
                          style: const TextStyle(fontSize: 11)),
                      selected: _category == cat,
                      onSelected: (_) => setState(() => _category = cat),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Text(
                  'No biomarkers match this category.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            for (final item in filtered)
              _buildNutrientTile(context, db, item, now),
        ],
      ),
    );
  }

  Widget _buildNutrientTile(
    BuildContext context,
    AppDatabase db,
    BiomarkerSummary item,
    DateTime now,
  ) {
    final ratio = item.ratio.clamp(0.0, 1.0);
    final pct = (item.ratio * 100).round();
    final isOverUl =
        item.upperLimit != null && item.avgDailyIntake > item.upperLimit!;
    final barColor = isOverUl
        ? Colors.amber
        : (ratio >= 0.80 ? AppTheme.calories : AppTheme.activeBlue);

    return Card(
      color: AppTheme.cardSurface,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: () => _showDetailSheet(context, db, item, now),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.displayName,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            if (item.isCustomGoal)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(Icons.star_rounded,
                    size: 14, color: AppTheme.activeBlue),
              ),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  '${item.avgDailyIntake.toStringAsFixed(1)} / ${item.targetAmount < 10 ? item.targetAmount.toStringAsFixed(1) : item.targetAmount.toStringAsFixed(0)} ${item.unit} ($pct%)',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: AppTheme.cardElevated,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailSheet(
    BuildContext context,
    AppDatabase db,
    BiomarkerSummary item,
    DateTime now,
  ) {
    final contributors = NutrientExplorerDao.topContributors(
      db.rawDb,
      userId: db.currentUserId,
      nutrientId: item.nutrientId,
      windowDays: _windowDays,
      referenceDate: now,
    );
    final targetCtrl = TextEditingController(
      text: item.targetAmount < 10
          ? item.targetAmount.toStringAsFixed(1)
          : item.targetAmount.toStringAsFixed(0),
    );
    String? targetError;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.cardSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            18,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.displayName} (${_windowDays}d Avg)',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'TOP FOOD CONTRIBUTORS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              if (contributors.isEmpty)
                const Text(
                  'No logged foods with tracked data for this nutrient in this window.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                )
              else
                for (final c in contributors)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            c.foodName,
                            style: const TextStyle(
                                color: AppTheme.textPrimary, fontSize: 13),
                          ),
                        ),
                        Text(
                          '${c.totalAmount.toStringAsFixed(1)} ${item.unit}',
                          style: const TextStyle(
                              color: AppTheme.activeBlueText,
                              fontWeight: FontWeight.w700,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: targetCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Custom Daily Target (${item.unit})',
                        errorText: targetError,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (item.isCustomGoal) ...[
                    TextButton(
                      onPressed: () {
                        db.diaryToolsDao.deleteCustomMicroGoal(item.nutrientId);
                        ref.read(foodLogsRevisionProvider.notifier).state++;
                        Navigator.pop(ctx);
                      },
                      child: const Text('Reset'),
                    ),
                    const SizedBox(width: 6),
                  ],
                  ElevatedButton(
                    onPressed: () {
                      final v =
                          double.tryParse(targetCtrl.text.replaceAll(',', '.'));
                      if (v != null && v.isFinite && v > 0 && v <= 100000) {
                        db.diaryToolsDao.setCustomMicroGoal(item.nutrientId, v);
                        ref.read(foodLogsRevisionProvider.notifier).state++;
                        Navigator.pop(ctx);
                      } else {
                        setSheetState(() {
                          targetError = 'Enter a valid value (1–100,000)';
                        });
                      }
                    },
                    child: const Text('Save Goal'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(targetCtrl.dispose);
  }
}
