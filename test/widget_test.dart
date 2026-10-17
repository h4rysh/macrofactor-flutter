import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macro_factor_app/data/local/app_database.dart';
import 'package:macro_factor_app/main.dart';
import 'package:macro_factor_app/presentation/providers/app_providers.dart';

void main() {
  testWidgets('App root initializes without errors',
      (WidgetTester tester) async {
    final db = AppDatabase.inMemory();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const MacroFactorApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('MacroFactor'), findsOneWidget);

    db.close();
  });
}
