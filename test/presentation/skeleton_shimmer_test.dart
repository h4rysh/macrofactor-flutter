import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/presentation/widgets/apple_skeleton.dart';

void main() {
  group('AppleSkeletonShimmer & Screen Skeletons Tests', () {
    testWidgets(
        'DashboardSkeleton layout dimensions match real dashboard modules',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DashboardSkeleton(),
          ),
        ),
      );

      // Verify AppleSkeletonShimmer is present
      expect(find.byType(AppleSkeletonShimmer), findsOneWidget);

      // Verify 184x184 circular macro ring placeholder
      final circleFinder = find.byWidgetPredicate((widget) {
        if (widget is AppleSkeletonBox) {
          return widget.width == 184 &&
              widget.height == 184 &&
              widget.shape == BoxShape.circle;
        }
        return false;
      });
      expect(circleFinder, findsOneWidget);

      // Verify card container with border radius 22.0
      final cardContainerFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final decoration = widget.decoration as BoxDecoration;
          return decoration.borderRadius == BorderRadius.circular(22.0);
        }
        return false;
      });
      expect(cardContainerFinder, findsOneWidget);

      // Verify 3 quick action pills (height: 48, borderRadius: 14)
      final actionPillsFinder = find.byWidgetPredicate((widget) {
        if (widget is AppleSkeletonBox) {
          return widget.height == 48 && widget.borderRadius == 14;
        }
        return false;
      });
      expect(actionPillsFinder, findsNWidgets(3));

      // Verify metric card placeholders (Expenditure & Weight Trend)
      final metricCardsFinder = find.byWidgetPredicate((widget) {
        if (widget is AppleSkeletonBox) {
          return widget.height == 140 && widget.borderRadius == 18;
        }
        return false;
      });
      expect(metricCardsFinder, findsNWidgets(2));
    });

    testWidgets(
        'FoodLogSkeleton layout matches DateCarouselRibbon and timeline slots',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FoodLogSkeleton(),
          ),
        ),
      );

      // Verify AppleSkeletonShimmer is present
      expect(find.byType(AppleSkeletonShimmer), findsOneWidget);

      // Verify date carousel pills placeholder (7 days, width 44, height 58, radius 16)
      final datePillFinder = find.byWidgetPredicate((widget) {
        if (widget is AppleSkeletonBox) {
          return widget.width == 44 &&
              widget.height == 58 &&
              widget.borderRadius == 16;
        }
        return false;
      });
      expect(datePillFinder, findsNWidgets(7));

      // Verify nutrition summary banner placeholder (height 52, borderRadius 14)
      final summaryBannerFinder = find.byWidgetPredicate((widget) {
        if (widget is AppleSkeletonBox) {
          return widget.height == 52 && widget.borderRadius == 14;
        }
        return false;
      });
      expect(summaryBannerFinder, findsOneWidget);

      // Verify timeline slot card placeholders (4 slots with borderRadius 16 and inner height 48)
      final timelineSlotsFinder = find.byWidgetPredicate((widget) {
        if (widget is AppleSkeletonBox) {
          return widget.height == 48 && widget.borderRadius == 10;
        }
        return false;
      });
      expect(timelineSlotsFinder, findsNWidgets(4));
    });

    testWidgets(
        'AppleSkeletonShimmer renders ShaderMask when animations enabled',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppleSkeletonShimmer(
              child: AppleSkeletonBox(width: 100, height: 20),
            ),
          ),
        ),
      );

      expect(find.byType(ShaderMask), findsOneWidget);
    });

    testWidgets(
        'AppleSkeletonShimmer freezes without ShaderMask when disableAnimations is true',
        (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: AppleSkeletonShimmer(
                child: AppleSkeletonBox(width: 100, height: 20),
              ),
            ),
          ),
        ),
      );

      // When animations disabled, build returns child directly (no ShaderMask)
      expect(find.byType(ShaderMask), findsNothing);
      expect(find.byType(AppleSkeletonBox), findsOneWidget);
    });
  });
}
