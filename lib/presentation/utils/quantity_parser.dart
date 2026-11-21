/// Utility for parsing flexible user-entered quantities (integers, decimals, fractions like 1/2 or 1 1/2).
class QuantityParser {
  const QuantityParser._();

  static double? parse(String text) {
    final clean = text.trim().replaceAll(',', '.');
    if (clean.isEmpty) return null;
    if (clean.contains(' ') && clean.contains('/')) {
      final p = clean.split(RegExp(r'\s+'));
      if (p.length == 2) {
        final w = double.tryParse(p[0]), f = parse(p[1]);
        if (w != null && f != null) return w + f;
      }
    }
    if (clean.contains('/')) {
      final p = clean.split('/');
      if (p.length == 2) {
        final n = double.tryParse(p[0].trim());
        final d = double.tryParse(p[1].trim());
        if (n != null && d != null && d > 0) return n / d;
      }
      return null;
    }
    return double.tryParse(clean);
  }

  static String format(double q) =>
      q.truncateToDouble() == q ? q.toInt().toString() : q.toStringAsFixed(1);
}
