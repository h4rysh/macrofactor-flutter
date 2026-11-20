import 'food_models.dart';

/// Centralized helper for rendering diet-aware preparation fat labels.
/// Enforces consistent 4-tier naming across food detail modals, plate serving sheets,
/// settings, and timeline meal sections.
class OilModifierDisplay {
  const OilModifierDisplay._();

  /// Canonical 4 tiers for oil adjustment in UI
  static const List<OilModifier> canonicalTiers = [
    OilModifier.standard, // None (0 kcal)
    OilModifier.oneTsp, // Light (+40 kcal)
    OilModifier.oneTbsp, // Home (+120 kcal)
    OilModifier.twoTbsp, // Rich (+240 kcal)
  ];

  /// Returns whether the specified diet type is vegan.
  static bool isVegan(String? dietType) =>
      dietType?.trim().toLowerCase() == 'vegan';

  /// Returns "oil" or "ghee" / "oil / ghee" based on user diet.
  static String fatMedium(bool isVegan, {bool capitalize = false}) {
    if (isVegan) {
      return capitalize ? 'Oil' : 'oil';
    }
    return capitalize ? 'Oil / Ghee' : 'oil / ghee';
  }

  /// Label for selection chips and modals:
  /// - None (0 kcal)
  /// - Light (+40 kcal)
  /// - Home (+120 kcal)
  /// - Rich (+240 kcal)
  static String getTierLabel(OilModifier modifier, {bool isVegan = false}) {
    switch (modifier) {
      case OilModifier.standard:
        return 'None (0 kcal)';
      case OilModifier.lowOil:
      case OilModifier.halfTsp:
      case OilModifier.oneTsp:
        return 'Light (+40 kcal)';
      case OilModifier.oneTbsp:
        return 'Home (+120 kcal)';
      case OilModifier.twoTbsp:
        return 'Rich (+240 kcal)';
    }
  }

  /// Detailed subtitle or description of the tier
  static String getTierSubtitle(OilModifier modifier, {bool isVegan = false}) {
    final fat = isVegan ? 'oil' : 'oil or ghee';
    switch (modifier) {
      case OilModifier.standard:
        return 'Raw, steamed, or boiled without added $fat';
      case OilModifier.lowOil:
      case OilModifier.halfTsp:
      case OilModifier.oneTsp:
        return 'Light tadka (~1 tsp $fat, +40 kcal)';
      case OilModifier.oneTbsp:
        return 'Home cooked standard (~1 tbsp $fat, +120 kcal)';
      case OilModifier.twoTbsp:
        return 'Restaurant / rich preparation (~2 tbsp $fat, +240 kcal)';
    }
  }

  /// Compact badge text for logged food timeline cards
  static String getTimelineBadge(OilModifier modifier, {bool isVegan = false}) {
    final fat = isVegan ? 'Oil' : 'Ghee';
    switch (modifier) {
      case OilModifier.standard:
        return '';
      case OilModifier.lowOil:
      case OilModifier.halfTsp:
      case OilModifier.oneTsp:
        return 'Light $fat';
      case OilModifier.oneTbsp:
        return 'Home $fat';
      case OilModifier.twoTbsp:
        return 'Rich $fat';
    }
  }
}
