@Tags(['screenshots'])
library;

import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:fikra/data/attachment_draft.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/features/add/add_screen.dart';
import 'package:fikra/features/note_details/note_details_screen.dart';
import 'package:fikra/features/shared/attachment_editor.dart';
import 'package:fikra/features/voice_text/voice_text_screen.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/app_harness.dart';
import '../support/transcription_scroll.dart';
import '../voice_text/fake_voice_text_backend.dart';

void main() {
  setUpAll(loadAppFonts);
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    for (final brightness in [Brightness.dark, Brightness.light]) {
      final backend = FakeVoiceTextBackend()..egyptianFilePresent = true;
      fikraTest(
        'saved voice transcription (${locale.languageCode}, ${brightness.name})',
        tags: 'screenshots',
        locale: locale,
        brightness: brightness,
        voiceTextBackend: backend,
        (tester, db) async {
          addTearDown(() => unawaited(backend.dispose()));
          tester.view.devicePixelRatio = 3;
          tester.view.physicalSize = const Size(390 * 3, 844 * 3);
          tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
          tester.view.viewPadding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
          addTearDown(tester.view.reset);
          final l = lookupAppLocalizations(locale);
          final ar = locale.languageCode == 'ar';
          Future<void> capture(String name) async {
            await tester.pump(const Duration(milliseconds: 600));
            expect(tester.takeException(), isNull);
            await saveScreenshot(tester, '${locale.languageCode}/${brightness.name}/transcription_$name');
          }

          await pumpUntil(tester, find.text(l.startNewProject));
          final fixture = await pumpFuture(tester, () async {
            final p = await LocalProjectsRepository(db).create(ar ? 'أفكار صوتية' : 'Voice ideas');
            final repo = LocalNotesRepository(db);
            final n = await repo.create(
              projectId: p.id,
              title: ar ? 'أفكار للمشروع' : 'Project ideas',
              text: ar ? 'نرجع للأفكار دي بكرة.' : 'Come back to these ideas tomorrow.',
              source: NoteSource.voice,
              attachments: [
                const AttachmentDraft(kind: AttachmentKind.voice, path: '/screenshot-voice.m4a', durationMs: 92000),
              ],
            );
            await repo.markReady(n.id);
            final a = (await repo.watchAttachments(n.id).first).single;
            await (db.update(db.noteAttachments)..where((f) => f.id.equals(a.id))).write(
              NoteAttachmentsCompanion(
                transcriptionStatus: const Value(TranscriptionStatus.done),
                transcript: Value(
                  ar
                      ? 'بكرة نبدأ بأبسط نسخة من المشروع.\nنجرّبها على الموبايل ونسجّل اللي ناقص.\nوبعدين نراجع الأفكار مع بعض.\nالمهم نبدأ بحاجة صغيرة ونحسّنها واحدة واحدة.'
                      : 'Tomorrow we start with a simple version.\nTry it on the phone and write down what is missing.\nThen we review the ideas together.\nStart small and improve it step by step.',
                ),
                transcriptionEngine: const Value('local:ggml-small-egy-cs-q5_1.bin'),
              ),
            );
            return (note: n, attachment: a, project: p);
          });
          await pumpUntil(tester, find.text(fixture.project.name));
          tester.element(find.text(fixture.project.name)).push('/note/${fixture.note.id}');
          await pumpUntil(tester, find.byType(NoteDetailsScreen));
          await revealTranscription(tester, NoteDetailsScreen, ValueKey('transcript-${fixture.attachment.id}'));
          await capture('details');
          await tester.tap(find.byKey(ValueKey('transcript-expand-${fixture.attachment.id}')));
          await capture('details_expanded');
          await pumpFuture(
            tester,
            () => (db.update(db.noteAttachments)..where((a) => a.id.equals(fixture.attachment.id))).write(
              const NoteAttachmentsCompanion(
                transcript: Value(null),
                transcriptionEngine: Value(null),
                transcriptionStatus: Value(TranscriptionStatus.failed),
                transcriptionFailure: Value('modelMissing'),
              ),
            ),
          );
          await revealTranscription(tester, NoteDetailsScreen, ValueKey('transcript-${fixture.attachment.id}'));
          await capture('failure');
          tester.element(find.byType(NoteDetailsScreen)).pop();
          await tester.pump(const Duration(milliseconds: 600));
          await tester.tap(Tabs.addButton);
          await pumpUntil(tester, find.byType(AddScreen));
          final editor = tester.state(find.byType(AddScreen)) as AttachmentEditing<AddScreen>;
          editor.updateDraft(
            () => editor.draftFiles = [
              const AttachmentDraft(kind: AttachmentKind.voice, path: '/screenshot-draft.m4a', durationMs: 15000),
            ],
          );
          await tester.pump();
          await revealTranscription(tester, AddScreen, const ValueKey('transcribe-draft-/screenshot-draft.m4a'));
          await tester.tap(find.byKey(const ValueKey('transcribe-draft-/screenshot-draft.m4a')));
          await capture('draft_toggle');
          tester.element(find.byType(AddScreen)).push('/settings/voice-text');
          await pumpUntil(tester, find.byType(VoiceTextScreen));
          await pumpUntil(tester, find.text(l.vtEgyptianHint));
          await revealTranscription(tester, VoiceTextScreen, const ValueKey('vt-auto-transcribe'));
          await capture('auto_off');
          await tester.tap(find.byKey(const ValueKey('vt-auto-transcribe')));
          await capture('auto_on');
        },
      );
    }
  }
}
