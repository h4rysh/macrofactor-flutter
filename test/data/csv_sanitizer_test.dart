import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/utils/csv_sanitizer.dart';

void main() {
  group('CsvSanitizer Formula Injection Prevention Tests', () {
    test('Prefixes cell beginning with "=" with a single quote', () {
      const malicious = '=1+2';
      final sanitized = CsvSanitizer.sanitize(malicious);
      expect(sanitized, equals("'=1+2"));
    });

    test('Prefixes cell beginning with DDE formula injection', () {
      const malicious = "=cmd|' /C calc'!A0";
      final sanitized = CsvSanitizer.sanitize(malicious);
      expect(sanitized, startsWith("'=cmd"));
    });

    test('Prefixes cell beginning with "+"', () {
      const malicious = '+12345';
      final sanitized = CsvSanitizer.sanitize(malicious);
      expect(sanitized, equals("'+12345"));
    });

    test('Prefixes cell beginning with "-"', () {
      const malicious = '-10% discount';
      final sanitized = CsvSanitizer.sanitize(malicious);
      expect(sanitized, equals("'-10% discount"));
    });

    test('Prefixes cell beginning with "@"', () {
      const malicious = '@SUM(A1:A10)';
      final sanitized = CsvSanitizer.sanitize(malicious);
      expect(sanitized, equals("'@SUM(A1:A10)"));
    });

    test('Prefixes cell beginning with tab character (\\t)', () {
      const malicious = '\tTabbedEntry';
      final sanitized = CsvSanitizer.sanitize(malicious);
      expect(sanitized, startsWith("'\t"));
    });

    test('Prefixes cell beginning with carriage return (\\r)', () {
      const malicious = '\rCarriageReturn';
      final sanitized = CsvSanitizer.sanitize(malicious);
      expect(sanitized, startsWith('"\'\rCarriageReturn"'));
    });

    test('Escapes internal double quotes in sanitized cell', () {
      const malicious = '="malicious","payload"';
      final sanitized = CsvSanitizer.sanitize(malicious);
      expect(sanitized, equals('"\'=""malicious"",""payload"""'));
    });

    test('Leaves benign text without prefix', () {
      const benign = 'Whole Wheat Phulka / Roti';
      final sanitized = CsvSanitizer.sanitize(benign);
      expect(sanitized, equals(benign));
    });

    test('Handles empty and null inputs gracefully', () {
      expect(CsvSanitizer.sanitize(''), equals(''));
      expect(CsvSanitizer.sanitize(null), equals(''));
    });
  });
}
