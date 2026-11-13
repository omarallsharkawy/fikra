import 'dart:async';

import 'package:fikra/core/theme/fikra_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:fikra/data/ai/ai_service.dart';
import 'package:fikra/data/attachment_draft.dart';
import 'package:fikra/data/groups_repository.dart';
import 'package:fikra/data/links_repository.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/features/notes/notes_screen.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';

// Shared by the selection-mode and group tests of the notes list.

final arL10n = lookupAppLocalizations(const Locale('ar'));
final enL10n = lookupAppLocalizations(const Locale('en'));

/// A phone screen; [height] in dp (taller to keep many cards built).
void phone(WidgetTester tester, {double height = 844}) {
  // Every tap must reach its target (a card under the tab bar would not).
  WidgetController.hitTestWarningShouldBeFatal = true;
  addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = Size(390 * 3, height * 3);
  addTearDown(tester.view.reset);
}

/// Project "Study" (selected) with [titles] as ready notes, newest last, and
/// project "Work" with one note. [files] gives a note (by index) attachment
/// paths. Returns Study, Work and Study's notes in [titles] order.
Future<(Project, Project, List<Note>)> seedNotes(
  WidgetTester tester,
  FikraDatabase db,
  List<String> titles, {
  AppLocalizations? l10n,
  Map<int, List<String>> files = const {},
}) async {
  await pumpUntil(tester, find.text((l10n ?? arL10n).startNewProject));
  final result = await pumpFuture(tester, () async {
    final projects = LocalProjectsRepository(db);
    final repo = LocalNotesRepository(db);
    final p = await projects.create('Study');
    final q = await projects.create('Work');
    final other = await repo.create(projectId: q.id, title: 'Q note', text: 'q', source: NoteSource.text);
    await repo.markReady(other.id);
    await projects.setCurrent(p.id);
    final notes = <Note>[];
    for (final (i, t) in titles.indexed) {
      final n = await repo.create(
        projectId: p.id,
        title: t,
        text: 'text of $t',
        source: files.containsKey(i) ? NoteSource.pdf : NoteSource.text,
        attachments: [
          for (final path in files[i] ?? const <String>[])
            AttachmentDraft(kind: AttachmentKind.pdf, path: path, name: 'f.pdf', bytes: 1),
        ],
        createdAt: DateTime(2026, 11, 1, 8, i),
      );
      await repo.markReady(n.id);
      notes.add(n);
    }
    return (p, q, notes);
  });
  await pumpUntil(tester, find.text(titles.last));
  return result;
}

var _edges = 0;

/// Inserts a link row directly.
Future<void> insertLink(
  WidgetTester tester,
  FikraDatabase db,
  Note a,
  Note b, {
  LinkOrigin origin = LinkOrigin.user,
  bool dismissed = false,
}) => pumpFuture(
  tester,
  () => db
      .into(db.noteLinks)
      .insert(
        NoteLink(
          id: 'edge-${_edges++}',
          projectId: a.projectId,
          sourceId: a.id,
          targetId: b.id,
          label: '',
          strength: 0.5,
          origin: origin,
          dismissed: dismissed,
        ),
      ),
);

Future<List<NoteLink>> allLinks(WidgetTester tester, FikraDatabase db) =>
    pumpFuture(tester, () => db.select(db.noteLinks).get());

/// Live user links between notes of [ids], as unordered pairs.
Future<Set<Set<String>>> userPairs(WidgetTester tester, FikraDatabase db) async => {
  for (final l in await allLinks(tester, db))
    if (l.origin == LinkOrigin.user && !l.dismissed) {l.sourceId, l.targetId},
};

Future<Note> readNote(WidgetTester tester, FikraDatabase db, String id) =>
    pumpFuture(tester, () => (db.select(db.notes)..where((n) => n.id.equals(id))).getSingle());

Future<List<NoteGroup>> allGroups(WidgetTester tester, FikraDatabase db) =>
    pumpFuture(tester, () => db.select(db.noteGroups).get());

/// A note's card in the notes list.
Finder card(String id) => find.descendant(of: find.byType(NotesScreen), matching: find.byKey(ValueKey(id)));

Future<void> settle(WidgetTester tester, Finder finder) async {
  await pumpUntil(tester, finder);
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> pumpAnimations(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

/// Lets the current toast time out (it would cover a sheet's bottom rows).
Future<void> waitOutToast(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 7));
  await pumpAnimations(tester);
}

