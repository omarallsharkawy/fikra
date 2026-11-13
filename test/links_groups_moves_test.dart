import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:fikra/data/ai/ai_service.dart';
import 'package:fikra/data/attachment_draft.dart';
import 'package:fikra/data/files/attachment_store.dart';
import 'package:fikra/data/groups_repository.dart';
import 'package:fikra/data/links_repository.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/processing/note_processor.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/data/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late FikraDatabase db;
  late LocalNotesRepository notes;
  late LocalLinksRepository links;
  late LocalGroupsRepository groups;
  late LocalProjectsRepository projects;
  late Project p;
  late Project q;
  var edgeSequence = 0;

  setUp(() async {
    edgeSequence = 0;
    db = FikraDatabase(NativeDatabase.memory());
    notes = LocalNotesRepository(db);
    links = LocalLinksRepository(db);
    groups = LocalGroupsRepository(db);
    projects = LocalProjectsRepository(db);
    p = await projects.create('p');
    q = await projects.create('q');
  });
  tearDown(() => db.close());

  Future<Note> note({String? project, String title = 'title', String text = 'original'}) =>
      notes.create(projectId: project ?? p.id, title: title, text: text, source: NoteSource.text);
  Future<NoteLink> edge(
    Note a,
    Note b, {
    LinkOrigin origin = LinkOrigin.ai,
    bool dismissed = false,
    String label = 'legacy',
  }) async {
    final row = NoteLink(
      id: 'edge-${edgeSequence++}',
      projectId: a.projectId,
      sourceId: a.id,
      targetId: b.id,
      label: label,
      strength: 0.3,
      origin: origin,
      dismissed: dismissed,
    );
    await db.into(db.noteLinks).insert(row);
    return row;
  }

  Future<List<NoteLink>> allLinks() => db.select(db.noteLinks).get();
  Future<Note> read(String id) async => (await notes.watchNote(id).first)!;
  NoteInsights insights(Iterable<String> targets) => NoteInsights(
    title: 'AI title',
    proposedText: 'AI rewrite',
    concepts: const ['new concept'],
    cluster: 'new cluster',
    links: [for (final id in targets) ProposedLink(targetId: id, label: 'suggestion', strength: 0.7)],
  );
  Matcher rule(GroupRuleReason reason) => isA<GroupRuleException>().having((e) => e.reason, 'reason', reason);

  test('links three targets atomically, ignores invalid targets, normalizes labels and duplicates', () async {
    final a = await note();
    final targets = [await note(), await note(), await note()];
    final other = await note(project: q.id);
    final ids = await links.linkNotes(a.id, [
      a.id,
      'missing',
      other.id,
      ...targets.map((n) => n.id),
      targets.first.id,
    ], label: '  ${'x' * 90}  ');
    expect(ids, hasLength(3));
    final rows = await allLinks();
    expect(rows.map((l) => l.id).toSet(), ids.toSet());
    expect(rows.map((l) => l.targetId).toSet(), targets.map((n) => n.id).toSet());
    expect(
      rows.every((l) => l.origin == LinkOrigin.user && !l.dismissed && l.strength == 1 && l.createdAt != null),
      isTrue,
    );
    expect(rows.map((l) => l.label), everyElement('x' * 80));
    expect(await links.linkNotes(targets.first.id, [a.id], label: 'replacement'), isEmpty);
    expect(await allLinks(), rows);
    expect(await links.linkNotes('missing', [a.id]), isEmpty);
  });

  test('linkNotes converts reverse suggestions and tombstones, clears further AI duplicates', () async {
    final a = await note();
    final b = await note();
    final c = await note();
    final ab = await edge(b, a);
    final duplicate = await edge(a, b);
    final dismissed = await edge(a, b, dismissed: true);
    final ac = await edge(a, c, dismissed: true, label: 'keep me');
    expect(
      (await links.linkNotes(a.id, [b.id], label: '  custom  ')).single,
      isIn([ab.id, duplicate.id, dismissed.id]),
    );
    expect(await links.linkNotes(a.id, [c.id], label: '   '), [ac.id]);
    final rows = await allLinks();
    expect(rows, hasLength(2));
    expect(rows.first.sourceId, a.id);
    expect(rows.first.label, 'custom');
    expect(rows.last.label, 'keep me');
    expect(
      rows.every((l) => l.origin == LinkOrigin.user && !l.dismissed && l.strength == 1 && l.createdAt != null),
      isTrue,
    );
    await edge(b, a);
    expect(await links.linkNotes(b.id, [a.id], label: 'do not replace'), isEmpty);
    expect(await allLinks(), rows);
  });

  test('a sole reverse suggestion keeps its id when converted', () async {
    final a = await note();
    final b = await note();
    final reverse = await edge(b, a);
    expect(await links.linkNotes(a.id, [b.id]), [reverse.id]);
    final row = (await allLinks()).single;
    expect(row.sourceId, a.id);
    expect(row.targetId, b.id);
    expect(row.origin, LinkOrigin.user);
    expect(row.label, reverse.label);
  });

  test('batch linking rolls back earlier conversions if a later insert fails', () async {
    final a = await note();
    final b = await note();
    final c = await note();
    final old = await edge(a, b);
    await db.customStatement(
      "CREATE TRIGGER reject_user_link BEFORE INSERT ON note_links WHEN NEW.target_id = '${c.id}' "
      "BEGIN SELECT RAISE(ABORT, 'test failure'); END",
    );
    await expectLater(links.linkNotes(a.id, [b.id, c.id]), throwsA(isA<Exception>()));
    expect(await allLinks(), [old]);
  });

  test('user label edits trim, cap and clear; AI edits throw; absent label is an empty SQL string', () async {
    final a = await note();
    final b = await note();
    final ai = await edge(a, b);
    await expectLater(links.updateLabel(ai.id, 'custom'), throwsStateError);
    expect((await allLinks()).single, ai);
    await links.acceptSuggestion(ai.id);
    await links.updateLabel(ai.id, '  ${'z' * 81}  ');
    expect((await allLinks()).single.label, 'z' * 80);
    await links.updateLabel(ai.id, '  ');
    expect((await allLinks()).single.label, '');
    expect((await db.customSelect('SELECT label FROM note_links').getSingle()).data['label'], '');
    final c = await note();
    await links.linkNotes(a.id, [c.id]);
    expect(await db.customSelect("SELECT id FROM note_links WHERE label = ''").get(), hasLength(2));
    final labelColumn = (await db.customSelect('PRAGMA table_info(note_links)').get()).singleWhere(
      (r) => r.read<String>('name') == 'label',
    );
    expect(labelColumn.read<int>('notnull'), 1);
  });

  test('label caps count whole characters (emoji included) for creation, edits and AI', () async {
    final a = await note();
    final b = await note();
    final c = await note();
    for (final (input, expected) in [
      ('${'x' * 79}😀tail', '${'x' * 79}😀'),
      ('${'x' * 78}😀tail', '${'x' * 78}😀t'),
      ('${'x' * 80}😀tail', 'x' * 80),
      // A joined family emoji is one character: kept whole, never split.
      ('${'x' * 79}👨‍👩‍👧tail', '${'x' * 79}👨‍👩‍👧'),
      ('${'x' * 80}👨‍👩‍👧', 'x' * 80),
    ]) {
      final userId = (await links.linkNotes(a.id, [b.id], label: '  $input  ')).firstOrNull;
      if (userId == null) {
        await links.updateLabel((await allLinks()).singleWhere((l) => l.origin == LinkOrigin.user).id, input);
      }
      expect((await allLinks()).singleWhere((l) => l.origin == LinkOrigin.user).label, expected);
      final id = (await allLinks()).singleWhere((l) => l.origin == LinkOrigin.user).id;
      await links.updateLabel(id, '  $input  ');
      expect((await allLinks()).singleWhere((l) => l.id == id).label, expected);
      await notes.applyInsights(
        a.id,
        NoteInsights(
          title: 'AI',
          concepts: const [],
          cluster: 'cluster',
          links: [ProposedLink(targetId: c.id, label: input, strength: 0.5)],
        ),
      );
      expect((await allLinks()).singleWhere((l) => l.origin == LinkOrigin.ai).label, expected);
    }
  });

  test('editing the label of a link removed meanwhile is a no-op', () async {
    final a = await note();
    final b = await note();
    final id = (await links.linkNotes(a.id, [b.id], label: 'kept')).single;
    await links.removeLink(id);
    final before = await allLinks();
    await links.updateLabel(id, 'too late');
    expect(await allLinks(), before);
    await links.updateLabel('missing', 'too late');
    expect(await allLinks(), before);
  });

  NoteInsights suggesting(String target) => NoteInsights(
    title: 'AI',
    concepts: const [],
    cluster: 'cluster',
    links: [ProposedLink(targetId: target, label: 'again', strength: 0.5)],
  );

  test('acceptPair accepts the live suggestion even after a re-analysis replaced its id', () async {
    final a = await note();
    final b = await note();
    await notes.applyInsights(a.id, suggesting(b.id));
    final shown = (await allLinks()).single;
    await notes.applyInsights(a.id, suggesting(b.id));
    final replaced = (await allLinks()).single;
    expect(replaced.id, isNot(shown.id));
    // The id-based accept the screen held is now a silent no-op ...
    await links.acceptSuggestion(shown.id);
    expect((await allLinks()).single.origin, LinkOrigin.ai);
    // ... while the pair-based one finds the new row, from either end.
    await links.acceptPair(b.id, a.id);
    final accepted = (await allLinks()).single;
    expect(accepted.id, replaced.id);
    expect(accepted.origin, LinkOrigin.user);
    expect(accepted.dismissed, isFalse);
    // Accepting again changes nothing.
    await links.acceptPair(a.id, b.id);
    expect(await allLinks(), [accepted]);
  });

  test('acceptPair never revives a rejected or removed pair and ignores pairs with no suggestion', () async {
    final a = await note();
    final b = await note();
    final c = await note();
    final d = await note();
    await notes.applyInsights(a.id, suggesting(b.id));
    await links.dismissPair(a.id, b.id);
    var before = await allLinks();
    await links.acceptPair(a.id, b.id);
    expect(await allLinks(), before);
    // A legacy live reverse suggestion next to a tombstone stays a suggestion.
    await edge(b, a);
    before = await allLinks();
    await links.acceptPair(a.id, b.id);
    expect(await allLinks(), before);

    final removed = (await links.linkNotes(a.id, [c.id])).single;
    await links.removeLink(removed);
    before = await allLinks();
    await links.acceptPair(c.id, a.id);
    expect(await allLinks(), before);

    await links.acceptPair(a.id, d.id);
    expect(await allLinks(), before);
    expect(await links.watchLinks(p.id).first, [isA<NoteLink>().having((l) => l.sourceId, 'source', b.id)]);
  });

  test('dismissPair rejects replaced, reverse and vanished suggestions for good, never your link', () async {
    final a = await note();
    final b = await note();
    final c = await note();
    final d = await note();
    final other = await note(project: q.id);
    // Replaced id, plus a legacy reverse row.
    await notes.applyInsights(a.id, suggesting(b.id));
    await notes.applyInsights(a.id, suggesting(b.id));
    await edge(b, a);
    await links.dismissPair(a.id, b.id);
    expect((await allLinks()).every((l) => l.dismissed && l.origin == LinkOrigin.ai), isTrue);
    expect(await links.watchLinks(p.id).first, isEmpty);
    await notes.applyInsights(a.id, suggesting(b.id));
    await notes.applyInsights(b.id, suggesting(a.id));
    expect(await links.watchLinks(p.id).first, isEmpty);

    // The suggestion vanished before the reject landed: a tombstone remembers it.
    await links.dismissPair(c.id, a.id);
    final tombstone = (await allLinks()).singleWhere((l) => {l.sourceId, l.targetId}.containsAll({a.id, c.id}));
    expect((tombstone.origin, tombstone.dismissed, tombstone.projectId), (LinkOrigin.ai, true, p.id));
    await notes.applyInsights(a.id, suggesting(c.id));
    await notes.applyInsights(c.id, suggesting(a.id));
    expect(await links.watchLinks(p.id).first, isEmpty);

    // Your link stays; unknown, cross-project and self pairs change nothing.
    final mine = (await links.linkNotes(a.id, [d.id], label: 'mine')).single;
    final before = await allLinks();
    await links.dismissPair(d.id, a.id);
    await links.dismissPair(a.id, 'missing');
    await links.dismissPair(a.id, other.id);
    await links.dismissPair(a.id, a.id);
    expect(await allLinks(), before);
    expect((await links.watchLinks(p.id).first).single.id, mine);
  });

  test('late accept after dismissal leaves every row untouched', () async {
    final a = await note();
    final b = await note();
    final ai = await edge(a, b);
    await edge(b, a);
    await links.dismissSuggestion(ai.id);
    final before = await allLinks();
    await links.acceptSuggestion(ai.id);
    expect(await allLinks(), before);
    expect(await links.watchLinks(p.id).first, isEmpty);
  });

  test('accepting a tombstone next to a reverse user link is a no-op', () async {
    final a = await note();
    final b = await note();
    final tombstone = await edge(a, b, dismissed: true);
    final user = await edge(b, a, origin: LinkOrigin.user);
    final reverseAi = await edge(b, a);
    final before = await allLinks();
    await links.acceptSuggestion(tombstone.id);
    expect(await allLinks(), before);
    expect(await links.watchLinks(p.id).first, [user, reverseAi]);
    // A stale accept of an already accepted row must not clean up other rows either.
    await links.acceptSuggestion(user.id);
    expect(await allLinks(), before);
  });

  test('removing an AI suggestion dismisses it without deleting it', () async {
    final a = await note();
    final b = await note();
    final ai = await edge(a, b);
    await links.removeLink(ai.id);
    expect(await allLinks(), [ai.copyWith(dismissed: true)]);
    expect(await links.watchLinks(p.id).first, isEmpty);
  });

  test('removing a user link also dismisses its legacy reverse AI suggestion', () async {
    final a = await note();
    final b = await note();
    final user = await edge(a, b, origin: LinkOrigin.user);
    final reverse = await edge(b, a);
    await links.removeLink(user.id);
    expect(await allLinks(), [
      user.copyWith(origin: LinkOrigin.ai, dismissed: true),
      reverse.copyWith(dismissed: true),
    ]);
    expect(await notes.watchLinks(p.id).first, isEmpty);
  });

  test('accept removes both-direction live AI duplicates and preserves tombstones and other user links', () async {
    final a = await note();
    final b = await note();
    final accepted = await edge(a, b);
    await edge(b, a);
    await edge(a, b);
    final tombstone = await edge(b, a, dismissed: true);
    final user = await edge(b, a, origin: LinkOrigin.user);
    await links.acceptSuggestion(accepted.id);
    final rows = await allLinks();
    expect(rows.map((l) => l.id), [accepted.id, tombstone.id, user.id]);
    expect(rows.first.origin, LinkOrigin.user);
    expect(rows.first.strength, 1);
    expect(rows.first.createdAt, isNotNull);
    expect(rows[1], tombstone);
    expect(rows[2], user);
    await links.acceptSuggestion('stale');
    await links.dismissSuggestion('stale');
    expect(await allLinks(), rows);
  });

  test('dismiss covers both directions and watchLinks hides all dismissed rows', () async {
    final a = await note();
    final b = await note();
    final ai = await edge(a, b);
    await edge(b, a);
    final user = await edge(a, b, origin: LinkOrigin.user);
    await links.dismissSuggestion(ai.id);
    expect((await allLinks()).where((l) => l.origin == LinkOrigin.ai).every((l) => l.dismissed), isTrue);
    expect(await links.watchLinks(p.id).first, [user]);
    expect(await notes.watchLinks(p.id).first, [user]);
  });

  test('analysis preserves user links in either direction and never reintroduces dismissed or removed pairs', () async {
    final a = await note();
    final b = await note();
    final c = await note();
    final d = await note();
    final e = await note();
    final userOut = await edge(a, b, origin: LinkOrigin.user);
    final userIn = await edge(c, a, origin: LinkOrigin.user);
    await edge(d, a, dismissed: true);
    final removedId = (await links.linkNotes(a.id, [e.id])).single;
    await links.removeLink(removedId);
    for (final source in [a, b, c, d, e]) {
      await notes.applyInsights(source.id, insights([a, b, c, d, e].where((n) => n.id != source.id).map((n) => n.id)));
    }
    final rows = await allLinks();
    expect(rows.singleWhere((l) => l.id == userOut.id), userOut);
    expect(rows.singleWhere((l) => l.id == userIn.id), userIn);
    for (final other in [d, e]) {
      final pair = rows.where(
        (l) => (l.sourceId == a.id && l.targetId == other.id) || (l.targetId == a.id && l.sourceId == other.id),
      );
      expect(pair, hasLength(1));
      expect(pair.single.dismissed, isTrue);
      expect(pair.single.origin, LinkOrigin.ai);
    }
    expect((await links.watchLinks(p.id).first).any((l) => l.id == removedId), isFalse);
    expect(await links.linkNotes(e.id, [a.id], label: 'revived'), [removedId]);
    expect((await allLinks()).singleWhere((l) => l.id == removedId).dismissed, isFalse);
  });

  test('AI filter runs before eight-link cap, blocks reverse AI and refreshes outgoing suggestions', () async {
    final a = await note();
    final blocked = [for (var i = 0; i < 10; i++) await note()];
    final valid = [for (var i = 0; i < 9; i++) await note()];
    for (final (i, b) in blocked.indexed) {
      await edge(
        i.isEven ? a : b,
        i.isEven ? b : a,
        origin: i < 3 ? LinkOrigin.user : LinkOrigin.ai,
        dismissed: i >= 3 && i < 9,
      );
    }
    final old = await edge(a, valid.first);
    final before = (await allLinks()).where((l) => l.id != old.id).toList();
    await notes.applyInsights(a.id, insights([...blocked.map((n) => n.id), ...valid.map((n) => n.id)]));
    final rows = await allLinks();
    expect(rows, containsAll(before));
    expect(rows.any((l) => l.id == old.id), isFalse);
    final added = rows.where((l) => !before.any((b) => b.id == l.id)).toList();
    expect(added.map((l) => l.targetId), valid.take(8).map((n) => n.id));
    expect(added.every((l) => l.createdAt != null && l.origin == LinkOrigin.ai && !l.dismissed), isTrue);
  });

  test('linksOnly updates concepts, cluster and links while preserving note and rewrite state', () async {
    final a = await note(title: '');
    final b = await note();
    await db
        .update(db.notes)
        .replace(
          a.copyWith(
            proposedText: const Value('pending'),
            rewrite: RewriteStatus.pending,
            status: ProcessingStatus.failed,
            updatedAt: DateTime(2020),
          ),
        );
    final before = await read(a.id);
    await notes.applyInsights(a.id, insights([b.id]), linksOnly: true);
    final after = await read(a.id);
    expect(after.title, before.title);
    expect(after.originalText, before.originalText);
    expect(after.editedText, before.editedText);
    expect(after.proposedText, before.proposedText);
    expect(after.rewrite, before.rewrite);
    expect(after.status, before.status);
    expect(after.updatedAt, before.updatedAt);
    expect(after.conceptList, ['new concept']);
    expect(after.cluster, 'new cluster');
    expect((await allLinks()).single.targetId, b.id);
  });

  test('move impact matches crossing deletes, internal links follow, groups clear and files survive sweep', () async {
    final directory = await Directory.systemTemp.createTemp('fikra-move-');
    addTearDown(() => directory.delete(recursive: true));
    final store = AttachmentStore(documentsDir: () async => directory, tempDir: () async => directory);
    final file = File('${directory.path}/attachments/saved.pdf');
    await file.parent.create();
    await file.writeAsString('pdf');
    await file.setLastModified(DateTime(2020));
    final a = await notes.create(
      projectId: p.id,
      title: 'a',
      text: 'a',
      source: NoteSource.pdf,
      attachments: [AttachmentDraft(kind: AttachmentKind.pdf, path: file.path)],
    );
    final b = await note();
    final c = await note();
    final already = await note(project: q.id);
    final group = await groups.create(p.id, 'g');
    await groups.assignNotes(group.id, [a.id, b.id, c.id]);
    final internal = await edge(a, b, origin: LinkOrigin.user);
    final internalTomb = await edge(b, a, dismissed: true);
    final crossingUser = await edge(a, c, origin: LinkOrigin.user);
    final crossingAi = await edge(c, b);
    final crossingTomb = await edge(b, c, dismissed: true);
    final attachments = await notes.watchAttachments(a.id).first;
    final ids = [a.id, b.id, a.id, already.id, 'missing'];
    expect(await notes.moveImpact(ids, q.id), (userLinks: 1, suggestions: 1));
    expect(await notes.moveNotes(ids, q.id), unorderedEquals([a.id, b.id]));
    final rows = await allLinks();
    expect(rows.map((l) => l.id), [internal.id, internalTomb.id]);
    expect(rows.every((l) => l.projectId == q.id), isTrue);
    expect(rows[1].dismissed, isTrue);
    expect(rows.map((l) => l.id), isNot(contains(anyOf(crossingUser.id, crossingAi.id, crossingTomb.id))));
    expect((await read(a.id)).projectId, q.id);
    expect((await read(a.id)).groupId, isNull);
    expect((await read(b.id)).groupId, isNull);
    expect((await read(c.id)).groupId, group.id);
    expect(await notes.watchAttachments(a.id).first, attachments);
    expect(await notes.attachmentPaths(), {file.path});
    await store.sweepOrphans(await notes.attachmentPaths());
    expect(await file.readAsString(), 'pdf');
    expect(await notes.moveImpact(ids, q.id), (userLinks: 0, suggestions: 0));
    expect(await notes.moveNotes(ids, q.id), isEmpty);
  });

  test('move impact counts unordered crossing pairs once and gives user origin precedence', () async {
    final a = await note();
    final b = await note();
    final c = await note();
    final d = await note();
    final e = await note();
    // A–B is a legacy two-way suggestion, A–C a two-way user link.
    await edge(a, b);
    await edge(b, a);
    await edge(a, c, origin: LinkOrigin.user);
    await edge(c, a, origin: LinkOrigin.user);
    // Mixed origins count as one user link regardless of row order.
    await edge(a, d);
    await edge(d, a, origin: LinkOrigin.user);
    await edge(a, e, origin: LinkOrigin.user);
    await edge(e, a);
    // Dismissed rows do not contribute to either category.
    await edge(b, a, dismissed: true, origin: LinkOrigin.user);
    expect(await notes.moveImpact([a.id, a.id], q.id), (userLinks: 3, suggestions: 1));
    expect(await allLinks(), hasLength(9));
    expect(await notes.moveNotes([a.id], q.id), [a.id]);
    expect(await allLinks(), isEmpty);
  });

  for (final linksOnly in [false, true]) {
    test('analysis from a previous project preserves moved links and concepts; linksOnly=$linksOnly', () async {
      final a = await note(title: '');
      final b = await note();
      final existing = await edge(a, b);
      await db
          .update(db.notes)
          .replace(a.copyWith(concepts: 'retained concept', cluster: const Value('retained cluster')));
      final started = Completer<Note>();
      final release = Completer<NoteInsights>();
      final processor = NoteProcessor(
        notes,
        _Ai((n, _) {
          started.complete(n);
          return release.future;
        }),
      );
      final job = linksOnly ? processor.relink([a.id]) : processor.process(a);
      await started.future;
      await notes.moveNotes([a.id, b.id], q.id);
      final moved = await read(a.id);
      final movedLinks = await allLinks();
      expect(movedLinks, [existing.copyWith(projectId: q.id)]);
      // Even if the old result proposes no link, it must not remove the moved one.
      release.complete(insights([]));
      await job;
      final after = await read(a.id);
      expect(after.concepts, 'retained concept');
      expect(after.cluster, 'retained cluster');
      expect(await allLinks(), movedLinks);
      if (linksOnly) {
        expect(after, moved);
      } else {
        expect(after.title, 'AI title');
        expect(after.proposedText, 'AI rewrite');
        expect(after.rewrite, RewriteStatus.pending);
        expect(after.status, ProcessingStatus.ready);
      }
    });
  }

  test('unknown move target throws atomically without changing notes, links, groups or attachments', () async {
    final a = await note();
    final b = await note();
    await edge(a, b);
    final g = await groups.create(p.id, 'g');
    await groups.assignNotes(g.id, [a.id]);
    final before = await db.select(db.notes).get();
    final edges = await allLinks();
    await expectLater(notes.moveNotes([a.id, b.id], 'unknown'), throwsStateError);
    expect(await db.select(db.notes).get(), before);
    expect(await allLinks(), edges);
    expect(await groups.watchGroups(p.id).first, [g]);
  });

  for (final timeout in [false, true]) {
    test(
      'relink ${timeout ? 'timeout' : 'failure'} leaves the entire note and links untouched and queue continues',
      () async {
        final a = await note();
        final b = await note();
        await notes.applyInsights(a.id, insights([b.id]));
        final before = await read(a.id);
        expect(before.status, ProcessingStatus.ready);
        final edges = await allLinks();
        final ai = _Ai(
          (n, _) => n.id == a.id
              ? (timeout ? Completer<NoteInsights>().future : Future.error(StateError('offline')))
              : Future.value(insights([a.id])),
        );
        final processor = NoteProcessor(notes, ai, timeout: const Duration(milliseconds: 20));
        await processor.relink([a.id]);
        expect((await read(a.id)).status, ProcessingStatus.ready);
        expect(await read(a.id), before);
        expect(await allLinks(), edges);
        await processor.process(b);
        expect((await read(b.id)).status, ProcessingStatus.ready);
      },
    );
  }

  test('relink shares FIFO queue, reads current project and skips blank or missing notes', () async {
    final a = await note();
    final b = await note();
    final blank = await note(text: ' ');
    final started = Completer<void>();
    final release = Completer<NoteInsights>();
    final seen = <String>[];
    final ai = _Ai((n, projectNotes) async {
      seen.add(n.id);
      if (n.id == a.id) {
        started.complete();
        return release.future;
      }
      expect(n.projectId, q.id);
      expect(projectNotes.every((n) => n.projectId == q.id), isTrue);
      expect(n.status, ProcessingStatus.failed);
      return insights([]);
    });
    final processor = NoteProcessor(notes, ai);
    final first = processor.process(a);
    await started.future;
    final second = processor.relink([b.id, blank.id, 'missing']);
    await notes.moveNotes([b.id], q.id);
    await notes.markFailed(b.id);
    final before = await read(b.id);
    final blankBefore = await read(blank.id);
    release.complete(insights([]));
    await Future.wait([first, second]);
    expect(seen, [a.id, b.id]);
    final after = await read(b.id);
    expect(after.status, before.status);
    expect(after.title, before.title);
    expect(after.proposedText, before.proposedText);
    expect(after.rewrite, before.rewrite);
    expect(after.conceptList, ['new concept']);
    expect(await read(blank.id), blankBefore);
  });

  test('group names, colors and position are validated on create and edit', () async {
    await expectLater(groups.create(p.id, '  '), throwsA(rule(GroupRuleReason.emptyName)));
    for (final color in [-1, 4]) {
      await expectLater(groups.create(p.id, 'g', color: color), throwsA(rule(GroupRuleReason.invalidColor)));
    }
    await expectLater(groups.create('missing', 'g'), throwsA(rule(GroupRuleReason.missingProject)));
    final g = await groups.create(p.id, '  top  ');
    expect(g.name, 'top');
    expect(g.position, 0);
    for (var color = 0; color <= 3; color++) {
      await groups.setColor(g.id, color);
      expect((await groups.watchGroups(p.id).first).single.color, color);
    }
    await groups.setColor(g.id, null);
    await groups.rename(g.id, '  renamed  ');
    await expectLater(groups.rename(g.id, ''), throwsA(rule(GroupRuleReason.emptyName)));
    await expectLater(groups.setColor(g.id, 4), throwsA(rule(GroupRuleReason.invalidColor)));
    final child = await groups.create(p.id, 'child', parentId: g.id, color: 3);
    final next = await groups.create(p.id, 'next');
    final other = await groups.create(q.id, 'other');
    expect(child.position, 1);
    expect(next.position, 2);
    expect(other.position, 0);
    final rows = await groups.watchGroups(p.id).first;
    expect(rows.map((g) => g.id), [g.id, child.id, next.id]);
    expect(rows.first.name, 'renamed');
    expect(rows.first.color, isNull);
  });

  test('group parents must be top level, same project, not self and without children when reparenting', () async {
    final top = await groups.create(p.id, 'top');
    final child = await groups.create(p.id, 'child', parentId: top.id);
    final other = await groups.create(q.id, 'other');
    final sibling = await groups.create(p.id, 'sibling');
    for (final parent in [child.id, other.id, 'missing']) {
      await expectLater(groups.create(p.id, 'invalid', parentId: parent), throwsA(rule(GroupRuleReason.invalidParent)));
      await expectLater(groups.setParent(sibling.id, parent), throwsA(rule(GroupRuleReason.invalidParent)));
    }
    await expectLater(groups.setParent(top.id, top.id), throwsA(rule(GroupRuleReason.selfParent)));
    await expectLater(groups.setParent(top.id, sibling.id), throwsA(rule(GroupRuleReason.hasChildren)));
    await expectLater(groups.setParent('missing', null), throwsA(rule(GroupRuleReason.missingGroup)));
    await groups.setParent(child.id, sibling.id);
    expect((await groups.watchGroups(p.id).first).singleWhere((g) => g.id == child.id).parentId, sibling.id);
    await groups.setParent(child.id, null);
    expect((await groups.watchGroups(p.id).first).every((g) => g.parentId == null), isTrue);
    expect(await groups.watchGroups(p.id).first, hasLength(3));
  });

  test('a note holds one group, cross-project assignments skipped, null clears, delete uses set null', () async {
    final a = await note();
    final b = await note(project: q.id);
    final top = await groups.create(p.id, 'top');
    final child = await groups.create(p.id, 'child', parentId: top.id);
    final other = await groups.create(p.id, 'other');
    await groups.assignNotes(top.id, [a.id, b.id, 'missing']);
    expect((await read(a.id)).groupId, top.id);
    expect((await read(b.id)).groupId, isNull);
    await groups.assignNotes(other.id, [a.id]);
    expect((await read(a.id)).groupId, other.id);
    await groups.assignNotes(null, [a.id, 'missing']);
    expect((await read(a.id)).groupId, isNull);
    await expectLater(groups.assignNotes('missing', [a.id]), throwsA(rule(GroupRuleReason.missingGroup)));
    await groups.assignNotes(top.id, [a.id]);
    await groups.delete(top.id);
    expect((await read(a.id)).groupId, isNull);
    expect((await read(b.id)).projectId, q.id);
    expect((await groups.watchGroups(p.id).first).singleWhere((g) => g.id == child.id).parentId, isNull);
    expect(await db.select(db.notes).get(), hasLength(2));
  });

  test('project deletion cascades groups; wipe clears all groups and preserves preferences', () async {
    final top = await groups.create(p.id, 'top');
    await groups.create(p.id, 'child', parentId: top.id);
    final survivor = await groups.create(q.id, 'survivor');
    await projects.delete(p.id);
    expect(await db.select(db.noteGroups).get(), [survivor]);
    final directory = await Directory.systemTemp.createTemp('fikra-wipe-groups-');
    addTearDown(() => directory.delete(recursive: true));
    final settings = LocalSettingsRepository(
      db,
      AttachmentStore(documentsDir: () async => directory, tempDir: () async => directory),
    );
    await settings.setLanguage(AppLanguage.en);
    await settings.wipeAllData();
    expect(await db.select(db.noteGroups).get(), isEmpty);
    expect(await db.select(db.projects).get(), isEmpty);
    expect(await settings.watchLanguage().first, AppLanguage.en);
  });
}

class _Ai implements AiService {
  _Ai(this.analyzeNote);
  final Future<NoteInsights> Function(Note, List<Note>) analyzeNote;

  @override
  Future<NoteInsights> analyze(Note note, List<Note> projectNotes) => analyzeNote(note, projectNotes);

  @override
  Future<ChatAnswer> ask(String question, List<Note> projectNotes) => throw UnimplementedError();
}
