import 'package:drift/drift.dart' show Value;
import 'package:fikra/data/attachment_draft.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';

Future<({Note note, String attachmentId})> seedVoice2(
  WidgetTester tester,
  FikraDatabase db, {
  bool arabic = false,
  bool newer = false,
  bool unsafe = false,
}) => pumpFuture(tester, () async {
  final project = (await LocalProjectsRepository(db).watchProjects().first).single.project;
  final repo = LocalNotesRepository(db);
  final machine = arabic ? 'بكرة نراجع خطة المشروع مع بعض.' : 'Tomorrow we review the project plan together.';
  final correction = arabic ? 'بكرة نراجع خطة التطبيق مع بعض.' : 'Tomorrow we review the app plan together.';
  final note = await repo.create(
    projectId: project.id,
    title: arabic ? 'خطة بكرة' : 'Tomorrow’s plan',
    text: unsafe ? 'Changed copy' : 'Typed\n\n${newer ? correction : machine}',
    source: NoteSource.voice,
    attachments: [const AttachmentDraft(kind: AttachmentKind.voice, path: '/voice2.m4a', durationMs: 12000)],
  );
  final a = (await repo.watchAttachments(note.id).first).single;
  await (db.update(db.noteAttachments)..where((f) => f.id.equals(a.id))).write(
    NoteAttachmentsCompanion(
      transcript: Value(machine),
      transcriptNoteText: Value(newer ? correction : machine),
      transcriptCorrection: Value(newer ? correction : null),
      correctedAt: Value(newer ? DateTime(2026, 11, 16) : null),
      transcriptRevision: Value(newer ? 3 : 0),
      transcriptionStatus: const Value(TranscriptionStatus.done),
      transcriptionEngine: const Value('local:ggml-small-egy-cs-q5_1.bin'),
    ),
  );
  await repo.markReady(note.id);
  return (note: note, attachmentId: a.id);
});

Future<void> revealVoice2Sheet(WidgetTester tester, String key) async {
  final scrollable = find.descendant(
    of: find.byType(BottomSheet),
    matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down),
  );
  final target = find.byKey(ValueKey(key));
  await tester.scrollUntilVisible(target, 160, scrollable: scrollable);
  await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
  await tester.pump(const Duration(milliseconds: 600));
}
