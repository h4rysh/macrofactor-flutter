import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/presentation/theme/tokens/app_haptics.dart';
import 'package:sique/presentation/widgets/sique_bouncy.dart';
import 'package:sique/presentation/widgets/sique_controls.dart';
import 'package:sique/presentation/widgets/sique_entrance.dart';
import 'package:sique/presentation/widgets/sique_frosted_chrome.dart';
import 'package:sique/presentation/widgets/sique_page_route.dart';
import 'package:sique/presentation/widgets/sique_shimmer.dart';
import 'package:sique/presentation/widgets/sique_tonal_card.dart';

void main() {
  group('Wave B1: Sique Design System Primitives Suite', () {
    test(
        'AppHaptics executes all feedback methods defensively without throwing',
        () async {
      await AppHaptics.selectionClick();
      await AppHaptics.lightImpact();
      await AppHaptics.mediumImpact();
      await AppHaptics.heavyImpact();
      await AppHaptics.successFeedback();
      await AppHaptics.warningFeedback();
    });

    testWidgets('SiqueBouncy responds to tap events and executes callback',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SiqueBouncy(
              onTap: () => tapped = true,
              child: const Text('Bouncy Child'),
            ),
          ),
        ),
      );

      expect(find.text('Bouncy Child'), findsOneWidget);
      await tester.tap(find.text('Bouncy Child'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('SiqueTonalCard renders background, border, and handles tap',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SiqueTonalCard(
              onTap: () => tapped = true,
              child: const Text('Tonal Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Tonal Card Content'), findsOneWidget);
      await tester.tap(find.text('Tonal Card Content'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets(
        'SiqueFrostedChrome renders pinned backdrop filter with safe area',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SiqueFrostedChrome(
                    child: Text('Frosted Chrome Content'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Frosted Chrome Content'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('SiqueEntrance animates child and renders stably',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SiqueEntrance(
              child: Text('Entrance Item'),
            ),
          ),
        ),
      );

      expect(find.text('Entrance Item'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Entrance Item'), findsOneWidget);
    });

    testWidgets('SiqueShimmer renders bone skeleton without throwing',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SiqueShimmer(width: 120, height: 24),
          ),
        ),
      );

      expect(find.byType(SiqueShimmer), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('SiqueButton renders all variants and handles taps',
        (tester) async {
      var primaryTapped = false;
      var secondaryTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SiqueButton(
                  label: 'Primary Action',
                  onPressed: () => primaryTapped = true,
                ),
                SiqueButton(
                  label: 'Secondary Action',
                  variant: SiqueButtonVariant.secondary,
                  onPressed: () => secondaryTapped = true,
                ),
                const SiqueButton(
                  label: 'Loading Action',
                  isLoading: true,
                  onPressed: null,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Primary Action'), findsOneWidget);
      expect(find.text('Secondary Action'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.text('Primary Action'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(primaryTapped, isTrue);

      await tester.tap(find.text('Secondary Action'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(secondaryTapped, isTrue);
    });

    testWidgets('SiqueSegmentedControl switches segment and triggers callback',
        (tester) async {
      var selected = 'kg';
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            home: Scaffold(
              body: SiqueSegmentedControl<String>(
                segments: const {'kg': 'kg · cm', 'lbs': 'lbs · ft'},
                selected: selected,
                onChanged: (val) => setState(() => selected = val),
              ),
            ),
          ),
        ),
      );

      expect(find.text('kg · cm'), findsOneWidget);
      expect(find.text('lbs · ft'), findsOneWidget);

      await tester.tap(find.text('lbs · ft'));
      await tester.pumpAndSettle();
      expect(selected, equals('lbs'));
    });

    testWidgets('SiqueStepper increments and decrements with tactile feedback',
        (tester) async {
      var count = 75.0;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            home: Scaffold(
              body: SiqueStepper(
                valueText: count.toStringAsFixed(1),
                unitLabel: 'kg',
                onIncrement: () => setState(() => count += 0.5),
                onDecrement: () => setState(() => count -= 0.5),
              ),
            ),
          ),
        ),
      );

      expect(find.text('75.0'), findsOneWidget);
      expect(find.text('kg'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(count, equals(75.5));

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();
      expect(count, equals(75.0));
    });

    testWidgets('SiquePageRoute transitions smoothly between routes',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    SiquePageRoute(
                      builder: (_) =>
                          const Scaffold(body: Text('Destination Screen')),
                    ),
                  );
                },
                child: const Text('Go'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text('Destination Screen'), findsOneWidget);
    });
  });
}
