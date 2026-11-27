import 'package:intl/intl.dart';

/// Centralized utility for localized date formatting, height, and weight conversions.
/// Default locale is set to 'en_IN' (English - India) with 'dd/MM/yyyy' date pattern.
class UnitFormatter {
  UnitFormatter._();

  static const String defaultDatePattern = 'dd/MM/yyyy';
  static const String defaultLocale = 'en_IN';
  static const double kgToLbsMultiplier = 2.20462262185;
  static const double cmPerInch = 2.54;
  static const double cmPerFoot = 30.48;

  // ---------------------------------------------------------------------------
  // Date Formatting & Parsing
  // ---------------------------------------------------------------------------

  /// Formats a [DateTime] into a localized date string.
  /// Defaults to 'dd/MM/yyyy' in 'en_IN' locale.
  static String formatDate(
    DateTime date, {
    String pattern = defaultDatePattern,
    String? locale,
  }) {
    if (pattern == 'dd/MM/yyyy' || pattern == defaultDatePattern) {
      return formatDateDdMmYyyy(date);
    }
    if (pattern == 'yyyy-MM-dd') {
      return formatIsoDate(date);
    }
    try {
      return DateFormat(pattern, locale ?? defaultLocale).format(date);
    } catch (_) {
      return DateFormat(pattern).format(date);
    }
  }

  /// Convenience helper returning 'dd/MM/yyyy'.
  static String formatDateDdMmYyyy(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString().padLeft(4, '0');
    return '$d/$m/$y';
  }

  /// Formats a [DateTime] into standard ISO-8601 'yyyy-MM-dd' for database persistence.
  static String formatIsoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Formats a [DateTime] into a human-readable display string, e.g. '15 Aug 2026'.
  static String formatDisplayDate(DateTime date, {String? locale}) {
    try {
      return DateFormat('d MMM yyyy', locale ?? defaultLocale).format(date);
    } catch (_) {
      return DateFormat('d MMM yyyy').format(date);
    }
  }

  /// Formats a [DateTime] into a readable weekday + date string, e.g. 'Sat, 15 Aug'.
  static String formatWeekdayDate(DateTime date, {String? locale}) {
    try {
      return DateFormat('EEE, d MMM', locale ?? defaultLocale).format(date);
    } catch (_) {
      return DateFormat('EEE, d MMM').format(date);
    }
  }

  /// Parses a 'dd/MM/yyyy' or 'dd-MM-yyyy' string into a [DateTime].
  /// Returns null if parsing fails.
  static DateTime? parseDateDdMmYyyy(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return null;

    final parts = clean.contains('/') ? clean.split('/') : clean.split('-');
    if (parts.length != 3) return null;

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) return null;
    if (year < 1900 || year > 2100) return null;
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;

    try {
      final dt = DateTime(year, month, day);
      // Validate leap year / month day overflow (e.g. 31 Nov -> 1 Dec)
      if (dt.year == year && dt.month == month && dt.day == day) {
        return dt;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Weight Formatting & Conversions
  // ---------------------------------------------------------------------------

  /// Converts kilograms to pounds.
  static double kgToLbs(double kg) => kg * kgToLbsMultiplier;

  /// Converts pounds to kilograms.
  static double lbsToKg(double lbs) => lbs / kgToLbsMultiplier;

  /// Returns localized weight string with unit, e.g. '70.0 kg' or '154.3 lbs'.
  static String formatWeight(
    double weightKg, {
    bool useLbs = false,
    int decimals = 1,
  }) {
    final val = useLbs ? kgToLbs(weightKg) : weightKg;
    final unit = weightUnit(useLbs: useLbs);
    return '${val.toStringAsFixed(decimals)} $unit';
  }

  /// Returns numeric value string without unit suffix, e.g. '70.0' or '154.3'.
  static String formatWeightValue(
    double weightKg, {
    bool useLbs = false,
    int decimals = 1,
  }) {
    final val = useLbs ? kgToLbs(weightKg) : weightKg;
    return val.toStringAsFixed(decimals);
  }

  /// Returns unit suffix ('kg' or 'lbs').
  static String weightUnit({bool useLbs = false}) => useLbs ? 'lbs' : 'kg';

  /// Formatted weight field label: 'Weight (kg)' or 'Weight (lbs)'.
  static String weightLabel({bool useLbs = false}) =>
      'Weight (${weightUnit(useLbs: useLbs)})';

  /// Formatted target weight field label: 'Target Weight (kg)' or 'Target Weight (lbs)'.
  static String targetWeightLabel({bool useLbs = false}) =>
      'Target Weight (${weightUnit(useLbs: useLbs)})';

  /// Formatted weekly rate: e.g. 'Stable 0.0 kg/wk' or '-0.50 kg/wk'.
  static String formatWeeklyRate(double rateKgPerWeek, {bool useLbs = false}) {
    final val = useLbs ? kgToLbs(rateKgPerWeek) : rateKgPerWeek;
    final unit = weightUnit(useLbs: useLbs);
    if (rateKgPerWeek.abs() < 0.01) {
      return 'Stable 0.0 $unit/wk';
    }
    final sign = val > 0 ? '+' : '';
    return '$sign${val.toStringAsFixed(2)} $unit/wk';
  }

  // ---------------------------------------------------------------------------
  // Height Formatting & Conversions
  // ---------------------------------------------------------------------------

  /// Converts centimeters to imperial (feet, inches).
  static ({int feet, double inches}) cmToFeetInches(double cm) {
    if (cm <= 0) return (feet: 0, inches: 0.0);
    final totalInches = cm / cmPerInch;
    final feet = totalInches ~/ 12;
    final inches = totalInches - (feet * 12);
    return (feet: feet, inches: inches);
  }

  /// Converts centimeters to rounded integer (feet, inches), carrying 12 in -> +1 ft.
  static ({int feet, int inches}) cmToRoundedFeetInches(double cm) {
    if (cm <= 0 || !cm.isFinite) return (feet: 0, inches: 0);
    final totalInches = (cm / cmPerInch).round();
    return (feet: totalInches ~/ 12, inches: totalInches % 12);
  }

  /// Converts imperial (feet, inches) to centimeters.
  static double feetInchesToCm(int feet, double inches) {
    return (feet * cmPerFoot) + (inches * cmPerInch);
  }

  /// Returns formatted height string, e.g. '175 cm' or '5 ft 9 in'.
  static String formatHeight(double heightCm, {bool useImperial = false}) {
    if (useImperial) {
      final imperial = cmToRoundedFeetInches(heightCm);
      return '${imperial.feet} ft ${imperial.inches} in';
    }
    return '${heightCm.round()} cm';
  }

  /// Returns unit suffix ('cm' or 'ft/in').
  static String heightUnit({bool useImperial = false}) =>
      useImperial ? 'ft/in' : 'cm';

  /// Formatted height field label: 'Height (cm)' or 'Height (ft/in)'.
  static String heightLabel({bool useImperial = false}) =>
      'Height (${heightUnit(useImperial: useImperial)})';
}
