import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../data/files/attachment_store.dart';
import '../../data/product/models.dart';
import 'capture_controller.dart';

/// Reuses the existing record, permissions and local temporary-file boundaries.
class NativeCaptureDevice implements CaptureDevice {
  NativeCaptureDevice(
    AudioRecorder? recorder,
    this.permission,
    this.files, {
    AudioRecorder Function()? createRecorder,
  }) : _recorder = recorder,
       _createRecorder = createRecorder ?? AudioRecorder.new;
  AudioRecorder? _recorder;
  final AudioRecorder Function() _createRecorder;
  final Future<PermissionStatus> Function() permission;
  final AttachmentStore files;
  String? _path;
  Future<void>? _starting;
  Future<RecordedClip?>? _stopping;
  bool _closed = false;

  AudioRecorder _ensureRecorder() => _recorder ??= _createRecorder();

  @override
  Future<void> start() async {
    _starting = _start();
    try {
      await _starting;
    } finally {
      _starting = null;
    }
  }

  Future<void> _start() async {
    if (_closed) throw const ProductFailure(FailureKind.unavailable);
    final status = await permission();
    if (status.isPermanentlyDenied || status.isRestricted) {
      throw const ProductFailure(FailureKind.validation, field: 'microphone_settings');
    }
    if (!status.isGranted) throw const ProductFailure(FailureKind.validation, field: 'microphone');
    _path = await files.newRecordingPath();
    final recorder = _ensureRecorder();
    await recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc, numChannels: 1, bitRate: 64000), path: _path!);
  }

  @override
  Future<RecordedClip?> stop(Duration duration) async {
    _stopping = _stop(duration);
    try {
      return await _stopping;
    } finally {
      _stopping = null;
    }
  }

  Future<RecordedClip?> _stop(Duration duration) async {
    final recorder = _recorder;
    if (recorder == null) return null;
    final path = await recorder.stop();
    if (path == null) return null;
    final file = File(path);
    if (!await file.exists() || await file.length() == 0) {
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {
        /* Already removed. */
      }
      return null;
    }
    return RecordedClip(path, 'audio/m4a', duration);
  }

  @override
  Future<void> cancel() async {
    try {
      await _starting;
    } catch (_) {
      /* A failed start still needs cleanup. */
    }
    try {
      await _stopping;
    } catch (_) {
      /* A failed stop still needs cancellation. */
    }
    if (_closed) return;
    final recorder = _recorder;
    if (recorder != null) {
      try {
        if (await recorder.isRecording()) {
          await recorder.cancel();
        }
      } catch (_) {
        try {
          await recorder.stop();
        } catch (_) {
          // Discard the broken recorder instance so the next start() creates
          // a fresh one instead of permanently disabling recording.
          _recorder = null;
          try {
            await recorder.dispose();
          } catch (_) {
            /* Best-effort teardown of broken recorder. */
          }
        }
      }
    }
    final path = _path;
    _path = null;
    if (path != null) {
      try {
        await File(path).delete();
      } catch (_) {
        /* Already removed. */
      }
    }
  }

  @override
  Future<void> dispose() async {
    await cancel();
    if (!_closed) {
      _closed = true;
      final recorder = _recorder;
      _recorder = null;
      if (recorder != null) {
        try {
          await recorder.dispose();
        } catch (_) {
          /* Best-effort teardown on dispose. */
        }
      }
    }
  }
}
