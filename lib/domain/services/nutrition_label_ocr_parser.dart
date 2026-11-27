import 'dart:convert';

import 'package:sique/domain/models/recipe_models.dart';

/// Parsed nutrition facts extracted from FSSAI (per-100g) or FDA (per-serving) labels.
class ParsedNutritionLabel {
  const ParsedNutritionLabel({
    required this.name,
    required this.servingSizeG,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    required this.fiberPer100g,
    this.sodiumMgPer100g,
  });

  final String name;
  final double servingSizeG;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double fiberPer100g;
  final double? sodiumMgPer100g;

  BarcodeFoodProduct toBarcodeProduct(String barcode, {DateTime? now}) {
    final micros = sodiumMgPer100g != null
        ? jsonEncode({'sodium_mg': sodiumMgPer100g})
        : null;
    return BarcodeFoodProduct(
      barcode: barcode,
      foodName: name,
      brandName: 'Label OCR',
      servingSizeG: servingSizeG,
      caloriesPer100g: caloriesPer100g,
      proteinPer100g: proteinPer100g,
      carbsPer100g: carbsPer100g,
      fatPer100g: fatPer100g,
      fiberPer100g: fiberPer100g,
      microsJson: micros,
      cachedAt: now ?? DateTime.now(),
    );
  }
}

/// Offline regex parser for FSSAI / FDA Nutrition Facts labels.
class NutritionLabelOcrParser {
  const NutritionLabelOcrParser._();

  static double? _extractNumber(String text, RegExp pattern) {
    final m = pattern.firstMatch(text);
    if (m == null) return null;
    final raw = m.group(1)?.replaceAll(',', '.') ?? '';
    return double.tryParse(raw);
  }

  /// Parses raw OCR / pasted label text into normalized per-100g macros.
  static ParsedNutritionLabel? parse(
    String rawText, {
    String fallbackName = 'Scanned Packaged Food',
  }) {
    if (rawText.length > 10000) return null;
    final text = rawText.trim();
    if (text.isEmpty) return null;
    final lower = text.toLowerCase();

    final isPerServing = !lower.contains('per 100') &&
        (lower.contains('per serving') || lower.contains('serving size'));
    final servingG = _extractNumber(
          lower,
          RegExp(
              r'serving[ \t]{1,8}size[^\n0-9]{0,30}?(\d+(?:[.,]\d+)?)[ \t]{0,4}(?:g|ml)\b'),
        ) ??
        100.0;

    final energyMatch = RegExp(
      r'(?:energy|calories?)[ \t]{0,16}(?:[:\-][ \t]{0,16})?(\d+(?:[.,]\d+)?)[ \t]{0,4}(kcal|cal|kj)?',
    ).firstMatch(lower);
    final rawEnergy = energyMatch != null
        ? double.tryParse(energyMatch.group(1)!.replaceAll(',', '.'))
        : null;
    final energyUnit = energyMatch?.group(2);
    final kcal = rawEnergy == null
        ? null
        : (energyUnit == 'kj' ? rawEnergy / 4.184 : rawEnergy);

    final protein = _extractNumber(
      lower,
      RegExp(
          r'protein[ \t]{0,16}(?:[:\-][ \t]{0,16})?(\d+(?:[.,]\d+)?)[ \t]{0,4}g?'),
    );
    final carbs = _extractNumber(
      lower,
      RegExp(
          r'(?:total[ \t]{1,8})?carb(?:ohydrate)?s?[ \t]{0,16}(?:[:\-][ \t]{0,16})?(\d+(?:[.,]\d+)?)[ \t]{0,4}g?'),
    );
    final fat = _extractNumber(
      lower,
      RegExp(
          r'(?:total[ \t]{1,8})?fat[ \t]{0,16}(?:[:\-][ \t]{0,16})?(\d+(?:[.,]\d+)?)[ \t]{0,4}g?'),
    );
    final fiber = _extractNumber(
          lower,
          RegExp(
              r'(?:dietary[ \t]{1,8})?fib(?:er|re)[ \t]{0,16}(?:[:\-][ \t]{0,16})?(\d+(?:[.,]\d+)?)[ \t]{0,4}g?'),
        ) ??
        0.0;
    final sodiumMatch = RegExp(
      r'sodium[ \t]{0,16}(?:[:\-][ \t]{0,16})?(\d+(?:[.,]\d+)?)[ \t]{0,4}(mg|g)?',
    ).firstMatch(lower);
    final rawSodium = sodiumMatch != null
        ? double.tryParse(sodiumMatch.group(1)!.replaceAll(',', '.'))
        : null;
    final sodium = rawSodium == null
        ? null
        : (sodiumMatch?.group(2) == 'g' ? rawSodium * 1000.0 : rawSodium);

    if (kcal == null && protein == null && carbs == null && fat == null) {
      return null;
    }

    final safeServingG = servingG.clamp(1.0, 5000.0);
    final factor = isPerServing ? (100.0 / safeServingG) : 1.0;
    final p100 = ((protein ?? 0.0) * factor).clamp(0.0, 100.0);
    final c100 = ((carbs ?? 0.0) * factor).clamp(0.0, 100.0);
    final f100 = ((fat ?? 0.0) * factor).clamp(0.0, 100.0);
    final k100 = kcal != null && kcal.isFinite
        ? (kcal * factor).clamp(0.0, 1000.0)
        : (p100 * 4.0 + c100 * 4.0 + f100 * 9.0).clamp(0.0, 1000.0);
    final fiber100 = fiber.isFinite ? (fiber * factor).clamp(0.0, 100.0) : 0.0;
    final sodium100 = sodium != null && sodium.isFinite
        ? (sodium * factor).clamp(0.0, 50000.0)
        : null;

    return ParsedNutritionLabel(
      name: fallbackName,
      servingSizeG: safeServingG,
      caloriesPer100g: k100,
      proteinPer100g: p100,
      carbsPer100g: c100,
      fatPer100g: f100,
      fiberPer100g: fiber100,
      sodiumMgPer100g: sodium100,
    );
  }
}
