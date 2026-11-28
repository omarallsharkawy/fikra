import 'dart:async';

import 'package:fikra/data/product/development/development_knowledge.dart';
import 'package:fikra/data/product/models.dart';
import 'package:fikra/features/capture/capture_controller.dart';
import 'package:fikra/features/capture/local_documents.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart' show loadAppFonts;
import 'auth_layout_test.dart' show input;
import 'controller_test.dart' show TestCaptureDevice;
import 'navigation_test.dart' show boot, cleanup, tapVisible;

class VoiceSaveRepository extends DevelopmentKnowledgeRepository {
  VoiceSaveRepository({this.loseFirstResponse = false});
  bool loseFirstResponse;
  final sent = <CreateAttempt>[];
  @override
  Future<String> transcribe(String accountId, RecordedClip clip) async => 'Reviewed voice text';
  @override
  Future<KnowledgeNote> createNote(CreateAttempt attempt) async {
    sent.add(attempt);
    final saved = await super.createNote(attempt);
    if (loseFirstResponse) {
      loseFirstResponse = false;
      throw const ProductFailure(FailureKind.uncertain);
    }
    return saved;
  }
}

class LateVoiceRepository extends DevelopmentKnowledgeRepository {
  final transcription = Completer<String>();
  @override
  Future<String> transcribe(String accountId, RecordedClip clip) => transcription.future;
}

void main() {
  setUpAll(loadAppFonts);
  for (final locale in [const Locale('en'), const Locale('ar')]) {
    for (final uncertain in [false, true]) {
      testWidgets('new idea has no old voice review after confirmed save ($locale, uncertain=$uncertain)', (
        tester,
      ) async {
        final repository = VoiceSaveRepository(loseFirstResponse: uncertain);
        final r = await boot(tester, locale: locale, knowledge: repository, size: const Size(360, 800));
        await r.session.login('other@example.invalid', 'fixture-only');
        await tester.pumpAndSettle();
        await tapVisible(tester, find.byKey(const ValueKey('nav-add')));
        await r.capture.start();
        await r.capture.stop();
        await r.capture.transcribe();
        await tester.pumpAndSettle();
        final clip = r.capture.clip;
        final l = tester.element(find.byKey(const ValueKey('save-product-note'))).l10n;
        expect(r.workspace.draft.content, 'Reviewed voice text');
        await tapVisible(tester, find.byKey(const ValueKey('save-product-note')));
        if (uncertain) {
          expect(r.workspace.pendingAttempt, isNotNull);
          expect(r.capture.clip, same(clip));
          expect(r.capture.transcript, 'Reviewed voice text');
          expect(r.workspace.draft.content, 'Reviewed voice text');
          await tapVisible(tester, find.byKey(const ValueKey('save-product-note')));
          expect(repository.sent[0].key, repository.sent[1].key);
        }
        expect(r.capture.state, CaptureState.idle);
        expect(r.capture.clip, isNull);
        expect(r.capture.transcript, isEmpty);
        expect(r.workspace.pendingAttempt, isNull);
        expect(r.workspace.notes.single.content, 'Reviewed voice text');
        await tapVisible(tester, find.byKey(const ValueKey('nav-add')));
        expect(find.byKey(ValueKey('capture-title-${r.workspace.selectedProjectId}')), findsNothing);
        expect(
          tester.widget<TextField>(input('capture-content-${r.workspace.selectedProjectId}')).controller!.text,
          isEmpty,
        );
        expect(find.byKey(const ValueKey('transcript-review')), findsNothing);
        expect(find.byKey(const ValueKey('use-transcript')), findsNothing);
        expect(find.byKey(const ValueKey('transcribe-product-voice')), findsNothing);
        expect(find.text(l.productDiscardRecording), findsNothing);
        await r.capture.start();
        expect(r.capture.state, CaptureState.recording);
        await r.capture.cancel();
        expect(tester.takeException(), isNull);
        await cleanup(tester);
      });
    }
  }
  test('confirmed-save cleanup ignores late transcription and preserves separate local documents', () async {
    final repository = LateVoiceRepository(), device = TestCaptureDevice();
    final capture = CaptureController(device, repository);
    addTearDown(capture.dispose);
    capture.setAccount('owner');
    capture.localPdfs = const [LocalDocument('/local.pdf', 'Local document')];
    await capture.start();
    await capture.stop();
    final pending = capture.transcribe();
    capture.clearAfterSave();
    repository.transcription.complete('Old voice result');
    await pending;
    expect(capture.state, CaptureState.idle);
    expect(capture.clip, isNull);
    expect(capture.transcript, isEmpty);
    expect(capture.localPdfs.single.path, '/local.pdf');
    expect(device.cancels, greaterThan(1));
    capture.setAccount(null);
    expect(capture.localPdfs, isEmpty);
  });
}
