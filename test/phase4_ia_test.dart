import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:drift/drift.dart' show Value;
import 'package:fikra/app/providers.dart';
import 'package:fikra/core/motion/pressable.dart';
import 'package:fikra/core/theme/fikra_theme.dart';
import 'package:fikra/core/theme/tokens.dart';
import 'package:fikra/core/widgets/fikra_widgets.dart';
import 'package:fikra/data/links_repository.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/data/transcription/service_config.dart';
import 'package:fikra/data/transcription/services_repository.dart';
import 'package:fikra/features/note_details/edit_note_screen.dart';
import 'package:fikra/features/note_details/note_details_screen.dart';
import 'package:fikra/features/projects/project_header.dart';
import 'package:fikra/features/settings/settings_screen.dart';
import 'package:fikra/features/shared/project_picker.dart';
import 'package:fikra/features/voice_text/service_form_screen.dart';
import 'package:fikra/features/voice_text/voice_text_engines.dart';
import 'package:fikra/features/voice_text/voice_text_screen.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/app_harness.dart';
import 'support/fake_external_transcription.dart';
import 'support/transcription_scroll.dart';
import 'voice_text/fake_voice_text_backend.dart';

void main() {
  setUpAll(loadAppFonts);

  void phone(WidgetTester tester, {Size size = const Size(390, 844)}) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
  }

  Future<void> withSemantics(WidgetTester tester, Future<void> Function() body) async {
    final semantics = tester.ensureSemantics();
    try {
      await body();
    } finally {
      semantics.dispose();
    }
  }

  /// Scroll-independent vertical coordinate inside [screen]'s outer Scrollable.
  Future<double> contentTop(WidgetTester tester, Type screen, Finder target) async {
    final scrollable = transcriptionScrollable(screen);
    final state = tester.state<ScrollableState>(scrollable);
    state.position.jumpTo(0);
    await tester.pump();
    await tester.scrollUntilVisible(target, 140, scrollable: scrollable);
    await tester.pump();
    return state.position.pixels + tester.getTopLeft(target).dy;
  }

  for (final code in ['ar', 'en']) {
    final locale = Locale(code);
    final l = lookupAppLocalizations(locale);
    final settingsKeys = MemoryServiceKeys();

    fikraTest(
      'Settings has six ordered sections, connected services, and red Erase all alone at the bottom ($code)',
      locale: locale,
      serviceKeys: settingsKeys,
      (tester, db) => withSemantics(tester, () async {
        phone(tester);
        await pumpUntil(tester, find.text(l.welcomeStartWriting));
        final project = await pumpFuture(tester, () => LocalProjectsRepository(db).create('Alpha'));
        await pumpFuture(
          tester,
          () =>
              LocalNotesRepository(db)
                  .create(projectId: project.id, title: 'Keep me', text: 'Body', source: NoteSource.text),
        );
        const savedService = TranscriptionService(
          id: 'svc-1',
          name: 'Cloud STT',
          type: TranscriptionServiceType.openAi,
          baseUrl: 'https://api.openai.com/v1',
          batchModel: 'whisper-1',
        );
        await pumpFuture(
          tester,
          () => LocalTranscriptionServices(db, settingsKeys).save(savedService, key: 'secret-key'),
        );
        await pumpUntil(tester, find.text('Alpha'));

        await tester.tap(find.byKey(const ValueKey('header-settings')));
        await pumpUntil(tester, find.byType(SettingsScreen));
        await tester.pump(const Duration(milliseconds: 500));

        final sections = [
          l.appearance,
          l.languageSection,
          l.vtVoiceSection,
          l.servicesSection,
          l.privacySection,
          l.aboutSection,
        ];
        final sectionTops = <double>[];
        for (final heading in sections) {
          final finder = find.text(heading);
          final top = await contentTop(tester, SettingsScreen, finder);
          expect(tester.getSemantics(finder).flagsCollection.isHeader, isTrue, reason: '$heading must be a header');
          sectionTops.add(top);
        }
        for (var i = 1; i < sectionTops.length; i++) {
          expect(
            sectionTops[i],
            greaterThan(sectionTops[i - 1]),
            reason: '${sections[i]} must come after ${sections[i - 1]}',
          );
        }

        final serviceRow = find.byKey(ValueKey('settings-service-${savedService.id}'));
        final addServiceRow = find.byKey(const ValueKey('settings-add-service'));
        final serviceTop = await contentTop(tester, SettingsScreen, serviceRow);
        final addServiceTop = await contentTop(tester, SettingsScreen, addServiceRow);
        expect(serviceTop, greaterThan(sectionTops[3]));
        expect(addServiceTop, greaterThan(serviceTop));
        expect(addServiceTop, lessThan(sectionTops[4]));

        // Navigating to edit service and add service routes from Settings.
        await tester.tap(serviceRow);
        await pumpUntil(tester, find.byType(ServiceFormScreen));
        await tester.pump(const Duration(milliseconds: 400));
        tester.element(find.byType(ServiceFormScreen)).pop();
        await pumpUntil(tester, find.byType(SettingsScreen));
        await tester.pump(const Duration(milliseconds: 400));

        await contentTop(tester, SettingsScreen, addServiceRow);
        await tester.tap(addServiceRow);
        await pumpUntil(tester, find.byType(ServiceFormScreen));
        await tester.pump(const Duration(milliseconds: 400));
        tester.element(find.byType(ServiceFormScreen)).pop();
        await pumpUntil(tester, find.byType(SettingsScreen));
        await tester.pump(const Duration(milliseconds: 400));

        // Erase all data sits alone at the very bottom, separated and red, behind confirmation.
        final aboutCardTop = await contentTop(tester, SettingsScreen, find.text(l.tagline));
        final eraseFinder = find.byKey(const ValueKey('settings-erase-all'));
        final eraseTop = await contentTop(tester, SettingsScreen, eraseFinder);
        expect(eraseTop, greaterThan(aboutCardTop + 32));
        final eraseOption = tester.widget<SheetOption>(eraseFinder);
        expect(eraseOption.danger, isTrue);
        final dangerColor = tester.element(eraseFinder).colors.danger;
        final eraseText = tester.widget<Text>(find.descendant(of: eraseFinder, matching: find.text(l.eraseAll)));
        expect(eraseText.style?.color, dangerColor);
        expect(tester.getSize(eraseFinder).height, greaterThanOrEqualTo(Pressable.minTargetSize));

        await tester.tap(eraseFinder);
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text(l.eraseAllTitle), findsOneWidget);
        await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text(l.cancel)));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(SettingsScreen), findsOneWidget);

        await tester.tap(eraseFinder);
        await tester.pump(const Duration(milliseconds: 400));
        await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text(l.eraseAllConfirm)));
        await pumpUntil(tester, find.text(l.welcomeStartWriting));
      }),
    );
  }

  for (final code in ['ar', 'en']) {
    final locale = Locale(code);
    final l = lookupAppLocalizations(locale);
    final voiceBackend = FakeVoiceTextBackend()..seed();

    fikraTest(
      'Voice-to-text screen order and collapsed For testing under normal and reduced motion ($code)',
      locale: locale,
      voiceTextBackend: voiceBackend,
      (tester, db) => withSemantics(tester, () async {
        addTearDown(() => unawaited(voiceBackend.dispose()));
        phone(tester);

        await pumpUntil(tester, find.text(l.welcomeStartWriting));
        await pumpFuture(tester, () => LocalProjectsRepository(db).create('Voice project'));
        await pumpUntil(tester, find.text('Voice project'));

        tester.element(find.text('Voice project')).push('/settings/voice-text');
        await pumpUntil(tester, find.byWidgetPredicate((w) => w is VoiceTextEngines && w.enabled));
        await tester.pump(const Duration(milliseconds: 500));

        final engineTop = await contentTop(tester, VoiceTextScreen, find.text(l.vsEngine));
        final modelTop = await contentTop(tester, VoiceTextScreen, find.text(l.vtModel));
        final languageTop = await contentTop(tester, VoiceTextScreen, find.text(l.vtLanguage));
        final autoTop = await contentTop(tester, VoiceTextScreen, find.byKey(const ValueKey('vt-auto-transcribe')));
        final tryTop = await contentTop(tester, VoiceTextScreen, find.text(l.vtTry));
        final recordTop = await contentTop(tester, VoiceTextScreen, find.byKey(const ValueKey('vt-record')));
        final tryTranscribeTop = await contentTop(
          tester,
          VoiceTextScreen,
          find.byKey(const ValueKey('vt-try-transcribe')),
        );
        final liveTop = await contentTop(tester, VoiceTextScreen, find.byKey(const ValueKey('vt-live')));
        final testingToggle = find.byKey(const ValueKey('vt-testing-toggle'));
        final testingTop = await contentTop(tester, VoiceTextScreen, testingToggle);

        expect(modelTop, greaterThan(engineTop));
        expect(languageTop, greaterThan(modelTop));
        expect(autoTop, greaterThan(languageTop));
        expect(tryTop, greaterThan(autoTop));
        expect(recordTop, greaterThan(tryTop));
        expect(tryTranscribeTop, greaterThan(recordTop));
        expect(liveTop, greaterThan(tryTranscribeTop));
        expect(testingTop, greaterThan(liveTop));

        // Technical "For testing" area is collapsed by default at the bottom.
        expect(find.byKey(const ValueKey('vt-testing-content')), findsNothing);
        expect(tester.getSemantics(testingToggle).flagsCollection.isExpanded, Tristate.isFalse);

        // Normal motion expand + collapse.
        await tester.tap(testingToggle);
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byKey(const ValueKey('vt-testing-content')), findsOneWidget);
        expect(tester.getSemantics(testingToggle).flagsCollection.isExpanded, Tristate.isTrue);

        await tester.tap(testingToggle);
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byKey(const ValueKey('vt-testing-content')), findsNothing);

        // Reduce Motion expand + collapse must not trigger a zero-duration AnimatedSize assertion.
        tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
          disableAnimations: true,
        );
        addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
        await tester.pump();

        await contentTop(tester, VoiceTextScreen, testingToggle);
        await tester.tap(testingToggle);
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('vt-testing-content')), findsOneWidget);

        await tester.tap(testingToggle);
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('vt-testing-content')), findsNothing);
      }),
    );
  }

  for (final code in ['ar', 'en']) {
    final locale = Locale(code);
    final l = lookupAppLocalizations(locale);

    fikraTest(
      'Notes list supports Newest first and Oldest first, composes with filters, and persists in session ($code)',
      locale: locale,
      clock: () => DateTime(2026, 11, 10, 12),
      (tester, db) => withSemantics(tester, () async {
        phone(tester);

        await pumpUntil(tester, find.text(l.welcomeStartWriting));
        final (n1, n2, n3, group) = await pumpFuture(tester, () async {
          final p = await LocalProjectsRepository(db).create('Notes order');
          final notesRepo = LocalNotesRepository(db);
          final a = await notesRepo.create(
            projectId: p.id,
            title: 'First note',
            text: 'common alpha',
            source: NoteSource.text,
            createdAt: DateTime(2026, 11, 8, 9),
          );
          final b = await notesRepo.create(
            projectId: p.id,
            title: 'Second note',
            text: 'common beta',
            source: NoteSource.text,
            createdAt: DateTime(2026, 11, 10, 10),
          );
          final c = await notesRepo.create(
            projectId: p.id,
            title: 'Third note',
            text: 'common gamma',
            source: NoteSource.text,
            createdAt: DateTime(2026, 11, 10, 11),
          );
          final g = NoteGroup(id: 'g1', projectId: p.id, name: 'Topic', position: 0, createdAt: DateTime(2026, 11, 8));
          await db.into(db.noteGroups).insert(g);
          await (db.update(
            db.notes,
          )..where((t) => t.id.isIn([a.id, c.id]))).write(const NotesCompanion(groupId: Value('g1')));
          return (a, b, c, g);
        });
        await pumpUntil(tester, find.text('Third note'));
        await tester.pump(const Duration(milliseconds: 400));

        // Default: Newest first (n3, n2, n1).
        expect(
          tester.getTopLeft(find.byKey(ValueKey(n3.id))).dy,
          lessThan(tester.getTopLeft(find.byKey(ValueKey(n2.id))).dy),
        );
        expect(
          tester.getTopLeft(find.byKey(ValueKey(n2.id))).dy,
          lessThan(tester.getTopLeft(find.byKey(ValueKey(n1.id))).dy),
        );

        final sortButton = find.byKey(const ValueKey('notes-sort'));
        expect(tester.getSize(sortButton).width, greaterThanOrEqualTo(Pressable.minTargetSize));
        expect(tester.getSize(sortButton).height, greaterThanOrEqualTo(Pressable.minTargetSize));
        expect(tester.getSemantics(sortButton).label, l.notesSort);

        await tester.tap(sortButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.text(l.linksNewest), findsOneWidget);
        expect(find.text(l.linksOldest), findsOneWidget);
        expect(
          tester
              .getSemantics(
                find.descendant(of: find.byKey(const ValueKey('notes-sort-newest')), matching: find.byType(Pressable)),
              )
              .flagsCollection
              .isSelected,
          Tristate.isTrue,
        );
        expect(
          tester
              .getSemantics(
                find.descendant(of: find.byKey(const ValueKey('notes-sort-oldest')), matching: find.byType(Pressable)),
              )
              .flagsCollection
              .isSelected,
          Tristate.isFalse,
        );

        await tester.tap(find.byKey(const ValueKey('notes-sort-oldest')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        // Oldest first: n1, n2, n3, and older date header above today's header.
        expect(
          tester.getTopLeft(find.byKey(ValueKey(n1.id))).dy,
          lessThan(tester.getTopLeft(find.byKey(ValueKey(n2.id))).dy),
        );
        expect(
          tester.getTopLeft(find.byKey(ValueKey(n2.id))).dy,
          lessThan(tester.getTopLeft(find.byKey(ValueKey(n3.id))).dy),
        );
        expect(find.text(l.today), findsOneWidget);
        expect(tester.getTopLeft(find.byKey(ValueKey(n1.id))).dy, lessThan(tester.getTopLeft(find.text(l.today)).dy));

        // Composes with group filter.
        await tester.tap(find.byKey(ValueKey('group-filter-${group.id}')));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byKey(ValueKey(n2.id)), findsNothing);
        expect(
          tester.getTopLeft(find.byKey(ValueKey(n1.id))).dy,
          lessThan(tester.getTopLeft(find.byKey(ValueKey(n3.id))).dy),
        );
        await tester.tap(find.byKey(ValueKey('group-filter-${group.id}')));
        await tester.pump(const Duration(milliseconds: 300));

        // Persists across tab switches within the session.
        await tester.tap(Tabs.finder(Tabs.ask));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.tap(Tabs.finder(Tabs.notes));
        await tester.pump(const Duration(milliseconds: 400));
        expect(
          tester.getTopLeft(find.byKey(ValueKey(n1.id))).dy,
          lessThan(tester.getTopLeft(find.byKey(ValueKey(n3.id))).dy),
        );

        await tester.tap(sortButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(
          tester
              .getSemantics(
                find.descendant(of: find.byKey(const ValueKey('notes-sort-oldest')), matching: find.byType(Pressable)),
              )
              .flagsCollection
              .isSelected,
          Tristate.isTrue,
        );
      }),
    );
  }

  fikraTest('Projects order current first, then remaining from most recent createdAt in switcher and picker', (
    tester,
    db,
  ) async {
    phone(tester);
    final ar = lookupAppLocalizations(const Locale('ar'));
    await pumpUntil(tester, find.text(ar.welcomeStartWriting));

    final (oldest, middle, newerA, newerB) = await pumpFuture(tester, () async {
      final repo = LocalProjectsRepository(db);
      // Seed explicit createdAt timestamps, including a same-second pair (newerA then newerB).
      await db
          .into(db.projects)
          .insert(ProjectsCompanion.insert(id: 'p-oldest', name: 'Oldest', createdAt: DateTime(2026, 1, 10, 10)));
      await db
          .into(db.projects)
          .insert(ProjectsCompanion.insert(id: 'p-middle', name: 'Middle', createdAt: DateTime(2026, 3, 15, 12)));
      await db
          .into(db.projects)
          .insert(ProjectsCompanion.insert(id: 'p-newer-a', name: 'Newer A', createdAt: DateTime(2026, 6, 20, 15)));
      await db
          .into(db.projects)
          .insert(ProjectsCompanion.insert(id: 'p-newer-b', name: 'Newer B', createdAt: DateTime(2026, 6, 20, 15)));
      await repo.setCurrent('p-middle');
      await LocalNotesRepository(db)
          .create(projectId: 'p-middle', title: 'Move candidate', text: 'Body', source: NoteSource.text);
      final rows = await db.select(db.projects).get();
      final byId = {for (final r in rows) r.id: r};
      return (byId['p-oldest']!, byId['p-middle']!, byId['p-newer-a']!, byId['p-newer-b']!);
    });
    await pumpUntil(tester, find.text('Middle'));
    await tester.pump(const Duration(milliseconds: 400));

    // Unit check on orderProjects with currentId.
    final summaries = <ProjectSummary>[
      (project: oldest, noteCount: 0),
      (project: middle, noteCount: 1),
      (project: newerA, noteCount: 0),
      (project: newerB, noteCount: 0),
    ];
    expect(orderProjects(summaries, currentId: middle.id).map((s) => s.project.id).toList(), [
      middle.id,
      newerB.id,
      newerA.id,
      oldest.id,
    ]);

    // Project switcher sheet: Middle (current) first, then Newer B, Newer A, Oldest.
    await tester.tap(find.bySemanticsLabel(ar.projectPillA11y('Middle')));
    await pumpUntil(tester, find.byKey(ValueKey('project-row-${oldest.id}')));
    await tester.pump(const Duration(milliseconds: 400));

    double rowY(String id) => tester.getTopLeft(find.byKey(ValueKey('project-row-$id'))).dy;
    expect(rowY(middle.id), lessThan(rowY(newerB.id)));
    expect(rowY(newerB.id), lessThan(rowY(newerA.id)));
    expect(rowY(newerA.id), lessThan(rowY(oldest.id)));

    // Switch current project to Oldest -> reopening switcher places Oldest first, then Newer B, Newer A, Middle.
    await tester.tap(find.byKey(ValueKey('project-row-${oldest.id}')));
    await pumpUntil(tester, find.text('Oldest'));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.bySemanticsLabel(ar.projectPillA11y('Oldest')));
    await pumpUntil(tester, find.byKey(ValueKey('project-row-${middle.id}')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(rowY(oldest.id), lessThan(rowY(newerB.id)));
    expect(rowY(newerB.id), lessThan(rowY(newerA.id)));
    expect(rowY(newerA.id), lessThan(rowY(middle.id)));

    // Switch back to Middle and verify showProjectPicker (move note) orders remaining from most recent.
    await tester.tap(find.byKey(ValueKey('project-row-${middle.id}')));
    await pumpUntil(tester, find.text('Move candidate'));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Move candidate'));
    await pumpUntil(tester, find.byType(NoteDetailsScreen));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.bySemanticsLabel(ar.options));
    await pumpUntil(tester, find.byKey(const ValueKey('note-move')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const ValueKey('note-move')));
    await pumpUntil(tester, find.byKey(ValueKey('project-pick-${oldest.id}')));
    await tester.pump(const Duration(milliseconds: 400));

    double pickY(String id) => tester.getTopLeft(find.byKey(ValueKey('project-pick-$id'))).dy;
    expect(find.byKey(ValueKey('project-pick-${middle.id}')), findsNothing);
    expect(pickY(newerB.id), lessThan(pickY(newerA.id)));
    expect(pickY(newerA.id), lessThan(pickY(oldest.id)));
  });

  fikraTest(
    'Search fields show an accessible clear (X) button when non-empty that clears text and keeps focus',
    (tester, db) => withSemantics(tester, () async {
      phone(tester);
      final ar = lookupAppLocalizations(const Locale('ar'));

      await pumpUntil(tester, find.text(ar.welcomeStartWriting));
      final (a, b) = await pumpFuture(tester, () async {
        final p = await LocalProjectsRepository(db).create('Search project');
        final notesRepo = LocalNotesRepository(db);
        final first = await notesRepo.create(
          projectId: p.id,
          title: 'Alpha idea',
          text: 'First body',
          source: NoteSource.text,
          createdAt: DateTime(2026, 11, 1),
        );
        final second = await notesRepo.create(
          projectId: p.id,
          title: 'Beta thought',
          text: 'Second body',
          source: NoteSource.text,
          createdAt: DateTime(2026, 11, 2),
        );
        await notesRepo.markReady(first.id);
        await notesRepo.markReady(second.id);
        await LocalLinksRepository(db).linkNotes(first.id, [second.id], label: 'related');
        return (first, second);
      });
      await pumpUntil(tester, find.text('Beta thought'));
      await tester.pump(const Duration(milliseconds: 400));

      Future<void> verifyClearField({
        required Finder fieldRoot,
        required String clearKey,
        required String query,
      }) async {
        final clearFinder = find.byKey(ValueKey(clearKey));
        expect(clearFinder, findsNothing);

        final textField = fieldRoot.evaluate().single.widget is TextField
            ? fieldRoot
            : find.descendant(of: fieldRoot, matching: find.byType(TextField));
        await tester.tap(textField);
        await tester.pump();
        await tester.enterText(textField, query);
        await tester.pump(const Duration(milliseconds: 250));

        expect(clearFinder, findsOneWidget);
        final size = tester.getSize(clearFinder);
        expect(size.width, greaterThanOrEqualTo(Pressable.minTargetSize));
        expect(size.height, greaterThanOrEqualTo(Pressable.minTargetSize));
        expect(tester.getSemantics(clearFinder).label, ar.clearSearch);

        await tester.tap(clearFinder);
        await tester.pump(const Duration(milliseconds: 100));

        expect(clearFinder, findsNothing);
        final editable = tester.widget<EditableText>(
          find.descendant(of: fieldRoot, matching: find.byType(EditableText)),
        );
        expect(editable.controller.text, isEmpty);
        expect(editable.focusNode.hasFocus, isTrue, reason: '$clearKey must preserve focus after clearing');
      }

      // 1. Notes list search.
      await verifyClearField(
        fieldRoot: find.byKey(const ValueKey('notes-search')),
        clearKey: 'notes-search-clear',
        query: 'Alpha',
      );
      expect(find.text('Beta thought'), findsOneWidget);

      // 2. Links library search.
      await tester.tap(Tabs.finder(Tabs.links));
      await pumpUntil(tester, find.byKey(const ValueKey('links-search')));
      await tester.pump(const Duration(milliseconds: 400));
      await verifyClearField(
        fieldRoot: find.byKey(const ValueKey('links-search')),
        clearKey: 'links-search-clear',
        query: 'Alpha',
      );

      // 3. Graph search panel.
      tester.testTextInput.hide();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byKey(const ValueKey('links-open-graph')));
      await pumpUntil(tester, find.byKey(const ValueKey('graph-search-open')));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byKey(const ValueKey('graph-search-open')));
      await pumpUntil(tester, find.byKey(const ValueKey('graph-search-field')));
      await tester.pump(const Duration(milliseconds: 300));
      // The panel's own close button already clears, so the field has no
      // second X next to it.
      final graphField = find.descendant(
        of: find.byKey(const ValueKey('graph-search-field')),
        matching: find.byType(TextField),
      );
      await tester.enterText(graphField, 'Alpha');
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byKey(const ValueKey('graph-search-clear')), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('graph-search-field')),
          matching: find.byIcon(Icons.close_rounded),
        ),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('graph-search-close')), findsOneWidget);
      await tester.enterText(graphField, '');
      await tester.pump(const Duration(milliseconds: 100));

      // 4. Link picker sheet search on Note details.
      tester.testTextInput.hide();
      await tester.pump(const Duration(milliseconds: 200));
      final extraNote = await pumpFuture(tester, () async {
        final n = await LocalNotesRepository(db).create(
          projectId: a.projectId,
          title: 'Gamma note',
          text: 'Third body',
          source: NoteSource.text,
          createdAt: DateTime(2026, 11, 3),
        );
        await LocalNotesRepository(db).markReady(n.id);
        return n;
      });
      tester.element(find.byType(Scaffold).last).push('/note/${extraNote.id}');
      await pumpUntil(
        tester,
        find.byWidgetPredicate((w) => w.key == const ValueKey('links-list') || w.key == const ValueKey('links-empty')),
      );
      await tester.pump(const Duration(milliseconds: 500));
      final linkBtn = find.byKey(const ValueKey('link-to-note'));
      await tester.ensureVisible(linkBtn);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(linkBtn);
      await pumpUntil(tester, find.byKey(const ValueKey('link-search')));
      await tester.pump(const Duration(milliseconds: 400));
      await verifyClearField(
        fieldRoot: find.byKey(const ValueKey('link-search')),
        clearKey: 'link-search-clear',
        query: b.title,
      );
    }),
  );

  for (final code in ['ar', 'en']) {
    final locale = Locale(code);
    final l = lookupAppLocalizations(locale);

    fikraTest(
      'Note details exposes a visible Edit button in the header in RTL/LTR and opens the editor ($code)',
      locale: locale,
      (tester, db) => withSemantics(tester, () async {
        phone(tester);

        await pumpUntil(tester, find.text(l.welcomeStartWriting));
        await pumpFuture(tester, () async {
          final p = await LocalProjectsRepository(db).create('Edit project');
          await LocalNotesRepository(db)
              .create(projectId: p.id, title: 'Editable note', text: 'Original content', source: NoteSource.text);
        });
        await pumpUntil(tester, find.text('Editable note'));
        await tester.tap(find.text('Editable note'));
        await pumpUntil(tester, find.byType(NoteDetailsScreen));
        await tester.pump(const Duration(milliseconds: 400));

        // Visible immediately without opening the options sheet.
        expect(find.byType(BottomSheet), findsNothing);
        final editButton = find.byKey(const ValueKey('note-edit'));
        expect(editButton, findsOneWidget);
        expect(find.descendant(of: editButton, matching: find.text(l.edit)), findsOneWidget);
        final editRect = tester.getRect(editButton);
        expect(editRect.width, greaterThanOrEqualTo(Pressable.minTargetSize));
        expect(editRect.height, greaterThanOrEqualTo(Pressable.minTargetSize));
        expect(tester.getSemantics(editButton).label, l.edit);

        // Directional order between Back and Options.
        final backRect = tester.getRect(find.bySemanticsLabel(l.back));
        final optionsRect = tester.getRect(find.bySemanticsLabel(l.options));
        if (code == 'ar') {
          expect(editRect.right, lessThanOrEqualTo(backRect.left));
          expect(editRect.left, greaterThanOrEqualTo(optionsRect.right));
        } else {
          expect(editRect.left, greaterThanOrEqualTo(backRect.right));
          expect(editRect.right, lessThanOrEqualTo(optionsRect.left));
        }

        // A double tap (both in the same frame) opens one editor.
        await tester.tap(editButton);
        await tester.tap(editButton);
        await pumpUntil(tester, find.byType(EditNoteScreen));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text(l.editNoteTitle), findsOneWidget);
        expect(find.byType(EditNoteScreen, skipOffstage: false), findsOneWidget);
      }),
    );
  }

  for (final code in ['ar', 'en']) {
    final locale = Locale(code);
    final l = lookupAppLocalizations(locale);

    fikraTest(
      'Main screen header icon controls show short labels when room allows ($code)',
      locale: locale,
      (tester, db) => withSemantics(tester, () async {
        phone(tester);

        await pumpUntil(tester, find.text(l.welcomeStartWriting));
        await pumpFuture(tester, () async {
          final p = await LocalProjectsRepository(db).create('Headers');
          await LocalNotesRepository(db).create(projectId: p.id, title: 'Seed', text: 'Body', source: NoteSource.text);
          await LocalChatRepository(db).add(projectId: p.id, role: 'user', body: 'Hello');
        });
        await pumpUntil(tester, find.text('Seed'));
        await tester.pump(const Duration(milliseconds: 400));

        void checkHeaderControl(Finder finder, {required String visibleLabel, required String a11y}) {
          expect(finder, findsOneWidget);
          final labelFinder = find.descendant(of: finder, matching: find.text(visibleLabel));
          final iconFinder = find.descendant(of: finder, matching: find.byType(Icon));
          final surfaceFinder = find.descendant(of: finder, matching: find.byType(SolidSurface));
          expect(labelFinder, findsOneWidget);
          expect(iconFinder, findsOneWidget);
          expect(surfaceFinder, findsOneWidget);
          expect(
            (tester.getCenter(iconFinder).dy - tester.getCenter(labelFinder).dy).abs(),
            lessThan(2),
            reason: '$visibleLabel must sit horizontally beside its icon',
          );
          expect(tester.getSize(surfaceFinder).height, greaterThanOrEqualTo(Pressable.minTargetSize));
          final size = tester.getSize(finder);
          expect(size.width, greaterThanOrEqualTo(Pressable.minTargetSize));
          expect(size.height, greaterThanOrEqualTo(Pressable.minTargetSize));
          expect(tester.getSemantics(finder).label, a11y);
        }

        // Notes header: Settings pill.
        checkHeaderControl(
          find.byKey(const ValueKey('header-settings')).hitTestable(),
          visibleLabel: l.settings,
          a11y: l.settings,
        );

        // Add header: Settings pill.
        await tester.tap(Tabs.addButton);
        await tester.pump(const Duration(milliseconds: 400));
        checkHeaderControl(
          find.byKey(const ValueKey('header-settings')).hitTestable(),
          visibleLabel: l.settings,
          a11y: l.settings,
        );

        // Links library header: Graph + Settings pills.
        await tester.tap(Tabs.finder(Tabs.links));
        await tester.pump(const Duration(milliseconds: 400));
        checkHeaderControl(
          find.byKey(const ValueKey('links-open-graph')).hitTestable(),
          visibleLabel: l.headerGraph,
          a11y: l.linksOpenGraph,
        );
        checkHeaderControl(
          find.byKey(const ValueKey('header-settings')).hitTestable(),
          visibleLabel: l.settings,
          a11y: l.settings,
        );

        // Graph header: Search + Settings pills.
        await tester.tap(find.byKey(const ValueKey('links-open-graph')).hitTestable());
        await pumpUntil(tester, find.byKey(const ValueKey('graph-search-open')));
        await tester.pump(const Duration(milliseconds: 500));
        checkHeaderControl(
          find.byKey(const ValueKey('graph-search-open')).hitTestable(),
          visibleLabel: l.headerSearch,
          a11y: l.graphSearchHint,
        );
        checkHeaderControl(
          find.byKey(const ValueKey('header-settings')).hitTestable(),
          visibleLabel: l.settings,
          a11y: l.settings,
        );
        tester.element(find.byKey(const ValueKey('graph-search-open')).hitTestable()).pop();
        await tester.pump(const Duration(milliseconds: 400));

        // Ask header: Clear + Settings pills.
        await tester.tap(Tabs.finder(Tabs.ask));
        await pumpUntil(tester, find.text('Hello'));
        await tester.pump(const Duration(milliseconds: 400));
        checkHeaderControl(
          find.byKey(const ValueKey('ask-clear-chat')).hitTestable(),
          visibleLabel: l.clear,
          a11y: l.clearChatA11y,
        );
        checkHeaderControl(
          find.byKey(const ValueKey('header-settings')).hitTestable(),
          visibleLabel: l.settings,
          a11y: l.settings,
        );
      }),
    );

    testWidgets(
      'Header short labels collapse cleanly at large text (2.5x, 320 dp) without overflow ($code)',
      (tester) => withSemantics(tester, () async {
        phone(tester, size: const Size(320, 640));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              selectedProjectProvider.overrideWithValue(
                Project(id: 'p1', name: l.sampleProjectName, createdAt: DateTime(2026, 11, 10)),
              ),
            ],
            child: MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: buildFikraTheme(Brightness.dark),
              home: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2.5)),
                  child: Scaffold(
                    body: ProjectHeader(
                      title: l.linksTitle,
                      trailing: HeaderActionButton(
                        key: const ValueKey('links-open-graph'),
                        icon: Icons.hub_outlined,
                        label: l.headerGraph,
                        semanticLabel: l.linksOpenGraph,
                        onTap: () {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final graphBtn = find.byKey(const ValueKey('links-open-graph'));
        final settingsBtn = find.byKey(const ValueKey('header-settings'));
        expect(find.descendant(of: graphBtn, matching: find.text(l.headerGraph)), findsNothing);
        expect(find.descendant(of: settingsBtn, matching: find.text(l.settings)), findsNothing);
        expect(tester.getSize(graphBtn).width, greaterThanOrEqualTo(Pressable.minTargetSize));
        expect(tester.getSize(settingsBtn).width, greaterThanOrEqualTo(Pressable.minTargetSize));
        expect(tester.getSize(find.descendant(of: graphBtn, matching: find.byType(SolidSurface))), const Size(48, 48));
        expect(
          tester.getSize(find.descendant(of: settingsBtn, matching: find.byType(SolidSurface))),
          const Size(48, 48),
        );
        expect(tester.widget<Icon>(find.descendant(of: settingsBtn, matching: find.byType(Icon))).size, 24);
        expect(tester.getSemantics(graphBtn).label, l.linksOpenGraph);
        expect(tester.getSemantics(settingsBtn).label, l.settings);
      }),
    );
  }

  fikraTest('clearing an unfocused search field leaves focus and the keyboard off', (tester, db) async {
    phone(tester);
    final ar = lookupAppLocalizations(const Locale('ar'));
    await pumpUntil(tester, find.text(ar.welcomeStartWriting));
    await pumpFuture(tester, () async {
      final p = await LocalProjectsRepository(db).create('Search project');
      final notesRepo = LocalNotesRepository(db);
      final first = await notesRepo.create(projectId: p.id, title: 'Alpha idea', text: 'One', source: NoteSource.text);
      final second = await notesRepo.create(projectId: p.id, title: 'Beta idea', text: 'Two', source: NoteSource.text);
      await notesRepo.markReady(first.id);
      await notesRepo.markReady(second.id);
      await LocalLinksRepository(db).linkNotes(first.id, [second.id]);
    });
    await pumpUntil(tester, find.text('Beta idea'));
    await tester.pump(const Duration(milliseconds: 400));

    Future<void> verify(String fieldKey, String clearKey) async {
      final root = find.byKey(ValueKey(fieldKey));
      final field = root.evaluate().single.widget is TextField
          ? root
          : find.descendant(of: root, matching: find.byType(TextField));
      await tester.tap(field);
      await tester.pump();
      await tester.enterText(field, 'Alpha');
      await tester.pump(const Duration(milliseconds: 250));
      // As a scroll with keyboardDismissBehavior.onDrag does: focus and keyboard go.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      expect(tester.testTextInput.isVisible, isFalse);
      await tester.tap(find.byKey(ValueKey(clearKey)));
      await tester.pump(const Duration(milliseconds: 100));
      final editable = tester.widget<EditableText>(find.descendant(of: root, matching: find.byType(EditableText)));
      expect(editable.controller.text, isEmpty);
      expect(editable.focusNode.hasFocus, isFalse, reason: '$clearKey must not bring the keyboard back');
      expect(tester.testTextInput.isVisible, isFalse);
    }

    await verify('notes-search', 'notes-search-clear');
    await tester.tap(Tabs.finder(Tabs.links));
    await pumpUntil(tester, find.byKey(const ValueKey('links-search')));
    await tester.pump(const Duration(milliseconds: 400));
    await verify('links-search', 'links-search-clear');
  });
}
