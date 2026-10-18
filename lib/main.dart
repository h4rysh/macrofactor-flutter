import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macro_factor_app/data/local/app_database.dart';
import 'package:macro_factor_app/presentation/providers/app_providers.dart';
import 'package:macro_factor_app/presentation/screens/onboarding/onboarding_coordinator.dart';
import 'package:macro_factor_app/presentation/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await AppDatabase.open();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: const MacroFactorApp(),
    ),
  );
}

/// MacroFactor Root Application.
class MacroFactorApp extends StatelessWidget {
  const MacroFactorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MacroFactor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const OnboardingCoordinator(),
    );
  }
}
