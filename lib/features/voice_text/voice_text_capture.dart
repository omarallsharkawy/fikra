part of 'voice_text_controller.dart';

extension VoiceTextCapture on VoiceTextController {
  Future<void> _captureClock() async {
    elapsed = Duration.zero;
    levels.clear();
    _clock
      ..reset()
      ..start();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      elapsed = _clock.elapsed;
      _notify();
      if (elapsed >= VoiceTextController.maxRecording && capturing) unawaited(stop());
    });
    _amplitude = backend.amplitudeDb.listen(
      (db) {
        levels.add(levelFromDb(db));
        if (levels.length > kWaveformSamples) levels.removeAt(0);
        _notify();
      },
      onError: (Object error) {
        issue = voiceTextIssue(error);
        _notify();
        if (capturing) unawaited(stop());
      },
    );
  }

  Future<void> start({bool live = false}) {
    if (!idle) return Future.value();
    if (live) {
      _liveLease = _claimWhisper();
      if (_liveLease == null) return Future.value();
    }
    if (!claimMicrophone()) {
      _liveLease?.release();
      _liveLease = null;
      issue = VoiceTextIssue.permission;
      _notify();
      return Future.value();
    }
    _ownsMicrophone = true;
    return _perform(VoiceTextPhase.starting, () async {
      try {
        await voicePlaybackCoordinator.stop();
        if (live) {
          _live = await backend.startLive(model, language, threads);
          partial = '';
          _partials = _live!.partials.listen(
            (text) {
              partial = text;
              _notify();
            },
            onError: (Object error) {
              issue = voiceTextIssue(error);
              _notify();
              if (capturing) unawaited(stop());
            },
          );
        } else {
          await backend.startRecording(aac);
        }
        await _captureClock();
        phase = live ? VoiceTextPhase.live : VoiceTextPhase.recording;
      } catch (_) {
        try {
          await backend.cancelRecording();
        } finally {
          _release();
        }
        rethrow;
      }
    });
  }

  Future<void> _stopClock() async {
    _clock.stop();
    _ticker?.cancel();
    _ticker = null;
    await _amplitude?.cancel();
    _amplitude = null;
  }

  Future<void> stop({bool discard = false}) {
    if (!capturing) return Future.value();
    final live = phase == VoiceTextPhase.live;
    final previousIssue = issue;
    return _perform(VoiceTextPhase.stopping, () async {
      try {
        await _stopClock();
        if (live) {
          _addRun(await _live!.stop());
          await _partials?.cancel();
          _partials = null;
          _live = null;
        } else if (discard) {
          await backend.cancelRecording();
        } else {
          try {
            await backend.stopRecording();
          } catch (_) {
            await backend.cancelRecording();
            rethrow;
          }
          await _refresh();
          selected = clips.firstOrNull;
        }
        issue ??= previousIssue;
      } finally {
        _release();
      }
    });
  }
}
