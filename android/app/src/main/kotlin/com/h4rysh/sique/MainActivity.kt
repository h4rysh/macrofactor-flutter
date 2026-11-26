package com.h4rysh.sique

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.h4rysh.sique/home_widget"
        ).setMethodCallHandler { call, result ->
            if (call.method == "updateMacros") {
                val args = call.arguments as? Map<*, *>
                if (args == null) {
                    result.error("INVALID_ARGUMENTS", "Expected map arguments", null)
                    return@setMethodCallHandler
                }
                fun parseBoundedInt(key: String): Int? {
                    val v = args[key] as? Number ?: return null
                    val d = v.toDouble()
                    if (!d.isFinite()) return null
                    return d.toInt().coerceIn(-50000, 50000)
                }
                val kcal = parseBoundedInt("caloriesRemaining")
                val p = parseBoundedInt("proteinRemaining")
                val c = parseBoundedInt("carbsRemaining")
                val f = parseBoundedInt("fatRemaining")
                if (kcal == null || p == null || c == null || f == null) {
                    result.error("INVALID_ARGUMENTS", "Missing or non-finite macro values", null)
                    return@setMethodCallHandler
                }
                SiqueMacroWidgetProvider.saveAndRefresh(this, kcal, p, c, f)
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }
}
