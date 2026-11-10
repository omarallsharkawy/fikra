part of 'attachment_editor.dart';

/// Voice transitions claim both local state and the shared microphone lease
/// synchronously, before permission, playback teardown or recorder I/O.
extension AttachmentVoice<T extends ConsumerStatefulWidget> on AttachmentEditing<T> {
  Future<void> startRecording() async {
    if (!mounted || rec != RecordingState.idle || saving || picking) return;
    final activity = ref.read(recordingActiveProvider.notifier);
    if (!activity.claim(this)) return;
    recordingActivity = activity;
    updateDraft(() => rec = RecordingState.starting);
    FocusScope.of(context).unfocus();
    var keepLease = false;
    try {
      final status = await ref.read(microphonePermissionProvider)();
      if (!mounted) return;
      if (!status.isGranted) {
        updateDraft(() {
          rec = RecordingState.idle;
          mic = status.isPermanentlyDenied ? MicPermission.blocked : MicPermission.denied;
        });
        return;
      }
      final path = await ref.read(attachmentStoreProvider).newRecordingPath();
      if (!mounted) return;
      activeRecordingPath = path;
      // A queued/lazily loading player must also finish stopping before the mic starts.
      await voicePlaybackCoordinator.stop();
      if (!mounted) return;
      final activeRecorder = recorder;
      recorderStart = activeRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, numChannels: 1, bitRate: 64000),
        path: path,
      );
      await recorderStart;
      if (!mounted) return; // dispose owns cancellation and the lease now
      levels.clear();
      ampSub = activeRecorder.onAmplitudeChanged(const Duration(milliseconds: 90)).listen((a) {
        updateDraft(() {
          levels.add(levelFromDb(a.current));
          if (levels.length > kWaveformSamples) levels.removeAt(0);
        });
      }, onError: (_) {});
      elapsed = Duration.zero;
      ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        updateDraft(() => elapsed += const Duration(seconds: 1));
        if (elapsed >= AttachmentEditing.maxRecording) stopRecording();
      });
      updateDraft(() {
        mic = MicPermission.unknown;
        rec = RecordingState.recording;
      });
      keepLease = true;
    } catch (_) {
      await teardown();
      try {
        await recorderInstance?.cancel();
      } catch (_) {
        try {
          await recorderInstance?.dispose();
        } catch (_) {}
        recorderInstance = null;
      }
      await AttachmentStore.deleteQuietly([?activeRecordingPath]);
      activeRecordingPath = null;
      updateDraft(() => rec = RecordingState.idle);
      if (mounted) showToast(context, context.l10n.recordStartFailed);
    } finally {
      recorderStart = null;
      if (!keepLease && mounted) releaseRecording();
    }
  }

  Future<void> teardown() async {
    ticker?.cancel();
    ticker = null;
    try {
      await ampSub?.cancel();
    } catch (_) {}
    ampSub = null;
  }

  Future<void> stopRecording() async {
    if (!mounted || rec != RecordingState.recording) return;
    updateDraft(() => rec = RecordingState.stopping);
    try {
      await teardown();
      String? path;
      try {
        path = await recorder.stop();
      } catch (_) {
        try {
          await recorder.cancel();
        } catch (_) {
          try {
            await recorderInstance?.dispose();
          } catch (_) {}
          recorderInstance = null;
        }
      }
      if (path == null) {
        await AttachmentStore.deleteQuietly([?activeRecordingPath]);
        if (mounted) showToast(context, context.l10n.recordInterrupted);
      } else if (!mounted) {
        await AttachmentStore.deleteQuietly([path]);
      } else {
        updateDraft(
          () => draftFiles = [
            ...draftFiles,
            AttachmentDraft(
              kind: AttachmentKind.voice,
              path: path!,
              name: p.basename(path),
              durationMs: elapsed.inMilliseconds,
            ),
          ],
        );
      }
    } finally {
      activeRecordingPath = null;
      updateDraft(() => rec = RecordingState.idle);
      if (mounted) releaseRecording();
    }
  }

  Future<void> cancelRecording() async {
    if (!mounted || rec != RecordingState.recording) return;
    updateDraft(() => rec = RecordingState.stopping);
    try {
      await teardown();
      try {
        await recorder.cancel();
      } catch (_) {
        try {
          await recorderInstance?.dispose();
        } catch (_) {}
        recorderInstance = null;
      }
      await AttachmentStore.deleteQuietly([?activeRecordingPath]);
    } finally {
      activeRecordingPath = null;
      updateDraft(() => rec = RecordingState.idle);
      if (mounted) releaseRecording();
    }
  }
}
