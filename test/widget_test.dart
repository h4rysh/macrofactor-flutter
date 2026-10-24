import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/main.dart';
import 'package:sique/presentation/providers/app_providers.dart';

void main() {
  testWidgets(
      'App root initializes without errors and routes to Welcome on fresh launch',
      (WidgetTester tester) async {
    final db = AppDatabase.inMemory();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const SiqueApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Fresh install routes to WelcomeScreen
    expect(find.text('SIQUE'), findsOneWidget);
    expect(find.text('Configure My Strategy'), findsOneWidget);

    db.close();
  });

  testWidgets('App root loads Dashboard directly when onboarding is completed',
      (WidgetTester tester) async {
    final db = AppDatabase.inMemory();
    db.setSetting('onboarding_completed', 'true');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const SiqueApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);

    db.close();
  });
}
