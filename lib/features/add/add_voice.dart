part of 'add_screen.dart';

/// Voice: record, stop, cancel and discard. Every transition is claimed
/// synchronously before the first await.
extension _AddVoice on _AddScreenState {
  Future<void> _startRecording() async {
    if (_rec != _Rec.idle || _saving || _picking || _voicePath != null) return;
    _set(() => _rec = _Rec.starting);
    FocusScope.of(context).unfocus();
    try {
      final status = await Permission.microphone.request();
      if (!mounted) return;
      if (!status.isGranted) {
        _set(() {
          _rec = _Rec.idle;
          _mic = status.isPermanentlyDenied ? _Mic.blocked : _Mic.denied;
        });
        return;
      }
      final path = await ref.read(attachmentStoreProvider).newRecordingPath();
      // Disposed meanwhile: never create a recorder that nothing will dispose.
      if (!mounted) return;
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, numChannels: 1, bitRate: 64000),
        path: path,
      );
      if (!mounted) return;
      _levels.clear();
      _ampSub = _recorder.onAmplitudeChanged(const Duration(milliseconds: 90)).listen((a) {
        _set(() {
          _levels.add(levelFromDb(a.current));
          if (_levels.length > kWaveformSamples) _levels.removeAt(0);
        });
      }, onError: (_) {});
      _elapsed = Duration.zero;
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        _set(() => _elapsed += const Duration(seconds: 1));
        if (_elapsed >= _AddScreenState.maxRecording) _stopRecording();
      });
      _set(() {
        _mic = _Mic.unknown;
        _rec = _Rec.recording;
      });
    } catch (_) {
      await _teardown();
      try {
        await _recorderInstance?.cancel();
      } catch (_) {}
      _set(() => _rec = _Rec.idle);
      if (mounted) showToast(context, context.l10n.recordStartFailed);
    }
  }

  Future<void> _teardown() async {
    _ticker?.cancel();
    _ticker = null;
    await _ampSub?.cancel();
    _ampSub = null;
  }

  Future<void> _stopRecording() async {
    if (_rec != _Rec.recording) return;
    _set(() => _rec = _Rec.stopping);
    await _teardown();
    String? path;
    try {
      path = await _recorder.stop();
    } catch (_) {}
    _set(() {
      _rec = _Rec.idle;
      if (path != null) {
        _voicePath = path;
        _voiceMs = _elapsed.inMilliseconds;
      }
    });
    if (path == null && mounted) showToast(context, context.l10n.recordInterrupted);
  }

  Future<void> _cancelRecording() async {
    if (_rec != _Rec.recording) return;
    _set(() => _rec = _Rec.stopping);
    await _teardown();
    try {
      await _recorder.cancel(); // deletes the partial file
    } catch (_) {}
    _set(() => _rec = _Rec.idle);
  }

  Future<void> _discardVoice() async {
    if (_saving) return; // the save is copying this file right now
    final path = _voicePath;
    _set(() {
      _voicePath = null;
      _voiceMs = null;
    });
    if (path != null) await AttachmentStore.deleteQuietly([path]);
  }
}
