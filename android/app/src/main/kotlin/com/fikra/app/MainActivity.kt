package com.fikra.app

import android.content.BroadcastReceiver
import android.content.ClipData
import java.io.File
import androidx.core.content.FileProvider
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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "fikrah/share")
            .setMethodCallHandler { call, result ->
                if (call.method != "file") {
                    result.notImplemented()
                } else {
                    try {
                        val bytes = call.argument<ByteArray>("bytes") ?: error("bytes")
                        val filename = call.argument<String>("filename") ?: error("filename")
                        val mime = call.argument<String>("mime") ?: error("mime")
                        require(filename.matches(Regex("[A-Za-z0-9_-]+\\.(png|json)")))
                        require(mime == "image/png" || mime == "application/json")
                        val directory = File(cacheDir, "shared_notes").apply { mkdirs() }
                        directory.listFiles()?.filter { System.currentTimeMillis() - it.lastModified() > 86400000L }
                            ?.forEach { it.delete() }
                        val file = File(directory, filename).apply { writeBytes(bytes) }
                        val uri = FileProvider.getUriForFile(this, "$packageName.sharing", file)
                        val intent = Intent(Intent.ACTION_SEND).apply {
                            type = mime
                            putExtra(Intent.EXTRA_STREAM, uri)
                            clipData = ClipData.newRawUri("", uri)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }
                        startActivity(Intent.createChooser(intent, null))
                        result.success(null)
                    } catch (_: Exception) {
                        result.error("share", null, null)
                    }
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