/// Scrolls the notes list until [id]'s card is fully in view (it may not be
/// built yet: the list is lazy).
Future<void> reveal(WidgetTester tester, String id) async {
  if (card(id).evaluate().isEmpty) {
    final list = find.descendant(
      of: find.descendant(of: find.byType(NotesScreen), matching: find.byType(ListView)),
      matching: find.byType(Scrollable),
    );
    try {
      await tester.scrollUntilVisible(card(id), 200, scrollable: list.first);
    } on StateError {
      await tester.scrollUntilVisible(card(id), -200, scrollable: list.first);
    }
    await tester.pump(const Duration(seconds: 1)); // let the fling stop
  }
  await tester.ensureVisible(card(id));
  await tester.pump();
}

/// Long-presses [notes]'s first card, then taps the others.
Future<void> select(WidgetTester tester, List<Note> notes) async {
  await reveal(tester, notes.first.id);
  await tester.longPress(card(notes.first.id));
  await tester.pump();
  for (final n in notes.skip(1)) {
    await reveal(tester, n.id);
    await tester.tap(card(n.id));
    await tester.pump();
  }
  await pumpAnimations(tester); // an earlier toast leaves
}

/// Taps a selection bar action and lets its sheet or dialog open.
Future<void> tapAction(WidgetTester tester, String key) async {
  // The test font is wide, so the bar scrolls: bring the action into view.
  await tester.ensureVisible(find.byKey(ValueKey('selection-$key')));
  await tester.pump();
  await tester.tap(find.byKey(ValueKey('selection-$key')));
  await pumpAnimations(tester);
}

/// Answers right away with no links, so re-linking finishes inside the test.
class QuietAi implements AiService {
  @override
  Future<NoteInsights> analyze(Note note, List<Note> projectNotes) async =>
      NoteInsights(title: note.title, concepts: const [], cluster: 'k', links: const []);

  @override
  Future<ChatAnswer> ask(String question, List<Note> projectNotes) => throw UnimplementedError();
}

/// Counts link calls; [failOn] makes that call (1-based) throw.
class SpyLinks extends LocalLinksRepository {
  SpyLinks(super.db);
  int linkCalls = 0;
  int? failOn;

  /// When set, Undo waits for it (a slow Undo).
  Completer<void>? undoGate;

  /// When set, linking waits for it (a slow action).
  Completer<void>? linkGate;

  @override
  Future<List<LinkChange>> linkNotesForUndo(String sourceId, Iterable<String> targetIds) async {
    linkCalls++;
    await linkGate?.future;
    if (linkCalls == failOn) throw StateError('link failed');
    return super.linkNotesForUndo(sourceId, targetIds);
  }

  @override
  Future<void> undoLinks(Iterable<LinkChange> changes) async {
    await undoGate?.future;
    return super.undoLinks(changes);
  }
}

/// Counts moves and relinks; [failDeleteOf] makes deleting that note throw.
class SpyNotes extends LocalNotesRepository {
  SpyNotes(super.db);
  int moves = 0;
  int impacts = 0;
  final relinked = <String>[];
  final deleted = <String>[];
  String? failDeleteOf;

  /// This project's notes never arrive (a slow first load).
  String? holdNotesOf;

  @override
  Stream<List<Note>> watchNotes(String projectId) =>
      projectId == holdNotesOf ? StreamController<List<Note>>().stream : super.watchNotes(projectId);

  @override
  Future<({int userLinks, int suggestions})> moveImpact(Iterable<String> noteIds, String targetProjectId) {
    impacts++;
    return super.moveImpact(noteIds, targetProjectId);
  }

  @override
  Future<List<String>> moveNotes(Iterable<String> noteIds, String targetProjectId) {
    moves++;
    return super.moveNotes(noteIds, targetProjectId);
  }

  @override
  Future<void> delete(String id) async {
    if (id == failDeleteOf) throw StateError('delete failed');
    deleted.add(id);
    return super.delete(id);
  }

  @override
  Future<void> applyInsights(String id, NoteInsights insights, {Note? basis, bool linksOnly = false}) {
    if (linksOnly) relinked.add(id);
    return super.applyInsights(id, insights, basis: basis, linksOnly: linksOnly);
  }
}

/// Counts assignments; [failAssign] makes them throw.
class SpyGroups extends LocalGroupsRepository {
  SpyGroups(super.db);
  int assigns = 0;
  bool failAssign = false;

  @override
  Future<void> assignNotes(String? groupId, Iterable<String> noteIds) {
    assigns++;
    if (failAssign) throw StateError('assign failed');
    return super.assignNotes(groupId, noteIds);
  }
}

/// A bare themed app (no tab shell) with [child] in a Scaffold, at [scale].
Future<void> host(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('ar'),
  double scale = 1,
  Brightness brightness = Brightness.dark,
  List<Override> overrides = const [],
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: locale,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildFikraTheme(brightness),
        // Above the navigator, so sheets and dialogs get the scale too.
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
          child: app!,
        ),
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump();
}
