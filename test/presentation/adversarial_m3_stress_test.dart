import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/presentation/theme/app_theme.dart';
import 'package:sique/presentation/widgets/animated_primitives.dart';
import 'package:sique/presentation/widgets/apple_skeleton.dart';

void main() {
  group('Adversarial Stress Suite: AppleBouncy Tactile Dwell & Clock', () {
    testWidgets(
        'Quick tap (10ms) holds pressed visual scale for 100ms dwell window',
        (tester) async {
      var currentTime = DateTime(2026, 11, 9, 10, 0, 0);

      await withClock(Clock(() => currentTime), () async {
        var tapCount = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: AppleBouncy(
                  scaleDown: 0.90,
                  minDwell: const Duration(milliseconds: 100),
                  duration: const Duration(milliseconds: 100),
                  onTap: () => tapCount++,
                  child: const SizedBox(
                    width: 80,
                    height: 80,
                    child: Text('QuickTap10'),
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

        // Tap down at t=0
        final gesture = await tester
            .startGesture(tester.getCenter(find.text('QuickTap10')));
        await tester.pump();

        AnimatedScale scale = tester.widget(scaleFinder);
        expect(scale.scale, 0.90);

        // Quick release at t=10ms
        currentTime = currentTime.add(const Duration(milliseconds: 10));
        await tester.pump(const Duration(milliseconds: 10));
        await gesture.up();
        await tester.pump();
        expect(tapCount, 1,
            reason: 'onTap must execute immediately upon release');

        // Remaining dwell is 100ms - 10ms = 90ms
        // At t=30ms (20ms after release): scale must still be pressed
        currentTime = currentTime.add(const Duration(milliseconds: 20));
        await tester.pump(const Duration(milliseconds: 20));
        scale = tester.widget(scaleFinder);
        expect(scale.scale, 0.90, reason: 'Scale must hold pressed at t=30ms');

        // At t=60ms (50ms after release): scale must still be pressed
        currentTime = currentTime.add(const Duration(milliseconds: 30));
        await tester.pump(const Duration(milliseconds: 30));
        scale = tester.widget(scaleFinder);
        expect(scale.scale, 0.90, reason: 'Scale must hold pressed at t=60ms');

        // At t=95ms (85ms after release, < 90ms remaining): scale must still be pressed
        currentTime = currentTime.add(const Duration(milliseconds: 35));
        await tester.pump(const Duration(milliseconds: 35));
        scale = tester.widget(scaleFinder);
        expect(scale.scale, 0.90, reason: 'Scale must hold pressed at t=95ms');

        // At t=110ms (100ms after release, > 90ms remaining): dwell timer has fired
        currentTime = currentTime.add(const Duration(milliseconds: 15));
        await tester.pump(const Duration(milliseconds: 15));
        scale = tester.widget(scaleFinder);
        expect(scale.scale, 1.0,
            reason: 'Target scale returns to 1.0 once dwell window ends');

        // Settle return spring animation
        await tester.pumpAndSettle();
        scale = tester.widget(scaleFinder);
        expect(scale.scale, 1.0);
      });
    });

    testWidgets(
        'Quick tap (25ms) holds pressed visual scale for 100ms dwell window',
        (tester) async {
      var currentTime = DateTime(2026, 11, 9, 10, 0, 0);

      await withClock(Clock(() => currentTime), () async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: AppleBouncy(
                  scaleDown: 0.85,
                  minDwell: const Duration(milliseconds: 100),
                  duration: const Duration(milliseconds: 100),
                  onTap: () {},
                  child: const Text('QuickTap25'),
                ),
              ),
            ),
          ),
        );

        final scaleFinder = find.descendant(
          of: find.byType(AppleBouncy),
          matching: find.byType(AnimatedScale),
        );

        final gesture = await tester
            .startGesture(tester.getCenter(find.text('QuickTap25')));
        await tester.pump();
        expect((tester.widget(scaleFinder) as AnimatedScale).scale, 0.85);

        // Tap held for 25ms (< 30ms requirement)
        currentTime = currentTime.add(const Duration(milliseconds: 25));
        await tester.pump(const Duration(milliseconds: 25));
        await gesture.up();
        await tester.pump();

        // Remaining dwell is 100ms - 25ms = 75ms
        // At t=50ms total (25ms after up), pressed state is strictly maintained
        currentTime = currentTime.add(const Duration(milliseconds: 25));
        await tester.pump(const Duration(milliseconds: 25));
        expect((tester.widget(scaleFinder) as AnimatedScale).scale, 0.85);

        // At t=85ms total (60ms after up, < 75ms remaining), still strictly maintained
        currentTime = currentTime.add(const Duration(milliseconds: 35));
        await tester.pump(const Duration(milliseconds: 35));
        expect((tester.widget(scaleFinder) as AnimatedScale).scale, 0.85);

        // Advance to 105ms total (80ms after up, > 75ms remaining)
        currentTime = currentTime.add(const Duration(milliseconds: 20));
        await tester.pump(const Duration(milliseconds: 20));
        expect((tester.widget(scaleFinder) as AnimatedScale).scale, 1.0);
      });
    });

    testWidgets(
        'Long tap (150ms) releases immediately without extra dwell padding',
        (tester) async {
      var currentTime = DateTime(2026, 11, 9, 10, 0, 0);

      await withClock(Clock(() => currentTime), () async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: AppleBouncy(
                  scaleDown: 0.90,
                  minDwell: const Duration(milliseconds: 100),
                  duration: const Duration(milliseconds: 100),
                  onTap: () {},
                  child: const Text('LongTap'),
                ),
              ),
            ),
          ),
        );

        final scaleFinder = find.descendant(
          of: find.byType(AppleBouncy),
          matching: find.byType(AnimatedScale),
        );

        final gesture =
            await tester.startGesture(tester.getCenter(find.text('LongTap')));
        await tester.pump();
        expect((tester.widget(scaleFinder) as AnimatedScale).scale, 0.90);

        // Hold press for 150ms (> 100ms minDwell)
        currentTime = currentTime.add(const Duration(milliseconds: 150));
        await tester.pump(const Duration(milliseconds: 150));
        await gesture.up();
        await tester.pump();

        // Since elapsed >= minDwell, target scale must immediately flip to 1.0
        expect((tester.widget(scaleFinder) as AnimatedScale).scale, 1.0);
      });
    });

    testWidgets(
        'Rapid double-tap stress does not leak timers or throw exceptions',
        (tester) async {
      var currentTime = DateTime(2026, 11, 9, 10, 0, 0);

      await withClock(Clock(() => currentTime), () async {
        var tapCount = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: AppleBouncy(
                  scaleDown: 0.90,
                  onTap: () => tapCount++,
                  child: const Text('DoubleTap'),
                ),
              ),
            ),
          ),
        );

        final center = tester.getCenter(find.text('DoubleTap'));

        // Tap 1: 10ms down, up
        final g1 = await tester.startGesture(center);
        currentTime = currentTime.add(const Duration(milliseconds: 10));
        await tester.pump(const Duration(milliseconds: 10));
        await g1.up();
        currentTime = currentTime.add(const Duration(milliseconds: 10));
        await tester.pump(const Duration(milliseconds: 10));

        // Tap 2: 15ms down, up
        final g2 = await tester.startGesture(center);
        currentTime = currentTime.add(const Duration(milliseconds: 15));
        await tester.pump(const Duration(milliseconds: 15));
        await g2.up();
        currentTime = currentTime.add(const Duration(milliseconds: 15));
        await tester.pump(const Duration(milliseconds: 15));

        expect(tapCount, 2);

        // Advance past all dwell timers
        currentTime = currentTime.add(const Duration(milliseconds: 150));
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pumpAndSettle();

        final scaleFinder = find.descendant(
          of: find.byType(AppleBouncy),
          matching: find.byType(AnimatedScale),
        );
        expect((tester.widget(scaleFinder) as AnimatedScale).scale, 1.0);
      });
    });

    testWidgets('disableAnimations: true bypasses dwell immediately on tap up',
        (tester) async {
      var tapCount = 0;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: AppleBouncy(
                  scaleDown: 0.88,
                  onTap: () => tapCount++,
                  child: const Text('ReducedMotionBouncy'),
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

      final gesture = await tester
          .startGesture(tester.getCenter(find.text('ReducedMotionBouncy')));
      await tester.pump();
      expect((tester.widget(scaleFinder) as AnimatedScale).scale, 0.88);

      // Release immediately
      await gesture.up();
      await tester.pump();

      // Dwell must be completely bypassed, scale snaps to 1.0 immediately
      expect(tapCount, 1);
      expect((tester.widget(scaleFinder) as AnimatedScale).scale, 1.0);
      expect(tester.binding.hasScheduledFrame, isFalse,
          reason:
              'No animation or dwell timers scheduled when disableAnimations: true');
    });

    testWidgets(
        'Gesture cancellation resets pressed scale cleanly without triggering onTap',
        (tester) async {
      var tapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppleBouncy(
                scaleDown: 0.90,
                onTap: () => tapCount++,
                child: const Text('CancelTest'),
              ),
            ),
          ),
        ),
      );

      final scaleFinder = find.descendant(
        of: find.byType(AppleBouncy),
        matching: find.byType(AnimatedScale),
      );

      final gesture =
          await tester.startGesture(tester.getCenter(find.text('CancelTest')));
      await tester.pump();
      expect((tester.widget(scaleFinder) as AnimatedScale).scale, 0.90);

      // Cancel gesture (e.g. pointer cancel)
      await gesture.cancel();
      await tester.pump();

      expect((tester.widget(scaleFinder) as AnimatedScale).scale, 1.0);
      expect(tapCount, 0,
          reason: 'Cancelled tap must not invoke onTap callback');
    });

    testWidgets(
        'Keyboard focus produces visible AppColors.activeBlue 2px border and handles blur',
        (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppleBouncy(
                focusNode: focusNode,
                focusBorderRadius: BorderRadius.circular(18),
                onTap: () {},
                child: const Text('FocusBorderTest'),
              ),
            ),
          ),
        ),
      );

      final boxFinder = find.descendant(
        of: find.byType(AppleBouncy),
        matching: find.byType(DecoratedBox),
      );
      expect(boxFinder, findsOneWidget);

      DecoratedBox box = tester.widget(boxFinder);
      BoxDecoration decoration = box.decoration as BoxDecoration;
      expect(decoration.border, isNull);

      // Request focus
      focusNode.requestFocus();
      await tester.pump();

      box = tester.widget(boxFinder);
      decoration = box.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
      final border = decoration.border as Border;
      expect(border.top.color, AppColors.activeBlue);
      expect(border.top.width, 2.0);
      expect(decoration.borderRadius, BorderRadius.circular(18));

      // Unfocus
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      box = tester.widget(boxFinder);
      decoration = box.decoration as BoxDecoration;
      expect(decoration.border, isNull,
          reason: 'Focus border must disappear when widget loses focus');
    });

    testWidgets('Disabled state (enabled: false) ignores gestures and focus',
        (tester) async {
      var tapCount = 0;
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppleBouncy(
                enabled: false,
                focusNode: focusNode,
                onTap: () => tapCount++,
                child: const Text('DisabledBouncy'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('DisabledBouncy'));
      await tester.pump();
      expect(tapCount, 0);

      focusNode.requestFocus();
      await tester.pump();

      final boxFinder = find.descendant(
        of: find.byType(AppleBouncy),
        matching: find.byType(DecoratedBox),
      );
      final DecoratedBox box = tester.widget(boxFinder);
      final BoxDecoration decoration = box.decoration as BoxDecoration;
      expect(decoration.border, isNull,
          reason: 'Disabled bouncy does not highlight on focus');
    });
  });

  group('Adversarial Stress Suite: Animated Primitives & Reduced Motion', () {
    testWidgets(
        'AnimatedCountText animates from 0.0 to target on initial appearance',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedCountText(
                value: 2000.0,
                duration: Duration(milliseconds: 600),
              ),
            ),
          ),
        ),
      );

      // Frame 0 must show 0.0 (the default initialValue)
      expect(find.text('0'), findsOneWidget);

      // Frame halfway (300ms)
      await tester.pump(const Duration(milliseconds: 300));
      final textWidget = tester.widget<Text>(find.byType(Text));
      final intermediate = double.parse(textWidget.data!);
      expect(intermediate, greaterThan(0));
      expect(intermediate, lessThan(2000));

      // Completion
      await tester.pumpAndSettle();
      expect(find.text('2000'), findsOneWidget);
    });

    testWidgets(
        'AnimatedCountText includes tabular figures (tnum) in font features',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedCountText(
                value: 500.0,
                prefix: '\$',
                suffix: ' USD',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('\$500 USD'), findsOneWidget);

      final textWidget = tester.widget<Text>(find.byType(Text));
      final fontFeatures = textWidget.style?.fontFeatures;
      expect(fontFeatures, isNotNull);
      expect(fontFeatures!.any((f) => f.feature == 'tnum'), isTrue);
    });

    testWidgets(
        'AnimatedCountText with disableAnimations renders target immediately without 0 frame',
        (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: AnimatedCountText(
                  value: 8500.0,
                ),
              ),
            ),
          ),
        ),
      );

      // Instant first frame verification
      expect(find.text('8500'), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets(
        'AppleStaggeredEntrance plays once and does not replay on multiple rebuilds',
        (tester) async {
      var rebuildState = 0;
      late StateSetter parentSetState;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                parentSetState = setState;
                return Column(
                  children: [
                    Text('RebuildState: $rebuildState'),
                    const AppleStaggeredEntrance(
                      index: 0,
                      duration: Duration(milliseconds: 200),
                      child: Text('StaggeredItem'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      final opacityFinder = find.ancestor(
        of: find.text('StaggeredItem'),
        matching: find.byType(Opacity),
      );

      // Initial opacity is 0.0
      expect((tester.widget(opacityFinder) as Opacity).opacity,
          closeTo(0.0, 0.05));

      // Settle initial animation
      await tester.pumpAndSettle();
      expect((tester.widget(opacityFinder) as Opacity).opacity, 1.0);

      // Rebuild parent 5 times rapidly
      for (var i = 1; i <= 5; i++) {
        parentSetState(() => rebuildState = i);
        await tester.pump();
        expect(find.text('RebuildState: $i'), findsOneWidget);
        // Opacity MUST remain 1.0 and not reset to 0.0
        expect((tester.widget(opacityFinder) as Opacity).opacity, 1.0,
            reason: 'AppleStaggeredEntrance must never replay on rebuild $i');
      }
    });

    testWidgets(
        'AppleStaggeredEntrance respects disableAnimations: true immediately',
        (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: AppleStaggeredEntrance(
                index: 2,
                child: Text('DirectItem'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('DirectItem'), findsOneWidget);
      // No Opacity or Transform ancestors should wrap child
      final opacityFinder = find.ancestor(
        of: find.text('DirectItem'),
        matching: find.byType(Opacity),
      );
      expect(opacityFinder, findsNothing);
    });

    testWidgets('AnimatedMacroBar clamps out-of-bound ratios properly',
        (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  child: AnimatedMacroBar(
                    ratio: -0.5,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      final containers = find.descendant(
        of: find.byType(AnimatedMacroBar),
        matching: find.byType(Container),
      );
      final fillBar = tester.renderObject(containers.at(1)) as RenderBox;
      expect(fillBar.size.width, closeTo(0.0, 0.1));
    });
  });

  group('Adversarial Stress Suite: Layout-Matching Skeletons', () {
    testWidgets(
        'DashboardSkeleton key dimensions match MacroGaugeRing without layout shift',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DashboardSkeleton(),
          ),
        ),
      );

      // 1. Macro Ring Box: 184x184 circle
      final macroRingFinder = find.byWidgetPredicate((w) {
        return w is AppleSkeletonBox &&
            w.width == 184 &&
            w.height == 184 &&
            w.shape == BoxShape.circle;
      });
      expect(macroRingFinder, findsOneWidget);

      // 2. Card Container: 22.0 border radius
      final cardFinder = find.byWidgetPredicate((w) {
        if (w is Container && w.decoration is BoxDecoration) {
          final d = w.decoration as BoxDecoration;
          return d.borderRadius == BorderRadius.circular(22.0);
        }
        return false;
      });
      expect(cardFinder, findsOneWidget);

      // 3. Quick Action Strip: 3 pills of height 48, radius 14
      final pillsFinder = find.byWidgetPredicate((w) {
        return w is AppleSkeletonBox && w.height == 48 && w.borderRadius == 14;
      });
      expect(pillsFinder, findsNWidgets(3));

      // 4. Metric cards: 2 cards of height 140, radius 18
      final metricCardsFinder = find.byWidgetPredicate((w) {
        return w is AppleSkeletonBox && w.height == 140 && w.borderRadius == 18;
      });
      expect(metricCardsFinder, findsNWidgets(2));
    });

    testWidgets(
        'FoodLogSkeleton dimensions match DateCarouselRibbon and timeline slots',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FoodLogSkeleton(),
          ),
        ),
      );

      // 1. Date Carousel: 7 day pills of width 44, height 58, radius 16
      final datePillsFinder = find.byWidgetPredicate((w) {
        return w is AppleSkeletonBox &&
            w.width == 44 &&
            w.height == 58 &&
            w.borderRadius == 16;
      });
      expect(datePillsFinder, findsNWidgets(7));

      // 2. Summary Banner: height 52, radius 14
      final bannerFinder = find.byWidgetPredicate((w) {
        return w is AppleSkeletonBox && w.height == 52 && w.borderRadius == 14;
      });
      expect(bannerFinder, findsOneWidget);

      // 3. Timeline Slot Placeholders: 4 cards with radius 16 and inner height 48
      final timelineSlotsFinder = find.byWidgetPredicate((w) {
        return w is AppleSkeletonBox && w.height == 48 && w.borderRadius == 10;
      });
      expect(timelineSlotsFinder, findsNWidgets(4));
    });

    testWidgets(
        'AppleSkeletonShimmer dynamic toggle between normal and reduced motion',
        (tester) async {
      var disableMotion = false;
      late StateSetter toggleSetState;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            toggleSetState = setState;
            return MediaQuery(
              data: MediaQueryData(disableAnimations: disableMotion),
              child: const MaterialApp(
                home: Scaffold(
                  body: AppleSkeletonShimmer(
                    child: AppleSkeletonBox(width: 120, height: 30),
                  ),
                ),
              ),
            );
          },
        ),
      );

      // Phase 1: animations enabled -> ShaderMask is active
      expect(find.byType(ShaderMask), findsOneWidget);

      // Phase 2: toggle disableAnimations: true
      toggleSetState(() => disableMotion = true);
      await tester.pump();

      // ShaderMask must be removed and child rendered statically
      expect(find.byType(ShaderMask), findsNothing);
      expect(find.byType(AppleSkeletonBox), findsOneWidget);

      // Phase 3: toggle disableAnimations: false again
      toggleSetState(() => disableMotion = false);
      await tester.pump();

      // ShaderMask returns
      expect(find.byType(ShaderMask), findsOneWidget);
    });
  });
}
