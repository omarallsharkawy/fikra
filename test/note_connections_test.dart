import 'dart:async';
import 'dart:ui' as ui;

import 'package:fikra/core/widgets/pearl_canvas.dart';
import 'package:fikra/app/providers.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/features/connections/library_session.dart';
import 'package:fikra/features/connections/connections_placeholder.dart';
import 'package:fikra/features/connections/links_library_provider.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/features/connections/note_connections_screen.dart';
import 'package:fikra/features/connections/note_connections_provider.dart';
import 'package:fikra/features/connections/suggestion_card.dart';
import 'package:fikra/features/note_details/note_details_screen.dart';
import 'package:fikra/features/connections/links_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/app_harness.dart';
import 'support/links_library_fixture.dart';
import 'support/selection_fixture.dart';

Finder get connectionsScroll => find.descendant(
  of: find.byType(NoteConnectionsScreen),
  matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down),
);

class _HeldNoteRepository extends LocalNotesRepository {
  _HeldNoteRepository(super.db);
  final pending = StreamController<Note?>.broadcast();
  bool hold = false;

  @override
  Stream<Note?> watchNote(String id) => hold ? pending.stream : super.watchNote(id);
}

Future<void> _expectOpaquePearl(WidgetTester tester, Finder screen) async {
  final paint = find.descendant(
    of: screen,
    matching: find.byWidgetPredicate((w) => w is CustomPaint && w.painter is PearlCanvasPainter),
  );
  final render = tester.renderObject<RenderCustomPaint>(paint);
  expect(render.size.height, greaterThan(500));
  final recorder = ui.PictureRecorder();
  render.painter!.paint(ui.Canvas(recorder), render.size);
  final picture = recorder.endRecording();
  try {
    await tester.runAsync(() async {
      final image = await picture.toImage(render.size.width.ceil(), render.size.height.ceil());
      try {
        final bytes = (await image.toByteData())!;
        for (var i = 3; i < bytes.lengthInBytes; i += 4) {
          expect(bytes.getUint8(i), 255, reason: 'the first frame covers every pixel');
        }
      } finally {
        image.dispose();
      }
    });
  } finally {
    picture.dispose();
  }
}

