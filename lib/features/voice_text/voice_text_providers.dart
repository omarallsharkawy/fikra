import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/settings_repository.dart';
import 'native_voice_text_backend.dart';
import 'voice_text_backend.dart';
import 'voice_text_controller.dart';

final voiceTextBackendProvider = Provider.autoDispose<VoiceTextBackend>((ref) => NativeVoiceTextBackend());
final voiceTextSettingsProvider = Provider<VoiceTextSettings>((ref) => ref.watch(settingsRepoProvider));
final voiceTextControllerProvider = Provider.autoDispose<VoiceTextController>((ref) {
  final activity = ref.read(recordingActiveProvider.notifier);
  final owner = Object();
  final controller = VoiceTextController(
    ref.watch(voiceTextBackendProvider),
    settings: ref.watch(voiceTextSettingsProvider),
    claimMicrophone: () => activity.claim(owner),
    releaseMicrophone: () => activity.release(owner),
  );
  ref.onDispose(controller.dispose);
  unawaited(controller.initialize());
  return controller;
});
