import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Pushes remaining daily calories & macros to the native Android Home Widget.
class HomeWidgetSyncService {
  const HomeWidgetSyncService._();

  static const MethodChannel _channel =
      MethodChannel('com.h4rysh.sique/home_widget');

  static Future<void> updateRemainingMacros({
    required double caloriesRemaining,
    required double proteinRemaining,
    required double carbsRemaining,
    required double fatRemaining,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      int safeRound(double v) =>
          v.isFinite ? v.round().clamp(-50000, 50000) : 0;
      await _channel.invokeMethod<bool>('updateMacros', {
        'caloriesRemaining': safeRound(caloriesRemaining),
        'proteinRemaining': safeRound(proteinRemaining),
        'carbsRemaining': safeRound(carbsRemaining),
        'fatRemaining': safeRound(fatRemaining),
      });
    } on MissingPluginException {
      // Safe no-op in headless/test environments
    } on PlatformException {
      // Safe no-op if widget not pinned
    }
  }
}
