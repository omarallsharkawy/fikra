import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fikra/data/product/local_ui_store.dart';
import 'package:fikra/data/product/models.dart';
import 'package:fikra/data/product/development/development_auth.dart';
import 'package:fikra/data/product/development/development_knowledge.dart';
import 'package:fikra/features/workspace/workspace_controller.dart';
import 'package:fikra/features/capture/capture_controller.dart';

import 'controller_test.dart' show TestCaptureDevice, UncertainCreate;

class FailingDraftStore extends MemoryLocalUiStore {
  bool fail = false;
  @override
  Future<void> writeValue(String key, String value) async {
    if (fail) throw StateError('test-only storage failure');
    await super.writeValue(key, value);
  }
}

class HeldTranscript extends DevelopmentKnowledgeRepository {
  final response = Completer<String>();
  @override
  Future<String> transcribe(String accountId, RecordedClip clip) => response.future;
}

void main() {
  test('durable drafts restore by account and project without creating notes', () async {
    final store = MemoryLocalUiStore(), repo = DevelopmentKnowledgeRepository();
    final project = await repo.createProject('owner', 'Work');
    final w = WorkspaceController(repo, MemoryAttemptStore(), localUi: store);
    await w.openAccount('owner');
    final general = w.selectedProjectId!;
    final count = w.notes.length;
    w.updateDraft(content: 'فكرة مستقلة', title: 'عنوان', titleVisible: true, tagIds: {'tag'});
    await w.selectProject(project.id);
    w.updateDraft(content: 'Work draft');
    await w.flushDraft();
    w.dispose();
    final restored = WorkspaceController(repo, MemoryAttemptStore(), localUi: store);
    addTearDown(restored.dispose);
    await restored.openAccount('owner');
    expect(restored.selectedProjectId, general);
    expect(restored.draft.content, 'فكرة مستقلة');
    expect(restored.draft.titleVisible, isTrue);
    expect(restored.draft.tagIds, {'tag'});
    expect(restored.notes.length, count);
    await restored.selectProject(project.id);
    expect(restored.draft.content, 'Work draft');
    await restored.openAccount('someone-else');
    expect(restored.draft.content, isEmpty);
    await restored.openAccount('owner');
    expect(restored.draft.content, 'فكرة مستقلة');
  });
  test('failed autosave retains the current draft and succeeds on explicit retry', () async {
    final store = FailingDraftStore(), repo = DevelopmentKnowledgeRepository();
    final w = WorkspaceController(repo, MemoryAttemptStore(), localUi: store);
    addTearDown(w.dispose);
    await w.openAccount('owner');
    store.fail = true;
    w.updateDraft(content: 'Do not lose this');
    await w.flushDraft();
    expect(w.draftFailure, isTrue);
    expect(w.draft.content, 'Do not lose this');
    store.fail = false;
    await w.flushDraft();
    expect(w.draftFailure, isFalse);
    final another = WorkspaceController(repo, MemoryAttemptStore(), localUi: store);
    addTearDown(another.dispose);
    await another.openAccount('owner');
    expect(another.draft.content, 'Do not lose this');
  });
  test('confirmed save clears durable draft and assigns tags without losing other projects', () async {
    final store = MemoryLocalUiStore(), repo = DevelopmentKnowledgeRepository();
    final project = await repo.createProject('owner', 'Work');
    final w = WorkspaceController(repo, MemoryAttemptStore(), localUi: store);
    addTearDown(w.dispose);
    await w.openAccount('owner');
    final general = w.selectedProjectId!;
    w.updateDraft(content: 'Kept elsewhere');
    await w.selectProject(project.id);
    w.updateDraft(content: 'Save this', tagIds: {'tag'});
    final note = await w.save();
    expect(note, isNotNull);
    final record = await store.read('account:owner');
    expect((record['drafts'] as Map).containsKey(project.id), isFalse);
    expect((record['drafts'] as Map)[general]['content'], 'Kept elsewhere');
    expect((record['note_tags'] as Map)[note!.id], ['tag']);
    await w.openAccount('owner');
    await w.selectProject(project.id);
    expect(w.draft.content, isEmpty);
  });
  test('local cleanup failure reconciles the same create key and cannot duplicate a note', () async {
    final store = FailingDraftStore(), repo = UncertainCreate()..throwAfterCommit = false;
    final w = WorkspaceController(repo, MemoryAttemptStore(), localUi: store);
    addTearDown(w.dispose);
    await w.openAccount('development-other');
    w.updateDraft(content: 'One note only');
    await w.flushDraft();
    store.fail = true;
    expect(await w.save(), isNull);
    expect(w.pendingAttempt, isNotNull);
    final key = w.pendingAttempt!.key;
    store.fail = false;
    expect(await w.save(), isNotNull);
    expect(repo.sent.map((a) => a.key), [key, key]);
    expect(w.notes, hasLength(1));
    expect(w.draft.content, isEmpty);
  });
  test('switching project or closing capture cancels late transcription and microphone', () async {
    final repo = HeldTranscript(), device = TestCaptureDevice();
    final c = CaptureController(device, repo);
    addTearDown(c.dispose);
    c.setAccount('owner');
    c.setProject('old');
    await c.start();
    await c.stop();
    final pending = c.transcribe();
    c.setProject('new');
    repo.response.complete('Old project transcript');
    await pending;
    expect(c.transcript, isEmpty);
    expect(c.clip, isNull);
    await c.start();
    await c.close();
    expect(c.active, isFalse);
    expect(c.state, CaptureState.idle);
  });
}
