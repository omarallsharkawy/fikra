@Tags(['screenshots'])
library;

import 'dart:async';

import 'package:fikra/data/attachment_draft.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/transcription/services_repository.dart';
import 'package:fikra/features/add/add_screen.dart';
import 'package:fikra/features/note_details/note_details_screen.dart';
import 'package:fikra/features/note_details/transcript_editor_screen.dart';
import 'package:fikra/features/shared/attachment_editor.dart';
import 'package:fikra/features/voice_text/service_form_screen.dart';
import 'package:fikra/features/voice_text/voice_text_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/app_harness.dart';
import '../support/external_service_fixture.dart';
import '../support/fake_external_transcription.dart';
import '../support/transcription_scroll.dart';
import '../support/voice2_fixture.dart';
import '../voice_text/fake_voice_text_backend.dart';

void main() {
  setUpAll(loadAppFonts);
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    for (final brightness in [Brightness.dark, Brightness.light]) {
      final backend = FakeVoiceTextBackend(), keys = MemoryServiceKeys();
      fikraTest(
        'voice2a ${locale.languageCode} ${brightness.name}',
        tags: 'screenshots',
        locale: locale,
        brightness: brightness,
        voiceTextBackend: backend,
        serviceKeys: keys,
        (tester, db) async {
          addTearDown(() => unawaited(backend.dispose()));
          await seedExternalProject(tester, db, locale);
          tester.view.devicePixelRatio = 3;
          tester.view.physicalSize = const Size(390 * 3, 844 * 3);
          tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
          tester.view.viewPadding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
          Future<void> capture(String name) async {
            await tester.pump(const Duration(milliseconds: 600));
            expect(tester.takeException(), isNull);
            await saveScreenshot(tester, '${locale.languageCode}/${brightness.name}/voice2_$name');
          }

          final f = await seedVoice2(tester, db, arabic: locale.languageCode == 'ar', newer: true);
          tester.element(find.text(externalProject)).push('/note/${f.note.id}');
          await pumpUntil(tester, find.byType(NoteDetailsScreen));
          await revealTranscription(tester, NoteDetailsScreen, ValueKey('transcript-new-${f.attachmentId}'));
          await capture('new_transcript');
          await revealTranscription(tester, NoteDetailsScreen, ValueKey('transcript-edit-${f.attachmentId}'));
          await tester.tap(find.byKey(ValueKey('transcript-edit-${f.attachmentId}')));
          await pumpUntil(tester, find.byType(TranscriptEditorScreen));
          await capture('editor');
          tester.element(find.byType(TranscriptEditorScreen)).pop();
          // The editor allows the pop on the next frame; wait for its route to finish leaving.
          for (var i = 0; i < 60 && find.byType(TranscriptEditorScreen).evaluate().isNotEmpty; i++) {
            await tester.pump(const Duration(milliseconds: 50));
          }
          expect(find.byType(TranscriptEditorScreen), findsNothing);
          tester.element(find.byType(NoteDetailsScreen)).pop();
          await tester.pump(const Duration(milliseconds: 600));
          await tester.tap(Tabs.finder(Tabs.add));
          await pumpUntil(tester, find.byType(AddScreen));
          final editor = tester.state(find.byType(AddScreen)) as AttachmentEditing<AddScreen>;
          editor.updateDraft(
            () => editor.draftFiles = [
              const AttachmentDraft(
                kind: AttachmentKind.voice,
                path: '/voice2-draft.m4a',
                durationMs: 12000,
                policy: TranscriptionPolicy.off,
              ),
            ],
          );
          await tester.pump();
          await revealTranscription(tester, AddScreen, const ValueKey('transcribe-off-/voice2-draft.m4a'));
          await capture('recording_choice');
          final s = sampleService(consent: true);
          await pumpFuture(tester, () => LocalTranscriptionServices(db, keys).save(s, key: 'fake'));
          tester.element(find.byType(AddScreen)).push('/settings/voice-text');
          await pumpUntil(tester, find.byType(VoiceTextScreen));
          await revealTranscription(tester, VoiceTextScreen, ValueKey('vs-edit-${s.id}'));
          await tester.tap(find.byKey(ValueKey('vs-edit-${s.id}')));
          await pumpUntil(tester, find.byType(ServiceFormScreen));
          await serviceFormAction(tester, 'vs-model');
          await tester.pump(const Duration(milliseconds: 600));
          await capture('model_picker');
        },
      );
    }
  }
}
