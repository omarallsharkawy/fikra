import 'dart:async';
import 'dart:io';

import 'package:fikra/app/shell.dart';
import 'package:fikra/app/tab_bar/floating_navigation.dart';
import 'package:fikra/core/motion/container_transform.dart';
import 'package:fikra/core/motion/motion.dart';
import 'package:fikra/core/motion/recording_pulse.dart';
import 'package:fikra/core/theme/fikra_theme.dart';
import 'package:fikra/core/widgets/fikra_widgets.dart';
import 'package:fikra/data/attachment_draft.dart';
import 'package:fikra/data/files/attachment_store.dart';
import 'package:fikra/data/links_repository.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/features/add/add_screen.dart';
import 'package:fikra/features/ask/ask_screen.dart';
import 'package:fikra/features/connections/note_connections_screen.dart';
import 'package:fikra/features/note_details/note_details_screen.dart';
import 'package:fikra/features/notes/note_card.dart';
import 'package:fikra/features/notes/notes_screen.dart';
import 'package:fikra/features/shared/attachment_editor.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    tempDir = await Directory.systemTemp.createTemp('fikra-p7-shell-');
    addTearDown(() => tempDir.delete(recursive: true));
  });

  Future<void> backGesture(WidgetTester tester, String method, [double? progress]) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/backgesture',
      const StandardMethodCodec().encodeMethodCall(
        MethodCall(
          method,
          progress == null
              ? null
              : {
                  'touchOffset': <double>[5, 300],
                  'progress': progress,
                  'swipeEdge': 0,
                },
        ),
      ),
      (_) {},
    );
    await tester.pump();
  }

  group('5. Flying note open (container transform)', () {
    fikraTest(
      'NoteCard and BrowseNoteCard fly open from card rect, shrink back toward card on pop, fallback offscreen, and support predictive back',
      aiService: FakeTranscriptionAi(),
      (tester, db) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await pumpUntil(tester, find.text(ar.welcomeStartWriting));

        final projects = LocalProjectsRepository(db);
        final notesRepo = LocalNotesRepository(db);
        final linksRepo = LocalLinksRepository(db);
        final seeded = <Note>[];
        await pumpFuture(tester, () async {
          final p = await projects.create('طيران');
          for (var i = 0; i < 18; i++) {
            seeded.add(
              await notesRepo.create(
                projectId: p.id,
                title: 'بطاقة $i',
                text: 'نص البطاقة رقم $i',
                source: NoteSource.text,
                createdAt: DateTime(2026, 11, 10, 10, i),
              ),
            );
          }
          await linksRepo.linkNotes(seeded.last.id, [seeded[16].id], label: 'صلة');
        });
        await pumpUntil(tester, find.text('بطاقة 17'));
        await tester.pump(const Duration(milliseconds: 450));

        // 1. Tap top NoteCard -> grows from card rect into full screen NoteDetailsScreen without remounting State.
        final topCard = find.ancestor(of: find.text('بطاقة 17'), matching: find.byType(NoteCard));
        final cardRect = tester.getRect(topCard);
        await tester.tap(topCard);
        for (var i = 0; i < 5 && find.byKey(const ValueKey('note-container-transform')).evaluate().isEmpty; i++) {
          await tester.pump();
        }
        await tester.pump(const Duration(milliseconds: 60));
        final transformBox = find.byKey(const ValueKey('note-container-transform'));
        expect(transformBox, findsOneWidget);
        final stateMidOpen = tester.state(find.byType(NoteDetailsScreen));
        final midRect = tester.getRect(transformBox);
        expect(midRect.width, greaterThan(cardRect.width));
        expect(midRect.height, lessThan(844));
        await tester.pump(FikraMotion.push + const Duration(milliseconds: 60));
        expect(find.byType(NoteDetailsScreen), findsOneWidget);
        expect(find.byKey(const ValueKey('note-container-transform')), findsNothing);
        final stateAtRest = tester.state(find.byType(NoteDetailsScreen));
        expect(identical(stateMidOpen, stateAtRest), isTrue);

        // 2. Android predictive back: scrub -> cancel keeps page & State; scrub -> commit pops cleanly.
        await backGesture(tester, 'startBackGesture', 0);
        await backGesture(tester, 'updateBackGestureProgress', 0.4);
        expect(find.byKey(const ValueKey('note-container-transform')), findsOneWidget);
        expect(identical(stateAtRest, tester.state(find.byType(NoteDetailsScreen))), isTrue);
        await backGesture(tester, 'cancelBackGesture');
        await tester.pump();
        await tester.pump(FikraMotion.push + const Duration(milliseconds: 60));
        expect(find.byType(NoteDetailsScreen), findsOneWidget);
        expect(identical(stateAtRest, tester.state(find.byType(NoteDetailsScreen))), isTrue);

        await backGesture(tester, 'startBackGesture', 0);
        await backGesture(tester, 'updateBackGestureProgress', 0.35);
        await backGesture(tester, 'commitBackGesture');
        await tester.pump();
        await tester.pump(FikraMotion.containerPop + const Duration(milliseconds: 50));
        expect(find.byType(NoteDetailsScreen, skipOffstage: false), findsNothing);

        // 3. Programmatic/system back while card is still visible shrinks container back toward cardRect.
        await tester.tap(topCard);
        for (var i = 0; i < 5 && find.byType(NoteDetailsScreen).evaluate().isEmpty; i++) {
          await tester.pump();
        }
        await tester.pump(FikraMotion.push + const Duration(milliseconds: 20));
        await tester.binding.handlePopRoute();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.byKey(const ValueKey('note-container-transform')), findsOneWidget);
        final revEarly = tester.getRect(find.byKey(const ValueKey('note-container-transform')));
        await tester.pump(const Duration(milliseconds: 140));
        final revLate = tester.getRect(find.byKey(const ValueKey('note-container-transform')));
        expect(revEarly.height, lessThan(844));
        expect(revLate.height, lessThan(revEarly.height));
        expect(revLate.width, lessThan(revEarly.width));
        expect(revLate.top, greaterThan(revEarly.top));
        expect((revLate.top - cardRect.top).abs(), lessThan((revEarly.top - cardRect.top).abs()));
        await tester.pump(FikraMotion.containerPop + const Duration(milliseconds: 50));
        expect(find.byType(NoteDetailsScreen, skipOffstage: false), findsNothing);

        // 4. Scroll source card offscreen while details is open -> back uses normal pop (no container transform).
        await tester.tap(topCard);
        for (var i = 0; i < 5 && find.byType(NoteDetailsScreen).evaluate().isEmpty; i++) {
          await tester.pump();
        }
        await tester.pump(FikraMotion.push + const Duration(milliseconds: 20));
        final notesScroll = find.descendant(
          of: find.byType(NotesScreen, skipOffstage: false),
          matching: find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            skipOffstage: false,
          ),
          skipOffstage: false,
        );
        final pos = tester.state<ScrollableState>(notesScroll).position;
        pos.jumpTo(pos.maxScrollExtent);
        await tester.pump();
        await tester.binding.handlePopRoute();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 40));
        expect(find.byKey(const ValueKey('note-container-transform')), findsNothing);
        await tester.pump(FikraMotion.pop + const Duration(milliseconds: 40));
        expect(find.byType(NoteDetailsScreen, skipOffstage: false), findsNothing);

        // 5. Links Browse card -> flies into NoteConnectionsScreen -> connections-note flies into NoteDetailsScreen.
        await tester.tap(Tabs.finder(Tabs.links));
        final browseCard = find.byKey(ValueKey('browse-${seeded.last.id}'));
        await pumpUntil(tester, browseCard);
        await tester.pump(const Duration(milliseconds: 450));
        await tester.tap(browseCard);
        for (var i = 0; i < 5 && find.byKey(const ValueKey('note-container-transform')).evaluate().isEmpty; i++) {
          await tester.pump();
        }
        await tester.pump(const Duration(milliseconds: 60));
        expect(find.byKey(const ValueKey('note-container-transform')), findsOneWidget);
        await tester.pump(FikraMotion.push);
        expect(find.byType(NoteConnectionsScreen), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('connections-note')));
        for (var i = 0; i < 5 && find.byKey(const ValueKey('note-container-transform')).evaluate().isEmpty; i++) {
          await tester.pump();
        }
        await tester.pump(const Duration(milliseconds: 60));
        expect(find.byKey(const ValueKey('note-container-transform')), findsOneWidget);
        await tester.pump(FikraMotion.push);
        expect(find.byType(NoteDetailsScreen), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pump();
        await tester.pump(FikraMotion.containerPop + const Duration(milliseconds: 60));
        expect(find.byType(NoteDetailsScreen, skipOffstage: false), findsNothing);
      },
    );

    testWidgets('ContainerTransformPage keeps page State mounted and builds child once across open and pop', (
      tester,
    ) async {
      var inits = 0;
      var builds = 0;
      var pushed = false;
      late StateSetter setHost;

      await tester.pumpWidget(
        MaterialApp(
          theme: buildFikraTheme(Brightness.dark),
          home: StatefulBuilder(
            builder: (context, setState) {
              setHost = setState;
              return Navigator(
                pages: [
                  const MaterialPage<void>(
                    key: ValueKey('root'),
                    child: Scaffold(body: SizedBox.expand()),
                  ),
                  if (pushed)
                    ContainerTransformPage<void>(
                      key: const ValueKey('details'),
                      origin: const CardOrigin(initialRect: Rect.fromLTWH(20, 120, 350, 96), borderRadius: 24),
                      child: _StateProbe(onInit: () => inits++, onBuild: () => builds++),
                    ),
                ],
                onDidRemovePage: (_) {},
              );
            },
          ),
        ),
      );

      setHost(() => pushed = true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final stateDuringOpen = tester.state(find.byType(_StateProbe));
      expect(inits, 1);
      expect(builds, 1);

      // Completing the open animation (crossing raw == 1) never remounts or rebuilds the page child.
      await tester.pump(FikraMotion.push + const Duration(milliseconds: 50));
      expect(identical(stateDuringOpen, tester.state(find.byType(_StateProbe))), isTrue);
      expect(inits, 1);
      expect(builds, 1);

      // Starting and completing reverse flight also keeps the same State without rebuilding the child.
      setHost(() => pushed = false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(identical(stateDuringOpen, tester.state(find.byType(_StateProbe))), isTrue);
      expect(inits, 1);
      expect(builds, 1);
      await tester.pump(FikraMotion.containerPop + const Duration(milliseconds: 50));
      expect(find.byType(_StateProbe), findsNothing);
    });

    fikraTest('Reduce Motion uses normal page transition instead of flying open', aiService: FakeTranscriptionAi(), (
      tester,
      db,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        disableAnimations: true,
      );
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await pumpUntil(tester, find.text(ar.welcomeStartWriting));
      await pumpFuture(tester, () async {
        final p = await LocalProjectsRepository(db).create('هادئ');
        await LocalNotesRepository(db).create(projectId: p.id, title: 'بسيط', text: 'نص', source: NoteSource.text);
      });
      await pumpUntil(tester, find.text('بسيط'));
      await tester.tap(find.text('بسيط'));
      for (var i = 0; i < 5 && find.byType(NoteDetailsScreen).evaluate().isEmpty; i++) {
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.byKey(const ValueKey('note-container-transform')), findsNothing);
      await tester.pump(FikraMotion.push);
      expect(find.byType(NoteDetailsScreen), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(FikraMotion.pop + const Duration(milliseconds: 40));
      expect(find.byType(NoteDetailsScreen, skipOffstage: false), findsNothing);
    });
  });

  group('6. Shrinking floating tab bar (experiment)', () {
    fikraTest(
      'flag is OFF by default; debug toggle turns it ON; scroll shrinks/restores; slide selects Ask & resets on branch change; Reduce Motion keeps full height',
      glassPreview: true,
      aiService: FakeTranscriptionAi(),
      (tester, db) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await pumpUntil(tester, find.text(ar.welcomeStartWriting));
        await pumpFuture(tester, () async {
          final p = await LocalProjectsRepository(db).create('شريط');
          final repo = LocalNotesRepository(db);
          for (var i = 0; i < 25; i++) {
            await repo.create(projectId: p.id, title: 'نوت $i', text: 'سطر طويل $i', source: NoteSource.text);
          }
        });
        await pumpUntil(tester, find.text('نوت 24'));
        await tester.pump(const Duration(milliseconds: 450));

        final container = ProviderScope.containerOf(tester.element(find.byType(AppShell)));
        final sub = container.listen(navBarShrinkEnabledProvider, (_, _) {});
        addTearDown(sub.close);
        expect(container.read(navBarShrinkEnabledProvider), isFalse);

        final bar = find.byType(FikraNavBar);
        final notesScroll = find.descendant(
          of: find.byType(NotesScreen),
          matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down),
        );

        // Default OFF: scrolling down leaves bar at full 72 dp height.
        expect(tester.getSize(bar).height, FloatingNavigation.height);
        await tester.drag(notesScroll, const Offset(0, -240));
        await tester.pump();
        expect(tester.getSize(bar).height, FloatingNavigation.height);

        // Toggle shrink flag ON via debug glass preview overlay UI.
        await tester.tap(find.byKey(const ValueKey('debug-shrink-bar-toggle')));
        await tester.pump();
        expect(container.read(navBarShrinkEnabledProvider), isTrue);

        // Scroll down >= 120 dp -> shrinks to 52 dp; scroll back up -> restores 72 dp.
        await tester.drag(notesScroll, const Offset(0, -200));
        await tester.pump();
        expect(tester.getSize(bar).height, closeTo(FikraMotion.barShrunkHeight, 0.5));
        await tester.drag(notesScroll, const Offset(0, 260));
        await tester.pump();
        expect(tester.getSize(bar).height, FloatingNavigation.height);

        // Shrink again, then press-and-slide lens from Notes to Ask: selects Ask and resets shrink on branch change.
        await tester.drag(notesScroll, const Offset(0, -200));
        await tester.pump();
        expect(tester.getSize(bar).height, closeTo(FikraMotion.barShrunkHeight, 0.5));

        final gesture = await tester.startGesture(tester.getCenter(Tabs.finder(Tabs.notes)));
        addTearDown(gesture.removePointer);
        await gesture.moveTo(tester.getCenter(Tabs.finder(Tabs.ask)));
        await tester.pump();
        await gesture.up();
        await tester.pump(const Duration(milliseconds: 450));
        expect(find.byType(AskScreen), findsOneWidget);
        expect(tester.widget<FikraNavBar>(bar).index, Tabs.ask);
        expect(tester.getSize(bar).height, FloatingNavigation.height);

        // Reversed scrollables (AxisDirection.up) are ignored by AppShell._onScroll.
        ScrollUpdateNotification(
          metrics: FixedScrollMetrics(
            minScrollExtent: 0,
            maxScrollExtent: 500,
            pixels: 180,
            viewportDimension: 400,
            axisDirection: AxisDirection.up,
            devicePixelRatio: 1,
          ),
          context: tester.element(find.byType(AskScreen)),
          scrollDelta: 150,
        ).dispatch(tester.element(find.byType(AskScreen)));
        await tester.pump();
        expect(tester.getSize(bar).height, FloatingNavigation.height);

        await tester.tap(Tabs.finder(Tabs.notes));
        await tester.pump(const Duration(milliseconds: 400));

        // Reduce Motion disables shrinking even when flag is ON.
        tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
          disableAnimations: true,
        );
        addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
        await tester.pump();
        await tester.drag(notesScroll, const Offset(0, -240));
        await tester.pump();
        expect(tester.getSize(bar).height, FloatingNavigation.height);
      },
    );
  });

  group('7. Activity capsule above the bar', () {
    for (final reduced in [false, true]) {
      fikraTest(
        'shows on another tab while recording with static dot & 1 Hz timer, keeps NavigationInset steady, hides with keyboard, clears Add, and taps through (reduced=$reduced)',
        attachmentStore: testStore,
        microphonePermission: () async => PermissionStatus.granted,
        aiService: FakeTranscriptionAi(),
        (tester, db) async {
          tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(
            disableAnimations: reduced,
          );
          addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final semantics = tester.ensureSemantics();

          final fake = RecordingFake([]);
          final prev = RecordPlatform.instance;
          RecordPlatform.instance = fake;
          addTearDown(() => RecordPlatform.instance = prev);

          await pumpUntil(tester, find.text(ar.welcomeStartWriting));
          await pumpFuture(tester, () => LocalProjectsRepository(db).create('كبسولة'));
          await pumpUntil(tester, find.text('كبسولة'));
          final insetBefore = NavigationInset.of(tester.element(find.byType(NotesScreen)));

          await tester.tap(Tabs.addButton);
          await pumpUntil(tester, find.byType(AddScreen));
          final add = tester.state(find.byType(AddScreen)) as AttachmentEditing<AddScreen>;
          await pumpFuture(tester, add.startRecording);
          await tester.pump();

          // Hidden on Add tab itself.
          expect(find.byKey(const ValueKey('activity-capsule')), findsNothing);

          // Switch to Notes tab: capsule appears above the bar, never covers nav-add, never changes NavigationInset.
          await tester.tap(Tabs.finder(Tabs.notes));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 450));
          final capsule = find.byKey(const ValueKey('activity-capsule'));
          expect(capsule, findsOneWidget);
          expect(find.descendant(of: capsule, matching: find.byType(RecordingPulse)), findsNothing);
          expect(tester.binding.hasScheduledFrame, isFalse);
          expect(NavigationInset.of(tester.element(find.byType(NotesScreen))), insetBefore);
          expect(find.text(ar.capsuleRecording), findsOneWidget);
          expect(find.text('0:00'), findsOneWidget);

          final capRect = tester.getRect(capsule);
          final barRect = tester.getRect(find.byType(FikraNavBar));
          final addRect = tester.getRect(Tabs.addButton);
          expect(capRect.bottom, lessThanOrEqualTo(barRect.top));
          expect(capRect.overlaps(addRect), isFalse);
          expect(tester.getSemantics(capsule).label, ar.capsuleRecordingA11y);

          // Timer ticks once per second; TalkBack label stays static without elapsed time.
          await tester.pump(const Duration(seconds: 2));
          expect(find.text('0:02'), findsOneWidget);
          expect(tester.getSemantics(capsule).label, ar.capsuleRecordingA11y);

          // Hides with the keyboard like the bar.
          tester.view.viewInsets = const FakeViewPadding(bottom: 300);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(capsule.hitTestable(), findsNothing);
          tester.view.viewInsets = FakeViewPadding.zero;
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(capsule.hitTestable(), findsOneWidget);

          // Tapping capsule returns to Add tab where recording owns the activity.
          await tester.tap(capsule);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          expect(find.byType(AddScreen), findsOneWidget);
          expect(find.byKey(const ValueKey('activity-capsule')), findsNothing);

          await pumpFuture(tester, add.cancelRecording);
          await tester.pump(const Duration(milliseconds: 300));
          semantics.dispose();
        },
      );
    }

    final transcribingGate = Completer<String>();
    fikraTest(
      'shows transcribing capsule during background transcription and taps through to the note',
      aiService: FakeTranscriptionAi(),
      attachmentStore: _CopyStore(),
      transcriptionEngine: FakeTranscriptionEngine(action: (_, _) => transcribingGate.future),
      (tester, db) async {
        final semantics = tester.ensureSemantics();
        await pumpUntil(tester, find.text(ar.welcomeStartWriting));
        await pumpFuture(tester, () => LocalProjectsRepository(db).create('تفريغ'));
        await pumpUntil(tester, find.text('تفريغ'));

        await tester.tap(Tabs.addButton);
        await pumpUntil(tester, find.byType(AddScreen));
        final add = tester.state(find.byType(AddScreen)) as AttachmentEditing<AddScreen>;
        add.updateDraft(
          () => add.draftFiles = [
            const AttachmentDraft(
              kind: AttachmentKind.voice,
              path: '/voice.m4a',
              durationMs: 3000,
              policy: TranscriptionPolicy.afterSave,
            ),
          ],
        );
        await tester.pump();
        final save = find.byKey(const ValueKey('add-save'));
        await Scrollable.ensureVisible(tester.element(save), alignment: 0.5);
        await tester.pump(const Duration(milliseconds: 400));
        await tester.tap(save);
        await tester.pump(FikraMotion.saveTick + const Duration(milliseconds: 100));

        final capsule = find.byKey(const ValueKey('activity-capsule'));
        await pumpUntil(tester, capsule);
        ScaffoldMessenger.of(tester.element(capsule)).hideCurrentSnackBar();
        await tester.pump(const Duration(milliseconds: 450));
        expect(find.descendant(of: capsule, matching: find.byType(RecordingPulse)), findsNothing);
        expect(find.text(ar.capsuleTranscribing), findsOneWidget);
        expect(tester.getSemantics(capsule).label, ar.capsuleTranscribingA11y);

        await tester.tap(capsule);
        await pumpUntil(tester, find.byType(NoteDetailsScreen));

        transcribingGate.complete('تم التفريغ');
        await tester.pump(const Duration(milliseconds: 300));
        semantics.dispose();
      },
    );
  });
}

class _StateProbe extends StatefulWidget {
  const _StateProbe({required this.onInit, required this.onBuild});
  final VoidCallback onInit;
  final VoidCallback onBuild;

  @override
  State<_StateProbe> createState() => _StateProbeState();
}

class _StateProbeState extends State<_StateProbe> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) {
    widget.onBuild();
    return const Scaffold(body: Center(child: Text('details')));
  }
}

class _CopyStore extends AttachmentStore {
  @override
  Future<String> persist(String source, {required String extension}) async => '/saved$source';
  @override
  Future<void> sweepOrphans(Set<String> referenced) async {}
  @override
  Future<void> clearPickerCopies() async {}
}
