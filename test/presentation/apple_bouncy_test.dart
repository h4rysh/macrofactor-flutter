import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/apple_tactile_card.dart';

void main() {
  group('AppleBouncy Widget Tests', () {
    testWidgets('scales down on press and returns to 1.0 on release',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppleBouncy(
                scaleDown: 0.90,
                onTap: () => tapped = true,
                child: const SizedBox(
                  width: 100,
                  height: 100,
                  child: Text('Bouncy'),
                ),
              ),
            ),
          ),
        ),
      );

      final animatedScaleFinder = find.descendant(
        of: find.byType(AppleBouncy),
        matching: find.byType(AnimatedScale),
      );
      expect(animatedScaleFinder, findsOneWidget);

      AnimatedScale scaleWidget = tester.widget(animatedScaleFinder);
      expect(scaleWidget.scale, 1.0);

      // Press down
      final gesture =
          await tester.startGesture(tester.getCenter(find.text('Bouncy')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      scaleWidget = tester.widget(animatedScaleFinder);
      expect(scaleWidget.scale, 0.90);

      // Release
      await gesture.up();
      expect(tapped, isTrue);

      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      scaleWidget = tester.widget(animatedScaleFinder);
      expect(scaleWidget.scale, 1.0);
    });

    testWidgets('enforces tactile minimum dwell time (80-100ms) with clock',
        (tester) async {
      final baseTime = DateTime(2026, 1, 1, 12, 0, 0);

      await withClock(Clock.fixed(baseTime), () async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: AppleBouncy(
                  scaleDown: 0.92,
                  minDwell: const Duration(milliseconds: 100),
                  duration: const Duration(milliseconds: 100),
                  onTap: () {},
                  child: const Text('DwellTest'),
                ),
              ),
            ),
          ),
        );

        final scaleFinder = find.descendant(
          of: find.byType(AppleBouncy),
          matching: find.byType(AnimatedScale),
        );

        // Tap down at t=0
        final gesture =
            await tester.startGesture(tester.getCenter(find.text('DwellTest')));
        await tester.pump();

        AnimatedScale scale = tester.widget(scaleFinder);
        expect(scale.scale, 0.92);

        // Release at t=10ms (before minDwell of 100ms)
        await gesture.up();
        await tester.pump();

        // At 30ms pump, dwell timer is still pending so scale stays 0.92
        await tester.pump(const Duration(milliseconds: 30));
        scale = tester.widget(scaleFinder);
        expect(scale.scale, 0.92);

        // Advance beyond the 100ms dwell window
        await tester.pump(const Duration(milliseconds: 80));
        await tester.pumpAndSettle();

        scale = tester.widget(scaleFinder);
        expect(scale.scale, 1.0);
      });
    });

    testWidgets('semantics has button role, label, and responds to a11y tap',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppleBouncy(
                semanticLabel: 'Action Card',
                onTap: () => tapped = true,
                child: const Text('Accessible Bouncy'),
              ),
            ),
          ),
        ),
      );

      final semanticsFinder = find.descendant(
        of: find.byType(AppleBouncy),
        matching: find.byType(Semantics),
      );
      expect(semanticsFinder, findsWidgets);

      final Semantics semanticsWidget = tester.widget(semanticsFinder.first);
      expect(semanticsWidget.properties.button, isTrue);
      expect(semanticsWidget.properties.enabled, isTrue);
      expect(semanticsWidget.properties.label, 'Action Card');

      // Verify a11y tap action is attached and invoking it triggers onTap
      expect(semanticsWidget.properties.onTap, isNotNull);
      semanticsWidget.properties.onTap!.call();
      expect(tapped, isTrue);
    });

    testWidgets('disableAnimations bypasses animation duration and dwell',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: AppleBouncy(
                  scaleDown: 0.88,
                  onTap: () => tapped = true,
                  child: const Text('NoAnim'),
                ),
              ),
            ),
          ),
        ),
      );

      final scaleFinder = find.descendant(
        of: find.byType(AppleBouncy),
        matching: find.byType(AnimatedScale),
      );
      final AnimatedScale scaleWidget = tester.widget(scaleFinder);
      expect(scaleWidget.duration, Duration.zero);

      await tester.tap(find.text('NoAnim'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('renders AppColors.activeBlue 2px focus ring on focus',
        (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppleBouncy(
                focusNode: focusNode,
                focusBorderRadius: BorderRadius.circular(12),
                onTap: () {},
                child: const Text('Focusable'),
              ),
            ),
          ),
        ),
      );

      final decoratedBoxFinder = find.descendant(
        of: find.byType(AppleBouncy),
        matching: find.byType(DecoratedBox),
      );
      expect(decoratedBoxFinder, findsOneWidget);

      DecoratedBox box = tester.widget(decoratedBoxFinder);
      BoxDecoration decoration = box.decoration as BoxDecoration;
      expect(decoration.border, isNull);

      // Focus the widget
      focusNode.requestFocus();
      await tester.pump();

      box = tester.widget(decoratedBoxFinder);
      decoration = box.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
      final border = decoration.border as Border;
      expect(border.top.color, AppColors.activeBlue);
      expect(border.top.width, 2.0);
    });

    testWidgets('responds to ActivateIntent and ButtonActivateIntent',
        (tester) async {
      var activateCount = 0;
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppleBouncy(
                focusNode: focusNode,
                onTap: () => activateCount++,
                child: const Text('IntentTest'),
              ),
            ),
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pump();

      // Invoke ActivateIntent
      Actions.invoke(
        tester.element(find.text('IntentTest')),
        const ActivateIntent(),
      );
      expect(activateCount, 1);

      // Invoke ButtonActivateIntent
      Actions.invoke(
        tester.element(find.text('IntentTest')),
        const ButtonActivateIntent(),
      );
      expect(activateCount, 2);
    });
  });
}
