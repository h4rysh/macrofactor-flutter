import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/presentation/screens/food_log_screen.dart';
import 'golden_test_helper.dart';

void main() {
  late AppDatabase db;

  setUpAll(() async {
    await loadAppFonts();
    setUpGoldenComparator(
      'test/presentation/goldens/food_log_golden_test.dart',
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

  testWidgets('FoodLogScreen baseline golden', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildGoldenTestApp(
        db: db,
        child: const FoodLogScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(FoodLogScreen),
      matchesGoldenFile('food_log_screen.png'),
    );
  });
}
