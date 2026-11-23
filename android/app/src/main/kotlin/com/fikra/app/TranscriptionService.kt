package com.fikra.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log

/**
 * Keeps the app process alive while saved recordings are transcribed, so
 * Android does not freeze or kill it after the user leaves the app. The work
 * itself runs in the app's Dart isolate; this service only holds a
 * foreground notification. Dart starts it when the first job starts and stops
 * it when the queue is empty (see transcription_service.dart).
 */
class TranscriptionService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val channelName = intent?.getStringExtra(EXTRA_CHANNEL) ?: "Transcription"
        val title = intent?.getStringExtra(EXTRA_TITLE) ?: ""
        val text = intent?.getStringExtra(EXTRA_TEXT) ?: ""
        try {
            val notification = notification(this, channelName, title, text)
            when {
                // Android 15 added a type for transcoding and similar local media work.
                Build.VERSION.SDK_INT >= 35 ->
                    startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROCESSING)
                // Android 10–14: the closest declared type; Android 14 requires one.
                Build.VERSION.SDK_INT >= 29 ->
                    startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
                else -> startForeground(NOTIFICATION_ID, notification)
            }
            running = true
            Log.i(TAG, "FIKRA_TRANSCRIPTION_SERVICE started")
        } catch (error: Exception) {
            // For example ForegroundServiceStartNotAllowedException. The queue
            // keeps working while the app is open.
            Log.w(TAG, "FIKRA_TRANSCRIPTION_SERVICE could not start", error)
            stopSelf()
        }
        // If Android kills the process, the queue resumes at the next launch.
        return START_NOT_STICKY
    }

    /** Android 15+: mediaProcessing has a daily time limit; stop before it becomes an error. */
    override fun onTimeout(startId: Int, fgsType: Int) {
        Log.w(TAG, "FIKRA_TRANSCRIPTION_SERVICE time limit reached")
        stopSelf()
    }

    override fun onDestroy() {
        running = false
        Log.i(TAG, "FIKRA_TRANSCRIPTION_SERVICE stopped")
        super.onDestroy()
    }

    companion object {
        private const val TAG = "FikraTranscription"
        private const val CHANNEL_ID = "transcription"
        private const val NOTIFICATION_ID = 4107
        private const val EXTRA_CHANNEL = "channel"
        private const val EXTRA_TITLE = "title"
        private const val EXTRA_TEXT = "text"

        @Volatile
        private var running = false

        /** Starts the service, or updates its notification. False if Android refused. */
        fun start(context: Context, channel: String, title: String, text: String): Boolean {
            if (running) {
                // Already in the foreground: only the count changed. Posting
                // directly avoids a second start, which Android may refuse
                // once the app is in the background.
                context.getSystemService(NotificationManager::class.java)
                    .notify(NOTIFICATION_ID, notification(context, channel, title, text))
                return true
            }
            val intent = Intent(context, TranscriptionService::class.java)
                .putExtra(EXTRA_CHANNEL, channel)
                .putExtra(EXTRA_TITLE, title)
                .putExtra(EXTRA_TEXT, text)
            return try {
                if (Build.VERSION.SDK_INT >= 26) context.startForegroundService(intent) else context.startService(intent)
                true
            } catch (error: Exception) {
                // Android 12+ refuses to start one while the app is in the background.
                Log.w(TAG, "FIKRA_TRANSCRIPTION_SERVICE not allowed to start", error)
                false
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, TranscriptionService::class.java))
        }

        /** Low importance, no sound or badge; a tap opens the app where it was. */
        private fun notification(context: Context, channelName: String, title: String, text: String): Notification {
            val open = PendingIntent.getActivity(
                context,
                0,
                Intent(context, MainActivity::class.java)
                    .setAction(Intent.ACTION_MAIN)
                    .addCategory(Intent.CATEGORY_LAUNCHER)
                    .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            val builder = if (Build.VERSION.SDK_INT >= 26) {
                context.getSystemService(NotificationManager::class.java).createNotificationChannel(
                    NotificationChannel(CHANNEL_ID, channelName, NotificationManager.IMPORTANCE_LOW).apply {
                        setShowBadge(false)
                    },
                )
                Notification.Builder(context, CHANNEL_ID)
            } else {
                @Suppress("DEPRECATION")
                Notification.Builder(context).setPriority(Notification.PRIORITY_LOW)
            }
            builder
                .setSmallIcon(R.drawable.ic_stat_transcription)
                .setContentTitle(title)
                .setContentText(text)
                .setContentIntent(open)
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setShowWhen(false)
                .setCategory(Notification.CATEGORY_PROGRESS)
            if (Build.VERSION.SDK_INT >= 31) {
                builder.setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE)
            }
            return builder.build()
        }
    }
}
