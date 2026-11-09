import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/presentation/theme/extensions/macro_colors.dart';
import 'package:sique/presentation/theme/tokens/app_colors.dart';

void main() {
  group('MacroColorsExtension Stress Testing', () {
    const dark = MacroColorsExtension.dark;

    const customA = MacroColorsExtension(
      calories: Color(0xFF110000),
      protein: Color(0xFF002200),
      carbs: Color(0xFF000033),
      fat: Color(0xFF440044),
    );

    const customB = MacroColorsExtension(
      calories: Color(0xFF990000),
      protein: Color(0xFF008800),
      carbs: Color(0xFF000077),
      fat: Color(0xFF660066),
    );

    test('Canonical dark instance matches AppColors tokens', () {
      expect(dark.calories, AppColors.calories);
      expect(dark.protein, AppColors.protein);
      expect(dark.carbs, AppColors.carbs);
      expect(dark.fat, AppColors.fat);
      expect(dark.fats, dark.fat);
    });

    group('copyWith', () {
      test('copyWith with all nulls preserves all original colors', () {
        final copied = dark.copyWith();
        expect(copied.calories, dark.calories);
        expect(copied.protein, dark.protein);
        expect(copied.carbs, dark.carbs);
        expect(copied.fat, dark.fat);
        expect(copied, equals(dark));
        expect(copied.hashCode, equals(dark.hashCode));
      });

      test('copyWith overrides single field while preserving others', () {
        const override = Color(0xFFAABBCC);

        final copyCalories = dark.copyWith(calories: override);
        expect(copyCalories.calories, override);
        expect(copyCalories.protein, dark.protein);
        expect(copyCalories.carbs, dark.carbs);
        expect(copyCalories.fat, dark.fat);

        final copyProtein = dark.copyWith(protein: override);
        expect(copyProtein.calories, dark.calories);
        expect(copyProtein.protein, override);
        expect(copyProtein.carbs, dark.carbs);
        expect(copyProtein.fat, dark.fat);

        final copyCarbs = dark.copyWith(carbs: override);
        expect(copyCarbs.calories, dark.calories);
        expect(copyCarbs.protein, dark.protein);
        expect(copyCarbs.carbs, override);
        expect(copyCarbs.fat, dark.fat);

        final copyFat = dark.copyWith(fat: override);
        expect(copyFat.calories, dark.calories);
        expect(copyFat.protein, dark.protein);
        expect(copyFat.carbs, dark.carbs);
        expect(copyFat.fat, override);
      });

      test('copyWith overrides all fields simultaneously', () {
        final copied = dark.copyWith(
          calories: const Color(0xFF111111),
          protein: const Color(0xFF222222),
          carbs: const Color(0xFF333333),
          fat: const Color(0xFF444444),
        );
        expect(copied.calories, const Color(0xFF111111));
        expect(copied.protein, const Color(0xFF222222));
        expect(copied.carbs, const Color(0xFF333333));
        expect(copied.fat, const Color(0xFF444444));
        expect(copied, isNot(equals(dark)));
      });
    });

    group('lerp', () {
      test('lerp with other == null returns this', () {
        final lerp0 = dark.lerp(null, 0.0);
        final lerp5 = dark.lerp(null, 0.5);
        final lerp1 = dark.lerp(null, 1.0);

        expect(identical(lerp0, dark), isTrue);
        expect(identical(lerp5, dark), isTrue);
        expect(identical(lerp1, dark), isTrue);
      });

      test('lerp with same instance returns this', () {
        final result = dark.lerp(dark, 0.5);
        expect(result.calories, dark.calories);
        expect(result.protein, dark.protein);
      });

      test('lerp at t = 0.0 returns this colors', () {
        final result = customA.lerp(customB, 0.0);
        expect(result.calories, customA.calories);
        expect(result.protein, customA.protein);
        expect(result.carbs, customA.carbs);
        expect(result.fat, customA.fat);
      });

      test('lerp at t = 1.0 returns other colors', () {
        final result = customA.lerp(customB, 1.0);
        expect(result.calories, customB.calories);
        expect(result.protein, customB.protein);
        expect(result.carbs, customB.carbs);
        expect(result.fat, customB.fat);
      });

      test('lerp at t = 0.5 produces midpoint colors', () {
        final result = customA.lerp(customB, 0.5);
        expect(
          result.calories,
          Color.lerp(customA.calories, customB.calories, 0.5),
        );
        expect(
          result.protein,
          Color.lerp(customA.protein, customB.protein, 0.5),
        );
        expect(
          result.carbs,
          Color.lerp(customA.carbs, customB.carbs, 0.5),
        );
        expect(
          result.fat,
          Color.lerp(customA.fat, customB.fat, 0.5),
        );
      });

      test('lerp with extreme t values (extrapolation/clamp)', () {
        final resultNeg = customA.lerp(customB, -0.5);
        expect(resultNeg.calories, isNotNull);

        final resultOver = customA.lerp(customB, 1.5);
        expect(resultOver.calories, isNotNull);
      });
    });

    group('equality, hashCode & toString', () {
      test('value equality and hashCode contract', () {
        const copy1 = MacroColorsExtension(
          calories: Color(0xFF112233),
          protein: Color(0xFF223344),
          carbs: Color(0xFF334455),
          fat: Color(0xFF445566),
        );
        const copy2 = MacroColorsExtension(
          calories: Color(0xFF112233),
          protein: Color(0xFF223344),
          carbs: Color(0xFF334455),
          fat: Color(0xFF445566),
        );

        expect(copy1, equals(copy2));
        expect(copy1.hashCode, equals(copy2.hashCode));
      });

      test('toString contains all field values', () {
        final str = dark.toString();
        expect(str, contains('MacroColorsExtension'));
        expect(str, contains('calories:'));
        expect(str, contains('protein:'));
        expect(str, contains('carbs:'));
        expect(str, contains('fat:'));
      });
    });

    group('BuildContext extension', () {
      testWidgets('context.macroColors resolves extension from theme',
          (tester) async {
        late MacroColorsExtension resolved;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark().copyWith(
              extensions: [customA],
            ),
            home: Builder(
              builder: (context) {
                resolved = context.macroColors;
                return const SizedBox();
              },
            ),
          ),
        );

        expect(resolved, equals(customA));
      });

      testWidgets(
          'context.macroColors falls back to MacroColorsExtension.dark when missing',
          (tester) async {
        late MacroColorsExtension resolved;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: Builder(
              builder: (context) {
                resolved = context.macroColors;
                return const SizedBox();
              },
            ),
          ),
        );

        expect(resolved, equals(MacroColorsExtension.dark));
      });
    });
  });
}
