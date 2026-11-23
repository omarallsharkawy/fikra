import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:fikra/core/format.dart';
import 'package:fikra/data/attachment_draft.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/data/transcription/service_config.dart';
import 'package:fikra/data/transcription/services_repository.dart';
import 'package:fikra/features/note_details/note_details_screen.dart';
import 'package:fikra/features/settings/settings_screen.dart';
import 'package:fikra/features/voice_text/service_copy.dart';
import 'package:fikra/features/voice_text/service_form_screen.dart';
import 'package:fikra/features/voice_text/voice_text_screen.dart';
import 'package:fikra/data/processing/transcription_engine.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/app_harness.dart';
import 'support/external_service_fixture.dart';
import 'support/fake_external_transcription.dart';
import 'support/transcription_scroll.dart';
import 'voice_text/fake_voice_text_backend.dart';

void main() {
  const locale = Locale('en');
  final l = lookupAppLocalizations(locale);
  final keys = MemoryServiceKeys(), http = FakeTranscriptionTransport();
  final backend = FakeVoiceTextBackend();
  fikraTest(
    'connection test asks before upload, saves consent once and keeps key obscured',
    locale: locale,
    serviceKeys: keys,
    transcriptionTransport: http,
    voiceTextBackend: backend,
    (tester, db) async {
      addTearDown(() => unawaited(backend.dispose()));
      await seedExternalProject(tester, db, locale);
      await openExternalSettings(tester);
      await revealTranscription(tester, VoiceTextScreen, const ValueKey('vs-add'));
      await tester.tap(find.byKey(const ValueKey('vs-add')));
      await pumpUntil(tester, find.byType(ServiceFormScreen));
      await serviceField(tester, 'vs-name', 'Owner service');
      await serviceField(tester, 'vs-key', 'synthetic-key');
      final field = find.descendant(of: find.byKey(const ValueKey('vs-key')), matching: find.byType(TextField));
      expect(tester.widget<TextField>(field).obscureText, isTrue);
      await serviceFormAction(tester, 'vs-key-visibility');
      expect(tester.widget<TextField>(field).obscureText, isFalse);
      await serviceFormAction(tester, 'vs-key-visibility');
      await serviceFormAction(tester, 'vs-test');
      expect(find.byType(Dialog), findsOneWidget);
      expect(http.requests, isEmpty);
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text(l.cancel)));
      await tester.pump(const Duration(milliseconds: 600));
      expect(http.requests, isEmpty);
      await serviceFormAction(tester, 'vs-test');
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text(l.vsConsentConfirm)));
      await pumpUntil(tester, find.byKey(const ValueKey('vs-connected')));
      expect(http.requests, hasLength(1));
      expect(http.requests.single.audio!.length, 32044);
      await serviceFormAction(tester, 'vs-test');
      await pumpUntil(tester, find.byKey(const ValueKey('vs-connected')));
      expect(find.byType(Dialog), findsNothing);
      expect(http.requests, hasLength(2));
      await serviceFormAction(tester, 'vs-save');
      await pumpUntil(tester, find.byType(VoiceTextScreen));
      final repo = LocalTranscriptionServices(db, keys);
      final saved = (await pumpFuture(tester, repo.read)).services.single;
      expect(saved.consented, isTrue);
      final state = await pumpFuture(tester, repo.read);
      expect(keys.values[state.credentials[saved.id]!.slot], 'synthetic-key');
      await tapEngine(tester, saved.id);
      expect(find.byType(Dialog), findsNothing);
      expect((await pumpFuture(tester, repo.read)).selected, saved.engineId);
    },
  );

  final selectionKeys = MemoryServiceKeys();
  final selectionHttp = FakeTranscriptionTransport();
  final selectionBackend = FakeVoiceTextBackend();
  fikraTest(
    'engine consent once, truthful Settings line and source retained after delete',
    locale: locale,
    serviceKeys: selectionKeys,
    transcriptionTransport: selectionHttp,
    voiceTextBackend: selectionBackend,
    (tester, db) async {
      addTearDown(() => unawaited(selectionBackend.dispose()));
      await seedExternalProject(tester, db, locale);
      final repo = LocalTranscriptionServices(db, selectionKeys);
      final service = sampleService(name: 'My Groq');
      await pumpFuture(tester, () => repo.save(service, key: 'key'));
      await openExternalSettings(tester);
      await tapEngine(tester, service.id);
      expect(find.text(l.vsConsentTitle(Fmt.isolate(service.name))), findsOneWidget);
      expect(selectionHttp.requests, isEmpty);
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text(l.cancel)));
      await tester.pump(const Duration(milliseconds: 600));
      expect((await pumpFuture(tester, repo.read)).selected, 'local');
      await tapEngine(tester, service.id);
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text(l.vsConsentConfirm)));
      await pumpFuture(tester, () async {
        while ((await repo.read()).selected != service.engineId) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      await tapEngine(tester, 'local');
      await tapEngine(tester, service.id);
      expect(find.byType(Dialog), findsNothing);
      expect(selectionHttp.requests, isEmpty);
      tester.element(find.byType(VoiceTextScreen)).pop();
      await tester.pump(const Duration(milliseconds: 600));
      tester.element(find.text(externalProject)).push('/settings');
      await pumpUntil(tester, find.byType(SettingsScreen));
      await revealTranscription(tester, SettingsScreen, const ValueKey('settings-data-location'));
      expect(find.text(l.vsRemoteData(Fmt.isolate(service.name))), findsOneWidget);
      expect(find.text(l.dataStaysLocal), findsNothing);
      await pumpFuture(tester, () => repo.delete(service.id));
      await pumpUntil(tester, find.text(l.dataStaysLocal));
      tester.element(find.byType(SettingsScreen)).pop();
      await tester.pump(const Duration(milliseconds: 600));
      final fixture = await pumpFuture(tester, () async {
        final project = (await LocalProjectsRepository(db).watchProjects().first).single.project;
        final notes = LocalNotesRepository(db);
        final note = await notes.create(
          projectId: project.id,
          title: 'Remote note',
          text: 'typed',
          source: NoteSource.voice,
          attachments: [const AttachmentDraft(kind: AttachmentKind.voice, path: '/remote.m4a')],
        );
        final a = (await notes.watchAttachments(note.id).first).single;
        await (db.update(db.noteAttachments)..where((v) => v.id.equals(a.id))).write(
          NoteAttachmentsCompanion(
            transcript: const Value('spoken text'),
            transcriptionStatus: const Value(TranscriptionStatus.done),
            transcriptionEngine: Value(service.engineId),
          ),
        );
        await notes.markReady(note.id);
        return (note: note, id: a.id);
      });
      tester.element(find.text(externalProject)).push('/note/${fixture.note.id}');
      await pumpUntil(tester, find.byType(NoteDetailsScreen));
      await revealTranscription(tester, NoteDetailsScreen, ValueKey('transcript-engine-${fixture.id}'));
      expect(find.text(l.vsVia(Fmt.isolate(service.name))), findsOneWidget);
    },
  );

  final invalidBackend = FakeVoiceTextBackend();
  final invalidHttp = FakeTranscriptionTransport();
  fikraTest(
    'forms show LAN warning, reject public HTTP and support Qwen regions',
    locale: locale,
    voiceTextBackend: invalidBackend,
    transcriptionTransport: invalidHttp,
    (tester, db) async {
      addTearDown(() => unawaited(invalidBackend.dispose()));
      await seedExternalProject(tester, db, locale);
      await openExternalSettings(tester);
      await revealTranscription(tester, VoiceTextScreen, const ValueKey('vs-add'));
      await tester.tap(find.byKey(const ValueKey('vs-add')));
      await pumpUntil(tester, find.byType(ServiceFormScreen));
      await serviceField(tester, 'vs-url', 'http://192.168.1.3:8080/v1');
      expect(find.text(l.vsHttpWarning), findsOneWidget);
      await serviceField(tester, 'vs-url', 'http://public.example/v1');
      await serviceField(tester, 'vs-key', 'key');
      await serviceFormAction(tester, 'vs-save');
      expect(find.text(l.vsInvalidUrl), findsWidgets);
      expect(invalidHttp.requests, isEmpty);
      await serviceType(tester, TranscriptionServiceType.qwen);
      await serviceFormAction(tester, 'vs-mainland');
      final url = find.descendant(of: find.byKey(const ValueKey('vs-url')), matching: find.byType(TextField));
      expect(tester.widget<TextField>(url).controller!.text, qwenMainlandUrl);
    },
  );

  final deleteKeys = MemoryServiceKeys();
  final deleteBackend = FakeVoiceTextBackend();
  fikraTest(
    'editing a partial URL stays usable; delete confirms and removes the selected service key',
    locale: locale,
    serviceKeys: deleteKeys,
    voiceTextBackend: deleteBackend,
    (tester, db) async {
      addTearDown(() => unawaited(deleteBackend.dispose()));
      await seedExternalProject(tester, db, locale);
      final repo = LocalTranscriptionServices(db, deleteKeys);
      final s = sampleService(consent: true);
      await pumpFuture(tester, () async {
        await repo.save(s, key: 'key');
        await repo.select(s.engineId);
      });
      await openExternalSettings(tester);
      await revealTranscription(tester, VoiceTextScreen, ValueKey('vs-edit-${s.id}'));
      await tester.tap(find.byKey(ValueKey('vs-edit-${s.id}')));
      await pumpUntil(tester, find.byType(ServiceFormScreen));
      await serviceField(tester, 'vs-url', 'http');
      expect(tester.takeException(), isNull);
      await serviceField(tester, 'vs-url', s.baseUrl);
      await serviceFormAction(tester, 'vs-delete');
      expect(find.text(l.vsDeleteTitle), findsOneWidget);
      expect(deleteKeys.values, isNotEmpty);
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text(l.delete)));
      await pumpUntil(tester, find.byType(VoiceTextScreen));
      expect((await pumpFuture(tester, repo.read)).selected, 'local');
      expect(deleteKeys.values, isEmpty);
    },
  );

  for (final reason in [
    TranscriptionFailureReason.offline,
    TranscriptionFailureReason.keyRejected,
    TranscriptionFailureReason.rateLimited,
    TranscriptionFailureReason.tooLarge,
    TranscriptionFailureReason.serviceError,
    TranscriptionFailureReason.unexpectedResponse,
    TranscriptionFailureReason.remoteTimeout,
    TranscriptionFailureReason.consentRequired,
  ]) {
    fikraTest('details explains ${reason.name} with retry and voice settings', locale: locale, (tester, db) async {
      await seedExternalProject(tester, db, locale);
      final fixture = await pumpFuture(tester, () async {
        final notes = LocalNotesRepository(db);
        final project = (await LocalProjectsRepository(db).watchProjects().first).single.project;
        final note = await notes.create(
          projectId: project.id,
          title: 'Failed remote',
          text: 'typed',
          source: NoteSource.voice,
          attachments: [const AttachmentDraft(kind: AttachmentKind.voice, path: '/missing.m4a')],
        );
        await notes.markReady(note.id);
        final a = (await notes.watchAttachments(note.id).first).single;
        await (db.update(db.noteAttachments)..where((v) => v.id.equals(a.id))).write(
          NoteAttachmentsCompanion(
            transcriptionStatus: const Value(TranscriptionStatus.failed),
            transcriptionFailure: Value(reason.name),
          ),
        );
        return (note: note, id: a.id);
      });
      tester.element(find.text(externalProject)).push('/note/${fixture.note.id}');
      await pumpUntil(tester, find.byType(NoteDetailsScreen));
      await revealTranscription(tester, NoteDetailsScreen, ValueKey('transcript-settings-${fixture.id}'));
      expect(find.text(transcriptionFailureMessage(l, reason)), findsOneWidget);
      expect(find.byKey(ValueKey('transcribe-${fixture.id}')), findsOneWidget);
    });
  }
}
