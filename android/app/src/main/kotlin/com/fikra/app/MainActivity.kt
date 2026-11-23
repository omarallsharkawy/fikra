package com.fikra.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.PowerManager
import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var glassPowerChannel: MethodChannel? = null
    private val powerReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            glassPowerChannel?.invokeMethod("powerSaveModeChanged", powerSaveMode())
        }
    }

    private fun powerSaveMode(): Boolean =
        (getSystemService(Context.POWER_SERVICE) as PowerManager).isPowerSaveMode

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        glassPowerChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "fikra/glass_power").also { channel ->
            channel.setMethodCallHandler { call, result ->
                if (call.method == "isPowerSaveMode") result.success(powerSaveMode())
                else result.notImplemented()
            }
        }
        val powerFilter = IntentFilter(PowerManager.ACTION_POWER_SAVE_MODE_CHANGED)
        if (android.os.Build.VERSION.SDK_INT >= 33) {
            registerReceiver(powerReceiver, powerFilter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(powerReceiver, powerFilter)
        }

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
        if (glassPowerChannel != null) {
            unregisterReceiver(powerReceiver)
            glassPowerChannel?.setMethodCallHandler(null)
            glassPowerChannel = null
        }
        super.onDestroy()
    }
}
