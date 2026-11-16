# Android activity

MainActivity retains FlutterActivity plugin registration. The experimental voice-to-text feature adds one read-only MethodChannel: `fikra/voice_text_storage`, method `availableBytes`. It returns StatFs(applicationInfo.dataDir).availableBytes as a long so Dart can check the private-storage filesystem before downloading a model. Exceptions return a storage error; unknown calls are not implemented. No permissions, recording settings, database, model engine or build configuration change.

## Transcription service

`TranscriptionService` keeps the process alive while saved recordings are transcribed after the user leaves the app. It only holds a foreground notification; inference stays in the Dart isolate. MainActivity's MethodChannel `fikra/transcription_service` has `start` (args `channel`, `title`, `text`, all localized by Dart; returns false when Android refuses, such as `ForegroundServiceStartNotAllowedException` from the background) and `stop`. When the service already runs, `start` only re-posts the notification with the new count. Type: `mediaProcessing` on Android 15+ (6 hours per 24 hours; `onTimeout` stops the service), `dataSync` on Android 10–14, untyped below. The manifest declares FOREGROUND_SERVICE, FOREGROUND_SERVICE_MEDIA_PROCESSING, FOREGROUND_SERVICE_DATA_SYNC and POST_NOTIFICATIONS. Notification: own low-importance channel (`transcription`), no badge, ongoing, small icon `res/drawable/ic_stat_transcription.xml`, tap opens MainActivity. `START_NOT_STICKY`, `stopWithTask`, and MainActivity stops it when finishing: the Dart work ends with the activity's engine, so swiping the app from recents interrupts the job (resumed at next launch, counted by the crash-loop guard). Without notification permission the service still runs; Android hides its notification.

Verify with the Android build and a phone download attempt, including insufficient storage. Widget tests fake the feature's backend; Android StatFs needs device verification.

Phase 3 adds INTERNET to the main manifest (previously debug/profile only), with the scope comment: model downloads and services the user adds. No activity/service/notification logic or service types change. Remote jobs use the existing keep-alive. HTTP uses Dart-owned sockets with explicit HTTPS/private-address validation; no app-wide native cleartext override is added.

## Glass power cap

MainActivity adds fikra/glass_power: isPowerSaveMode reads
PowerManager.isPowerSaveMode. A receiver for ACTION_POWER_SAVE_MODE_CHANGED
invokes powerSaveModeChanged(bool) on the same channel. API 33+ uses
RECEIVER_NOT_EXPORTED. onDestroy unregisters the receiver and clears the channel
handler. No permission, service, DB, package or build configuration change.
Dart GlassPowerSource is injectable; unit/widget tests use a fake stream.
Native broadcast delivery/recreation requires a phone check.
