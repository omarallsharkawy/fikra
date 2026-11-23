import 'dart:async';
import 'dart:io';

import 'package:fikra/app/providers.dart';
import 'package:fikra/core/motion/motion.dart';
import 'package:fikra/core/motion/pressable.dart';
import 'package:fikra/core/widgets/fikra_widgets.dart';
import 'package:fikra/core/widgets/voice_player.dart';
import 'package:fikra/data/attachment_draft.dart';
import 'package:fikra/data/files/attachment_store.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/features/add/add_screen.dart';
import 'package:fikra/features/note_details/edit_note_screen.dart';
import 'package:fikra/features/shared/attachment_editor.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import 'support/app_harness.dart';
import 'support/recording_fake.dart';

class ReviewStore extends AttachmentStore {
  ReviewStore(this.directory) : super(documentsDir: () async => directory(), tempDir: () async => directory());
  final Directory Function() directory;
  int cleared = 0;
  @override
  Future<void> sweepOrphans(Set<String> referenced) async {}
  @override
  Future<void> clearPickerCopies() async {
    cleared++;
    final cache = Directory('${directory().path}/file_picker');
    if (await cache.exists()) await cache.delete(recursive: true);
  }
}

Future<void> waitFor(WidgetTester tester, bool Function() predicate) => pumpFuture(tester, () async {
  while (!predicate()) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
});

Future<void> play(WidgetTester tester, String path) async {
  final voice = find.byWidgetPredicate((w) => w is VoicePlayer && w.path == path);
  await Scrollable.ensureVisible(tester.element(voice), alignment: 0.5);
  await tester.pump(const Duration(milliseconds: 400));
  await tester.tap(find.descendant(of: voice, matching: find.byIcon(Icons.play_arrow_rounded)));
  await tester.pump();
}

