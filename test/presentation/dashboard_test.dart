import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macro_factor_app/data/local/app_database.dart';
import 'package:macro_factor_app/main.dart';
import 'package:macro_factor_app/presentation/providers/app_providers.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.inMemory();
    db.setSetting('onboarding_completed', 'true');
  });

  tearDown(() {
    db.close();
  });

  testWidgets(
      'MacroFactorApp loads dashboard and renders core adherence-neutral UI',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(450, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const MacroFactorApp(),
      ),
    );

    await tester.pumpAndSettle();

    // The app starts on Food Log screen (Index 1) as reconstructed from MacroFactor
    expect(find.text('Today'), findsOneWidget);

    // Switch to Dashboard tab (Index 0)
    await tester.tap(find.text('Dashboard').first);
    await tester.pumpAndSettle();

    // Verify Brand / Screen Header
    expect(find.text('Dashboard'), findsWidgets);

    // Verify Core Dynamic Algorithm Cards
    expect(find.text('ENERGY EXPENDITURE'), findsOneWidget);

    // Scroll until Weight Trend and Energy Balance are visible
    await tester.scrollUntilVisible(
      find.text('WEIGHT TREND'),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('WEIGHT TREND'), findsOneWidget);
    expect(find.text('ENERGY BALANCE'), findsOneWidget);

    // Verify Quick Actions
    expect(find.text('Log Food'), findsOneWidget);
    expect(find.text('Log Weight'), findsOneWidget);
  });

  testWidgets(
      'Tapping FAB opens Quick Log bottom sheet with meal and weight actions',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(450, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const MacroFactorApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Tap the centered FAB (+) in bottom nav bar
    await tester.tap(find.byKey(const Key('center_action_fab')));
    await tester.pumpAndSettle();

    // Verify Quick Actions Sheet contents
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Search Food / Add to Plate'), findsOneWidget);
    expect(find.text('Scan Barcode'), findsOneWidget);
    expect(find.text('Log Scale Weight'), findsOneWidget);
    expect(find.textContaining('Quick Add Calories'), findsOneWidget);
  });

  testWidgets(
      'Switching bottom nav tabs toggles between Dashboard and Strategy',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const MacroFactorApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Strategy icon is Icons.hub_outlined (authentic MacroFactor 3 interconnected nodes)
    final strategyIcon = find.byIcon(Icons.hub_outlined);
    expect(strategyIcon, findsOneWidget);

    await tester.tap(strategyIcon);
    await tester.pumpAndSettle();

    // Verify Strategy screen is displayed
    expect(find.text('Coaching & Strategy'), findsOneWidget);
    expect(find.text('ADHERENCE-NEUTRAL COACHING'), findsOneWidget);
    expect(find.text('kcal / day avg'), findsOneWidget);
    expect(find.text('PROTEIN'), findsOneWidget);
  });
}
