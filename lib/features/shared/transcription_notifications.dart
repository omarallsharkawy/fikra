import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../l10n/localizations.dart';

/// The first time a recording is queued for transcription, explain in one line
/// and ask for notification permission (Android 13+). Never blocks or fails a
/// save: if refused, transcription still runs while the app is open.
Future<void> askTranscriptionNotificationsOnce(BuildContext context, WidgetRef ref) async {
  // The root context outlives a screen that closes after saving (Edit).
  final host = Navigator.of(context, rootNavigator: true).context;
  final settings = ref.read(settingsRepoProvider);
  final permission = ref.read(transcriptionNotificationPermissionProvider);
  try {
    if (await settings.readTranscriptionNotificationsAsked()) return;
    if (!await permission.canAsk()) return;
    await settings.markTranscriptionNotificationsAsked();
    if (host.mounted) showToast(host, host.l10n.trNotificationWhy);
    await permission.request();
  } catch (_) {
    // A missing permission plugin or settings failure only skips the question.
  }
}
