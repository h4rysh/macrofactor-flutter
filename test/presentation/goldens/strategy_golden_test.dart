import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/presentation/screens/strategy_screen.dart';
import 'golden_test_helper.dart';

void main() {
  late AppDatabase db;

  setUpAll(() async {
    await loadAppFonts();
    setUpGoldenComparator(
      'test/presentation/goldens/strategy_golden_test.dart',
      tolerance: 0.02,
    );
  });

  setUp(() {
    db = AppDatabase.inMemory();
    db.setSetting('onboarding_completed', 'true');
  });

  tearDown(() {
    db.close();
  });

  testWidgets('StrategyScreen baseline golden', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildGoldenTestApp(
        db: db,
        child: const StrategyScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(StrategyScreen),
      matchesGoldenFile('strategy_screen.png'),
    );
  });
}
