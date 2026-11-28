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
    private var voiceStorageChannel: MethodChannel? = null
    private var transcriptionChannel: MethodChannel? = null
    private var powerReceiverRegistered = false

    private val powerReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            glassPowerChannel?.invokeMethod("powerSaveModeChanged", powerSaveMode())
        }
    }

    private fun powerSaveMode(): Boolean =
        (getSystemService(Context.POWER_SERVICE) as? PowerManager)?.isPowerSaveMode ?: false

    private fun unregisterPowerReceiverSafely() {
        if (!powerReceiverRegistered) return
        powerReceiverRegistered = false
        try {
            unregisterReceiver(powerReceiver)
        } catch (_: IllegalArgumentException) {
            // Receiver was already unregistered by the system.
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        glassPowerChannel = MethodChannel(messenger, "fikra/glass_power").also { channel ->
            channel.setMethodCallHandler { call, result ->
                if (call.method == "isPowerSaveMode") result.success(powerSaveMode())
                else result.notImplemented()
            }
        }
        if (!powerReceiverRegistered) {
            val powerFilter = IntentFilter(PowerManager.ACTION_POWER_SAVE_MODE_CHANGED)
            if (android.os.Build.VERSION.SDK_INT >= 33) {
                registerReceiver(powerReceiver, powerFilter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                registerReceiver(powerReceiver, powerFilter)
            }
            powerReceiverRegistered = true
        }

        voiceStorageChannel = MethodChannel(messenger, "fikra/voice_text_storage").also { channel ->
            channel.setMethodCallHandler { call, result ->
                if (call.method != "availableBytes") {
                    result.notImplemented()
                } else {
                    try {
                        result.success(StatFs(applicationInfo.dataDir).availableBytes)
                    } catch (_: Exception) {
                        result.error("storage", "Cannot read available storage", null)
                    }
                }
            }
        }

        transcriptionChannel = MethodChannel(messenger, "fikra/transcription_service").also { channel ->
            channel.setMethodCallHandler { call, result ->
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
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        unregisterPowerReceiverSafely()
        glassPowerChannel?.setMethodCallHandler(null)
        glassPowerChannel = null
        voiceStorageChannel?.setMethodCallHandler(null)
        voiceStorageChannel = null
        transcriptionChannel?.setMethodCallHandler(null)
        transcriptionChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onDestroy() {
        // The Dart work ends with this activity's engine; never leave the
        // notification behind it.
        if (isFinishing) TranscriptionService.stop(this)
        unregisterPowerReceiverSafely()
        glassPowerChannel?.setMethodCallHandler(null)
        glassPowerChannel = null
        voiceStorageChannel?.setMethodCallHandler(null)
        voiceStorageChannel = null
        transcriptionChannel?.setMethodCallHandler(null)
        transcriptionChannel = null
        super.onDestroy()
    }
}
