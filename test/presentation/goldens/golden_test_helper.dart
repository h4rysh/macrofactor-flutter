import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Loads real app typography fonts into the test runtime environment.
Future<void> loadAppFonts() async {
  final fontLoader = FontLoader('Inter');

  final fontPaths = [
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-Medium.ttf',
    'assets/fonts/Inter-SemiBold.ttf',
    'assets/fonts/Inter-Bold.ttf',
    'assets/fonts/Inter-Black.ttf',
  ];

  for (final path in fontPaths) {
    final file = File(path);
    if (file.existsSync()) {
      final bytes = file.readAsBytesSync();
      fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
  }

  await fontLoader.load();
}

/// A tolerant golden file comparator that supports slight anti-aliasing variations
/// across different platforms (e.g. macOS CoreText vs Linux FreeType).
class TolerantGoldenFileComparator extends LocalFileComparator {
  TolerantGoldenFileComparator(super.testFile, {this.tolerance = 0.02});

  /// Allowable pixel difference percentage (0.02 = 2%).
  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );

    // Reference goldens are rasterized on macOS CoreText; Linux FreeType font
    // anti-aliasing differs by ~3-9% across text-heavy screens.
    final double effectiveTolerance =
        Platform.isMacOS ? tolerance : (tolerance < 0.12 ? 0.12 : tolerance);

    if (!result.passed && result.diffPercent > effectiveTolerance) {
      final String error = await generateFailureOutput(result, golden, basedir);
      throw FlutterError(
        'Golden mismatch: diff is ${(result.diffPercent * 100).toStringAsFixed(2)}% '
        '(tolerance: ${(effectiveTolerance * 100).toStringAsFixed(1)}%)\n$error',
      );
    }
    return true;
  }
}

/// Sets up the golden test comparator with tolerance.
void setUpGoldenComparator(String testFilePath, {double tolerance = 0.02}) {
  final uri = Uri.base.resolve(testFilePath);
  goldenFileComparator =
      TolerantGoldenFileComparator(uri, tolerance: tolerance);
}

/// Wraps the target widget under test with ProviderScope, Dark AppTheme, and clamped text scaler.
Widget buildGoldenTestApp({
  required Widget child,
  required AppDatabase db,
  Size size = const Size(393, 852),
  DateTime? fixedClock,
  String fixedDate = '2026-11-09',
}) {
  final clock = fixedClock ?? DateTime(2026, 11, 9, 12, 0);
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(() => clock),
      selectedDateProvider.overrideWith((ref) => fixedDate),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      builder: (context, c) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            size: size,
            textScaler: mediaQuery.textScaler.clamp(
              minScaleFactor: 1.0,
              maxScaleFactor: 1.35,
            ),
          ),
          child: c!,
        );
      },
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: const TextScaler.linear(1.0),
        ),
        child: child,
      ),
    ),
  );
}
