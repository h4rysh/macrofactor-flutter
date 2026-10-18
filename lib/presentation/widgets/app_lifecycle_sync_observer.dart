import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macro_factor_app/presentation/providers/auth_providers.dart';
import 'package:macro_factor_app/presentation/providers/health_sync_providers.dart';

/// Configurable app lifecycle observer that triggers quiet background
/// synchronization with Google Health Connect upon app launch and app resume.
///
/// Features:
/// - Fires on initial frame render (`addPostFrameCallback`) and `AppLifecycleState.resumed`.
/// - Guards against unauthenticated or disabled states (`user.healthConnectEnabled`).
/// - Guards against concurrent sync execution (`state.isSyncing`).
/// - Enforces a throttle duration (default: 5 minutes) to avoid spamming Health Connect.
/// - Catches transient platform errors quietly without interrupting the UI.
class AppLifecycleSyncObserver extends ConsumerStatefulWidget {
  const AppLifecycleSyncObserver({
    super.key,
    required this.child,
    this.throttleDuration = const Duration(minutes: 5),
    this.clock,
    this.onSyncTriggered,
  });

  /// The child widget tree (e.g. [ScaffoldWithNavBar] or root navigation).
  final Widget child;

  /// Minimum interval required between automated background sync executions.
  final Duration throttleDuration;

  /// Optional clock provider for deterministic time manipulation in tests.
  final DateTime Function()? clock;

  /// Optional callback invoked when auto-sync is dispatched (for tests & telemetry).
  final void Function(String reason)? onSyncTriggered;

  @override
  ConsumerState<AppLifecycleSyncObserver> createState() =>
      _AppLifecycleSyncObserverState();
}

class _AppLifecycleSyncObserverState
    extends ConsumerState<AppLifecycleSyncObserver>
    with WidgetsBindingObserver {
  DateTime? _lastAttemptTime;

  DateTime get _currentTime =>
      widget.clock != null ? widget.clock!() : DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initial launch auto-sync: triggered immediately after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(triggerSync(reason: 'launch'));
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(triggerSync(reason: 'resume'));
    }
  }

  /// Evaluates preconditions and dispatches quiet background synchronization.
  Future<bool> triggerSync({required String reason}) async {
    // 1. Guard: check if another synchronization is already in progress
    final syncState = ref.read(healthConnectSyncProvider);
    if (syncState.isSyncing) {
      return false;
    }

    // 2. Guard: verify user has explicitly enabled Health Connect synchronization
    final user = ref.read(currentUserProvider);
    if (!user.healthConnectEnabled) {
      return false;
    }

    // 3. Guard: throttle check against recent attempt and persistent lastSyncedAt
    final now = _currentTime;
    if (_lastAttemptTime != null &&
        now.difference(_lastAttemptTime!) < widget.throttleDuration) {
      return false;
    }

    if (syncState.lastSyncedAt != null &&
        now.isAfter(syncState.lastSyncedAt!) &&
        now.difference(syncState.lastSyncedAt!) < widget.throttleDuration) {
      return false;
    }

    // Record attempt timestamp to throttle immediate subsequent transitions
    _lastAttemptTime = now;
    widget.onSyncTriggered?.call(reason);

    // 4. Quiet background execution
    try {
      final success =
          await ref.read(healthConnectSyncProvider.notifier).syncNow();
      return success;
    } catch (e) {
      debugPrint('Quiet background auto-sync failed ($reason): $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
