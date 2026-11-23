import 'package:fikra/data/attachment_draft.dart';

import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:fikra/data/files/attachment_store.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/data/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_external_transcription.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late FikraDatabase db;
  late LocalSettingsRepository settings;
  late Directory docs;
  late Directory temp;

  setUp(() async {
    db = FikraDatabase(NativeDatabase.memory());
    docs = await Directory.systemTemp.createTemp('fikra_docs');
    temp = await Directory.systemTemp.createTemp('fikra_tmp');
    settings = LocalSettingsRepository(
      db,
      AttachmentStore(documentsDir: () async => docs, tempDir: () async => temp),
      transcriptionServices: MemoryTranscriptionServices(),
    );
  });
  tearDown(() async {
    await db.close();
    await docs.delete(recursive: true);
    await temp.delete(recursive: true);
  });

  test('theme defaults to system and persists the choice', () async {
    expect(await settings.watchTheme().first, AppTheme.system);
    await settings.setTheme(AppTheme.light);
    expect(await settings.watchTheme().first, AppTheme.light);
    await settings.setTheme(AppTheme.system);
    expect(await settings.watchTheme().first, AppTheme.system);
  });

  test('language defaults to system, persists, and unknown values fall back', () async {
    expect(await settings.watchLanguage().first, AppLanguage.system);
    await settings.setLanguage(AppLanguage.en);
    final reopened = LocalSettingsRepository(db, AttachmentStore());
    expect(await reopened.watchLanguage().first, AppLanguage.en);
    await settings.setLanguage(AppLanguage.ar);
    expect(await reopened.watchLanguage().first, AppLanguage.ar);
    await settings.setLanguage(AppLanguage.system);
    expect(await reopened.watchLanguage().first, AppLanguage.system);
    expect(await (db.select(db.settings)..where((s) => s.key.equals('language'))).get(), isEmpty);
    await db.into(db.settings).insertOnConflictUpdate(const Setting(key: 'language', value: 'unknown'));
    expect(await reopened.watchLanguage().first, AppLanguage.system);
  });

  test('voice choices persist independently of UI language and survive reopening', () async {
    expect(await settings.readVoiceTextChoices(), (modelName: null, language: null));
    await settings.setVoiceTextModel('small-egy-cs-q5_1');
    await settings.setVoiceTextLanguage('auto');
    final reopened = LocalSettingsRepository(db, AttachmentStore());
    expect(await reopened.readVoiceTextChoices(), (modelName: 'small-egy-cs-q5_1', language: 'auto'));
    expect(await reopened.watchLanguage().first, AppLanguage.system);
    await settings.setVoiceTextModel('base-q5_1');
    await settings.setVoiceTextLanguage('en');
    expect(await reopened.readVoiceTextChoices(), (modelName: 'base-q5_1', language: 'en'));
    expect(() => settings.setVoiceTextLanguage('unknown'), throwsArgumentError);
  });

  test('automatic transcription defaults off, persists and can be turned off', () async {
    expect(await settings.readAutoTranscribe(), isFalse);
    await settings.setAutoTranscribe(true);
    final reopened = LocalSettingsRepository(db, AttachmentStore());
    expect(await reopened.readAutoTranscribe(), isTrue);
    await reopened.setAutoTranscribe(false);
    expect(await settings.readAutoTranscribe(), isFalse);
  });

  test('wipe removes all data and files but keeps the theme', () async {
    final projects = LocalProjectsRepository(db);
    final notes = LocalNotesRepository(db);
    final chat = LocalChatRepository(db);
    await Directory('${docs.path}/attachments').create();
    final file = await File('${docs.path}/attachments/a.m4a').writeAsString('x');
    final orphan = await File('${docs.path}/attachments/orphan.pdf').writeAsString('x');
    final draft = await File('${temp.path}/${AttachmentStore.recordingPrefix}1.m4a').writeAsString('x');
    final unrelated = await File('${temp.path}/other.txt').writeAsString('x');

    await settings.setTheme(AppTheme.dark);
    await settings.setAutoTranscribe(true);
    await settings.setVoiceTextModel('small-egy-cs-q5_1');
    await settings.setVoiceTextLanguage('ar');
    await settings.setLanguage(AppLanguage.en);
    final p = await projects.create('p');
    await notes.create(
      projectId: p.id,
      title: 't',
      text: 'x',
      source: NoteSource.voice,
      attachments: [AttachmentDraft(kind: AttachmentKind.voice, path: file.path)],
    );
    await chat.add(projectId: p.id, role: 'user', body: 'q');

    await settings.wipeAllData();

    expect(await projects.watchProjects().first, isEmpty);
    expect(await projects.watchCurrentId().first, isNull);
    expect(await notes.notesWithStatus(ProcessingStatus.processing), isEmpty);
    expect(await chat.watch(p.id).first, isEmpty);
    expect(file.existsSync(), isFalse);
    expect(orphan.existsSync(), isFalse);
    expect(draft.existsSync(), isFalse);
    expect(unrelated.existsSync(), isTrue);
    expect(await settings.watchTheme().first, AppTheme.dark);
    expect(await settings.readAutoTranscribe(), isTrue);
    expect(await settings.readVoiceTextChoices(), (modelName: 'small-egy-cs-q5_1', language: 'ar'));
    expect(await settings.watchLanguage().first, AppLanguage.en);
  });
}
