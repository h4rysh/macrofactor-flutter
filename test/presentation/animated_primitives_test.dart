import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/presentation/theme/tokens/app_motion.dart';
import 'package:sique/presentation/widgets/animated_primitives.dart';

void main() {
  group('AnimatedCountText Tests', () {
    testWidgets('counts up from initialValue to target value smoothly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedCountText(
                value: 1000.0,
                initialValue: 0.0,
                duration: Duration(milliseconds: 750),
              ),
            ),
          ),
        ),
      );

      // Initial frame at t=0 displays initialValue (0)
      expect(find.text('0'), findsOneWidget);

      // Halfway through (375ms), it has interpolated to an intermediate value
      await tester.pump(const Duration(milliseconds: 375));

      final textFinder = find.byType(Text);
      expect(textFinder, findsOneWidget);
      final midText = (tester.widget(textFinder) as Text).data!;
      final midValue = double.parse(midText);
      expect(midValue, greaterThan(0.0));
      expect(midValue, lessThan(1000.0));

      // Settle the remaining animation
      await tester.pumpAndSettle();
      expect(find.text('1000'), findsOneWidget);
    });

    testWidgets(
        'applies tabular figures and custom formatter with prefix/suffix',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedCountText(
                value: 2450.0,
                initialValue: 2450.0,
                prefix: 'Budget: ',
                suffix: ' kcal',
                formatter: (v) => '${v.round()}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Budget: 2450 kcal'), findsOneWidget);

      final textWidget = tester.widget<Text>(find.byType(Text));
      final fontFeatures = textWidget.style?.fontFeatures;
      expect(fontFeatures, isNotNull);
      expect(
        fontFeatures!.any((f) => f.feature == 'tnum'),
        isTrue,
        reason: 'Font features must include tabular figures (tnum)',
      );
    });

    testWidgets('bypasses animation immediately when disableAnimations is true',
        (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: AnimatedCountText(
                  value: 3200.0,
                  initialValue: 0.0,
                  duration: Duration(milliseconds: 750),
                ),
              ),
            ),
          ),
        ),
      );

      // On first pump, target value is rendered immediately with no tween lag
      expect(find.text('3200'), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });
  });

  group('AppleStaggeredEntrance Tests', () {
    testWidgets('animates fade and slide translation from offsetY to zero',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppleStaggeredEntrance(
              index: 0,
              offsetY: 20.0,
              duration: Duration(milliseconds: 400),
              child: Text('Entrance Item'),
            ),
          ),
        ),
      );

      // At t=0, Opacity is 0.0 and Offset is at offsetY
      expect(find.text('Entrance Item'), findsOneWidget);
      final opacityFinder = find.ancestor(
        of: find.text('Entrance Item'),
        matching: find.byType(Opacity),
      );
      final transformFinder = find.ancestor(
        of: find.text('Entrance Item'),
        matching: find.byType(Transform),
      );

      expect(opacityFinder, findsOneWidget);
      expect(transformFinder, findsOneWidget);

      Opacity opacityWidget = tester.widget(opacityFinder);
      Transform transformWidget = tester.widget(transformFinder);
      expect(opacityWidget.opacity, closeTo(0.0, 0.01));
      expect(
        transformWidget.transform.getTranslation().y,
        closeTo(20.0, 0.01),
      );

      // At t=200ms (halfway), intermediate values
      await tester.pump(const Duration(milliseconds: 200));
      opacityWidget = tester.widget(opacityFinder);
      transformWidget = tester.widget(transformFinder);
      expect(opacityWidget.opacity, greaterThan(0.0));
      expect(opacityWidget.opacity, lessThan(1.0));
      expect(transformWidget.transform.getTranslation().y, lessThan(20.0));
      expect(transformWidget.transform.getTranslation().y, greaterThan(0.0));

      // Settle
      await tester.pumpAndSettle();
      opacityWidget = tester.widget(opacityFinder);
      transformWidget = tester.widget(transformFinder);
      expect(opacityWidget.opacity, 1.0);
      expect(
        transformWidget.transform.getTranslation().y,
        closeTo(0.0, 0.01),
      );
    });

    testWidgets('staggers delay based on index * interval', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppleStaggeredEntrance(
              index: 2,
              interval: Duration(milliseconds: 50),
              duration: Duration(milliseconds: 300),
              child: Text('Delayed Item'),
            ),
          ),
        ),
      );

      final opacityFinder = find.ancestor(
        of: find.text('Delayed Item'),
        matching: find.byType(Opacity),
      );

      // At t=50ms, the 100ms timer has not fired yet -> opacity is 0.0
      await tester.pump(const Duration(milliseconds: 50));
      Opacity opacityWidget = tester.widget(opacityFinder);
      expect(opacityWidget.opacity, 0.0);

      // Advance past 100ms so the delay timer fires and calls _controller.forward()
      await tester.pump(const Duration(milliseconds: 60));
      // Tick the animation controller
      await tester.pump(const Duration(milliseconds: 30));
      opacityWidget = tester.widget(opacityFinder);
      expect(opacityWidget.opacity, greaterThan(0.0));

      await tester.pumpAndSettle();
      opacityWidget = tester.widget(opacityFinder);
      expect(opacityWidget.opacity, 1.0);
    });

    testWidgets('single-play guard prevents replay on widget rebuild',
        (tester) async {
      Widget buildTree(int rebuildCount) {
        return MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text('Count: $rebuildCount'),
                const AppleStaggeredEntrance(
                  index: 0,
                  duration: Duration(milliseconds: 250),
                  child: Text('Keep Alive Item'),
                ),
              ],
            ),
          ),
        );
      }

      await tester.pumpWidget(buildTree(0));
      await tester.pumpAndSettle();

      final opacityFinder = find.ancestor(
        of: find.text('Keep Alive Item'),
        matching: find.byType(Opacity),
      );
      Opacity opacityWidget = tester.widget(opacityFinder);
      expect(opacityWidget.opacity, 1.0);

      // Rebuild parent tree with new count
      await tester.pumpWidget(buildTree(1));
      await tester.pump();

      // Opacity should NOT restart from 0.0
      opacityWidget = tester.widget(opacityFinder);
      expect(opacityWidget.opacity, 1.0);
      expect(find.text('Count: 1'), findsOneWidget);
    });

    testWidgets('bypasses animation immediately when disableAnimations is true',
        (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: AppleStaggeredEntrance(
                index: 3,
                duration: Duration(milliseconds: 400),
                child: Text('Immediate Item'),
              ),
            ),
          ),
        ),
      );

      // Child is returned directly without Opacity or Transform animation wrappers
      expect(find.text('Immediate Item'), findsOneWidget);
      final opacityFinder = find.ancestor(
        of: find.text('Immediate Item'),
        matching: find.byType(Opacity),
      );
      expect(opacityFinder, findsNothing);
    });
  });

  group('AnimatedMacroBar Tests', () {
    testWidgets('interpolates bar width smoothly to target fraction',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                child: AnimatedMacroBar(
                  ratio: 0.6,
                  color: Colors.green,
                  duration: AppMotion.macroBar,
                ),
              ),
            ),
          ),
        ),
      );

      // Initial pump begins tween
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 325));

      // After settling, the inner container has width = 200 * 0.6 = 120.0
      await tester.pumpAndSettle();

      final containerFinders = find.descendant(
        of: find.byType(AnimatedMacroBar),
        matching: find.byType(Container),
      );
      // There are 2 containers: the background track and the fill bar
      expect(containerFinders, findsNWidgets(2));

      final fillBarWidget = tester.widget<Container>(containerFinders.at(1));
      final constraints = fillBarWidget.constraints;
      expect(constraints?.maxWidth ?? fillBarWidget.decoration, isNotNull);

      final renderBox =
          tester.renderObject(containerFinders.at(1)) as RenderBox;
      expect(renderBox.size.width, closeTo(120.0, 0.5));
    });

    testWidgets(
        'renders target width immediately when disableAnimations is true',
        (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 200,
                  child: AnimatedMacroBar(
                    ratio: 0.75,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // On first pump, width is rendered immediately at 200 * 0.75 = 150.0
      await tester.pump();

      final containerFinders = find.descendant(
        of: find.byType(AnimatedMacroBar),
        matching: find.byType(Container),
      );
      expect(containerFinders, findsNWidgets(2));

      final renderBox =
          tester.renderObject(containerFinders.at(1)) as RenderBox;
      expect(renderBox.size.width, closeTo(150.0, 0.5));
    });

    testWidgets('clamps ratio to 0.0 and 1.0 bounds', (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 200,
                  child: AnimatedMacroBar(
                    ratio: 1.5, // over 1.0
                    color: Colors.orange,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      final containerFinders = find.descendant(
        of: find.byType(AnimatedMacroBar),
        matching: find.byType(Container),
      );
      final renderBox =
          tester.renderObject(containerFinders.at(1)) as RenderBox;
      expect(renderBox.size.width, closeTo(200.0, 0.5));
    });
  });
}
