import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/processing/transcription_keep_alive.dart';
import '../../l10n/localizations.dart';

/// The Android foreground service (TranscriptionService.kt) behind a
/// MethodChannel. Notification text comes from the app's current language.
class AndroidTranscriptionKeepAlive implements TranscriptionKeepAlive {
  AndroidTranscriptionKeepAlive(this.l10n);
  final AppLocalizations Function() l10n;
  static const _channel = MethodChannel('fikra/transcription_service');

  @override
  Future<void> start(int remaining) async {
    final l = l10n();
    // false: Android refused to start it (the app was already in the
    // background). Work continues while the app is open.
    final started = await _channel.invokeMethod<bool>('start', {
      'channel': l.trNotificationChannel,
      'title': l.trWorking,
      'text': l.trNotificationLeft(remaining),
    });
    if (started == false) developer.log('Foreground service not allowed now', name: 'FIKRA_TRANSCRIPTION');
  }

  @override
  Future<void> stop() => _channel.invokeMethod<void>('stop');
}

/// Android 13+ asks before an app may post notifications.
abstract interface class TranscriptionNotificationPermission {
  /// True when the system can still be asked (not granted, not refused for good).
  Future<bool> canAsk();
  Future<void> request();
}

class PluginNotificationPermission implements TranscriptionNotificationPermission {
  const PluginNotificationPermission();
  @override
  Future<bool> canAsk() async => (await Permission.notification.status).isDenied;
  @override
  Future<void> request() => Permission.notification.request();
}
