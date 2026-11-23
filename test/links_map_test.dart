import 'package:drift/drift.dart' show Value;
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/features/connections/library_session.dart';
import 'package:fikra/features/connections/map_canvas.dart';
import 'package:fikra/features/connections/map_provider.dart';
import 'package:fikra/features/connections/note_connections_screen.dart';
import 'package:fikra/features/note_details/note_details_screen.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'support/app_harness.dart';
import 'support/links_library_fixture.dart';
import 'support/selection_fixture.dart';

void main() {
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    final l10n = lookupAppLocalizations(locale);
    fikraTest(
      'Map defaults per project, remembers choices, and legacy route selects Map (${locale.languageCode})',
      locale: locale,
      (tester, db) async {
        phone(tester);
        final notes = await seedLibrary(tester, db, l10n: l10n, browse: false);
        await pumpUntil(tester, find.byKey(const ValueKey('map-paint')));
        final context = tester.element(find.byKey(const ValueKey('map-paint')));
        final container = ProviderScope.containerOf(context);
        final router = GoRouter.of(context);
        expect(container.read(linksSegmentProvider)[notes.first.projectId] ?? 0, 0);
        await librarySegment(tester, 1);
        await tester.tap(Tabs.finder(Tabs.notes));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(Tabs.finder(Tabs.links));
        await tester.pump(const Duration(milliseconds: 300));
        expect(container.read(linksSegmentProvider)[notes.first.projectId], 2);
        final other = (await pumpFuture(
          tester,
          () => db.select(db.projects).get(),
        )).singleWhere((p) => p.id != notes.first.projectId);
        await pumpFuture(tester, () => LocalProjectsRepository(db).setCurrent(other.id));
        await pumpUntil(tester, find.text(other.name));
        expect(container.read(linksSegmentProvider)[other.id] ?? 0, 0);
        await pumpFuture(tester, () => LocalProjectsRepository(db).setCurrent(notes.first.projectId));
        await tester.pump(const Duration(milliseconds: 400));
        expect(container.read(linksSegmentProvider)[notes.first.projectId], 2);
        router.go('/links/graph');
        await tester.pump(const Duration(milliseconds: 400));
        await pumpUntil(tester, find.byKey(const ValueKey('map-paint')));
        expect(router.routeInformationProvider.value.uri.path, '/links');
        expect(container.read(linksSegmentProvider)[notes.first.projectId], 0);
      },
    );

    fikraTest(
      'painted cluster and note taps update breadcrumbs, card, semantics and open route (${locale.languageCode})',
      locale: locale,
      (tester, db) async {
        phone(tester);
        final notes = await seedLibrary(tester, db, l10n: l10n, browse: false);
        await pumpUntil(tester, find.byKey(const ValueKey('map-paint')));
        final semantics = tester.ensureSemantics();
        try {
          expect(find.bySemanticsLabel(l10n.mapCanvasSummary(6, 0)), findsOneWidget);
          final paint = tester.widget<CustomPaint>(find.byKey(const ValueKey('map-paint'))).painter! as LinksMapPainter;
          expect(paint.nodes.length, lessThanOrEqualTo(8));
          expect(find.semantics.byLabel(RegExp('^Study, ')), findsOneWidget);
          await tapMapNode(tester, 'group:parent');
          expect(
            find.descendant(of: find.byKey(const ValueKey('map-breadcrumbs')), matching: find.text('Study')),
            findsNWidgets(2),
          );
          expect(find.byKey(const ValueKey('map-open-cluster')), findsOneWidget);
          await tapMapNode(tester, notes[0].id);
          expect(
            find.descendant(of: find.byKey(const ValueKey('map-card')), matching: find.text('Note 0')),
            findsOneWidget,
          );
          expect(
            find.descendant(of: find.byKey(const ValueKey('map-breadcrumbs')), matching: find.text('Note 0')),
            findsOneWidget,
          );
          expect(find.semantics.byLabel(RegExp('^Note 1, ')), findsOneWidget);
          final viewer = tester.widget<InteractiveViewer>(find.byKey(const ValueKey('map-viewport')));
          final before =
              tester.widget<CustomPaint>(find.byKey(const ValueKey('map-paint'))).painter! as LinksMapPainter;
          viewer.transformationController!.value = viewer.transformationController!.value.clone()
            ..translateByDouble(-20, -15, 0, 1);
          await tester.pump();
          final after = tester.widget<CustomPaint>(find.byKey(const ValueKey('map-paint'))).painter! as LinksMapPainter;
          expect(identical(before.picture, after.picture), isTrue);
          await tester.ensureVisible(find.byKey(const ValueKey('map-open-note')));
          await tester.pump();
          await tester.tap(find.byKey(const ValueKey('map-open-note')));
          // «افتح» opens the note itself (its details screen), not the connections list.
          await pumpUntil(tester, find.byType(NoteDetailsScreen));
          await tester.pump(const Duration(milliseconds: 400));
          expect(find.byType(NoteDetailsScreen), findsOneWidget);
          expect(find.byType(NoteConnectionsScreen), findsNothing);
          await tester.binding.handlePopRoute();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          await tester.binding.handlePopRoute();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byKey(const ValueKey('map-open-cluster')), findsOneWidget);
          await tester.binding.handlePopRoute();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byKey(const ValueKey('map-back')), findsNothing);
        } finally {
          semantics.dispose();
        }
      },
    );

    fikraTest(
      'search reaches isolated notes and cache invalidates after a note edit (${locale.languageCode})',
      locale: locale,
      (tester, db) async {
        phone(tester);
        final notes = await seedLibrary(tester, db, l10n: l10n, browse: false);
        await pumpUntil(tester, find.byKey(const ValueKey('map-paint')));
        final scope = ProviderScope.containerOf(tester.element(find.byKey(const ValueKey('map-paint'))));
        final first = await pumpFuture(tester, () => scope.read(linksMapProvider(notes[0].projectId).future));
        final picture =
            (tester.widget<CustomPaint>(find.byKey(const ValueKey('map-paint'))).painter! as LinksMapPainter).picture;
        await pumpFuture(
          tester,
          () => (db.update(
            db.notes,
          )..where((n) => n.id.equals(notes[0].id))).write(const NotesCompanion(title: Value('Changed title'))),
        );
        await tester.pump(const Duration(milliseconds: 300));
        final next = await pumpFuture(tester, () => scope.read(linksMapProvider(notes[0].projectId).future));
        expect(identical(first, next), isFalse);
        await tester.pump();
        expect(
          (tester.widget<CustomPaint>(find.byKey(const ValueKey('map-paint'))).painter! as LinksMapPainter).picture,
          isNot(same(picture)),
        );
        await tester.enterText(find.byKey(const ValueKey('links-search')), 'Changed title');
        await tester.pump(const Duration(milliseconds: 220));
        await tester.tap(find.byKey(ValueKey('map-search-${notes[0].id}')));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byKey(const ValueKey('map-open-note')), findsOneWidget);
        expect(
          find.descendant(of: find.byKey(const ValueKey('map-breadcrumbs')), matching: find.text('Changed title')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('map-back')));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byKey(const ValueKey('map-open-cluster')), findsOneWidget);
        final isolated = await pumpFuture(tester, () async {
          final repo = LocalNotesRepository(db);
          final n = await repo.create(
            projectId: notes.first.projectId,
            title: 'Isolated thought',
            text: 'body',
            source: NoteSource.text,
          );
          await repo.markReady(n.id);
          return n;
        });
        await tester.enterText(find.byKey(const ValueKey('links-search')), 'Isolated thought');
        await tester.pump(const Duration(milliseconds: 220));
        await pumpUntil(tester, find.byKey(ValueKey('map-search-${isolated.id}')));
        await tester.tap(find.byKey(ValueKey('map-search-${isolated.id}')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          find.descendant(of: find.byKey(const ValueKey('map-card')), matching: find.text('Isolated thought')),
          findsOneWidget,
        );
      },
    );
  }

  fikraTest('Map +N opens a solid list and focuses an omitted note', (tester, db) async {
    phone(tester);
    final notes = await seedLibrary(tester, db, count: 27, browse: false);
    await pumpUntil(tester, find.byKey(const ValueKey('map-paint')));
    final scope = ProviderScope.containerOf(tester.element(find.byKey(const ValueKey('map-paint'))));
    final index = await pumpFuture(tester, () => scope.read(linksMapProvider(notes.first.projectId).future));
    // Ungrouped notes fall back to their AI topic (cluster 'Ideas'), not to 'others'.
    final hidden = index.clusters.singleWhere((c) => c.id == 'topic:Ideas').notes.last;
    await tapMapNode(tester, 'topic:Ideas');
    final painter = tester.widget<CustomPaint>(find.byKey(const ValueKey('map-paint'))).painter! as LinksMapPainter;
    expect(painter.nodes.last.count, 5);
    await tester.tap(find.byKey(const ValueKey('map-show-more')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final row = find.byKey(ValueKey('map-more-$hidden'));
    final scroll = find.descendant(of: find.byKey(const ValueKey('map-more-list')), matching: find.byType(Scrollable));
    await tester.scrollUntilVisible(row, 160, scrollable: scroll);
    await tester.pump();
    await tester.tap(row);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.descendant(of: find.byKey(const ValueKey('map-card')), matching: find.text(index.notes[hidden]!.title)),
      findsOneWidget,
    );
  });

  for (final accept in [true, false]) {
    late LibrarySpy spy;
    fikraTest(
      'Map ${accept ? 'accept' : 'reject'} suggestion uses shared actions and Undo',
      linksRepository: (db) => spy = LibrarySpy(db),
      (tester, db) async {
        phone(tester);
        final notes = await seedLibrary(tester, db, browse: false);
        await pumpUntil(tester, find.byKey(const ValueKey('map-paint')));
        await tapMapNode(tester, 'group:parent');
        await tapMapNode(tester, notes[0].id);
        await tapMapNode(tester, notes[3].id);
        final action = find.byKey(ValueKey('map-${accept ? 'accept' : 'reject'}'));
        await tester.ensureVisible(action);
        await tester.pump();
        await tester.tap(action);
        await pumpUntil(tester, find.text(arL10n.undo));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text(arL10n.undo));
        await pumpFuture(tester, () => spy.pending!);
        await tester.pump(const Duration(milliseconds: 500));
        await pumpUntil(tester, action);
        expect(tester.widget<TextButton>(action).onPressed, isNotNull);
      },
    );
  }

  for (final locale in [const Locale('ar'), const Locale('en')]) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      fikraTest(
        'Map 360dp at 2x text (${locale.languageCode}, ${brightness.name})',
        locale: locale,
        brightness: brightness,
        textScale: 2,
        (tester, db) async {
          phone(tester);
          tester.view.physicalSize = const Size(1080, 2400);
          tester.view.devicePixelRatio = 3;
          final notes = await seedLibrary(tester, db, l10n: lookupAppLocalizations(locale), browse: false);
          await pumpUntil(tester, find.byKey(const ValueKey('map-paint')));
          expect(tester.takeException(), isNull);
          await tapMapNode(tester, 'group:parent');
          expect(tester.takeException(), isNull);
          await tapMapNode(tester, notes[0].id);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