void main() {
  late Directory directory;
  final events = <String>[];
  late RecordingFake recorder;
  final store = ReviewStore(() => directory);
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('fikra-review-');
    events.clear();
    store.cleared = 0;
    recorder = RecordingFake(events);
    final previous = RecordPlatform.instance;
    RecordPlatform.instance = recorder;
    addTearDown(() => RecordPlatform.instance = previous);
    addTearDown(() => directory.delete(recursive: true));
  });

  Future<Project> project(WidgetTester tester, FikraDatabase db) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final l10n = lookupAppLocalizations(tester.platformDispatcher.locale);
    await pumpUntil(tester, find.text(l10n.welcomeStartWriting));
    final p = await pumpFuture(tester, () => LocalProjectsRepository(db).create('project'));
    await pumpUntil(tester, find.text('project'));
    return p;
  }

  Future<AttachmentDraft> source(WidgetTester tester, AttachmentKind kind, String name) async {
    final file = await tester.runAsync(() => File('${directory.path}/$name').writeAsString('source'));
    return AttachmentDraft(
      kind: kind,
      path: file!.path,
      name: name,
      durationMs: kind == AttachmentKind.voice ? 1000 : null,
    );
  }

  Future<AttachmentEditing<AddScreen>> openAdd(WidgetTester tester) async {
    tester.element(find.text('project').first).go('/add');
    await pumpUntil(tester, find.byType(AddScreen));
    await tester.pumpAndSettle();
    return tester.state(find.byType(AddScreen)) as AttachmentEditing<AddScreen>;
  }

  Future<Note> saveAdd(WidgetTester tester, FikraDatabase db, Project p, List<AttachmentDraft> files) async {
    final before = await pumpFuture(tester, () => LocalNotesRepository(db).notesOf(p.id));
    final add = await openAdd(tester);
    add.updateDraft(() => add.draftFiles = files);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final save = find.byKey(const ValueKey('add-save'));
    await Scrollable.ensureVisible(tester.element(save), alignment: 0.5);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(save);
    await waitFor(tester, () => !add.saving);
    await tester.pump(FikraMotion.saveTick);
    final all = await pumpFuture(tester, () => LocalNotesRepository(db).notesOf(p.id));
    return all.singleWhere((n) => !before.any((old) => old.id == n.id));
  }

  Future<AttachmentEditing<EditNoteScreen>> openEdit(WidgetTester tester, Note n) async {
    final context = tester.element(find.byType(Scaffold).last);
    context.push('/note/${n.id}/edit');
    await pumpUntil(tester, find.byType(EditNoteScreen));
    await pumpUntil(tester, find.byKey(const ValueKey('add-mic')));
    await tester.pumpAndSettle();
    return tester.state(find.byType(EditNoteScreen)) as AttachmentEditing<EditNoteScreen>;
  }

  Future<void> removeSaved(WidgetTester tester, AttachmentEditing<EditNoteScreen> edit, AttachmentDraft a) async {
    final removed = edit.removeDraft(a);
    final l10n = lookupAppLocalizations(tester.platformDispatcher.locale);
    await pumpUntil(tester, find.text(l10n.removeAttachmentBody));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text(l10n.delete));
    await pumpFuture(tester, () => removed);
    await tester.pumpAndSettle();
  }

  Future<void> saveEdit(WidgetTester tester) async {
    final l10n = lookupAppLocalizations(tester.platformDispatcher.locale);
    final save = find.text(l10n.saveChanges).last;
    await Scrollable.ensureVisible(tester.element(save), alignment: 0.5);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(save);
  }

  for (final locale in [const Locale('ar'), const Locale('en')]) {
    for (final kind in AttachmentKind.values) {
      fikraTest(
        'Add restores ${kind.name} auto-title (${locale.languageCode})',
        locale: locale,
        attachmentStore: store,
        (tester, db) async {
          final p = await project(tester, db);
          final name = switch (kind) {
            AttachmentKind.pdf => 'lecture.pdf',
            AttachmentKind.voice => 'rec_123.m4a',
            AttachmentKind.image => 'camera.jpg',
          };
          final a = await source(tester, kind, name);
          final n = await saveAdd(tester, db, p, [a]);
          final l10n = lookupAppLocalizations(locale);
          expect(n.title, switch (kind) {
            AttachmentKind.pdf => 'lecture',
            AttachmentKind.voice => l10n.voiceRecording,
            AttachmentKind.image => l10n.photosTitle,
          });
        },
      );
    }
  }

  fikraTest('a real Add file-only note cannot become empty despite its auto-title', attachmentStore: store, (
    tester,
    db,
  ) async {
    final p = await project(tester, db);
    final n = await saveAdd(tester, db, p, [await source(tester, AttachmentKind.pdf, 'lecture.pdf')]);
    expect(n.title, 'lecture');
    final edit = await openEdit(tester, n);
    final a = edit.draftFiles.single;
    await removeSaved(tester, edit, a);
    await saveEdit(tester);
    final l10n = lookupAppLocalizations(tester.platformDispatcher.locale);
    await pumpUntil(tester, find.text(l10n.emptyNoteBlocked));
    expect(await pumpFuture(tester, () => LocalNotesRepository(db).watchAttachments(n.id).first), hasLength(1));
    expect(await tester.runAsync(() => File(a.path).exists()), isTrue);
  });

  for (final custom in [false, true]) {
    fikraTest('stale attachment auto-title retitles only an untouched title, custom=$custom', attachmentStore: store, (
      tester,
      db,
    ) async {
      final p = await project(tester, db);
      final n = await saveAdd(tester, db, p, [
        await source(tester, AttachmentKind.pdf, 'lecture.pdf'),
        await source(tester, AttachmentKind.voice, 'rec_next.m4a'),
      ]);
      final edit = await openEdit(tester, n);
      if (custom) {
        await tester.enterText(find.byType(TextField).first, 'My title');
      }
      await removeSaved(tester, edit, edit.draftFiles.first);
      await saveEdit(tester);
      await pumpUntil(tester, find.text(lookupAppLocalizations(tester.platformDispatcher.locale).changesSaved));
      final saved = (await pumpFuture(tester, () => LocalNotesRepository(db).watchNote(n.id).first))!;
      expect(
        saved.title,
        custom ? 'My title' : lookupAppLocalizations(tester.platformDispatcher.locale).voiceRecording,
      );
    });
  }

  fikraTest('explicitly typing the same auto-title keeps it when its file is removed', attachmentStore: store, (
    tester,
    db,
  ) async {
    final p = await project(tester, db);
    final n = await saveAdd(tester, db, p, [
      await source(tester, AttachmentKind.pdf, 'lecture.pdf'),
      await source(tester, AttachmentKind.image, 'photo.jpg'),
    ]);
    final edit = await openEdit(tester, n);
    await tester.enterText(find.byType(TextField).first, 'My lecture');
    await tester.enterText(find.byType(TextField).first, 'lecture');
    await removeSaved(tester, edit, edit.draftFiles.first);
    await saveEdit(tester);
    await pumpUntil(tester, find.text(lookupAppLocalizations(tester.platformDispatcher.locale).changesSaved));
    expect((await pumpFuture(tester, () => LocalNotesRepository(db).watchNote(n.id).first))!.title, 'lecture');
  });

  fikraTest('Edit Save preserves an offstage Add picker draft and its source file', attachmentStore: store, (
    tester,
    db,
  ) async {
    final p = await project(tester, db);
    final n = await saveAdd(tester, db, p, [await source(tester, AttachmentKind.pdf, 'saved.pdf')]);
    final add = await openAdd(tester);
    final cached = await tester.runAsync(() async {
      final f = File('${directory.path}/file_picker/draft.pdf');
      await f.parent.create(recursive: true);
      return f.writeAsString('draft');
    });
    add.updateDraft(
      () => add.draftFiles = [AttachmentDraft(kind: AttachmentKind.pdf, path: cached!.path, name: 'draft.pdf')],
    );
    await tester.pump();
    await openEdit(tester, n);
    await tester.enterText(find.byType(TextField).first, 'renamed');
    final before = store.cleared;
    await saveEdit(tester);
    await pumpUntil(tester, find.text(lookupAppLocalizations(tester.platformDispatcher.locale).changesSaved));
    expect(store.cleared, before);
    expect(await tester.runAsync(() => cached!.exists()), isTrue);
    await tester.pumpAndSettle();
    final save = find.byKey(const ValueKey('add-save'));
    await Scrollable.ensureVisible(tester.element(save), alignment: 0.5);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(save);
    await waitFor(tester, () => !add.saving);
    await tester.pump(FikraMotion.saveTick);
    final all = await pumpFuture(tester, () => LocalNotesRepository(db).notesOf(p.id));
    expect(all, hasLength(2));
    expect(all.any((n) => n.title == 'draft'), isTrue);
  });

  late CountingEdits edits;
  final editGate = Completer<void>();
  fikraTest(
    'double-tapping Edit Save commits only once',
    attachmentStore: store,
    notesRepository: (db) => edits = CountingEdits(db, editGate.future),
    (tester, db) async {
      final p = await project(tester, db);
      final n = await saveAdd(tester, db, p, [await source(tester, AttachmentKind.pdf, 'saved.pdf')]);
      await openEdit(tester, n);
      await tester.enterText(find.byType(TextField).first, 'new title');
      final l10n = lookupAppLocalizations(tester.platformDispatcher.locale);
      final save = find.text(l10n.saveChanges).last;
      await Scrollable.ensureVisible(tester.element(save), alignment: 0.5);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(save);
      await tester.tap(save);
      await waitFor(tester, () => edits.calls > 0);
      final calls = edits.calls;
      editGate.complete();
      // Drain attempted writes before asserting, so a regression cannot hide
      // behind teardown waiting on a transaction in fake time.
      await waitFor(tester, () => edits.completed == calls);
      expect(calls, 1);
      await pumpUntil(tester, find.text(l10n.changesSaved));
      expect(edits.calls, 1);
      expect((await pumpFuture(tester, () => LocalNotesRepository(db).watchAttachments(n.id).first)), hasLength(1));
    },
  );

  final playback = <String>[];
  fikraTest(
    'VoicePlayer allocates lazily, switches through the coordinator, and disposes played files',
    audioEvents: playback,
    (tester, db) async {
      playback.clear();
      final p = await project(tester, db);
      final repo = LocalNotesRepository(db);
      final n = await pumpFuture(
        tester,
        () => repo.create(
          projectId: p.id,
          title: 'voices',
          text: '',
          source: NoteSource.voice,
          attachments: const [
            AttachmentDraft(kind: AttachmentKind.voice, path: '/one.m4a'),
            AttachmentDraft(kind: AttachmentKind.voice, path: '/two.m4a'),
            AttachmentDraft(kind: AttachmentKind.voice, path: '/unused.m4a'),
          ],
        ),
      );
      tester.element(find.text('project').first).push('/note/${n.id}');
      await pumpUntil(tester, find.byType(VoicePlayer));
      await tester.pump(const Duration(milliseconds: 400));
      expect(playback.where((e) => e.startsWith('init:')), isEmpty);
      await play(tester, '/one.m4a');

      await waitFor(tester, () => playback.contains('play:/one.m4a'));
      await play(tester, '/two.m4a');
      await waitFor(tester, () => playback.contains('play:/two.m4a'));
      expect(playback.indexOf('pause:/one.m4a'), lessThan(playback.indexOf('play:/two.m4a')));
      expect(playback.where((e) => e.startsWith('init:')), hasLength(2));
      tester.element(find.byType(VoicePlayer).first).pop();
      await tester.pump(const Duration(milliseconds: 400));
      await waitFor(tester, () => playback.where((e) => e.startsWith('dispose:')).length == 2);
      expect(playback.any((e) => e.contains('unused.m4a')), isFalse);
    },
  );

  final pauseGate = Completer<void>();
  fikraTest(
    'recording waits for playback to stop; stopRecording adds the captured file',
    attachmentStore: store,
    audioEvents: events,
    pauseAudio: (_) => pauseGate.future,
    microphonePermission: () async => PermissionStatus.granted,
    (tester, db) async {
      await project(tester, db);
      final add = await openAdd(tester);
      final preview = await source(tester, AttachmentKind.voice, 'preview.m4a');
      add.updateDraft(() => add.draftFiles = [preview]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await play(tester, preview.path);
      await waitFor(tester, () => events.contains('play:${preview.path}'));
      final starting = add.startRecording();
      await waitFor(tester, () => events.contains('pause:${preview.path}'));
      expect(events.where((e) => e.startsWith('record:start:')), isEmpty);
      pauseGate.complete();
      await pumpFuture(tester, () => starting);
      expect(add.rec, RecordingState.recording);
      expect(
        events.indexOf('pause:${preview.path}'),
        lessThan(events.indexWhere((e) => e.startsWith('record:start:'))),
      );
      await tester.pump(const Duration(seconds: 2));
      await pumpFuture(tester, add.stopRecording);
      expect(add.draftFiles, hasLength(2));
      expect(add.draftFiles.last.path, recorder.paths.values.single);
      expect(add.draftFiles.last.durationMs, greaterThanOrEqualTo(2000));
      expect(await tester.runAsync(() => File(add.draftFiles.last.path).exists()), isTrue);
      final container = ProviderScope.containerOf(tester.element(find.byType(AddScreen)));
      expect(container.read(recordingActiveProvider), isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  fikraTest(
    'Add and Edit share one microphone; busy Cancel is disabled and temporary removal skips confirmation',
    attachmentStore: store,
    microphonePermission: () async => PermissionStatus.granted,
    (tester, db) async {
      final p = await project(tester, db);
      final n = await pumpFuture(
        tester,
        () => LocalNotesRepository(db).create(projectId: p.id, title: 'note', text: 'body', source: NoteSource.text),
      );
      final add = await openAdd(tester);
      await pumpFuture(tester, add.startRecording);
      final edit = await openEdit(tester, n);
      final mic = find.descendant(of: find.byKey(const ValueKey('add-mic')), matching: find.byType(Pressable));
      expect(tester.widget<Pressable>(mic).onTap, isNull);
      await pumpFuture(tester, edit.startRecording);
      expect(recorder.paths, hasLength(1));
      await pumpFuture(tester, add.cancelRecording);
      await pumpFuture(tester, edit.startRecording);
      expect(recorder.maxActive, 1);
      final l10n = lookupAppLocalizations(tester.platformDispatcher.locale);
      FikraButton cancel() =>
          tester.widget<FikraButton>(find.ancestor(of: find.text(l10n.cancel), matching: find.byType(FikraButton)));
      await tester.pump();
      expect(cancel().onPressed, isNull);
      await pumpFuture(tester, edit.stopRecording);
      edit.updateDraft(() => edit.picking = true);
      await tester.pump();
      expect(cancel().onPressed, isNull);
      edit.updateDraft(() => edit.picking = false);
      final path = edit.draftFiles.single.path;
      await tester.pump();
      final remove = find.bySemanticsLabel(l10n.deleteRecording);
      await Scrollable.ensureVisible(tester.element(remove), alignment: 0.5);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(remove);
      await waitFor(tester, () => edit.draftFiles.isEmpty);
      await waitFor(tester, () => !File(path).existsSync());
      expect(find.text(l10n.removeAttachmentBody), findsNothing);
      expect(edit.draftFiles, isEmpty);
      expect(await tester.runAsync(() => File(path).exists()), isFalse);
    },
  );
}

class CountingEdits extends LocalNotesRepository {
  CountingEdits(super.db, this.gate);
  final Future<void> gate;
  int calls = 0;
  int completed = 0;
  @override
  Future<void> edit(
    String id, {
    required String title,
    required String text,
    List<AttachmentDraft>? attachments,
    NoteEditBasis? basis,
  }) async {
    calls++;
    await gate;
    try {
      await super.edit(id, title: title, text: text, attachments: attachments, basis: basis);
    } finally {
      completed++;
    }
  }
}
