import 'dart:async';

import 'package:fikra/data/attachment_draft.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/features/note_details/edit_note_screen.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/app_harness.dart';
import 'support/fake_transcription_engine.dart';
import 'support/transcription_scroll.dart';

class _GatedEdit extends LocalNotesRepository {
  _GatedEdit(super.db);
  final started = Completer<void>(), proceed = Completer<void>(), finished = Completer<void>();
  NoteEditBasis? receivedBasis;
  @override
  Future<void> edit(
    String id, {
    required String title,
    required String text,
    List<AttachmentDraft>? attachments,
    NoteEditBasis? basis,
  }) async {
    receivedBasis = basis;
    started.complete();
    await proceed.future;
    try {
      await super.edit(id, title: title, text: text, attachments: attachments, basis: basis);
    } finally {
      finished.complete();
    }
  }
}

void main() {
  late _GatedEdit repo;
  const locale = Locale('en');
  final l = lookupAppLocalizations(locale);
  fikraTest(
    'edit conflict retains the submitted draft and keeps the editor open',
    locale: locale,
    aiService: FakeTranscriptionAi(),
    notesRepository: (db) => repo = _GatedEdit(db),
    (tester, db) async {
      addTearDown(() {
        if (!repo.proceed.isCompleted) repo.proceed.complete();
      });
      await pumpUntil(tester, find.text(l.welcomeStartWriting));
      final p = await pumpFuture(tester, () => LocalProjectsRepository(db).create('Edit project'));
      final n = await pumpFuture(
        tester,
        () => repo.create(projectId: p.id, title: 'Title', text: 'Base body', source: NoteSource.text),
      );
      await pumpUntil(tester, find.text('Edit project'));
      tester.element(find.text('Edit project')).push('/note/${n.id}/edit');
      final body = find.descendant(
        of: find.byType(EditNoteScreen),
        matching: find.byWidgetPredicate((w) => w is TextField && w.maxLines == 20),
      );
      await pumpUntil(tester, body);
      await tester.enterText(body, 'My retained draft');
      final save = find.text(l.saveChanges);
      await tester.scrollUntilVisible(save, 160, scrollable: transcriptionScrollable(EditNoteScreen));
      await Scrollable.ensureVisible(tester.element(save), alignment: .5);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(save);
      await pumpFuture(tester, () => repo.started.future);
      expect(repo.receivedBasis?.note.displayText, 'Base body');
      await pumpFuture(tester, () => LocalNotesRepository(db).edit(n.id, title: 'Title', text: 'Other edit'));
      repo.proceed.complete();
      await pumpFuture(tester, () => repo.finished.future);
      await pumpUntil(tester, find.text(l.changesSaveFailed));
      expect(find.byType(EditNoteScreen), findsOneWidget);
      await tester.scrollUntilVisible(body, -160, scrollable: transcriptionScrollable(EditNoteScreen));
      expect(tester.widget<TextField>(body).controller!.text, 'My retained draft');
      expect((await pumpFuture(tester, () => repo.watchNote(n.id).first))!.displayText, 'Other edit');
    },
  );
}
