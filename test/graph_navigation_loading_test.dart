import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:fikra/app/providers.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/features/links/graph_layout.dart';
import 'package:fikra/features/links/graph_session.dart';
import 'package:fikra/features/links/links_screen.dart';
import 'package:fikra/features/shared/note_groups.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'graph_navigation_fixture.dart';
import 'support/selection_fixture.dart' show host;

void main() {
  testWidgets('chips and indexed search results wait for an installed layout', (t) async {
    final now = DateTime(2026);
    final p = Project(id: 'p', name: 'Project', createdAt: now);
    final group = NoteGroup(id: 'g', projectId: p.id, name: 'Group', position: 0, createdAt: now);
    final notes = [
      for (var i = 0; i < 301; i++)
        Note(
          id: '$i',
          projectId: p.id,
          title: 'Find $i',
          originalText: '',
          source: NoteSource.text,
          status: ProcessingStatus.ready,
          rewrite: RewriteStatus.none,
          imagePaths: '',
          concepts: '',
          createdAt: now,
          updatedAt: now,
        ),
    ];
    final links = StreamController<List<NoteLink>>();
    // Not awaited in the body: once cancelled, close() returns a root-zone future
    // and the fake-async test body would never be seen to finish.
    addTearDown(links.close);
    final source = StreamProvider((ref) => links.stream);
    final worker = Completer<GraphLayout>();
    GraphInput? input;
    await host(
      t,
      const LinksScreen(),
      locale: const Locale('en'),
      overrides: [
        selectedProjectProvider.overrideWithValue(p),
        selectedNotesProvider.overrideWithValue(AsyncData(notes)),
        selectedLinksProvider.overrideWith((ref) => ref.watch(source)),
        groupsOfProjectProvider(p.id).overrideWith((ref) => Stream.value([group])),
        graphLayoutWorkerProvider.overrideWithValue((value) {
          input = value;
          return worker.future;
        }),
      ],
    );
    await navPump(t);
    final chip = navKey('group-filter-g');
    expect(chip, findsOneWidget);
    expect(t.getSemantics(chip).flagsCollection.isEnabled, Tristate.isFalse);
    await t.tap(chip);
    await navPump(t);
    expect(t.takeException(), isNull);
    expect(input, isNull);

    // Data is now indexed, but its first isolate result has not arrived.
    links.add([]);
    await navPump(t);
    expect(input, isNotNull);
    await graphQuery(t, 'Find 0');
    final result = navKey('graph-search-note-0');
    final tile = t.widget<ListTile>(result);
    expect(tile.enabled, isFalse);
    expect(tile.onTap, isNull);
    await t.tap(result);
    await navPump(t);
    expect(navKey('graph-search-field'), findsOneWidget);
    expect(t.takeException(), isNull);

    worker.complete(GraphLayout.fromInput(input!));
    await navPump(t);
    expect(t.widget<ListTile>(result).onTap, isNotNull);
    await t.tap(navKey('graph-search-close'));
    await navPump(t);
    expect(t.getSemantics(chip).flagsCollection.isEnabled, Tristate.isTrue);
    await t.tap(chip);
    await navPump(t);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });
}
