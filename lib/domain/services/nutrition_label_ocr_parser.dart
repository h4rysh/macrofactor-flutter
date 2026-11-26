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

  BarcodeFoodProduct toBarcodeProduct(String barcode) {
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
      cachedAt: DateTime.now(),
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
              r'serving[ \t]{1,8}size[^0-9]{0,20}(\d+(?:[.,]\d+)?)[ \t]{0,4}g'),
        ) ??
        100.0;

    final kcal = _extractNumber(
      lower,
      RegExp(
          r'(?:energy|calories?)[ \t]{0,16}(?:[:\-][ \t]{0,16})?(\d+(?:[.,]\d+)?)[ \t]{0,4}(?:kcal|cal)?'),
    );
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
    final sodium = _extractNumber(
      lower,
      RegExp(
          r'sodium[ \t]{0,16}(?:[:\-][ \t]{0,16})?(\d+(?:[.,]\d+)?)[ \t]{0,4}m?g?'),
    );

    if (kcal == null && protein == null && carbs == null && fat == null) {
      return null;
    }

    final factor = (isPerServing && servingG > 0) ? (100.0 / servingG) : 1.0;
    final p100 = (protein ?? 0.0) * factor;
    final c100 = (carbs ?? 0.0) * factor;
    final f100 = (fat ?? 0.0) * factor;
    final k100 =
        (kcal ?? ((p100 * 4.0 + c100 * 4.0 + f100 * 9.0) / factor)) * factor;

    return ParsedNutritionLabel(
      name: fallbackName,
      servingSizeG: servingG,
      caloriesPer100g: k100,
      proteinPer100g: p100,
      carbsPer100g: c100,
      fatPer100g: f100,
      fiberPer100g: fiber * factor,
      sodiumMgPer100g: sodium != null ? sodium * factor : null,
    );
  }
}
