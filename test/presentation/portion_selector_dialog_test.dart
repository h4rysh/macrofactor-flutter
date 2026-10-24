import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/presentation/widgets/portion_selector_dialog.dart';

void main() {
  group('PortionSelectorDialog - Numeric Serving Input and Stepper', () {
    const units = [
      PortionUnit(
          id: 1,
          foodId: 10,
          unitName: 'Serving',
          gramWeight: 100.0,
          isDefault: true),
      PortionUnit(
          id: 2,
          foodId: 10,
          unitName: 'Grams',
          gramWeight: 1.0,
          isDefault: false),
    ];

    testWidgets(
        'Renders initial quantity and updates via stepper increment/decrement',
        (tester) async {
      double? confirmedQuantity;
      PortionUnit? confirmedUnit;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  PortionSelectorDialog.show(
                    context: ctx,
                    initialQuantity: 1.0,
                    portionUnits: units,
                    initialUnit: units.first,
                    onConfirmed: (q, u) {
                      confirmedQuantity = q;
                      confirmedUnit = u;
                    },
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Serving Size'), findsOneWidget);
      expect(find.byKey(const Key('portion_numeric_field')), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      // Tap Increment (+0.5)
      await tester.tap(find.byKey(const Key('portion_increment_btn')));
      await tester.pumpAndSettle();
      expect(find.text('1.5'), findsOneWidget);

      // Confirm portion
      await tester.tap(find.byKey(const Key('portion_confirm_btn')));
      await tester.pumpAndSettle();

      expect(confirmedQuantity, equals(1.5));
      expect(confirmedUnit?.unitName, equals('Serving'));
    });

    testWidgets(
        'Directly accepts numeric input (e.g. typing 180) and validates > 0',
        (tester) async {
      double? confirmedQuantity;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  PortionSelectorDialog.show(
                    context: ctx,
                    initialQuantity: 1.0,
                    portionUnits: units,
                    initialUnit: units.last,
                    onConfirmed: (q, u) {
                      confirmedQuantity = q;
                    },
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

      // Clear text field and type "0"
      final numericField = find.byKey(const Key('portion_numeric_field'));
      await tester.enterText(numericField, '0');
      await tester.pumpAndSettle();

      // Tap confirm -> Validation error
      await tester.tap(find.byKey(const Key('portion_confirm_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Must be > 0'), findsOneWidget);
      expect(confirmedQuantity, isNull);

      // Type "180"
      await tester.enterText(numericField, '180');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('portion_confirm_btn')));
      await tester.pumpAndSettle();

      expect(confirmedQuantity, equals(180.0));
    });
  });
}
