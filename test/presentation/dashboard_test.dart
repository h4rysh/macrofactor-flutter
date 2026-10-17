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
  });

  tearDown(() {
    db.close();
  });

  testWidgets(
      'MacroFactorApp loads dashboard and renders core adherence-neutral UI',
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

    // Verify Brand Title
    expect(find.text('MacroFactor'), findsOneWidget);
    expect(find.text('MF'), findsOneWidget);

    // Verify Core Dynamic Algorithm Cards
    expect(find.text('ENERGY EXPENDITURE'), findsOneWidget);
    expect(find.text('WEIGHT TREND'), findsOneWidget);

    // Verify 4 Meal Sections
    expect(find.text('BREAKFAST'), findsOneWidget);
    expect(find.text('LUNCH'), findsOneWidget);
    expect(find.text('DINNER'), findsOneWidget);
    expect(find.text('SNACKS & EXTRAS'), findsOneWidget);

    // Verify Date Switcher
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets(
      'Tapping FAB opens Quick Log bottom sheet with meal and weight actions',
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

    // Tap the centered FAB (+)
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Verify Quick Log Sheet contents
    expect(find.text('Quick Log'), findsOneWidget);
    expect(find.text('Breakfast'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Dinner'), findsOneWidget);
    expect(find.text('Snacks'), findsOneWidget);
    expect(find.text('Scale Weight'), findsOneWidget);
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

    // Strategy icon is in the bottom app bar
    final strategyIcon = find.byIcon(Icons.tune_outlined).last;
    expect(strategyIcon, findsOneWidget);

    await tester.tap(strategyIcon);
    await tester.pumpAndSettle();

    // Verify Strategy screen is displayed
    expect(find.text('Coaching & Strategy'), findsOneWidget);
    expect(find.text('ADHERENCE-NEUTRAL COACHING'), findsOneWidget);
    expect(find.text('PROJECTED DAILY TARGETS'), findsOneWidget);
    expect(find.text('APPLY PROGRAM TARGETS'), findsOneWidget);
  });
}
