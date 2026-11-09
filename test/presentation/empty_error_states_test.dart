import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/presentation/widgets/sique_empty_state.dart';
import 'package:sique/presentation/widgets/sique_error_state.dart';

void main() {
  group('SiqueEmptyState', () {
    testWidgets(
        'renders standard empty state with icon, title, message and action',
        (tester) async {
      var actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SiqueEmptyState(
              icon: Icons.search_off_rounded,
              title: 'No results found',
              message:
                  'Try checking your spelling or searching for another term.',
              actionLabel: 'Clear Filter',
              onAction: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
      expect(find.text('No results found'), findsOneWidget);
      expect(
        find.text('Try checking your spelling or searching for another term.'),
        findsOneWidget,
      );
      expect(find.text('Clear Filter'), findsOneWidget);

      await tester.tap(find.text('Clear Filter'));
      await tester.pump();
      expect(actionTriggered, isTrue);
    });

    testWidgets('renders compact empty state without action button',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SiqueEmptyState(
              icon: Icons.history_rounded,
              title: 'No check-ins yet',
              message: 'Check back after your first check-in.',
              isCompact: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.history_rounded), findsOneWidget);
      expect(find.text('No check-ins yet'), findsOneWidget);
      expect(
          find.text('Check back after your first check-in.'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
    });
  });

  group('SiqueErrorState', () {
    testWidgets('renders full-page error state with retry button',
        (tester) async {
      var retryTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SiqueErrorState(
              title: 'Unable to Load',
              message: 'Network connection failed.',
              retryLabel: 'Retry Request',
              onRetry: () => retryTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('Unable to Load'), findsOneWidget);
      expect(find.text('Network connection failed.'), findsOneWidget);
      expect(find.text('Retry Request'), findsOneWidget);

      await tester.tap(find.text('Retry Request'));
      await tester.pump();
      expect(retryTriggered, isTrue);
    });

    testWidgets('renders inline banner error state with refresh icon',
        (tester) async {
      var retryTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SiqueErrorState(
              title: 'Sync failed',
              message: 'Could not sync weights with cloud.',
              isInline: true,
              onRetry: () => retryTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('Sync failed'), findsOneWidget);
      expect(find.text('Could not sync weights with cloud.'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pump();
      expect(retryTriggered, isTrue);
    });
  });
}
