import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/presentation/screens/onboarding/welcome_screen.dart';
import 'golden_test_helper.dart';

void main() {
  late AppDatabase db;

  setUpAll(() async {
    await loadAppFonts();
    setUpGoldenComparator(
      'test/presentation/goldens/welcome_golden_test.dart',
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

  testWidgets('WelcomeScreen baseline golden', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildGoldenTestApp(
        db: db,
        child: const WelcomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(WelcomeScreen),
      matchesGoldenFile('welcome_screen.png'),
    );
  });
}
