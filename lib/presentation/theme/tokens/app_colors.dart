import 'package:flutter/material.dart';

/// Centralized color tokens for the Sique Clean-Room Design System.
///
/// Implements deep Obsidian dark mode with WCAG 2.1 AA compliant text contrast
/// and adherence-neutral nutritional accents.
class AppColors {
  AppColors._();

  // ===========================================================================
  // Surface Tokens
  // ===========================================================================

  /// Root obsidian background (#0B0B0E).
  static const Color background = Color(0xFF0B0B0E);

  /// Elevated dark card / container surface (#141418).
  static const Color surface = Color(0xFF141418);

  /// Card surface for standard content modules (#16161C).
  static const Color cardSurface = Color(0xFF16161C);

  /// Elevated surface for inputs, chips, and pills (#1F1F26).
  static const Color cardElevated = Color(0xFF1F1F26);

  /// Subtle hairline divider and border token (#26262E).
  static const Color cardBorder = Color(0xFF26262E);

  /// Top-edge specular highlight for physical anodized surface depth (12% white).
  static const Color specularHighlightTop = Color(0x1FFFFFFF);

  /// Bottom-edge hairline border for subtle shadow separation (2% white).
  static const Color specularHighlightBottom = Color(0x05FFFFFF);

  // ===========================================================================
  // Text & Content Tokens
  // All text tokens guarantee >= 4.5:1 WCAG AA contrast across all surfaces.
  // ===========================================================================

  /// High-contrast primary text and icons (#F5F5F7).
  /// Achieves >= 13.78:1 contrast across all surfaces.
  static const Color textPrimary = Color(0xFFF5F5F7);

  /// Secondary text, subtitles, and captions (#A1A1AA).
  /// Achieves >= 5.86:1 contrast across all surfaces.
  static const Color textSecondary = Color(0xFFA1A1AA);

  /// Muted labels, placeholders, and inactive icons (#8E8E9A).
  /// Lifted from legacy #63636E to guarantee >= 4.64:1 contrast across all
  /// surfaces (5.06:1 on cardElevated, 5.56:1 on cardSurface, 6.07:1 on background).
  static const Color textMuted = Color(0xFF8E8E9A);

  /// Alias for [textMuted] for backward compatibility.
  static const Color textTertiary = textMuted;

  // ===========================================================================
  // Accent & Action Tokens
  // ===========================================================================

  /// Vibrant electric blue for active selection, focus rings, and links (#3B82F6).
  /// Guarantees >= 3.0:1 non-text graphic contrast across all dark surfaces
  /// (4.08:1 on cardBorder, 4.45:1 on cardElevated, 5.34:1 on background).
  static const Color activeBlue = Color(0xFF3B82F6);

  /// Accessible blue text/icon color on dark surfaces (#60A5FA, 6.65:1 on cardElevated).
  static const Color activeBlueText = Color(0xFF60A5FA);

  /// Accessible error/rose text color on dark surfaces (#FB7185, 5.92:1 on cardElevated).
  static const Color errorText = Color(0xFFFB7185);

  /// High-contrast foreground text/icon color for primary buttons (#0B0B0E).
  /// Ensures 6.21:1 contrast on flame orange ([calories]) button backgrounds.
  static const Color buttonForeground = Color(0xFF0B0B0E);

  /// Primary CTA button background (#FAFAFA).
  static const Color buttonBackground = Color(0xFFFAFAFA);

  /// Primary CTA button dark text (#09090B).
  static const Color buttonText = Color(0xFF09090B);

  /// Secondary peach orange for calorie gradients and accents (#FF8A65).
  static const Color caloriesSecondary = Color(0xFFFF8A65);

  /// Calming indigo/lavender for adherence-neutral over-target calorie states (#818CF8).
  static const Color calmOverBudget = Color(0xFF818CF8);

  /// Elevated dark chip and tile background (#27272A).
  static const Color chipBackground = Color(0xFF27272A);

  /// Subtle chip and tag border (#3F3F46).
  static const Color chipBorder = Color(0xFF3F3F46);

  /// Primary theme accent, aliased to [calories] (#FF5722).
  static const Color primary = calories;

  // ===========================================================================
  // Semantic Macro Tokens
  // ===========================================================================

  /// Caloric energy intake indicator (#FF5722, Flame Orange, Hue 14°).
  static const Color calories = Color(0xFFFF5722);

  /// Protein macronutrient indicator (#F43F5E, Rose / Crimson, Hue 350°).
  /// Shifted from legacy peach (#FB923C, Hue 28°) to provide a distinct 66°
  /// hue delta from [calories], eliminating visual confusion on gauge rings.
  static const Color protein = Color(0xFFF43F5E);

  /// Carbohydrate macronutrient indicator (#38BDF8, Electric Cyan, Hue 199°).
  static const Color carbs = Color(0xFF38BDF8);

  /// Fat macronutrient indicator (#A78BFA, Lavender, Hue 252°).
  static const Color fat = Color(0xFFA78BFA);

  /// Alias for [fat] to support plural naming conventions.
  static const Color fats = fat;

  // ===========================================================================
  // Metric & Status Tokens
  // ===========================================================================

  /// Daily expenditure and metabolic burn rate (#34D399, Dynamic Emerald).
  static const Color expenditure = Color(0xFF34D399);

  /// Smoothed trend weight trajectory (#C084FC, Lavender / Violet).
  static const Color trendWeight = Color(0xFFC084FC);

  /// Informational alerts and indicators (#38BDF8).
  static const Color neutralInfo = Color(0xFF38BDF8);

  /// Positive confirmation and success states (#10B981).
  static const Color success = Color(0xFF10B981);

  /// Cautionary warnings and alerts (#F59E0B).
  static const Color warning = Color(0xFFF59E0B);

  // ===========================================================================
  // Contrast Audit Collections
  // ===========================================================================

  /// Map of all dark surface tokens for automated contrast testing.
  static const Map<String, Color> surfaces = {
    'background': background,
    'surface': surface,
    'cardSurface': cardSurface,
    'cardElevated': cardElevated,
    'cardBorder': cardBorder,
  };

  /// Map of all text tokens for automated contrast testing against surfaces.
  static const Map<String, Color> textColors = {
    'textPrimary': textPrimary,
    'textSecondary': textSecondary,
    'textMuted': textMuted,
  };

  /// Map of all graphic/accent tokens for automated non-text contrast testing.
  static const Map<String, Color> graphicColors = {
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'expenditure': expenditure,
    'trendWeight': trendWeight,
    'activeBlue': activeBlue,
  };
}
