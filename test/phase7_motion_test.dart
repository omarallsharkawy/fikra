import 'dart:io';

import 'package:fikra/core/motion/motion.dart';
import 'package:fikra/core/motion/recording_pulse.dart';
import 'package:fikra/core/motion/rolling_text.dart';
import 'package:fikra/core/motion/stagger.dart';
import 'package:fikra/core/theme/fikra_theme.dart';
import 'package:fikra/data/ai/ai_service.dart';
import 'package:fikra/data/files/attachment_store.dart';
import 'package:fikra/data/groups_repository.dart';
import 'package:fikra/data/links_repository.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/features/add/add_screen.dart';
import 'package:fikra/features/ask/ask_screen.dart';
import 'package:fikra/features/connections/library_session.dart';
import 'package:fikra/features/connections/links_index.dart';
import 'package:fikra/features/notes/notes_screen.dart';
import 'package:fikra/features/shared/attachment_editor.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import 'support/app_harness.dart';
import 'support/fake_transcription_engine.dart';
import 'support/recording_fake.dart';

void main() {
  final ar = lookupAppLocalizations(const Locale('ar'));
  late Directory tempDir;
  final testStore = AttachmentStore(documentsDir: () async => tempDir, tempDir: () async => tempDir);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('fikra-p7-');
    addTearDown(() => tempDir.delete(recursive: true));
  });

  group('1. Save tick', () {
    for (final reduced in [false, true]) {
      fikraTest(
        'commits immediately, morphs with haptic, and returns to check_rounded (reduced=$reduced)',
        aiService: FakeTranscriptionAi(),
        (tester, db) async {
          tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(
            disableAnimations: reduced,
          );
          addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
          final haptics = <String>[];
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            (call) async {
              if (call.method == 'HapticFeedback.vibrate') haptics.add('${call.arguments}');
              return null;
            },
          );
          addTearDown(
            () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
              SystemChannels.platform,
              null,
            ),
          );

          await pumpUntil(tester, find.text(ar.welcomeStartWriting));
          final project = await pumpFuture(tester, () => LocalProjectsRepository(db).create('مشروع'));
          await pumpUntil(tester, find.text('مشروع'));

          await tester.tap(Tabs.addButton);
          await pumpUntil(tester, find.byType(AddScreen));
          final fields = find.descendant(of: find.byType(AddScreen), matching: find.byType(TextField));
          await tester.enterText(fields.first, 'عنوان سريع');
          await tester.enterText(fields.last, 'محتوى الملاحظة');
          await tester.pump();

          final saveBtn = find.byKey(const ValueKey('add-save'));
          expect(find.descendant(of: saveBtn, matching: find.byIcon(Icons.check_rounded)), findsOneWidget);
          expect(find.descendant(of: saveBtn, matching: find.byType(SaveTickMark)), findsNothing);
          await tester.tap(saveBtn);

          // Saving must finish immediately without waiting for the 360 ms tick animation.
          final addState = tester.state(find.byType(AddScreen)) as AttachmentEditing<AddScreen>;
          await pumpFuture(tester, () async {
            while (addState.saving) {
              await Future<void>.delayed(const Duration(milliseconds: 5));
            }
          });
          final savedNow = await pumpFuture(tester, () => LocalNotesRepository(db).notesOf(project.id));
          expect(savedNow.map((n) => n.title), contains('عنوان سريع'));
          expect(haptics, contains('HapticFeedbackType.lightImpact'));

          // Typing after Save keeps the user on Add so we observe return-to-normal on screen.
          await tester.enterText(fields.first, 'تانية');
          await tester.pump(const Duration(milliseconds: 90));
          final tickFinder = find.descendant(of: saveBtn, matching: find.byType(SaveTickMark));
          expect(tickFinder, findsOneWidget);
          final midTick = tester.widget<SaveTickMark>(tickFinder);
          if (reduced) {
            expect(midTick.progress, 1.0);
          } else {
            expect(midTick.progress, greaterThan(0));
          }

          await tester.pump(FikraMotion.saveTick);
          expect(find.byType(AddScreen), findsOneWidget);
          expect(find.descendant(of: saveBtn, matching: find.byType(SaveTickMark)), findsNothing);
          expect(find.descendant(of: saveBtn, matching: find.byIcon(Icons.check_rounded)), findsOneWidget);
        },
      );
    }

    fikraTest('navigates to /notes after the save tick by default when untouched', aiService: FakeTranscriptionAi(), (
      tester,
      db,
    ) async {
      await pumpUntil(tester, find.text(ar.welcomeStartWriting));
      await pumpFuture(tester, () => LocalProjectsRepository(db).create('مشروع'));
      await pumpUntil(tester, find.text('مشروع'));

      await tester.tap(Tabs.addButton);
      await pumpUntil(tester, find.byType(AddScreen));
      final fields = find.descendant(of: find.byType(AddScreen), matching: find.byType(TextField));
      await tester.enterText(fields.first, 'تلقائي');
      await tester.enterText(fields.last, 'نص الملاحظة');
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('add-save')));
      final addState = tester.state(find.byType(AddScreen)) as AttachmentEditing<AddScreen>;
      await pumpFuture(tester, () async {
        while (addState.saving) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      });

      // During the tick delay, AddScreen remains visible showing SaveTickMark.
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(AddScreen), findsOneWidget);
      expect(find.byType(SaveTickMark), findsOneWidget);

      // Once the tick finishes with no typing, tab leave, or newer save, it navigates to /notes.
      await tester.pump(FikraMotion.saveTick);
      await pumpUntil(tester, find.byType(NotesScreen));
      await tester.pump(const Duration(milliseconds: 120)); // outgoing composer fade
      expect(find.byType(AddScreen), findsNothing);
      expect(find.text('تلقائي'), findsOneWidget);
    });
  });

  group('2. Recording pulse and live waveform', () {
    testWidgets('pulse stops under Reduce Motion and when TickerMode is disabled', (tester) async {
      Widget harness({required bool reduced, required bool tickerEnabled}) => MaterialApp(
        theme: buildFikraTheme(Brightness.dark),
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: TickerMode(
            enabled: tickerEnabled,
            child: const Scaffold(
              body: Center(
                child: RecordingPulse(
                  key: ValueKey('pulse'),
                  active: true,
                  color: Colors.red,
                  child: SizedBox(width: 44, height: 44),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidget(harness(reduced: false, tickerEnabled: true));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.binding.hasScheduledFrame, isTrue);

      await tester.pumpWidget(harness(reduced: true, tickerEnabled: true));
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);

      await tester.pumpWidget(harness(reduced: false, tickerEnabled: false));
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    fikraTest(
      'live amplitude updates drive waveform without rebuilding AddScreen and do not setState while hidden',
      attachmentStore: testStore,
      microphonePermission: () async => PermissionStatus.granted,
      (tester, db) async {
        final fake = RecordingFake([])..amplitudeSequence = [-45, -28, -12, -4, -18, -8, -15, -6];
        final prev = RecordPlatform.instance;
        RecordPlatform.instance = fake;
        addTearDown(() => RecordPlatform.instance = prev);

        await pumpUntil(tester, find.text(ar.welcomeStartWriting));
        await pumpFuture(tester, () => LocalProjectsRepository(db).create('صوت'));
        await pumpUntil(tester, find.text('صوت'));
        await tester.tap(Tabs.addButton);
        await pumpUntil(tester, find.byType(AddScreen));

        final add = tester.state(find.byType(AddScreen)) as AttachmentEditing<AddScreen>;
        await pumpFuture(tester, add.startRecording);
        await tester.pump();
        expect(find.byKey(const ValueKey('add-stop-pulse')), findsOneWidget);
        expect(find.byKey(const ValueKey('recording-waveform')), findsOneWidget);

        final waveBoundary = tester.renderObject<RenderRepaintBoundary>(
          find
              .ancestor(of: find.byKey(const ValueKey('recording-waveform')), matching: find.byType(RepaintBoundary))
              .first,
        );
        final rootBoundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(appBoundaryKey));
        int paints(RenderRepaintBoundary b) => b.debugSymmetricPaintCount + b.debugAsymmetricPaintCount;
        final waveBefore = paints(waveBoundary);
        final rootBefore = paints(rootBoundary);

        for (var i = 0; i < 4; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 95)));
          await tester.pump(const Duration(milliseconds: 95));
        }
        expect(add.levels, isNotEmpty);
        expect(add.levels.any((v) => v > 0.2), isTrue);
        expect(paints(waveBoundary), greaterThan(waveBefore));
        expect(paints(rootBoundary), rootBefore);

        // Hide Add tab: amplitude samples still accumulate without repainting offstage waveform or scheduling tickers.
        await tester.tap(find.byKey(const ValueKey('add-close')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 450));
        final hiddenWaveBefore = paints(waveBoundary);
        final samplesBefore = add.levels.length;
        await tester.pump(const Duration(milliseconds: 110));
        expect(add.levels.length, greaterThan(samplesBefore));
        expect(paints(waveBoundary), hiddenWaveBefore);

        await pumpFuture(tester, add.cancelRecording);
        await tester.pump(const Duration(milliseconds: 300));
      },
    );
  });

  group('3. Card stagger (first appearance only)', () {
    fikraTest(
      'Notes, Browse and Suggestions stagger <= 8 cards only on visible first load or visible project switch',
      aiService: FakeTranscriptionAi(),
      (tester, db) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await pumpUntil(tester, find.text(ar.welcomeStartWriting));

        final projects = LocalProjectsRepository(db);
        final notesRepo = LocalNotesRepository(db);
        final linksRepo = LocalLinksRepository(db);
        late Project p1, p2, pEmpty;
        late Note p2Note;
        final p1Notes = <Note>[];
        await pumpFuture(tester, () async {
          p1 = await projects.create('أول');
          for (var i = 0; i < 12; i++) {
            final n = await notesRepo.create(
              projectId: p1.id,
              title: 'ملاحظة $i',
              text: 'تفاصيل $i',
              source: NoteSource.text,
              createdAt: DateTime(2026, 11, 10, 12, i),
            );
            p1Notes.add(n);
          }
          await linksRepo.linkNotes(p1Notes[11].id, [p1Notes[10].id], label: 'مؤكد');
          await notesRepo.applyInsights(
            p1Notes[9].id,
            NoteInsights(
              title: p1Notes[9].title,
              concepts: const ['مفهوم'],
              cluster: 'موضوع',
              links: [ProposedLink(targetId: p1Notes[8].id, label: 'مقترح', strength: 0.9)],
            ),
          );
          p2 = await projects.create('تاني');
          p2Note = await notesRepo.create(projectId: p2.id, title: 'ملاحظة تاني', text: 'نص', source: NoteSource.text);
          pEmpty = await projects.create('فاضي');
          await projects.setCurrent(p1.id);
        });

        // 1. Initial load of p1 on Notes staggers <= 8 cards.
        await pumpUntil(tester, find.text('ملاحظة 11'));
        final newestEntry = find.ancestor(of: find.text('ملاحظة 11'), matching: find.byType(StaggeredEntry));
        final stagger = tester.widget<StaggeredEntry>(newestEntry).stagger;
        expect(stagger.isAnimating, isTrue);
        expect(stagger.slotOf(p1Notes[11].id), 0);
        expect(stagger.slotOf(p1Notes[2].id), isNull);

        await tester.pump(FikraMotion.staggerTotal + const Duration(milliseconds: 40));
        expect(stagger.isAnimating, isFalse);

        // 2. Scroll down to build offscreen cards, then back up: never triggers stagger.
        final notesScroll = find.descendant(
          of: find.byType(NotesScreen),
          matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down),
        );
        await tester.drag(notesScroll, const Offset(0, -600));
        await tester.pump(const Duration(milliseconds: 80));
        expect(stagger.isAnimating, isFalse);
        await tester.drag(notesScroll, const Offset(0, 600));
        await tester.pump(const Duration(milliseconds: 80));
        expect(stagger.isAnimating, isFalse);

        // 3. Stream update: assert on the very first frame (well before 384 ms) that no stagger started.
        final beforeStream = tester.binding.clock.now();
        final streamNote = await pumpFuture(
          tester,
          () => notesRepo.create(projectId: p1.id, title: 'تحديث حي', text: 'جديد', source: NoteSource.text),
        );
        await pumpUntil(tester, find.text('تحديث حي'));
        expect(tester.binding.clock.now().difference(beforeStream), lessThan(FikraMotion.staggerTotal));
        expect(stagger.isAnimating, isFalse);
        expect(stagger.slotOf(streamNote.id), isNull);

        // 4. Switch to Links tab: Browse animates once; opening Suggestions animates Suggestions once.
        final beforeLinks = tester.binding.clock.now();
        await tester.tap(Tabs.finder(Tabs.links));
        await pumpUntil(tester, find.byKey(LinksLibrarySegment.key(LinksLibrarySegment.browse)));
        await tester.tap(find.byKey(LinksLibrarySegment.key(LinksLibrarySegment.browse)));
        await pumpUntil(tester, find.byKey(ValueKey('browse-${p1Notes[11].id}')));
        expect(tester.binding.clock.now().difference(beforeLinks), lessThan(FikraMotion.staggerTotal));
        final browseEntry = find.byKey(ValueKey('browse-slot-${p1Notes[11].id}'));
        final browseStagger = tester.widget<StaggeredEntry>(browseEntry).stagger;
        expect(browseStagger.isAnimating, isTrue);
        expect(browseStagger.slotOf(p1Notes[11].id), 0);
        await tester.pump(FikraMotion.staggerTotal + const Duration(milliseconds: 40));
        expect(browseStagger.isAnimating, isFalse);

        await tester.tap(find.byKey(LinksLibrarySegment.key(LinksLibrarySegment.suggestions)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 30));
        final sugKey = pairKey(p1Notes[9].id, p1Notes[8].id);
        final sugEntries = find.descendant(
          of: find.byKey(LinksLibrarySegment.listKey(p1.id, LinksLibrarySegment.suggestions)),
          matching: find.byType(StaggeredEntry),
        );
        expect(sugEntries, findsOneWidget);
        final sugStagger = tester.widget<StaggeredEntry>(sugEntries).stagger;
        expect(sugStagger.isAnimating, isTrue);
        expect(sugStagger.slotOf(sugKey), 0);
        final sugOpacity = tester.widget<Opacity>(
          find.descendant(of: sugEntries, matching: find.byType(Opacity)).first,
        );
        expect(sugOpacity.opacity, lessThan(1.0));
        await tester.pump(FikraMotion.staggerTotal + const Duration(milliseconds: 40));
        expect(sugStagger.isAnimating, isFalse);

        // 5. Returning to Notes tab does NOT stagger again.
        await tester.tap(Tabs.finder(Tabs.notes));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 40));
        expect(stagger.isAnimating, isFalse);

        // 6. Visible project switch to p2 DOES stagger (assert mid-animation before 384 ms).
        final beforeSwitch = tester.binding.clock.now();
        await pumpFuture(tester, () => projects.setCurrent(p2.id));
        await pumpUntil(tester, find.text('ملاحظة تاني'));
        expect(tester.binding.clock.now().difference(beforeSwitch), lessThan(FikraMotion.staggerTotal));
        expect(stagger.projectId, p2.id);
        expect(stagger.isAnimating, isTrue);
        expect(stagger.slotOf(p2Note.id), 0);
        await tester.pump(FikraMotion.staggerTotal + const Duration(milliseconds: 40));
        expect(stagger.isAnimating, isFalse);

        // 7. Empty project records as shown once loaded, so a later stream item never staggers.
        await pumpFuture(tester, () => projects.setCurrent(pEmpty.id));
        await pumpUntil(tester, find.text(ar.notesEmptyTitle));
        expect(stagger.projectId, pEmpty.id);
        expect(stagger.isAnimating, isFalse);
        final beforeEmptyStream = tester.binding.clock.now();
        final arrivedInEmpty = await pumpFuture(
          tester,
          () => notesRepo.create(projectId: pEmpty.id, title: 'أول وصول', text: 'نص', source: NoteSource.text),
        );
        await pumpUntil(tester, find.text('أول وصول'));
        expect(tester.binding.clock.now().difference(beforeEmptyStream), lessThan(FikraMotion.staggerTotal));
        expect(stagger.isAnimating, isFalse);
        expect(stagger.slotOf(arrivedInEmpty.id), isNull);

        // 8. Switching project while Notes tab is hidden (on Ask) does NOT stagger on returning to Notes.
        await tester.tap(Tabs.finder(Tabs.ask));
        await pumpUntil(tester, find.byType(AskScreen));
        await pumpFuture(tester, () => projects.setCurrent(p1.id));
        await tester.pump(const Duration(milliseconds: 60));
        await tester.tap(Tabs.finder(Tabs.notes));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 40));
        expect(find.text('تحديث حي'), findsOneWidget);
        expect(stagger.projectId, p1.id);
        expect(stagger.isAnimating, isFalse);
      },
    );

    testWidgets('Reduce Motion skips card stagger completely', (tester) async {
      late StaggerController controller;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFikraTheme(Brightness.dark),
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: _StaggerProbe(onReady: (c) => controller = c),
          ),
        ),
      );
      expect(controller.isAnimating, isFalse);
      expect(controller.slotOf('a'), isNull);
    });
  });

  group('4. Rolling numbers', () {
    testWidgets(
      'no roll on first build; rolls changed digits in Western & Arabic-Indic; preserves maxLines & TalkBack',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          Widget box(String text, {bool reduced = false, String? a11y, int? maxLines}) => MaterialApp(
            theme: buildFikraTheme(Brightness.dark),
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduced),
              child: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 140,
                    child: RollingText(
                      text,
                      key: const ValueKey('roll'),
                      semanticLabel: a11y,
                      maxLines: maxLines,
                      overflow: maxLines != null ? TextOverflow.ellipsis : null,
                    ),
                  ),
                ),
              ),
            ),
          );

          // First build: plain Text, zero RollingDigit widgets.
          await tester.pumpWidget(box('اقتراحات 12', a11y: 'اقتراحات، 12'));
          expect(find.byType(RollingDigit), findsNothing);
          expect(find.text('اقتراحات 12'), findsOneWidget);

          // Change 12 -> 13: '1' stays static Text, only '2'->'3' mounts RollingDigit; TalkBack reads final value.
          await tester.pumpWidget(box('اقتراحات 13', a11y: 'اقتراحات، 13'));
          await tester.pump(const Duration(milliseconds: 80));
          expect(find.byType(RollingDigit), findsOneWidget);
          expect(tester.getSemantics(find.byKey(const ValueKey('roll'))).label, 'اقتراحات، 13');
          await tester.pump(FikraMotion.roll + const Duration(milliseconds: 20));
          expect(find.byType(RollingDigit), findsNothing);
          expect(find.text('اقتراحات 13'), findsOneWidget);

          // Multi-line label with maxLines: 2 keeps identical height before, during, and after roll.
          const longPrefix = 'مجموعة طويلة جداً للتجربة السطر التاني ';
          await tester.pumpWidget(box('${longPrefix}2', maxLines: 2));
          await tester.pump();
          final restHeight = tester.getSize(find.byKey(const ValueKey('roll'))).height;
          await tester.pumpWidget(box('${longPrefix}3', maxLines: 2));
          await tester.pump(const Duration(milliseconds: 60));
          expect(find.byType(RollingDigit), findsOneWidget);
          expect(tester.getSize(find.byKey(const ValueKey('roll'))).height, restHeight);
          await tester.pump(FikraMotion.roll + const Duration(milliseconds: 20));
          expect(tester.getSize(find.byKey(const ValueKey('roll'))).height, restHeight);

          // Arabic-Indic numerals: ١٢ -> ١٣ rolls only the changed Arabic-Indic digit.
          await tester.pumpWidget(box('١٢'));
          await tester.pump();
          expect(find.byType(RollingDigit), findsNothing);
          await tester.pumpWidget(box('١٣'));
          await tester.pump(const Duration(milliseconds: 60));
          final digit = tester.widget<RollingDigit>(find.byType(RollingDigit));
          expect(digit.oldChar, '٢');
          expect(digit.newChar, '٣');
          await tester.pump(FikraMotion.roll + const Duration(milliseconds: 20));
          expect(find.text('١٣'), findsOneWidget);

          // Reduce Motion: updates immediately with zero RollingDigit widgets.
          await tester.pumpWidget(box('١٤', reduced: true));
          await tester.pump(const Duration(milliseconds: 60));
          expect(find.byType(RollingDigit), findsNothing);
          expect(find.text('١٤'), findsOneWidget);
        } finally {
          semantics.dispose();
        }
      },
    );

    fikraTest('Suggestions segment count and Links chip counts roll when updated live', (tester, db) async {
      await pumpUntil(tester, find.text(ar.welcomeStartWriting));
      final projects = LocalProjectsRepository(db);
      final notesRepo = LocalNotesRepository(db);
      final groupsRepo = LocalGroupsRepository(db);
      final linksRepo = LocalLinksRepository(db);
      late Project p;
      late Note n1, n2, n3, n4;
      late NoteGroup g;
      await pumpFuture(tester, () async {
        p = await projects.create('عداد');
        g = await groupsRepo.create(p.id, 'شبكات');
        n1 = await notesRepo.create(projectId: p.id, title: 'أ', text: '1', source: NoteSource.text);
        n2 = await notesRepo.create(projectId: p.id, title: 'ب', text: '2', source: NoteSource.text);
        n3 = await notesRepo.create(projectId: p.id, title: 'ج', text: '3', source: NoteSource.text);
        n4 = await notesRepo.create(projectId: p.id, title: 'د', text: '4', source: NoteSource.text);
        await groupsRepo.assignNotes(g.id, [n1.id, n2.id, n3.id, n4.id]);
        await linksRepo.linkNotes(n1.id, [n2.id], label: 'ربط');
        await notesRepo.applyInsights(
          n1.id,
          NoteInsights(
            title: 'أ',
            concepts: const [],
            cluster: 'عام',
            links: [ProposedLink(targetId: n3.id, label: 'اقتراح ١', strength: 0.9)],
          ),
        );
        await notesRepo.applyInsights(
          n2.id,
          NoteInsights(
            title: 'ب',
            concepts: const [],
            cluster: 'عام',
            links: [ProposedLink(targetId: n3.id, label: 'اقتراح ٢', strength: 0.8)],
          ),
        );
      });
      await pumpUntil(tester, find.text('د'));
      expect(find.byKey(const ValueKey('project-header-count')), findsNothing);

      // Switch to Links: accepting a suggestion rolls Suggestions segment count (2 -> 1) and group chip count (2 -> 3).
      await tester.tap(Tabs.finder(Tabs.links));
      await pumpUntil(tester, find.byKey(LinksLibrarySegment.key(LinksLibrarySegment.browse)));
      await tester.tap(find.byKey(LinksLibrarySegment.key(LinksLibrarySegment.browse)));
      await pumpUntil(tester, find.text('اقتراحات 2'));
      await tester.pump(const Duration(milliseconds: 450));
      expect(find.byType(RollingDigit), findsNothing);

      await pumpFuture(tester, () => linksRepo.acceptPair(n1.id, n3.id));
      await pumpUntil(
        tester,
        find.descendant(
          of: find.byKey(LinksLibrarySegment.key(LinksLibrarySegment.suggestions)),
          matching: find.byType(RollingDigit),
        ),
      );
      await tester.pump(const Duration(milliseconds: 40));
      expect(
        find.descendant(of: find.byKey(ValueKey('group-filter-${g.id}')), matching: find.byType(RollingDigit)),
        findsOneWidget,
      );
      await tester.pump(FikraMotion.roll + const Duration(milliseconds: 50));
      expect(find.text('اقتراحات 1'), findsOneWidget);
    }, aiService: FakeTranscriptionAi());
  });
}

class _StaggerProbe extends StatefulWidget {
  const _StaggerProbe({required this.onReady});
  final ValueChanged<StaggerController> onReady;

  @override
  State<_StaggerProbe> createState() => _StaggerProbeState();
}

class _StaggerProbeState extends State<_StaggerProbe> with SingleTickerProviderStateMixin {
  late final StaggerController _c = StaggerController(this);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _c.maybeStart(
      projectId: 'p1',
      visibleIds: const ['a', 'b', 'c'],
      tickerEnabled: TickerMode.valuesOf(context).enabled,
      reduced: FikraMotion.reduced(context),
    );
    widget.onReady(_c);
    return StaggeredEntry(stagger: _c, itemId: 'a', child: const Text('card'));
  }
}
