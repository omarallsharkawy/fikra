import 'dart:async';
import 'dart:io';

import 'package:fikra/app/providers.dart';
import 'package:fikra/core/theme/fikra_theme.dart';
import 'package:fikra/data/files/attachment_store.dart';
import 'package:fikra/features/shared/attachment_editor.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import 'support/app_harness.dart';
import 'support/recording_fake.dart';

class RecorderHost extends ConsumerStatefulWidget {
  const RecorderHost({super.key});
  @override
  ConsumerState<RecorderHost> createState() => RecorderHostState();
}

class RecorderHostState extends ConsumerState<RecorderHost> with AttachmentEditing<RecorderHost> {
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        permissionCard(),
        if (recording) recordingPreview(),
        attachmentToolbar(canSave: false, onSave: () {}),
      ],
    ),
  );
}

Future<RecorderHostState> host(WidgetTester tester, ProviderContainer container, String key) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildFikraTheme(Brightness.dark),
        home: RecorderHost(key: ValueKey(key)),
      ),
    ),
  );
  await tester.pump();
  return tester.state<RecorderHostState>(find.byType(RecorderHost));
}

Future<void> until(WidgetTester tester, bool Function() predicate) => pumpFuture(tester, () async {
  while (!predicate()) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
});

void main() {
  late Directory dir;
  late RecordingFake native;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('fikra-rec-lifecycle-');
    native = RecordingFake([]);
    final previous = RecordPlatform.instance;
    RecordPlatform.instance = native;
    addTearDown(() => RecordPlatform.instance = previous);
    addTearDown(() => dir.delete(recursive: true));
  });
  ProviderContainer container(Future<PermissionStatus> Function() permission) => ProviderContainer(
    overrides: [
      microphonePermissionProvider.overrideWithValue(permission),
      attachmentStoreProvider.overrideWithValue(
        AttachmentStore(documentsDir: () async => dir, tempDir: () async => dir),
      ),
    ],
  );
  Future<void> finish(WidgetTester tester, ProviderContainer scope) async {
    await tester.pumpWidget(const SizedBox());
    await until(tester, () => !scope.read(recordingActiveProvider));
    scope.dispose();
    await tester.pump();
  }

  for (final failure in ['denied', 'permission', 'start', 'stop', 'stop+cancel', 'cancel']) {
    testWidgets('microphone lease releases after $failure and permits a new recording', (tester) async {
      var denied = failure == 'denied';
      var permissionError = failure == 'permission';
      final scope = container(() async {
        if (permissionError) throw StateError('permission failed');
        return denied ? PermissionStatus.denied : PermissionStatus.granted;
      });
      native.failStart = failure == 'start';
      final state = await host(tester, scope, 'first');
      await pumpFuture(tester, state.startRecording);
      if (failure == 'stop' || failure == 'stop+cancel') {
        native.failStop = true;
        native.failCancel = failure == 'stop+cancel';
        await pumpFuture(tester, state.stopRecording);
      }
      if (failure == 'cancel') {
        native.failCancel = true;
        await pumpFuture(tester, state.cancelRecording);
      }
      expect(scope.read(recordingActiveProvider), isFalse);
      expect(native.active, isEmpty);
      expect(state.rec, RecordingState.idle);
      expect(state.draftFiles, isEmpty);
      denied = false;
      permissionError = false;
      native.failStart = false;
      native.failStop = false;
      native.failCancel = false;
      await pumpFuture(tester, state.startRecording);
      expect(state.rec, RecordingState.recording);
      expect(scope.read(recordingActiveProvider), isTrue);
      await pumpFuture(tester, state.cancelRecording);
      expect(scope.read(recordingActiveProvider), isFalse);
      await finish(tester, scope);
    });
  }

  testWidgets('dispose releases the lease even when native cancel and disposal throw', (tester) async {
    final scope = container(() async => PermissionStatus.granted);
    final first = await host(tester, scope, 'first');
    await pumpFuture(tester, first.startRecording);
    native.failCancel = true;
    native.failDispose = true;
    final second = await host(tester, scope, 'second');
    await until(tester, () => !scope.read(recordingActiveProvider));
    expect(native.active, isEmpty);
    native.failCancel = false;
    native.failDispose = false;
    await pumpFuture(tester, second.startRecording);
    expect(native.maxActive, 1);
    await pumpFuture(tester, second.cancelRecording);
    await finish(tester, scope);
  });

  for (final pending in ['permission', 'start', 'cancel']) {
    testWidgets('dispose releases microphone ownership safely during pending $pending', (tester) async {
      final gate = Completer<void>();
      final permission = Completer<PermissionStatus>();
      final scope = container(
        () => pending == 'permission' ? permission.future : Future.value(PermissionStatus.granted),
      );
      if (pending == 'start') native.startGate = gate.future;
      final first = await host(tester, scope, 'first');
      final starting = first.startRecording();
      if (pending != 'permission') {
        if (pending == 'start') {
          await until(tester, () => native.events.any((e) => e.startsWith('record:start:')));
        } else {
          await pumpFuture(tester, () => starting);
          native.cancelGate = gate.future;
        }
      }
      expect(scope.read(recordingActiveProvider), isTrue);
      final second = await host(tester, scope, 'second');
      if (pending == 'permission') {
        await until(tester, () => !scope.read(recordingActiveProvider));
        permission.complete(PermissionStatus.granted);
      } else {
        expect(scope.read(recordingActiveProvider), isTrue);
        await pumpFuture(tester, second.startRecording);
        expect(native.events.where((e) => e.startsWith('record:start:')), hasLength(1));
        gate.complete();
      }
      await pumpFuture(tester, () => starting);
      await until(tester, () => !scope.read(recordingActiveProvider));
      expect(native.active, isEmpty);
      native.startGate = null;
      native.cancelGate = null;
      await pumpFuture(tester, second.startRecording);
      expect(native.maxActive, 1);
      await pumpFuture(tester, second.cancelRecording);
      await finish(tester, scope);
    });
  }
}
