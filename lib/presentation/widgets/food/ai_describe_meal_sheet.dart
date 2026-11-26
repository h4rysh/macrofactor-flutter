import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/domain/services/gemini_food_capture_service.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Opt-in natural-language meal parser powered by user-supplied Gemini API key.
class AiDescribeMealSheet extends ConsumerStatefulWidget {
  const AiDescribeMealSheet({
    super.key,
    required this.mealType,
    required this.loggedAt,
  });

  final MealType mealType;
  final DateTime loggedAt;

  static Future<void> show(
    BuildContext context, {
    required MealType mealType,
    required DateTime loggedAt,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AiDescribeMealSheet(
        mealType: mealType,
        loggedAt: loggedAt,
      ),
    );
  }

  @override
  ConsumerState<AiDescribeMealSheet> createState() =>
      _AiDescribeMealSheetState();
}

class _AiDescribeMealSheetState extends ConsumerState<AiDescribeMealSheet> {
  late final TextEditingController _keyCtrl;
  final _descCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;
  List<AiParsedFoodItem> _items = const [];

  @override
  void initState() {
    super.initState();
    final savedKey = ref
        .read(databaseProvider)
        .getSetting(GeminiFoodCaptureService.apiKeySettingKey, '');
    _keyCtrl = TextEditingController(text: savedKey);
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _parse() async {
    final key = _keyCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    if (key.isEmpty) {
      setState(() => _error = 'Enter your Gemini API key to use AI Describe.');
      return;
    }
    if (desc.isEmpty) return;

    ref
        .read(databaseProvider)
        .setSetting(GeminiFoodCaptureService.apiKeySettingKey, key);
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final parsed = await GeminiFoodCaptureService.parseNaturalLanguageMeal(
      description: desc,
      apiKey: key,
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _items = parsed;
      if (parsed.isEmpty) {
        _error = 'Could not parse items. Check your API key or description.';
      }
    });
  }

  void _logAll() {
    final notifier = ref.read(dailyFoodLogsProvider.notifier);
    for (final item in _items) {
      final g = item.grams > 0 ? item.grams : 100.0;
      final factor = 100.0 / g;
      final id = -DateTime.now().microsecondsSinceEpoch;
      final food = FoodItem(
        id: id,
        uuid: 'ai_${id.abs()}',
        name: item.name,
        category: 'AI Describe',
        region: 'Custom',
        caloriesPer100g: item.calories * factor,
        proteinPer100g: item.protein * factor,
        carbsPer100g: item.carbs * factor,
        fatPer100g: item.fat * factor,
        fiberPer100g: item.fiber * factor,
        iconSvg: 'i2.svg',
        source: 'GEMINI_AI',
        aliases: item.name,
      );
      final unit = PortionUnit(
        id: 0,
        foodId: id,
        unitName: '${g.round()}g',
        gramsPerUnit: g,
        isDefault: true,
      );
      notifier.addEntry(
        food: food,
        portionUnit: unit,
        quantity: 1.0,
        mealType: widget.mealType,
        oilModifier: OilModifier.none,
        loggedAt: widget.loggedAt,
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 18, 20, bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'AI Describe Meal (Opt-In)',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _keyCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText:
                  'Gemini API Key (stored locally, excluded from backups)',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            maxLength: 1000,
            decoration: const InputDecoration(
              labelText: 'Describe what you ate',
              hintText: 'e.g. 2 idlis, 1 bowl sambar, and 2 boiled eggs',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(_error!,
                style: const TextStyle(color: Colors.amber, fontSize: 12)),
          ],
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _parse,
            icon: _isLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_rounded, size: 16),
            label: Text(_isLoading ? 'Parsing...' : 'Parse Meal'),
          ),
          if (_items.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final item in _items)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${item.name} (${item.grams.round()}g)',
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
                ),
                trailing: Text(
                  '${item.calories.round()} kcal · ${item.protein.round()}P',
                  style:
                      const TextStyle(color: AppTheme.activeBlue, fontSize: 12),
                ),
              ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _logAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.buttonBackground,
                foregroundColor: AppTheme.buttonText,
              ),
              child: Text('Log ${_items.length} Item(s)'),
            ),
          ],
        ],
      ),
    );
  }
}
