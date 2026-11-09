import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/domain/algorithms/coaching_engine.dart';
import 'package:sique/domain/models/food_models.dart';
import 'package:sique/domain/models/user_profile.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/screens/dashboard_screen.dart';
import 'package:sique/presentation/screens/food_detail_modal.dart';
import 'package:sique/presentation/screens/food_log_screen.dart';
import 'package:sique/presentation/screens/onboarding/welcome_screen.dart';
import 'package:sique/presentation/screens/plate_serving_sheet.dart';
import 'package:sique/presentation/screens/profile_targets_screen.dart';
import 'package:sique/presentation/screens/scaffold_with_nav_bar.dart';
import 'package:sique/presentation/screens/strategy_screen.dart';
import 'package:sique/presentation/screens/weight_log_modal.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/onboarding/wizard_input_tiles.dart';
import 'package:sique/presentation/widgets/strategy/checkin_review_sheet.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.inMemory();
    db.setSetting('onboarding_completed', 'true');
  });

  tearDown(() {
    db.close();
  });

  Widget buildAppWrapper({
    required Widget child,
    required double textScaleFactor,
    Size viewport = const Size(390, 844),
  }) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          size: viewport,
          textScaler: TextScaler.linear(textScaleFactor),
        ),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: mediaQuery.textScaler.clamp(
                  minScaleFactor: 1.0,
                  maxScaleFactor: 1.50,
                ),
              ),
              child: child!,
            );
          },
          home: child,
        ),
      ),
    );
  }

  group('Text Scaling & Clamping Unit Tests', () {
    testWidgets('builder clamps text scaler between 1.0 and 1.50',
        (tester) async {
      late TextScaler effectiveScaler;

      Widget testScaler(double scale) {
        return buildAppWrapper(
          textScaleFactor: scale,
          child: Builder(
            builder: (context) {
              effectiveScaler = MediaQuery.of(context).textScaler;
              return const SizedBox();
            },
          ),
        );
      }

      // Below floor: 0.8 -> clamped to 1.0
      await tester.pumpWidget(testScaler(0.8));
      expect(effectiveScaler.scale(10.0), 10.0);

      // Within range: 1.25 -> 1.25
      await tester.pumpWidget(testScaler(1.25));
      expect(effectiveScaler.scale(10.0), 12.5);

      // At boundary: 1.50 -> 1.50
      await tester.pumpWidget(testScaler(1.50));
      expect(effectiveScaler.scale(10.0), 15.0);

      // Above ceiling: 2.0 -> clamped to 1.50
      await tester.pumpWidget(testScaler(2.0));
      expect(effectiveScaler.scale(10.0), 15.0);
    });
  });

  group('Screen Layout Overflow Tests at 1.3x and 2.0x Text Scale', () {
    for (final scale in [1.3, 2.0]) {
      testWidgets('WelcomeScreen renders with 0 overflows at ${scale}x scale',
          (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildAppWrapper(
            textScaleFactor: scale,
            child: const WelcomeScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('SIQUE'), findsOneWidget);
        expect(find.text('Configure My Strategy'), findsOneWidget);
      });

      testWidgets('DashboardScreen renders with 0 overflows at ${scale}x scale',
          (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildAppWrapper(
            textScaleFactor: scale,
            child: const Scaffold(body: DashboardScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Dashboard'), findsWidgets);
        expect(find.text('ENERGY EXPENDITURE'), findsOneWidget);
      });

      testWidgets('FoodLogScreen renders with 0 overflows at ${scale}x scale',
          (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildAppWrapper(
            textScaleFactor: scale,
            child: const Scaffold(body: FoodLogScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Today'), findsOneWidget);
      });

      testWidgets('StrategyScreen renders with 0 overflows at ${scale}x scale',
          (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildAppWrapper(
            textScaleFactor: scale,
            child: const Scaffold(body: StrategyScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.textContaining('Strategy'), findsWidgets);
      });

      testWidgets(
          'ScaffoldWithNavBar dock labels do not overflow at ${scale}x scale on narrow viewport',
          (tester) async {
        // Narrow viewport: 360px width
        tester.view.physicalSize = const Size(360, 780);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildAppWrapper(
            viewport: const Size(360, 780),
            textScaleFactor: scale,
            child: const ScaffoldWithNavBar(),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Dashboard'), findsWidgets);
        expect(find.text('Food Log'), findsWidgets);
        expect(find.text('Strategy'), findsWidgets);
        expect(find.text('More'), findsWidgets);
      });

      testWidgets('WeightLogModal renders with 0 overflows at ${scale}x scale',
          (tester) async {
        tester.view.physicalSize = const Size(360, 780);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildAppWrapper(
            viewport: const Size(360, 780),
            textScaleFactor: scale,
            child: const Scaffold(body: WeightLogModal()),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('LOG SCALE WEIGHT'), findsOneWidget);
        expect(find.text('SAVE SCALE WEIGHT'), findsOneWidget);
      });

      testWidgets(
          'CheckinReviewSheet renders with 0 overflows at ${scale}x scale',
          (tester) async {
        tester.view.physicalSize = const Size(360, 780);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        late CheckInRecommendation rec;
        await tester.pumpWidget(
          buildAppWrapper(
            viewport: const Size(360, 780),
            textScaleFactor: scale,
            child: Consumer(
              builder: (context, ref, _) {
                rec = ref.watch(coachingCheckInStatusProvider);
                return Scaffold(body: CheckinReviewSheet(recommendation: rec));
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('WEEKLY COACHING CHECK-IN'), findsOneWidget);
        expect(find.text('Accept & Update Program'), findsOneWidget);
      });

      testWidgets(
          'ProfileTargetsScreen renders with 0 overflows at ${scale}x scale',
          (tester) async {
        tester.view.physicalSize = const Size(360, 780);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildAppWrapper(
            viewport: const Size(360, 780),
            textScaleFactor: scale,
            child: const Scaffold(body: ProfileTargetsScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Physical Stats'), findsOneWidget);
        expect(find.text('Weekly Rate of Change'), findsOneWidget);
      });

      testWidgets(
          'PlateServingSheet renders with 0 overflows at ${scale}x scale',
          (tester) async {
        tester.view.physicalSize = const Size(360, 780);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const dummyFood = FoodItem(
          id: 1,
          uuid: 'test_food_1',
          name: 'Paneer Butter Masala',
          category: 'Curry',
          region: 'North Indian',
          caloriesPer100g: 240,
          proteinPer100g: 12,
          carbsPer100g: 8,
          fatPer100g: 18,
          fiberPer100g: 2,
          iconSvg: 'curry',
          source: 'ICMR-NIN',
          aliases: 'paneer',
          portionUnits: [
            PortionUnit(
                id: 1,
                foodId: 1,
                unitName: 'Serving',
                gramWeight: 200,
                isDefault: true),
            PortionUnit(id: 2, foodId: 1, unitName: 'Gram', gramWeight: 1),
          ],
          isVerified: true,
        );

        const macroTargets = MacroTargets(
          calories: 2200,
          proteinGrams: 160,
          fatGrams: 70,
          carbsGrams: 230,
        );

        await tester.pumpWidget(
          buildAppWrapper(
            viewport: const Size(360, 780),
            textScaleFactor: scale,
            child: Scaffold(
              body: PlateServingSheet(
                food: dummyFood,
                portionUnits: dummyFood.portionUnits,
                macroTargets: macroTargets,
                initialLoggedAt: DateTime(2026, 11, 10, 12, 30),
                onLogConfirmed: ({
                  required unit,
                  required quantity,
                  required oilModifier,
                  required loggedAt,
                }) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Paneer Butter Masala'), findsOneWidget);
        expect(find.text('Add to Plate'), findsOneWidget);
      });

      testWidgets('FoodDetailModal renders with 0 overflows at ${scale}x scale',
          (tester) async {
        tester.view.physicalSize = const Size(360, 780);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const dummyFood = FoodItem(
          id: 1,
          uuid: 'test_food_1',
          name: 'Paneer Butter Masala',
          category: 'Curry',
          region: 'North Indian',
          caloriesPer100g: 240,
          proteinPer100g: 12,
          carbsPer100g: 8,
          fatPer100g: 18,
          fiberPer100g: 2,
          iconSvg: 'curry',
          source: 'ICMR-NIN',
          aliases: 'paneer',
          isVerified: true,
        );

        await tester.pumpWidget(
          buildAppWrapper(
            viewport: const Size(360, 780),
            textScaleFactor: scale,
            child: const Scaffold(
              body: FoodDetailModal(
                food: dummyFood,
                mealType: MealType.lunch,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Paneer Butter Masala'), findsOneWidget);
        expect(find.text('LOG TO LUNCH'), findsOneWidget);
      });

      testWidgets(
          'Wizard input tiles render with 0 overflows at ${scale}x scale',
          (tester) async {
        tester.view.physicalSize = const Size(360, 780);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildAppWrapper(
            viewport: const Size(360, 780),
            textScaleFactor: scale,
            child: Scaffold(
              body: Column(
                children: [
                  WizardSliderTile(
                    title: 'Current Weight Rating',
                    valueText: '78.5 kg / 173 lbs',
                    value: 78.5,
                    min: 40.0,
                    max: 160.0,
                    onChanged: (_) {},
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: WizardChoiceChip(
                          label: 'Biological Male',
                          icon: Icons.male,
                          selected: true,
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: WizardChoiceChip(
                          label: 'Biological Female',
                          icon: Icons.female,
                          selected: false,
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  WizardSmallChoiceChip(
                    label: 'Vegetarian High Protein',
                    selected: true,
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  const WizardMacroBadge(text: 'P: 160g • F: 70g • C: 230g'),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Current Weight Rating'), findsOneWidget);
        expect(find.text('Biological Male'), findsOneWidget);
      });
    }
  });

  group(
      'Multi-Viewport Stress Tests at Clamped 1.50 Scale (390x844, 360x780, 320x568)',
      () {
    const viewports = [
      (name: 'Standard (390x844)', size: Size(390, 844)),
      (name: 'Compact (360x780)', size: Size(360, 780)),
      (name: 'Ultra-Compact (320x568)', size: Size(320, 568)),
    ];

    for (final vp in viewports) {
      testWidgets(
          'DashboardScreen renders with 0 overflows on ${vp.name} at 1.50x scale',
          (tester) async {
        tester.view.physicalSize = vp.size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildAppWrapper(
            viewport: vp.size,
            textScaleFactor: 1.50,
            child: const Scaffold(body: DashboardScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Dashboard'), findsWidgets);
      });

      testWidgets(
          'StrategyScreen renders with 0 overflows on ${vp.name} at 1.50x scale',
          (tester) async {
        tester.view.physicalSize = vp.size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildAppWrapper(
            viewport: vp.size,
            textScaleFactor: 1.50,
            child: const Scaffold(body: StrategyScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.textContaining('Strategy'), findsWidgets);
      });

      testWidgets(
          'PlateServingSheet renders with 0 overflows on ${vp.name} at 1.50x scale',
          (tester) async {
        tester.view.physicalSize = vp.size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const dummyFood = FoodItem(
          id: 1,
          uuid: 'test_food_1',
          name: 'Paneer Butter Masala',
          category: 'Curry',
          region: 'North Indian',
          caloriesPer100g: 240,
          proteinPer100g: 12,
          carbsPer100g: 8,
          fatPer100g: 18,
          fiberPer100g: 2,
          iconSvg: 'curry',
          source: 'ICMR-NIN',
          aliases: 'paneer',
          portionUnits: [
            PortionUnit(
                id: 1,
                foodId: 1,
                unitName: 'Serving',
                gramWeight: 200,
                isDefault: true),
            PortionUnit(id: 2, foodId: 1, unitName: 'Gram', gramWeight: 1),
          ],
          isVerified: true,
        );

        const macroTargets = MacroTargets(
          calories: 2200,
          proteinGrams: 160,
          fatGrams: 70,
          carbsGrams: 230,
        );

        await tester.pumpWidget(
          buildAppWrapper(
            viewport: vp.size,
            textScaleFactor: 1.50,
            child: Scaffold(
              body: PlateServingSheet(
                food: dummyFood,
                portionUnits: dummyFood.portionUnits,
                macroTargets: macroTargets,
                initialLoggedAt: DateTime(2026, 11, 10, 12, 30),
                onLogConfirmed: ({
                  required unit,
                  required quantity,
                  required oilModifier,
                  required loggedAt,
                }) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Paneer Butter Masala'), findsOneWidget);
      });
    }
  });
}
