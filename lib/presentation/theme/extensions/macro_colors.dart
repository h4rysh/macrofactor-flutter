import 'package:flutter/material.dart';
import 'package:sique/presentation/theme/tokens/app_colors.dart';

/// Semantic macronutrient color tokens packaged as a [ThemeExtension].
///
/// Enables cohesive styling of nutrition rings, charts, progress bars, and badges
/// across theme modes while keeping macro color semantics decoupled from core
/// Material color roles.
@immutable
class MacroColorsExtension extends ThemeExtension<MacroColorsExtension> {
  const MacroColorsExtension({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  /// Caloric intake indicator color (#FF5722).
  final Color calories;

  /// Protein macronutrient color (#F43F5E, Rose / Crimson).
  final Color protein;

  /// Carbohydrate macronutrient color (#38BDF8, Electric Cyan).
  final Color carbs;

  /// Fat macronutrient color (#A78BFA, Lavender).
  final Color fat;

  /// Plural alias for [fat].
  Color get fats => fat;

  /// Canonical dark theme instance.
  static const dark = MacroColorsExtension(
    calories: AppColors.calories,
    protein: AppColors.protein,
    carbs: AppColors.carbs,
    fat: AppColors.fat,
  );

  @override
  MacroColorsExtension copyWith({
    Color? calories,
    Color? protein,
    Color? carbs,
    Color? fat,
  }) {
    return MacroColorsExtension(
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
    );
  }

  @override
  MacroColorsExtension lerp(
    ThemeExtension<MacroColorsExtension>? other,
    double t,
  ) {
    if (other is! MacroColorsExtension) {
      return this;
    }
    return MacroColorsExtension(
      calories: Color.lerp(calories, other.calories, t) ?? calories,
      protein: Color.lerp(protein, other.protein, t) ?? protein,
      carbs: Color.lerp(carbs, other.carbs, t) ?? carbs,
      fat: Color.lerp(fat, other.fat, t) ?? fat,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MacroColorsExtension &&
        other.calories == calories &&
        other.protein == protein &&
        other.carbs == carbs &&
        other.fat == fat;
  }

  @override
  int get hashCode => Object.hash(calories, protein, carbs, fat);

  @override
  String toString() =>
      'MacroColorsExtension(calories: $calories, protein: $protein, carbs: $carbs, fat: $fat)';
}

/// Convenience extension on [BuildContext] to access [MacroColorsExtension].
extension MacroColorsContextExtension on BuildContext {
  /// Returns the nearest [MacroColorsExtension], defaulting to [MacroColorsExtension.dark].
  MacroColorsExtension get macroColors =>
      Theme.of(this).extension<MacroColorsExtension>() ??
      MacroColorsExtension.dark;
}
