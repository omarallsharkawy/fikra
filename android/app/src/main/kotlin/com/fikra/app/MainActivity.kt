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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "fikra/transcription_service")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> result.success(
                        TranscriptionService.start(
                            this,
                            call.argument<String>("channel") ?: "",
                            call.argument<String>("title") ?: "",
                            call.argument<String>("text") ?: "",
                        ),
                    )
                    "stop" -> {
                        TranscriptionService.stop(this)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        // The Dart work ends with this activity's engine; never leave the
        // notification behind it.
        if (isFinishing) TranscriptionService.stop(this)
        super.onDestroy()
    }
}