void main() {
  late _HeldNoteRepository held;
  fikraTest('push paints Pearl, shows initial title and holds section geometry through entry', (tester, db) async {
    phone(tester);
    addTearDown(() => unawaited(held.pending.close()));
    final notes = await seedLibrary(tester, db);
    held.hold = true;
    final row = find.byKey(ValueKey('browse-${notes.last.id}'));
    await tester.tap(row);
    await tester.pump();
    await tester.pump();
    final screen = find.byType(NoteConnectionsScreen);
    expect(find.byKey(const ValueKey('connections-placeholder')), findsOneWidget);
    expect(find.descendant(of: screen, matching: find.text(notes.last.title)), findsOneWidget);
    await _expectOpaquePearl(tester, screen);
    final header = find.byType(ConnectionsNoteHeader);
    Offset offset() => tester
        .renderObject<RenderBox>(header)
        .localToGlobal(Offset.zero, ancestor: tester.renderObject<RenderBox>(screen));
    final position = offset(), size = tester.getSize(header);
    held.pending.add(notes.last);
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.byKey(const ValueKey('connections-placeholder')), findsOneWidget);
    expect(offset(), position);
    expect(tester.getSize(header), size);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('connections-list')), findsOneWidget);
    expect(tester.getSize(header), size);
    // Live data replaces the preview, including a changed title.
    held.pending.add(notes.last.copyWith(title: 'Live title'));
    await tester.pump();
    expect(find.descendant(of: screen, matching: find.text('Live title')), findsOneWidget);
  }, notesRepository: (db) => held = _HeldNoteRepository(db));

  for (final cold in [true, false]) {
    fikraTest('${cold ? 'cold' : 'warm'} entrance keeps updated connections during reverse animation', (
      tester,
      db,
    ) async {
      phone(tester);
      addTearDown(() => unawaited(held.pending.close()));
      final notes = await seedLibrary(tester, db);
      held.hold = cold;
      if (!cold) {
        final container = ProviderScope.containerOf(
          tester.element(find.byKey(LinksLibrarySegment.key(LinksLibrarySegment.browse))),
        );
        final warmNote = container.listen(noteProvider(notes.last.id), (_, _) {});
        addTearDown(warmNote.close);
        final warmConnections = container.listen(noteConnectionsProvider(notes.last.id), (_, _) {});
        addTearDown(warmConnections.close);
        await pumpFuture(tester, () => container.read(noteProvider(notes.last.id).future));
        expect(container.read(noteConnectionsProvider(notes.last.id)).hasValue, isTrue);
      }
      await tester.tap(find.byKey(ValueKey('browse-${notes.last.id}')));
      await tester.pump();
      await tester.pump();
      if (cold) {
        expect(find.byKey(const ValueKey('connections-placeholder')), findsOneWidget);
        held.pending.add(notes.last);
        await tester.pump(const Duration(milliseconds: 16));
        expect(find.byKey(const ValueKey('connections-placeholder')), findsOneWidget);
      } else {
        expect(find.byKey(const ValueKey('connections-list')), findsOneWidget);
      }
      await tester.pump(const Duration(seconds: 1));
      final screen = find.byType(NoteConnectionsScreen);
      final context = tester.element(screen);
      final animation = ModalRoute.of(context)!.animation!;
      expect(animation.status, AnimationStatus.completed);
      final container = ProviderScope.containerOf(context);
      final provider = noteConnectionsProvider(notes.last.id);
      final removed = container.read(provider).requireValue.confirmed.single;
      final row = find.byKey(ValueKey('connection-${removed.other.id}'));
      expect(row, findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(animation.status, AnimationStatus.reverse);
      // A repository write finishes after Back has started. Its derivation
      // must replace the live snapshot while the departing page is visible.
      await pumpFuture(tester, () => container.read(linksRepoProvider).removeLink(removed.link.id));
      for (var i = 0; i < 5 && container.read(provider).requireValue.confirmed.isNotEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 1));
      }
      expect(container.read(provider).requireValue.confirmed, isEmpty);
      expect(animation.status, AnimationStatus.reverse, reason: 'assert the update midway through the pop');
      expect(screen, findsOneWidget);
      expect(find.byKey(const ValueKey('connections-list')), findsOneWidget);
      expect(find.byKey(const ValueKey('connections-placeholder')), findsNothing);
      expect(row, findsNothing, reason: 'the entry snapshot must never resurrect removed connections');
      await tester.pump(const Duration(seconds: 1));
      expect(screen, findsNothing);
    }, notesRepository: (db) => held = _HeldNoteRepository(db));
  }

  for (final path in ['/links/note/', '/note/']) {
    fikraTest('cold deep link $path paints an opaque placeholder without preview', (tester, db) async {
      phone(tester);
      addTearDown(() => unawaited(held.pending.close()));
      final notes = await seedLibrary(tester, db);
      held.hold = true;
      final container = ProviderScope.containerOf(
        tester.element(find.byKey(LinksLibrarySegment.key(LinksLibrarySegment.browse))),
      );
      // Drop the shared derived snapshot too: this is a genuinely cold entry.
      container.invalidate(linksLibraryProvider(notes.last.projectId));
      final context = tester.element(find.byKey(LinksLibrarySegment.key(LinksLibrarySegment.browse)));
      context.go(
        '$path${notes.last.id}',
        extra: path.startsWith('/links') ? (projectNote(notes.first), null) : notes.first,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      final connections = path.startsWith('/links');
      final screen = find.byType(connections ? NoteConnectionsScreen : NoteDetailsScreen);
      expect(find.byKey(ValueKey(connections ? 'connections-placeholder' : 'note-placeholder')), findsOneWidget);
      expect(
        find.descendant(of: screen, matching: find.text(notes.first.title)),
        findsNothing,
        reason: 'a mismatched preview is ignored',
      );
      await _expectOpaquePearl(tester, screen);
    }, notesRepository: (db) => held = _HeldNoteRepository(db));
  }

  for (final locale in [const Locale('ar'), const Locale('en')]) {
    fikraTest(
      'connections, options, picker, full note, branch back and graph (${locale.languageCode})',
      locale: locale,
      (tester, db) async {
        phone(tester);
        final l10n = locale.languageCode == 'ar' ? arL10n : enL10n;
        final notes = await seedLibrary(tester, db, l10n: l10n);
        await openNoteConnections(tester, notes, 5);
        expect(find.text(l10n.linksConfirmed), findsOneWidget);
        expect(find.byKey(ValueKey('connection-${notes[4].id}')), findsOneWidget);
        expect(find.byType(SuggestionCard), findsOneWidget);
        expect(find.byKey(const ValueKey('floating-tab-bar')), findsOneWidget);
        await tester.tap(find.byKey(ValueKey('connection-options-${notes[4].id}')));
        await tester.pump();
        await tester.pumpAndSettle();
        expect(find.text(l10n.editLinkReason), findsOneWidget);
        expect(find.text(l10n.removeLink), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.longPress(find.byKey(ValueKey('connection-${notes[4].id}')));
        await tester.pump();
        await tester.pumpAndSettle();
        expect(find.text(l10n.editLinkReason), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('connections-link-picker')));
        await tester.pump();
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('link-search')), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('connections-note')));
        await tester.pumpAndSettle();
        expect(find.byType(NoteDetailsScreen), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('connection-${notes[4].id}')));
        await tester.pumpAndSettle();
        expect(tester.widget<NoteConnectionsScreen>(find.byType(NoteConnectionsScreen)).noteId, notes[4].id);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(tester.widget<NoteConnectionsScreen>(find.byType(NoteConnectionsScreen)).noteId, notes[5].id);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(LinksLibrarySegment.key(LinksLibrarySegment.map)));
        await tester.pumpAndSettle();
        expect(find.byType(LinksMap), findsOneWidget);
        expect(find.byType(InteractiveViewer), findsOneWidget);
        await tester.tap(find.byKey(LinksLibrarySegment.key(LinksLibrarySegment.browse)));
        await tester.pumpAndSettle();
        expect(find.byKey(LinksLibrarySegment.key(LinksLibrarySegment.browse)), findsOneWidget);
      },
    );
  }

  for (final move in [false, true]) {
    fikraTest('connections pops when its note is ${move ? 'moved' : 'deleted'}', (tester, db) async {
      phone(tester);
      final notes = await seedLibrary(tester, db);
      await openNoteConnections(tester, notes, 5);
      await pumpFuture(tester, () async {
        if (move) {
          final other = (await db.select(db.projects).get()).singleWhere((p) => p.id != notes[5].projectId);
          await LocalNotesRepository(db).moveNotes([notes[5].id], other.id);
        } else {
          await LocalNotesRepository(db).delete(notes[5].id);
        }
      });
      await tester.pumpAndSettle();
      expect(find.byType(NoteConnectionsScreen), findsNothing);
      expect(find.byKey(LinksLibrarySegment.key(LinksLibrarySegment.browse)), findsOneWidget);
    });
  }

  fikraTest('invalid background connections cannot pop a newer full note route', (tester, db) async {
    phone(tester);
    final notes = await seedLibrary(tester, db);
    await openNoteConnections(tester, notes, 5);
    final context = tester.element(find.byType(NoteConnectionsScreen));
    context.push('/note/${notes[4].id}', extra: notes[4]);
    await tester.pumpAndSettle();
    await pumpFuture(tester, () => LocalNotesRepository(db).delete(notes[5].id));
    await tester.pumpAndSettle();
    expect(find.byType(NoteDetailsScreen), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(NoteConnectionsScreen), findsNothing);
  });

  fikraTest('a suggestion row for the page\'s own note does not push the same page again', (tester, db) async {
    phone(tester);
    final notes = await seedLibrary(tester, db);
    await openNoteConnections(tester, notes, 5);
    final card = tester.widget<SuggestionCard>(find.byType(SuggestionCard));
    final self = find.byKey(ValueKey('suggestion-note-${card.entry.link.id}-${notes[5].id}'));
    await tester.scrollUntilVisible(self, 200, scrollable: connectionsScroll);
    await tester.pumpAndSettle();
    await tester.tap(self);
    await tester.pumpAndSettle();
    expect(find.byType(NoteConnectionsScreen, skipOffstage: false), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('suggestion-note-${card.entry.link.id}-${notes[2].id}')));
    await tester.pumpAndSettle();
    expect(tester.widget<NoteConnectionsScreen>(find.byType(NoteConnectionsScreen)).noteId, notes[2].id);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(tester.widget<NoteConnectionsScreen>(find.byType(NoteConnectionsScreen)).noteId, notes[5].id);
  });
}
