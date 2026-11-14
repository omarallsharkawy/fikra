import 'package:drift/native.dart';
import 'package:fikra/app/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:fikra/data/attachment_draft.dart';
import 'package:fikra/data/files/attachment_store.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/data/settings_repository.dart';
import 'package:fikra/features/add/add_screen.dart';
import 'package:fikra/features/note_details/edit_note_screen.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/app_harness.dart';
import 'support/fake_transcription_engine.dart';
import 'support/transcription_scroll.dart';

class _Copies extends AttachmentStore {
  @override
  Future<String> persist(String source, {required String extension}) async => '/saved$source';
  @override
  Future<void> sweepOrphans(Set<String> referenced) async {}
  @override
  Future<void> clearPickerCopies() async {}
}

void main() {
  final l = lookupAppLocalizations(const Locale('en'));
  for (final automatic in [false, true]) {
    for (final editing in [false, true]) {
      final engine = FakeTranscriptionEngine();
      fikraTest(
        'auto $automatic, ${editing ? 'Edit' : 'Add'} queues new voices only; explicit draft toggle',
        locale: const Locale('en'),
        aiService: FakeTranscriptionAi(),
        attachmentStore: _Copies(),
        transcriptionEngine: engine,
        (tester, db) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await pumpUntil(tester, find.text(l.startNewProject));
          final project = await pumpFuture(tester, () => LocalProjectsRepository(db).create('Save project'));
          await pumpFuture(tester, () => LocalSettingsRepository(db, _Copies()).setAutoTranscribe(automatic));
          Note? existing;
          if (editing) {
            existing = await pumpFuture(
              tester,
              () => LocalNotesRepository(db).create(
                projectId: project.id,
                title: 'Edit voice',
                text: 'Typed',
                source: NoteSource.voice,
                attachments: [const AttachmentDraft(kind: AttachmentKind.voice, path: '/existing.m4a')],
              ),
            );
            await pumpUntil(tester, find.text('Save project'));
            tester.element(find.text('Save project')).push('/note/${existing!.id}/edit');
            await pumpUntil(tester, find.text(l.editNoteTitle));
          } else {
            await tester.tap(Tabs.finder(Tabs.add));
            await pumpUntil(tester, find.byType(AddScreen));
          }
          final type = editing ? EditNoteScreen : AddScreen;
          final dynamic editor = tester.state(find.byType(type));
          if (editing) {
            await pumpFuture(tester, () async {
              while (!(editor.draftFiles as List<AttachmentDraft>).any((a) => a.id != null)) {
                await Future<void>.delayed(const Duration(milliseconds: 10));
              }
            });
          }
          // This is the shared post-stop draft path, without a native recorder.
          editor.updateDraft(() {
            editor.draftFiles = <AttachmentDraft>[
              ...editor.draftFiles as List<AttachmentDraft>,
              const AttachmentDraft(kind: AttachmentKind.voice, path: '/new-one.m4a', durationMs: 1000),
              const AttachmentDraft(kind: AttachmentKind.voice, path: '/new-two.m4a', durationMs: 2000),
            ];
          });
          await tester.pump();
          await pumpFuture(
            tester,
            () => ProviderScope.containerOf(tester.element(find.byType(type))).read(autoTranscribeProvider.future),
          );
          await tester.pump();
          final toggle = const ValueKey('transcribe-draft-/new-one.m4a');
          if (!automatic) {
            await revealTranscription(tester, type, toggle);
            final playerState = tester.state(find.byKey(const ValueKey('/new-one.m4a')));
            await tester.tap(find.byKey(toggle));
            await tester.pump();
            expect(tester.state(find.byKey(const ValueKey('/new-one.m4a'))), same(playerState));
            expect((editor.draftFiles as List<AttachmentDraft>).where((a) => a.transcribe).length, 1);
          } else {
            expect(find.byKey(toggle), findsNothing);
          }
          final container = ProviderScope.containerOf(tester.element(find.byType(type)));
          final save = editing ? find.text(l.saveChanges) : find.byKey(const ValueKey('add-save'));
          final scroll = transcriptionScrollable(type);
          await tester.scrollUntilVisible(save, 160, scrollable: scroll);
          await Scrollable.ensureVisible(tester.element(save), alignment: 0.5);
          await tester.pump(const Duration(milliseconds: 600));
          await tester.tap(save);
          await pumpUntil(tester, find.text(editing ? l.changesSaved : l.noteSaved));
          final expected = automatic ? 2 : 1;
          // Wait for fake inference and durable attachment writes.
          await pumpFuture(tester, () async {
            while (engine.paths.length < expected) {
              await Future<void>.delayed(const Duration(milliseconds: 10));
            }
          });
          await pumpFuture(tester, () => container.read(transcriptionQueueProvider).drained);
          expect(engine.paths, contains('/saved/new-one.m4a'));
          expect(engine.paths, isNot(contains('/existing.m4a')));
          expect(engine.paths, automatic ? contains('/saved/new-two.m4a') : isNot(contains('/saved/new-two.m4a')));
        },
      );
    }
  }

  // Saves one voice recording from Add with auto transcription on.
  Future<void> saveVoiceFromAdd(WidgetTester tester, String path) async {
    await tester.tap(Tabs.finder(Tabs.add));
    await pumpUntil(tester, find.byType(AddScreen));
    final dynamic editor = tester.state(find.byType(AddScreen));
    editor.updateDraft(() {
      editor.draftFiles = <AttachmentDraft>[AttachmentDraft(kind: AttachmentKind.voice, path: path, durationMs: 1000)];
    });
    await tester.pump();
    final container = ProviderScope.containerOf(tester.element(find.byType(AddScreen)));
    await pumpFuture(tester, () => container.read(autoTranscribeProvider.future));
    await tester.pump();
    final save = find.byKey(const ValueKey('add-save'));
    await tester.scrollUntilVisible(save, 160, scrollable: transcriptionScrollable(AddScreen));
    await Scrollable.ensureVisible(tester.element(save), alignment: 0.5);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(save);
    for (var i = 0; i < 600 && find.byType(AddScreen).evaluate().isNotEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.byType(AddScreen), findsNothing);
    await pumpFuture(tester, () => container.read(transcriptionQueueProvider).drained);
  }

  for (final askable in [true, false]) {
    final permission = FakeNotificationPermission(askable: askable);
    final keepAlive = FakeTranscriptionKeepAlive();
    fikraTest(
      'the first queued transcription ${askable ? 'explains and asks for' : 'skips asking for'} notifications, once',
      locale: const Locale('en'),
      aiService: FakeTranscriptionAi(),
      attachmentStore: _Copies(),
      notificationPermission: permission,
      keepAlive: keepAlive,
      (tester, db) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await pumpUntil(tester, find.text(l.startNewProject));
        await pumpFuture(tester, () => LocalProjectsRepository(db).create('Save project'));
        final settings = LocalSettingsRepository(db, _Copies());
        await pumpFuture(tester, () => settings.setAutoTranscribe(true));
        await saveVoiceFromAdd(tester, '/first.m4a');
        expect(permission.requests, askable ? 1 : 0);
        expect(find.text(l.trNotificationWhy), askable ? findsOneWidget : findsNothing);
        expect(await pumpFuture(tester, settings.readTranscriptionNotificationsAsked), askable);
        // Asked or not, the save went through and the recording was transcribed.
        expect(keepAlive.events, ['start 1', 'stop']);
        final rows = await pumpFuture(tester, () => db.select(db.noteAttachments).get());
        expect(rows.single.transcriptionStatus, TranscriptionStatus.done);

        await tester.pump(const Duration(seconds: 4)); // the toast leaves
        // Even if the system could ask again, the app does not.
        if (askable) permission.askable = true;
        await saveVoiceFromAdd(tester, '/second.m4a');
        expect(permission.requests, askable ? 1 : 0, reason: 'asked at most once');
        await tester.pump(const Duration(seconds: 4));
      },
    );
  }

  test('save policy ignores saved rows; attachment-only edit preserves transcript metadata', () async {
    final db = FikraDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final notes = LocalNotesRepository(db);
    final p = await LocalProjectsRepository(db).create('p');
    final draft = transcriptionDraft([
      const AttachmentDraft(kind: AttachmentKind.voice, path: '/new.m4a'),
      const AttachmentDraft(kind: AttachmentKind.image, path: '/photo.jpg', transcribe: true),
    ], automatic: true);
    expect(draft.map((a) => a.transcribe), [true, false]);
    final note = await notes.create(projectId: p.id, title: '', text: '', source: NoteSource.voice, attachments: draft);
    final first = (await notes.watchAttachments(note.id).first).first;
    await (db.update(db.noteAttachments)..where((a) => a.id.equals(first.id))).write(
      NoteAttachmentsCompanion(
        transcript: const Value('words'),
        transcriptNoteText: const Value('words'),
        transcriptionStatus: const Value(TranscriptionStatus.done),
        transcriptionEngine: const Value('local:model'),
        transcribedAt: Value(DateTime(2026, 11, 14)),
      ),
    );
    final before = await notes.watchAttachments(note.id).first;
    expect(before[0].transcriptionStatus, TranscriptionStatus.done);
    await notes.edit(
      note.id,
      title: '',
      text: '',
      attachments: transcriptionDraft(before.map(AttachmentDraft.saved).toList(), automatic: true),
    );
    expect(await notes.watchAttachments(note.id).first, before);
  });
}
