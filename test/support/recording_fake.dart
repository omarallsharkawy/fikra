import 'dart:async';
import 'dart:io';

import 'package:record/record.dart';

/// Exercises AudioRecorder's real serialization and streams with no microphone.
class RecordingFake extends RecordPlatform {
  RecordingFake(this.events);
  final List<String> events;
  final states = <String, StreamController<RecordState>>{};
  final paths = <String, String>{};
  final active = <String>{};
  Future<void>? startGate;
  Future<void>? cancelGate;
  bool failStart = false;
  bool failStop = false;
  bool failCancel = false;
  bool failDispose = false;
  int maxActive = 0;

  @override
  Future<void> create(String recorderId) async {
    events.add('record:create');
    states[recorderId] = StreamController<RecordState>.broadcast();
  }

  @override
  Future<void> start(String recorderId, RecordConfig config, {required String path}) async {
    events.add('record:start:$path');
    paths[recorderId] = path;
    await startGate;
    active.add(recorderId);
    if (active.length > maxActive) maxActive = active.length;
    if (failStart) throw StateError('start failed');
    await File(path).writeAsString('recorded');
    states[recorderId]!.add(RecordState.record);
  }

  @override
  Future<String?> stop(String recorderId) async {
    events.add('record:stop');
    if (failStop) throw StateError('stop failed');
    active.remove(recorderId);
    states[recorderId]!.add(RecordState.stop);
    return paths[recorderId];
  }

  @override
  Future<void> cancel(String recorderId) async {
    events.add('record:cancel');
    await cancelGate;
    if (failCancel) throw StateError('cancel failed');
    active.remove(recorderId);
    states[recorderId]!.add(RecordState.stop);
    final path = paths[recorderId];
    if (path != null && await File(path).exists()) await File(path).delete();
  }

  @override
  Future<void> dispose(String recorderId) async {
    events.add('record:dispose');
    active.remove(recorderId);
    await states.remove(recorderId)?.close();
    if (failDispose) throw StateError('dispose failed');
  }

  @override
  Stream<RecordState> onStateChanged(String recorderId) => states[recorderId]!.stream;
  @override
  Future<bool> isRecording(String recorderId) async => active.contains(recorderId);
  @override
  Future<Amplitude> getAmplitude(String recorderId) async => Amplitude(current: -10, max: -5);
  @override
  void setOnConfigChanged(String recorderId, void Function(RecordConfig config)? handler) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
