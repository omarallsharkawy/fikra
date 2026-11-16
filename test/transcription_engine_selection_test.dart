import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:fikra/app/providers.dart';
import 'package:fikra/data/attachment_draft.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/processing/whisper_lock.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/data/transcription/service_config.dart';
import 'package:fikra/data/transcription/services_repository.dart';
import 'package:fikra/data/transcription/remote_request.dart';
import 'package:fikra/features/voice_text/voice_text_controller.dart';
import 'package:fikra/features/voice_text/voice_text_backend.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_external_transcription.dart';
import 'support/fake_transcription_engine.dart';
import 'voice_text/fake_voice_text_backend.dart';

void main() {
  late FikraDatabase db;
  late ProviderContainer container;
  late LocalTranscriptionServices services;
  late FakeTranscriptionTransport http;
  late WhisperLock lock;
  late Directory temp;
  late String path;
  setUp(() async {
    db = FikraDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    temp = await Directory.systemTemp.createTemp('fikra-remote-test-');
    addTearDown(() => temp.delete(recursive: true));
    path = (await File('${temp.path}/saved.m4a').writeAsBytes([1, 2, 3, 4])).path;
    http = FakeTranscriptionTransport();
    lock = WhisperLock();
    final keys = MemoryServiceKeys();
    services = LocalTranscriptionServices(db, keys);
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        transcriptionServicesProvider.overrideWithValue(services),
        transcriptionTransportProvider.overrideWithValue(http),
        whisperLockProvider.overrideWithValue(lock),
        transcriptionKeepAliveProvider.overrideWithValue(FakeTranscriptionKeepAlive()),
        aiServiceProvider.overrideWithValue(FakeTranscriptionAi()),
        localTranscriptionEngineProvider.overrideWithValue(() async => FakeTranscriptionEngine()),
      ],
    );
    addTearDown(container.dispose);
  });
  Future<Note> seed({int count = 1}) async {
    final project = await LocalProjectsRepository(db).create('project');
    return LocalNotesRepository(db).create(
      projectId: project.id,
      title: 'note',
      text: 'typed',
      source: NoteSource.voice,
      attachments: [
        for (var i = 0; i < count; i++)
          AttachmentDraft(kind: AttachmentKind.voice, path: path, policy: TranscriptionPolicy.afterSave),
      ],
    );
  }

  Future<void> select(TranscriptionService service, String key) async {
    await services.save(service, key: key);
    await services.authorize(service);
    await services.select(service.engineId);
  }

  test('factory resolves local by default, and current remote service after selection', () async {
    final factory = container.read(transcriptionEngineProvider);
    expect((await factory()).id, startsWith('local:'));
    final service = sampleService();
    await select(service, 'key');
    final engine = await factory();
    expect(engine.id, service.engineId);
    expect(await engine.transcribe(path, language: 'ar'), 'External transcript');
    expect(http.requests.single.headers['Authorization'], 'Bearer key');
  });

  test('queue remote work skips WhisperLock and uses the choice when each job starts', () async {
    final a = sampleService(id: 'one', url: 'https://one.example/v1');
    final b = sampleService(id: 'two', url: 'https://two.example/v1');
    await select(a, 'key-one');
    await services.save(b, key: 'key-two');
    await services.authorize(b);
    final note = await seed(count: 2);
    final attachments = await LocalNotesRepository(db).watchAttachments(note.id).first;
    final lease = lock.tryAcquire()!;
    addTearDown(lease.release);
    final started = Completer<void>();
    final release = Completer<RemoteResponse>();
    addTearDown(() {
      if (!release.isCompleted) release.complete(const RemoteResponse(200, '{"text":"cleanup"}'));
    });
    http.action = (_) async {
      if (http.requests.length == 1) {
        started.complete();
        return release.future;
      }
      return const RemoteResponse(200, '{"text":"second result"}');
    };
    final queue = container.read(transcriptionQueueProvider);
    await queue.enqueue(attachments[0].id);
    await started.future;
    await queue.enqueue(attachments[1].id);
    await services.select(b.engineId);
    release.complete(const RemoteResponse(200, '{"text":"first result"}'));
    await queue.drained.timeout(const Duration(seconds: 5));
    expect(lock.busy, isTrue); // The held local lease never blocked a remote job.
    expect(http.requests.map((r) => r.uri.host), ['one.example', 'two.example']);
    final results = await LocalNotesRepository(db).watchAttachments(note.id).first;
    expect(results.map((a) => a.transcriptionEngine), [a.engineId, b.engineId]);
    await container.read(noteProcessorProvider).retry(note.id); // Finish pending processor work before db.close.
  });

  test('Try it uses the selected remote service with no model or Whisper lease, and never prints text', () async {
    final s = sampleService();
    await select(s, 'key');
    final backend = FakeVoiceTextBackend()..clips = [SpikeRecording(path, 'aac_lc_m4a_64k_mono', 1)];
    final c = VoiceTextController(
      backend,
      settings: FakeVoiceTextSettings(),
      services: services,
      externalEngineFactory: container.read(transcriptionEngineProvider),
      whisperLock: lock,
      claimMicrophone: () => true,
      releaseMicrophone: () {},
    );
    addTearDown(c.dispose);
    await c.initialize();
    expect(c.downloaded, isFalse);
    expect(c.canTranscribe, isTrue);
    final lease = lock.tryAcquire()!;
    addTearDown(lease.release);
    final printed = <String>[];
    await runZoned(c.transcribe, zoneSpecification: ZoneSpecification(print: (_, _, _, line) => printed.add(line)));
    expect(backend.transcriptions, 0);
    expect(c.history.single['text'], 'External transcript');
    expect(c.history.single['engine_id'], s.engineId);
    expect(printed, isEmpty);
    await c.start(live: true);
    expect(c.phase, VoiceTextPhase.idle);
  });
}
