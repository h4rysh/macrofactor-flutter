/// Utility for sanitizing strings exported to CSV to prevent formula injection attacks
/// (also known as CSV Injection or Formula Injection).
///
/// Any text cell starting with `=`, `+`, `-`, `@`, `\t` (tab), or `\r` (carriage return)
/// will be prefixed with a single quote (`'`), neutralizing spreadsheet formula execution.
class CsvSanitizer {
  const CsvSanitizer._();

  /// Sanitizes a single cell value for CSV export.
  static String sanitize(String? input) {
    if (input == null || input.isEmpty) return '';

    final firstChar = input[0];
    final trimmedLeft = input.trimLeft();
    final trimmedFirst = trimmedLeft.isNotEmpty ? trimmedLeft[0] : '';
    String sanitized = input;

    if (firstChar == '=' ||
        firstChar == '+' ||
        firstChar == '-' ||
        firstChar == '@' ||
        firstChar == '\t' ||
        firstChar == '\r' ||
        firstChar == '\n' ||
        trimmedFirst == '=' ||
        trimmedFirst == '+' ||
        trimmedFirst == '-' ||
        trimmedFirst == '@') {
      sanitized = "'$input";
    }

    // Escape internal double quotes for CSV standard RFC 4180
    if (sanitized.contains('"') ||
        sanitized.contains(',') ||
        sanitized.contains('\n') ||
        sanitized.contains('\r')) {
      return '"${sanitized.replaceAll('"', '""')}"';
    }

    return sanitized;
  }
}
