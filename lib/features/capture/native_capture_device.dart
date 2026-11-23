import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../data/files/attachment_store.dart';
import '../../data/product/models.dart';
import 'capture_controller.dart';

/// Reuses the existing record, permissions and local temporary-file boundaries.
class NativeCaptureDevice implements CaptureDevice {
  NativeCaptureDevice(this.recorder, this.permission, this.files);
  final AudioRecorder recorder;
  final Future<PermissionStatus> Function() permission;
  final AttachmentStore files;
  String? _path;
  Future<void>? _starting;
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
    if (!(await permission()).isGranted) throw const ProductFailure(FailureKind.validation, field: 'microphone');
    _path = await files.newRecordingPath();
    await recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc, numChannels: 1, bitRate: 64000), path: _path!);
  }

  @override
  Future<RecordedClip?> stop(Duration duration) async {
    final path = await recorder.stop();
    return path == null ? null : RecordedClip(path, 'audio/m4a', duration);
  }

  @override
  Future<void> cancel() async {
    try {
      await _starting;
    } catch (_) {
      /* A failed start still needs cleanup. */
    }
    try {
      await recorder.cancel();
    } catch (_) {
      /* No active recording is normal. */
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
    await recorder.dispose();
  }
}
