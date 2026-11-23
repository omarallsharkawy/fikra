import 'package:fikra/app/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:async';

import 'package:fikra/core/format.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/data/transcription/services_repository.dart';
import 'package:fikra/data/transcription/remote_request.dart';
import 'package:fikra/features/note_details/note_details_screen.dart';
import 'package:fikra/features/note_details/transcript_editor_screen.dart';
import 'package:fikra/features/voice_text/service_form_screen.dart';
import 'package:fikra/features/voice_text/voice_text_screen.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/app_harness.dart';
import 'support/external_service_fixture.dart';
import 'support/fake_external_transcription.dart';
import 'support/fake_transcription_engine.dart';
import 'support/transcription_scroll.dart';
import 'support/voice2_fixture.dart';
import 'voice_text/fake_voice_text_backend.dart';

void main() {
  const locale = Locale('en');
  final l = lookupAppLocalizations(locale);
  final keys = MemoryServiceKeys();
  final backend = FakeVoiceTextBackend();
  fikraTest(
    'catalog groups, legacy warning, custom ID and persisted picker selection',
    locale: locale,
    serviceKeys: keys,
    voiceTextBackend: backend,
    (tester, db) async {
      addTearDown(() => unawaited(backend.dispose()));
      await seedExternalProject(tester, db, locale);
      final service = sampleService(consent: true);
      final repo = LocalTranscriptionServices(db, keys);
      await pumpFuture(tester, () => repo.save(service, key: 'fake'));
      await openExternalSettings(tester);
      await revealTranscription(tester, VoiceTextScreen, ValueKey('vs-edit-${service.id}'));
      await tester.tap(find.byKey(ValueKey('vs-edit-${service.id}')));
      await pumpUntil(tester, find.byType(ServiceFormScreen));
      await serviceFormAction(tester, 'vs-model');
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(l.v2Recommended), findsOneWidget);
      expect(find.text(l.v2Legacy), findsOneWidget);
      expect(find.text(l.v2Shutdown(Fmt.isolate(Fmt.date(l, DateTime(2027, 2, 26))))), findsNWidgets(4));
      expect(find.textContaining('2027-02-26'), findsNothing);
      await revealVoice2Sheet(tester, 'v2-model-whisper-1');
      await tester.tap(find.byKey(const ValueKey('v2-model-whisper-1')));
      await tester.pump(const Duration(milliseconds: 600));
      await serviceFormAction(tester, 'vs-model');
      await tester.pump(const Duration(milliseconds: 600));
      await revealVoice2Sheet(tester, 'v2-custom-toggle');
      await tester.tap(find.byKey(const ValueKey('v2-custom-toggle')));
      await tester.pump();
      await revealVoice2Sheet(tester, 'v2-custom-id');
      await tester.enterText(
        find.descendant(of: find.byKey(const ValueKey('v2-custom-id')), matching: find.byType(TextField)),
        'my-custom-asr',
      );
      tester.testTextInput.hide();
      await tester.pump();
      await revealVoice2Sheet(tester, 'v2-custom-save');
      await tester.tap(find.byKey(const ValueKey('v2-custom-save')));
      await tester.pump(const Duration(milliseconds: 600));
      await serviceFormAction(tester, 'vs-save');
      await pumpUntil(tester, find.byType(VoiceTextScreen));
      expect((await pumpFuture(tester, repo.read)).services.single.batchModel, 'my-custom-asr');
    },
  );

  for (final unsafe in [false, true]) {
    fikraTest(
      'transcript editor saves correction; unsafe copy=$unsafe',
      locale: locale,
      aiService: FakeTranscriptionAi(),
      (tester, db) async {
        await seedExternalProject(tester, db, locale);
        final fixture = await seedVoice2(tester, db, unsafe: unsafe);
        tester.element(find.text(externalProject)).push('/note/${fixture.note.id}');
        await pumpUntil(tester, find.byType(NoteDetailsScreen));
        await revealTranscription(tester, NoteDetailsScreen, ValueKey('transcript-edit-${fixture.attachmentId}'));
        await tester.tap(find.byKey(ValueKey('transcript-edit-${fixture.attachmentId}')));
        await pumpUntil(tester, find.byType(TranscriptEditorScreen));
        await tester.enterText(find.byKey(const ValueKey('v2-transcript-field')), 'Corrected words');
        tester.testTextInput.hide();
        await tester.pump();
        await revealTranscription(tester, TranscriptEditorScreen, const ValueKey('v2-transcript-save'));
        await tester.tap(find.byKey(const ValueKey('v2-transcript-save')));
        if (unsafe) {
          await pumpUntil(tester, find.byKey(const ValueKey('v2-copy-unchanged')));
          expect(
            (await pumpFuture(tester, () => LocalNotesRepository(db).watchNote(fixture.note.id).first))!.originalText,
            'Changed copy',
          );
          await revealTranscription(tester, TranscriptEditorScreen, const ValueKey('v2-append'));
          await tester.tap(find.byKey(const ValueKey('v2-append')));
        }
        await pumpUntil(tester, find.byType(NoteDetailsScreen));
        await revealTranscription(tester, NoteDetailsScreen, ValueKey('transcript-text-${fixture.attachmentId}'));
        expect(find.text('Corrected words'), findsOneWidget);
        final a = (await pumpFuture(
          tester,
          () => LocalNotesRepository(db).watchAttachments(fixture.note.id).first,
        )).single;
        expect(a.transcriptCorrection, 'Corrected words');
        expect(a.transcript, isNot('Corrected words'));
        if (!unsafe) {
          await revealTranscription(tester, NoteDetailsScreen, ValueKey('transcript-edit-${fixture.attachmentId}'));
          await tester.tap(find.byKey(ValueKey('transcript-edit-${fixture.attachmentId}')));
          await pumpUntil(tester, find.byKey(const ValueKey('v2-transcript-field')));
          await revealTranscription(tester, TranscriptEditorScreen, const ValueKey('v2-transcript-restore'));
          await tester.tap(find.byKey(const ValueKey('v2-transcript-restore')));
          await pumpUntil(tester, find.byType(NoteDetailsScreen));
          final restored = (await pumpFuture(
            tester,
            () => LocalNotesRepository(db).watchAttachments(fixture.note.id).first,
          )).single;
          expect(restored.transcriptCorrection, isNull);
          expect(restored.transcript, a.transcript);
        }
      },
    );
  }
  fikraTest(
    'new machine transcript keeps correction until Use it and updates safely',
    locale: locale,
    aiService: FakeTranscriptionAi(),
    (tester, db) async {
      await seedExternalProject(tester, db, locale);
      final f = await seedVoice2(tester, db, newer: true);
      tester.element(find.text(externalProject)).push('/note/${f.note.id}');
      await pumpUntil(tester, find.byType(NoteDetailsScreen));
      await revealTranscription(tester, NoteDetailsScreen, ValueKey('transcript-new-${f.attachmentId}'));
      expect(find.text(l.v2NewTranscript), findsOneWidget);
      expect(find.text('Tomorrow we review the app plan together.'), findsOneWidget);
      await revealTranscription(tester, NoteDetailsScreen, ValueKey('transcript-use-${f.attachmentId}'));
      await tester.tap(find.byKey(ValueKey('transcript-use-${f.attachmentId}')));
      await pumpFuture(tester, () async {
        while ((await LocalNotesRepository(db).watchAttachments(f.note.id).first).single.transcriptCorrection != null) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        await ProviderScope.containerOf(tester.element(find.byType(NoteDetailsScreen)))
            .read(noteProcessorProvider)
            .retry(f.note.id);
      });

      final a = (await pumpFuture(tester, () => LocalNotesRepository(db).watchAttachments(f.note.id).first)).single;
      expect(a.transcriptCorrection, isNull);
      await pumpFuture(tester, () => LocalNotesRepository(db).watchNote(f.note.id).first);
    },
  );
  fikraTest('transcript editor cancel asks before discarding unsaved changes', locale: locale, (tester, db) async {
    await seedExternalProject(tester, db, locale);
    final f = await seedVoice2(tester, db);
    tester.element(find.text(externalProject)).push('/note/${f.note.id}/transcript/${f.attachmentId}');
    await pumpUntil(tester, find.byType(TranscriptEditorScreen));
    await pumpUntil(tester, find.byKey(const ValueKey('v2-transcript-field')));
    await tester.enterText(find.byKey(const ValueKey('v2-transcript-field')), 'Unsaved');
    tester.testTextInput.hide();
    await tester.pump();
    await revealTranscription(tester, TranscriptEditorScreen, const ValueKey('v2-transcript-cancel'));
    await tester.tap(find.byKey(const ValueKey('v2-transcript-cancel')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text(l.unsavedTitle), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text(l.keepEditing));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(TranscriptEditorScreen), findsOneWidget);
    expect(tester.widget<TextField>(find.byKey(const ValueKey('v2-transcript-field'))).controller!.text, 'Unsaved');
  });
  final discoveryKeys = MemoryServiceKeys();
  final discoveryHttp = FakeTranscriptionTransport()
    ..response = const RemoteResponse(200, '{"data":[{"id":"gpt-transcribe"},{"id":"unknown-audio-model"}]}');
  final discoveryBackend = FakeVoiceTextBackend();
  fikraTest(
    'model refresh consents before GET, sends no audio and persists the availability cache',
    locale: locale,
    serviceKeys: discoveryKeys,
    transcriptionTransport: discoveryHttp,
    voiceTextBackend: discoveryBackend,
    (tester, db) async {
      addTearDown(() => unawaited(discoveryBackend.dispose()));
      await seedExternalProject(tester, db, locale);
      await openExternalSettings(tester);
      await revealTranscription(tester, VoiceTextScreen, const ValueKey('vs-add'));
      await tester.tap(find.byKey(const ValueKey('vs-add')));
      await pumpUntil(tester, find.byType(ServiceFormScreen));
      await serviceField(tester, 'vs-key', 'fake-discovery-key');
      await serviceFormAction(tester, 'v2-refresh');
      expect(discoveryHttp.requests, isEmpty);
      expect(find.byType(Dialog), findsOneWidget);
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text(l.vsConsentConfirm)));
      await pumpFuture(tester, () async {
        while (discoveryHttp.requests.isEmpty ||
            await db
                .select(db.settings)
                .get()
                .then((rows) => !rows.any((r) => r.key.startsWith('transcription_models.')))) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      await tester.pump(const Duration(milliseconds: 600));
      expect(discoveryHttp.requests.single.method, 'GET');
      expect(discoveryHttp.requests.single.audio, isNull);
      await serviceFormAction(tester, 'vs-model');
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(l.v2Available), findsOneWidget);
      expect(find.text('unknown-audio-model'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('v2-model-gpt-transcribe')));
      await tester.pump(const Duration(milliseconds: 600));
      await serviceFormAction(tester, 'vs-save');
      await pumpUntil(tester, find.byType(VoiceTextScreen));
      final repo = LocalTranscriptionServices(db, discoveryKeys);
      final service = (await pumpFuture(tester, repo.read)).services.single;
      expect(service.consented, isTrue);
      await revealTranscription(tester, VoiceTextScreen, ValueKey('vs-edit-${service.id}'));
      await tester.tap(find.byKey(ValueKey('vs-edit-${service.id}')));
      await pumpUntil(tester, find.byType(ServiceFormScreen));
      await pumpUntil(
        tester,
        find.byWidgetPredicate((w) => w is Text && (w.data?.startsWith('Last checked:') ?? false)),
      );
      await serviceFormAction(tester, 'vs-model');
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(l.v2Available), findsOneWidget);
    },
  );
}
