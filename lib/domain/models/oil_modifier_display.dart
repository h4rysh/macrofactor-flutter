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
      case OilModifier.lowOil:
        return 'Low Oil (-30 kcal)';
      case OilModifier.standard:
        return 'None (0 kcal)';
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
      case OilModifier.lowOil:
        return 'Trimmed / blotted preparation (-30 kcal)';
      case OilModifier.standard:
        return 'Raw, steamed, or boiled without added $fat';
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
      case OilModifier.lowOil:
        return 'Low $fat';
      case OilModifier.standard:
        return '';
      case OilModifier.halfTsp:
      case OilModifier.oneTsp:
        return 'Light $fat';
      case OilModifier.oneTbsp:
        return 'Home $fat';
      case OilModifier.twoTbsp:
        return 'Rich $fat';
    }
  }

  /// Resolves either slug ('none'/'low'/'standard'/'extra') or display label into an [OilModifier].
  static OilModifier fromPreferenceSetting(String? raw) {
    final s = (raw ?? '').trim().toLowerCase();
    if (s.isEmpty) return OilModifier.standard;
    if (s == 'none' || s.startsWith('zero oil') || s.contains('0 kcal')) {
      return OilModifier.standard;
    }
    if (s == 'low' || s.startsWith('low oil') || s.contains('1 tsp')) {
      return OilModifier.oneTsp;
    }
    if (s == 'extra' || s.startsWith('extra') || s.contains('2 tbsp')) {
      return OilModifier.twoTbsp;
    }
    if (s == 'standard' || s.startsWith('standard') || s.contains('1 tbsp')) {
      return OilModifier.oneTbsp;
    }
    return OilModifier.standard;
  }

  /// Selects a [PortionUnit] matching the saved `default_portion_unit` preference.
  static PortionUnit resolveDefaultUnit(
    List<PortionUnit> units,
    String? pref,
    PortionUnit fallback,
  ) {
    if (units.isEmpty) return fallback;
    final p = (pref ?? '').trim().toLowerCase();
    if (p.contains('katori')) {
      return units.firstWhere(
        (u) => u.unitName.toLowerCase().contains('katori'),
        orElse: () => units.first,
      );
    }
    if (p.contains('piece') || p.contains('roti') || p.contains('idli')) {
      return units.firstWhere(
        (u) {
          final n = u.unitName.toLowerCase();
          return n.contains('roti') ||
              n.contains('piece') ||
              n.contains('idli');
        },
        orElse: () => units.first,
      );
    }
    if (p.contains('tablespoon') || p.contains('tbsp')) {
      return units.firstWhere(
        (u) {
          final n = u.unitName.toLowerCase();
          return n.contains('tbsp') || n.contains('tablespoon');
        },
        orElse: () => units.first,
      );
    }
    if (p.contains('gram')) {
      return units.firstWhere(
        (u) => u.unitName.toLowerCase().contains('gram'),
        orElse: () => units.first,
      );
    }
    return units.first;
  }
}
