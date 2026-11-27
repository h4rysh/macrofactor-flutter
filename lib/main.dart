import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sique/data/local/app_database.dart';
import 'package:sique/presentation/providers/app_providers.dart';
import 'package:sique/presentation/screens/onboarding/onboarding_coordinator.dart';
import 'package:sique/presentation/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android 15 & modern mobile edge-to-edge system UI configuration
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
    ),
  );

  AppDatabase? db;
  Object? startupError;

  // Startup try/catch guard for AppDatabase.open() (ISS-8-01)
  try {
    db = await AppDatabase.open();
  } catch (e, st) {
    startupError = e;
    developer.log(
      'AppDatabase.open failed during application startup; attempting recovery',
      name: 'Startup',
      error: e,
      stackTrace: st,
    );
    try {
      db = AppDatabase.inMemory();
    } catch (inMemErr, inMemSt) {
      developer.log(
        'In-memory fallback database failed to initialize',
        name: 'Startup',
        error: inMemErr,
        stackTrace: inMemSt,
      );
      db = null;
    }
  }

  // Safe error UI fallback when database fails fatally
  if (db == null) {
    runApp(DatabaseErrorFallbackApp(
      error: startupError,
      onRetry: () => main(),
    ));
    return;
  }

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: SiqueApp(
        isVolatileStorage: db.isInMemory,
      ),
    ),
  );
}

/// Safe error UI fallback screen for fatal database opening failures (ISS-8-01).
class DatabaseErrorFallbackApp extends StatefulWidget {
  const DatabaseErrorFallbackApp({
    super.key,
    this.error,
    this.onRetry,
  });

  final Object? error;
  final VoidCallback? onRetry;

  @override
  State<DatabaseErrorFallbackApp> createState() =>
      _DatabaseErrorFallbackAppState();
}

class _DatabaseErrorFallbackAppState extends State<DatabaseErrorFallbackApp> {
  bool _isRetrying = false;

  void _handleRetry() {
    if (_isRetrying || widget.onRetry == null) return;
    setState(() => _isRetrying = true);
    widget.onRetry!();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      restorationScopeId: 'sique_error_root',
      title: 'Sique',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 64,
                    color: AppTheme.calories,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Storage Initialization Error',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Sique could not open local device storage safely. Your existing data is protected.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Text(
                        widget.error.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  if (widget.onRetry != null)
                    ElevatedButton.icon(
                      onPressed: _isRetrying ? null : _handleRetry,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label:
                          Text(_isRetrying ? 'Retrying...' : 'Retry Startup'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.calories,
                        foregroundColor: AppTheme.background,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sique Root Application.
class SiqueApp extends StatefulWidget {
  const SiqueApp({
    super.key,
    this.isVolatileStorage = false,
  });

  final bool isVolatileStorage;

  @override
  State<SiqueApp> createState() => _SiqueAppState();
}

class _SiqueAppState extends State<SiqueApp> {
  bool _bannerDismissed = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      restorationScopeId: 'sique_app_root', // ISS-8-02
      title: 'Sique',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'IN'),
        Locale('en', 'US'),
        Locale('en', 'GB'),
      ],
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final content = MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(
              minScaleFactor: 1.0,
              maxScaleFactor: 2.0,
            ),
          ),
          child: child!,
        );
        if (!widget.isVolatileStorage || _bannerDismissed) {
          return content;
        }
        return Column(
          children: [
            Material(
              color: AppTheme.warning,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 16, color: AppTheme.background),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Temporary storage active: logs will not persist after closing Sique.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.background,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Dismiss storage warning',
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 36, minHeight: 36),
                        icon: const Icon(Icons.close_rounded,
                            size: 16, color: AppTheme.background),
                        onPressed: () =>
                            setState(() => _bannerDismissed = true),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(child: content),
          ],
        );
      },
      home: const OnboardingCoordinator(),
    );
  }
}
