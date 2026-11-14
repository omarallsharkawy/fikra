import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:drift/drift.dart' show Value;
import 'package:fikra/core/widgets/fikra_widgets.dart';
import 'package:fikra/data/attachment_draft.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/features/note_details/edit_note_screen.dart';
import 'package:fikra/features/note_details/note_details_screen.dart';
import 'package:fikra/features/voice_text/voice_text_screen.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/app_harness.dart';
import 'support/fake_transcription_engine.dart';
import 'support/transcription_scroll.dart';
import 'voice_text/fake_voice_text_backend.dart';
import 'voice_text/voice_text_fixture.dart';

void main() {
  final l = lookupAppLocalizations(const Locale('en'));
  Future<({Note note, NoteAttachment attachment})> seed(
    WidgetTester tester,
    FikraDatabase db, {
    TranscriptionStatus status = TranscriptionStatus.none,
    String? failure,
    int attempts = 0,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpUntil(tester, find.text(l.startNewProject));
    return pumpFuture(tester, () async {
      final p = await LocalProjectsRepository(db).create('Voice project');
      final notes = LocalNotesRepository(db);
      final n = await notes.create(
        projectId: p.id,
        title: 'Voice note',
        text: 'Typed',
        source: NoteSource.voice,
        attachments: [const AttachmentDraft(kind: AttachmentKind.voice, path: '/saved.m4a', durationMs: 5000)],
      );
      await notes.markReady(n.id);
      final a = (await notes.watchAttachments(n.id).first).single;
      await (db.update(db.noteAttachments)..where((f) => f.id.equals(a.id))).write(
        NoteAttachmentsCompanion(
          transcriptionStatus: Value(status),
          transcriptionFailure: Value(failure),
          transcriptionAttempts: Value(attempts),
          transcript: Value(status == TranscriptionStatus.done ? List.filled(12, 'Spoken words.').join('\n') : null),
          transcriptionEngine: Value(status == TranscriptionStatus.done ? 'local:ggml-small-egy-cs-q5_1.bin' : null),
        ),
      );
      return (note: n, attachment: a);
    });
  }

  Future<void> open(WidgetTester tester, Note n) async {
    await pumpUntil(tester, find.text('Voice project'));
    tester.element(find.text('Voice project')).push('/note/${n.id}');
    await pumpUntil(tester, find.byType(NoteDetailsScreen));
  }

  for (final status in [TranscriptionStatus.queued, TranscriptionStatus.running]) {
    fikraTest('card and details show ${status.name}', locale: const Locale('en'), aiService: FakeTranscriptionAi(), (
      tester,
      db,
    ) async {
      final fixture = await seed(tester, db, status: status);
      await pumpUntil(tester, find.byKey(ValueKey('transcribing-${fixture.note.id}')));
      expect(tester.widget<FikraBadge>(find.byKey(ValueKey('transcribing-${fixture.note.id}'))).label, l.trWorking);
      await open(tester, fixture.note);
      await revealTranscription(tester, NoteDetailsScreen, ValueKey('transcript-${fixture.attachment.id}'));
      expect(find.text(status == TranscriptionStatus.queued ? l.trQueued : l.trWorking), findsOneWidget);
      expect(find.byKey(ValueKey('transcribe-${fixture.attachment.id}')), findsNothing);
    });
  }

  fikraTest(
    'details done starts collapsed, expands and shows the engine and redo',
    locale: const Locale('en'),
    aiService: FakeTranscriptionAi(),
    (tester, db) async {
      final fixture = await seed(tester, db, status: TranscriptionStatus.done);
      await open(tester, fixture.note);
      final id = fixture.attachment.id;
      await revealTranscription(tester, NoteDetailsScreen, ValueKey('transcript-text-$id'));
      expect(
        tester
            .widget<Text>(find.descendant(of: find.byKey(ValueKey('transcript-text-$id')), matching: find.byType(Text)))
            .maxLines,
        3,
      );
      expect(find.text(l.trLocalEngine(l.vtEgyptian)), findsOneWidget);
      await tester.tap(find.byKey(ValueKey('transcript-expand-$id')));
      await tester.pump();
      expect(
        find.descendant(of: find.byKey(ValueKey('transcript-text-$id')), matching: find.byType(SelectableText)),
        findsOneWidget,
      );
      await revealTranscription(tester, NoteDetailsScreen, ValueKey('transcribe-$id'));
      expect(find.text(l.trRedo), findsOneWidget);
    },
  );

  for (final failure in ['other', 'audioUnreadable', 'busy', 'interruptedTwice', 'modelMissing']) {
    final backend = failure == 'modelMissing' ? FakeVoiceTextBackend() : null;
    fikraTest(
      'details failure $failure provides visible explanation and retry/settings',
      locale: const Locale('en'),
      aiService: FakeTranscriptionAi(),
      voiceTextBackend: backend,
      (tester, db) async {
        if (backend != null) addTearDown(() => unawaited(backend.dispose()));
        final interrupted = failure == 'interruptedTwice';
        final fixture = await seed(
          tester,
          db,
          status: TranscriptionStatus.failed,
          failure: failure,
          attempts: interrupted ? 2 : 1,
        );
        await open(tester, fixture.note);
        final id = fixture.attachment.id;
        await revealTranscription(tester, NoteDetailsScreen, ValueKey('transcript-$id'));
        expect(find.byType(StatusBanner), findsOneWidget);
        if (interrupted) {
          expect(find.text(l.trInterruptedTwice), findsOneWidget);
          // A smaller model is one way out, so settings are offered as well.
          expect(find.byKey(ValueKey('transcript-settings-$id')), findsOneWidget);
        }
        if (failure == 'modelMissing') {
          await revealTranscription(tester, NoteDetailsScreen, ValueKey('transcript-settings-$id'));
          await tester.tap(find.byKey(ValueKey('transcript-settings-$id')));
          await pumpUntil(tester, find.byType(VoiceTextScreen));
        } else {
          await revealTranscription(tester, NoteDetailsScreen, ValueKey('transcribe-$id'));
          await tester.tap(find.byKey(ValueKey('transcribe-$id')));
          await pumpUntil(tester, find.text('Test transcript'));
          // The user's retry started the count again; this run is attempt one.
          final row = await pumpFuture(
            tester,
            () => (db.select(db.noteAttachments)..where((a) => a.id.equals(id))).getSingle(),
          );
          expect(row.transcriptionAttempts, 1);
        }
      },
    );
  }

  testWidgets('voice auto setting defaults off, persists, explains missing model', (tester) async {
    // The handle is checked before tearDowns run, so it is disposed in the body.
    final semantics = tester.ensureSemantics();
    final backend = FakeVoiceTextBackend()..sizes['tiny-q5_1'] = 100;
    final settings = FakeVoiceTextSettings();
    await pumpVoiceText(tester, backend, settings: settings);
    await tapVoiceText(tester, 'vt-auto-transcribe');
    expect(settings.autoTranscribe, isTrue);
    expect(
      tester.getSemantics(find.byKey(const ValueKey('vt-auto-transcribe'))).flagsCollection.isToggled,
      Tristate.isTrue,
    );
    await tapVoiceText(tester, 'vt-auto-transcribe');
    expect(settings.autoTranscribe, isFalse);
    expect(
      tester.getSemantics(find.byKey(const ValueKey('vt-auto-transcribe'))).flagsCollection.isToggled,
      Tristate.isFalse,
    );
    final empty = FakeVoiceTextBackend();
    await pumpVoiceText(tester, empty);
    await revealVoiceText(tester, 'vt-auto-transcribe');
    expect(find.text(l.trDownloadFirst), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(const ValueKey('vt-auto-transcribe'))).flagsCollection.isEnabled,
      Tristate.isFalse,
    );
    semantics.dispose();
  });

  for (final typed in [false, true]) {
    fikraTest(
      'a transcript appended while Edit is open survives saving ${typed ? 'typed text' : 'a title change'}',
      locale: const Locale('en'),
      aiService: FakeTranscriptionAi(),
      (tester, db) async {
        final fixture = await seed(tester, db);
        await pumpUntil(tester, find.text('Voice project'));
        tester.element(find.text('Voice project')).push('/note/${fixture.note.id}/edit');
        await pumpUntil(tester, find.text(l.editNoteTitle));
        await pumpUntil(tester, find.text('Typed'));
        // What TranscriptionQueue writes when inference finishes.
        await pumpFuture(
          tester,
          () => (db.update(db.notes)..where((n) => n.id.equals(fixture.note.id))).write(
            const NotesCompanion(editedText: Value('Typed\n\nSpoken words.')),
          ),
        );
        if (typed) {
          await tester.enterText(find.byType(TextField).last, 'Mine');
        } else {
          await tester.enterText(find.byType(TextField).first, 'New title');
        }
        await tester.pump();
        final save = find.text(l.saveChanges);
        await tester.scrollUntilVisible(save, 160, scrollable: transcriptionScrollable(EditNoteScreen));
        await tester.tap(save);
        await pumpUntil(tester, find.text(l.changesSaved));
        final saved = await pumpFuture(
          tester,
          () => (db.select(db.notes)..where((n) => n.id.equals(fixture.note.id))).getSingle(),
        );
        expect(saved.displayText, typed ? 'Mine\n\nSpoken words.' : 'Typed\n\nSpoken words.');
      },
    );
  }

  final engine = FakeTranscriptionEngine();
  fikraTest(
    'manual transcription queues and starts in background without blocking details',
    locale: const Locale('en'),
    aiService: FakeTranscriptionAi(),
    transcriptionEngine: engine,
    (tester, db) async {
      final fixture = await seed(tester, db);
      final gate = Completer<String>();
      addTearDown(() {
        if (!gate.isCompleted) gate.complete('done');
      });
      engine.action = (_, _) => gate.future;
      await open(tester, fixture.note);
      await revealTranscription(tester, NoteDetailsScreen, ValueKey('transcribe-${fixture.attachment.id}'));
      await tester.tap(find.byKey(ValueKey('transcribe-${fixture.attachment.id}')));
      await pumpUntil(tester, find.text(l.trWorking));
      gate.complete('done');
      await pumpUntil(tester, find.text('done'));
    },
  );
}
