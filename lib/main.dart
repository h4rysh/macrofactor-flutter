import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/screens/onboarding/onboarding_coordinator.dart';
import 'package:sique/presentation/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await AppDatabase.open();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: const SiqueApp(),
    ),
  );
}

/// Sique Root Application.
class SiqueApp extends StatelessWidget {
  const SiqueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sique',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const OnboardingCoordinator(),
    );
  }
}
