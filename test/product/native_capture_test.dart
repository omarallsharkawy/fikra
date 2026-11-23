import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fikra/data/files/attachment_store.dart';
import 'package:fikra/data/product/development/development_knowledge.dart';
import 'package:fikra/features/capture/capture_controller.dart';
import 'package:fikra/features/capture/native_capture_device.dart';

import '../support/recording_fake.dart';

class HeldStop extends RecordingFake {
  HeldStop(super.events);
  final stopping = Completer<void>();
  @override
  Future<String?> stop(String id) async {
    events.add('stop:waiting');
    await stopping.future;
    return super.stop(id);
  }
}

Future<void> until(bool Function() predicate) async {
  for (var n = 0; n < 500; n++) {
    if (predicate()) return;
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
  fail('Native boundary did not reach the expected state');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('changing account during native start cleans the old recorder before a new start', () async {
    final previous = RecordPlatform.instance, events = <String>[];
    final fake = RecordingFake(events);
    final gate = Completer<void>();
    fake.startGate = gate.future;
    RecordPlatform.instance = fake;
    final dir = await Directory.systemTemp.createTemp('fikrah-product-recording-');
    final device = NativeCaptureDevice(
      AudioRecorder(),
      () async => PermissionStatus.granted,
      AttachmentStore(tempDir: () async => dir, documentsDir: () async => dir),
    );
    final capture = CaptureController(device, DevelopmentKnowledgeRepository());
    try {
      capture.setAccount('old');
      final oldStart = capture.start();
      await until(() => events.any((e) => e.startsWith('record:start:')));
      capture.setAccount('new');
      final newStart = capture.start();
      expect(events.where((e) => e.startsWith('record:start:')).length, 1);
      gate.complete();
      await oldStart;
      await newStart;
      expect(capture.accountId, 'new');
      expect(capture.state, CaptureState.recording);
      expect(fake.maxActive, 1);
      expect(fake.active.length, 1);
      await capture.cancel();
      expect(fake.active, isEmpty);
      expect(await dir.list().toList(), isEmpty);
    } finally {
      capture.dispose();
      await until(() => fake.states.isEmpty);
      RecordPlatform.instance = previous;
      await dir.delete(recursive: true);
    }
  });
  test('changing account waits for a native stop before another recording', () async {
    final previous = RecordPlatform.instance, events = <String>[];
    final fake = HeldStop(events);
    RecordPlatform.instance = fake;
    final dir = await Directory.systemTemp.createTemp('fikrah-product-stopping-');
    final device = NativeCaptureDevice(
      AudioRecorder(),
      () async => PermissionStatus.granted,
      AttachmentStore(tempDir: () async => dir, documentsDir: () async => dir),
    );
    final capture = CaptureController(device, DevelopmentKnowledgeRepository());
    try {
      capture.setAccount('old');
      await capture.start();
      final stopped = capture.stop();
      await until(() => events.contains('stop:waiting'));
      capture.setAccount('new');
      final newStart = capture.start();
      expect(events.where((e) => e.startsWith('record:start:')).length, 1);
      fake.stopping.complete();
      await stopped;
      await newStart;
      expect(capture.clip, isNull);
      expect(capture.state, CaptureState.recording);
      expect(fake.maxActive, 1);
      await capture.cancel();
      expect(fake.active, isEmpty);
    } finally {
      capture.dispose();
      await until(() => fake.states.isEmpty);
      RecordPlatform.instance = previous;
      await dir.delete(recursive: true);
    }
  });
}
