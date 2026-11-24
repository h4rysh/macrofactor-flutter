import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/presentation/widgets/food_svg_icon.dart';
import 'package:sique/presentation/widgets/portion_selector_dialog.dart';
import 'package:sique/domain/models/food_models.dart';

void main() {
  group('FoodSvgIcon Dynamic Category Normalization Tests (DEF-01)', () {
    test('Normalizes database category strings to verified existing SVG assets', () {
      const testCases = {
        'veg': 'i740.svg',
        'vegetable': 'i740.svg',
        'meat': 'i201.svg',
        'non-veg': 'i201.svg',
        'dairy': 'i101.svg',
        'milk': 'i101.svg',
        'grain': 'i549.svg',
        'rice': 'i549.svg',
        'i105': 'i105.svg',
        'i105.svg': 'i105.svg',
        '': 'i1.svg',
        null: 'i1.svg',
        'unknown_random_food': 'i1.svg',
      };

      for (final entry in testCases.entries) {
        final icon = FoodSvgIcon(iconName: entry.key);
        expect(icon.resolvedIconSvg, equals(entry.value),
            reason: 'Failed for category input: "${entry.key}"');

        // Verify that the file actually exists on disk in assets/foods/
        final assetFile = File('assets/foods/${icon.resolvedIconSvg}');
        expect(assetFile.existsSync(), isTrue,
            reason: 'Asset file does not exist on disk: assets/foods/${icon.resolvedIconSvg}');
      }
    });

    testWidgets('FoodSvgIcon renders without throwing asset exceptions for category tokens',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                FoodSvgIcon(iconName: 'veg'),
                FoodSvgIcon(iconName: 'meat'),
                FoodSvgIcon(iconName: 'dairy'),
                FoodSvgIcon(iconName: 'grain'),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(FoodSvgIcon), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    });
  });

  group('Input Robustness & Localization Tests (DEF-11)', () {
    testWidgets('PortionSelectorDialog accepts comma decimal inputs gracefully',
        (tester) async {
      double? confirmedVal;
      PortionUnit? confirmedUnit;

      const unit = PortionUnit(
        id: 1,
        foodId: 10,
        unitName: 'Katori',
        gramWeight: 150.0,
        isDefault: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => PortionSelectorDialog(
                      initialQuantity: 1.0,
                      initialUnit: unit,
                      portionUnits: const [unit],
                      onConfirmed: (qty, u) {
                        confirmedVal = qty;
                        confirmedUnit = u;
                      },
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Enter European / locale comma decimal: 2,5
      final inputFinder = find.byType(TextFormField);
      expect(inputFinder, findsOneWidget);
      await tester.enterText(inputFinder, '2,5');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('portion_confirm_btn')));
      await tester.pumpAndSettle();

      expect(confirmedVal, equals(2.5));
      expect(confirmedUnit?.unitName, equals('Katori'));
      expect(tester.takeException(), isNull);
    });
  });
}
