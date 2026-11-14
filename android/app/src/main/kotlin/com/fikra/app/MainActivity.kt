package com.fikra.app

import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "fikra/voice_text_storage")
            .setMethodCallHandler { call, result ->
                if (call.method != "availableBytes") {
                    result.notImplemented()
                } else {
                    try {
                        result.success(StatFs(applicationInfo.dataDir).availableBytes)
                    } catch (error: Exception) {
                        result.error("storage", "Cannot read available storage", null)
                    }
                }
            }
    }
}
