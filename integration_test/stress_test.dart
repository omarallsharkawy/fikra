// Scale test on a real device: seeds N notes and measures queries, screens,
// scrolling, search, the graph, the demo AI and memory.
//
//   flutter drive --profile -d <device> --dart-define=FIKRA_STRESS_N=5000 \
//     --driver=test_driver/integration_test.dart --target=integration_test/stress_test.dart
//
// Glass comparison: 12-second scroll + six held slides across tabs per tier:
//   flutter drive --profile -d <device> --dart-define=FIKRA_STRESS_N=5000 \
//     --dart-define=FIKRA_GLASS_PERF=true --driver=test_driver/integration_test.dart \
//     --target=integration_test/stress_test.dart
//
// Add --dart-define=FIKRA_GLASS_PERF=true for per-tier Notes/slide/Links/graph metrics.
// Use --dart-define=FIKRA_STRESS_N=5000 for the phase-3 phone comparison.
// Results: build/integration_response_data.json. Uses its own database file and
// never touches the app's real data or attachment files. Profile builds install
// as com.fikra.app.stress (android/app/build.gradle.kts), a separate app.
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fikra/features/connections/library_session.dart';
import 'package:fikra/app/app.dart';
import 'package:fikra/app/providers.dart';
import 'package:fikra/core/motion/motion.dart';
import 'package:fikra/core/widgets/glass_watchdog.dart';
import 'package:fikra/data/ai/demo_ai_service.dart';
import 'package:fikra/data/files/attachment_store.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/features/notes/note_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';

import 'glass_perf_scenario.dart';

const _glassPerf = bool.fromEnvironment('FIKRA_GLASS_PERF');

const _n = int.fromEnvironment('FIKRA_STRESS_N', defaultValue: 1000);

/// --dart-define=FIKRA_TRACE=true records a timeline per FPS step (with
/// per-widget build events) into the response file, to find slow frames.
const _trace = bool.fromEnvironment('FIKRA_TRACE');

class _NoFiles extends AttachmentStore {
  @override
  Future<void> sweepOrphans(Set<String> referenced) async {}
  @override
  Future<void> purgeAll() async {}
}

const _topics = [
  ('الشبكات', 'محاضرة عن TCP و UDP والـrouting وطبقات الشبكة، لازم أراجع الفرق بين البروتوكولات قبل الامتحان'),
  ('الذكاء الاصطناعي', 'الـrag بيجيب أقرب أجزاء من النوتس بالـembedding وبعدين الـllm بيكتب الإجابة مع المصدر'),
  ('قواعد البيانات', 'postgres مع pgvector للتضمينات، والفهارس مهمة جدًا عشان البحث يفضل سريع لما الداتا تكبر'),
  ('Flutter', 'هستخدم riverpod لإدارة الحالة في flutter، و drift لقاعدة البيانات المحلية على الموبايل'),
  ('التصميم', 'الواجهة داكنة وبسيطة بالعربي من اليمين للشمال، والحركة خفيفة ومش بتشتت المستخدم'),
  ('الباك إند', 'fastapi و postgres، والتطبيق بيكلّم السيرفر عن طريق api مع retry و idempotency'),
  ('الامتحانات', 'جدول المذاكرة: كل يوم مادة، ومراجعة الأسئلة القديمة، وتلخيص المحاضرات في نوت واحدة'),
  ('أفكار', 'فكرة مشروع جديد: تطبيق يجمع النوتس ويطلّع أسئلة مراجعة لوحده من المحاضرات'),
];

Map<String, Object> _frames(List<FrameTiming> t) {
  if (t.isEmpty) return {'frames': 0};
  double p(List<double> v, double q) => (v..sort())[(q * (v.length - 1)).round()];
  final build = [for (final f in t) f.buildDuration.inMicroseconds / 1000];
  final raster = [for (final f in t) f.rasterDuration.inMicroseconds / 1000];
  final total = [for (final f in t) f.totalSpan.inMicroseconds / 1000];
  double r(double x) => (x * 10).round() / 10;
  return {
    'frames': t.length,
    'build_p50': r(p(build, .5)),
    'build_p90': r(p(build, .9)),
    'build_max': r(build.reduce(max)),
    'raster_p90': r(p(raster, .9)),
    'over_16ms': total.where((x) => x > 16.7).length,
    'worst_ms': r(total.reduce(max)),
  };
}

/// Frame rate over animations. [windows] holds, per gesture or animation,
/// the vsync time (µs) of every frame drawn while it was running, so every
/// gap inside a window counts, stalls included, and the pauses between
/// windows never do. A frame is janky when its build or raster phase takes
/// longer than one refresh. `latency_*` is FrameTiming.totalSpan: vsync to
/// raster finish (before the frame is presented).
Map<String, Object> _fps(List<FrameTiming> t, List<List<int>> windows, double refreshHz) {
  if (t.length < 10) return {'frames': t.length};
  final budget = 1000 / refreshHz;
  double ms(Duration d) => d.inMicroseconds / 1000;
  final build = [for (final f in t) ms(f.buildDuration)]..sort();
  final raster = [for (final f in t) ms(f.rasterDuration)]..sort();
  final latency = [for (final f in t) ms(f.totalSpan)]..sort();
  final janky = t.where((f) => ms(f.buildDuration) > budget || ms(f.rasterDuration) > budget).length;
  final gaps = <double>[
    for (final w in windows)
      for (var i = 1; i < w.length; i++) (w[i] - w[i - 1]) / 1000,
  ]..sort();
  double r(double x) => (x * 10).round() / 10;
  double p(List<double> a, double q) => a[(q * (a.length - 1)).round()];
  return {
    'frames': t.length,
    if (gaps.isNotEmpty) ...{
      'avg_fps': r(1000 / (gaps.reduce((a, b) => a + b) / gaps.length)),
      'low_1pct_fps': r(1000 / p(gaps, .99)),
      'low_01pct_fps': r(1000 / p(gaps, .999)),
    },
    'jank_pct': r(100 * janky / t.length),
    // Measured build or raster phases over 6.94 ms. The run is at the panel's
    // idle rate, so this is how close each frame is to a 144 Hz budget, not a
    // prediction of on-screen 144 Hz behaviour.
    'over_144hz_pct': r(
      100 * t.where((f) => ms(f.buildDuration) > 1000 / 144 || ms(f.rasterDuration) > 1000 / 144).length / t.length,
    ),
    'build_p90': r(p(build, .9)),
    'build_p99': r(p(build, .99)),
    'build_max': r(build.last),
    'raster_p90': r(p(raster, .9)),
    'raster_p99': r(p(raster, .99)),
    'raster_max': r(raster.last),
    'latency_p99': r(p(latency, .99)),
    'latency_max': r(latency.last),
  };
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final report = <String, Object>{'notes': _n};

  testWidgets('stress with $_n notes', (tester) async {
    await initializeDateFormatting('ar');
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/fikra_stress.sqlite');
    if (file.existsSync()) file.deleteSync();
    final db = FikraDatabase(NativeDatabase.createInBackground(file));
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });
    addTearDown(db.close);
    final rnd = Random(42);

    Future<double> time(Future<void> Function() f) async {
      final sw = Stopwatch()..start();
      await f();
      return sw.elapsedMicroseconds / 1000;
    }

    // ---- seed: N notes, one confirmed chain edge + one AI suggestion each, 40 chat entries
    final now = DateTime.now();
    final ids = <String>[];
    report['seed_ms'] = await time(() async {
      await db.into(db.projects).insert(Project(id: 'p', name: 'ضغط', createdAt: now));
      await db.into(db.settings).insert(Setting(key: 'current_project', value: 'p'));
      await db.batch((batch) {
        for (var g = 0; g < 5; g++) {
          batch.insert(
            db.noteGroups,
            NoteGroup(
              id: 'g$g',
              projectId: 'p',
              name: 'مجموعة $g',
              position: g,
              createdAt: now,
              parentId: g == 1 ? 'g0' : null,
            ),
          );
        }
      });
      const chunk = 500;
      for (var start = 0; start < _n; start += chunk) {
        await db.batch((b) {
          for (var i = start; i < min(_n, start + chunk); i++) {
            final (topic, body) = _topics[rnd.nextInt(_topics.length)];
            final id = 'n$i';
            ids.add(id);
            final text = List.filled(1 + rnd.nextInt(4), body).join('. ');
            b.insert(
              db.notes,
              NotesCompanion.insert(
                id: id,
                projectId: 'p',
                title: '$topic ${i + 1}',
                originalText: text,
                source: NoteSource.text,
                status: ProcessingStatus.ready,
                concepts: Value([topic, 'مراجعة', 'نوت ${i % 50}'].join('|')),
                cluster: Value(topic),
                groupId: i % 3 == 0 ? Value('g${i % 5}') : const Value(null),
                createdAt: now.subtract(Duration(minutes: i * 37)),
                updatedAt: now,
              ),
            );
            if (i % 4 == 0) {
              for (var j = 0; j < 6; j++) {
                b.insert(
                  db.noteAttachments,
                  NoteAttachment(
                    id: '$id-a$j',
                    noteId: id,
                    kind: AttachmentKind.values[j ~/ 2],
                    transcriptionStatus: TranscriptionStatus.none,
                    transcriptionAttempts: 0,
                    transcriptionPolicy: TranscriptionPolicy.off,
                    transcriptRevision: 0,
                    path: '/stress/$id-$j',
                    name: 'file-$j.pdf',
                    bytes: 12345,
                    durationMs: 3000,
                    position: j,
                    createdAt: now,
                  ),
                );
              }
            }
          }
        });
      }
      await db.batch((b) {
        for (var i = 1; i < _n; i++) {
          for (var k = 0; k < 2; k++) {
            b.insert(
              db.noteLinks,
              NoteLink(
                id: 'l$i-$k',
                projectId: 'p',
                sourceId: 'n$i',
                targetId: k == 0 ? 'n${i - 1}' : 'n${(i + 37) % _n}',
                label: 'مرتبطة',
                strength: rnd.nextDouble(),
                origin: k == 0 ? LinkOrigin.user : LinkOrigin.ai,
                dismissed: false,
                createdAt: now,
              ),
            );
          }
        }
        for (var i = 0; i < 40; i++) {
          b.insert(
            db.chatEntries,
            ChatEntry(
              id: 'c$i',
              projectId: 'p',
              role: i.isEven ? 'user' : 'assistant',
              body: 'سؤال وإجابة رقم $i عن الشبكات والـrag',
              sourceIds: 'n${i % _n}',
              found: true,
              createdAt: now.subtract(Duration(minutes: 40 - i)),
            ),
          );
        }
      });
    });
    report['db_mb'] = (file.lengthSync() / 1024 / 1024 * 10).round() / 10;

    // ---- raw queries
    final notesRepo = LocalNotesRepository(db);
    final projectsRepo = LocalProjectsRepository(db);
    report['q_watchNotes_ms'] = await time(() => notesRepo.watchNotes('p').first);
    report['q_watchProjects_ms'] = await time(() => projectsRepo.watchProjects().first);
    report['q_watchLinks_ms'] = await time(() => notesRepo.watchLinks('p').first);
    report['q_projectAttachments_ms'] = await time(() => notesRepo.watchProjectAttachments('p').first);
    report['q_attachmentPaths_ms'] = await time(() => notesRepo.attachmentPaths());

    // ---- demo AI against N notes (what runs after every save / every question)
    final all = await notesRepo.notesOf('p');
    final ai = DemoAiService(latency: Duration.zero);
    report['ai_analyze_one_ms'] = await time(() => ai.analyze(all.first, all));
    report['ai_ask_ms'] = await time(() => ai.ask('إيه اللي كتبته عن الشبكات؟', all));

    // ---- the app
    final timings = <FrameTiming>[];
    void collect(List<FrameTiming> t) => timings.addAll(t);
    SchedulerBinding.instance.addTimingsCallback(collect);
    addTearDown(() => SchedulerBinding.instance.removeTimingsCallback(collect));
    Future<Map<String, Object>> frames(Future<void> Function() f) async {
      timings.clear();
      await f();
      await tester.pump(const Duration(milliseconds: 500));
      return _frames(List.of(timings));
    }

    Future<void> until(Finder f, {int maxMs = 60000}) async {
      final sw = Stopwatch()..start();
      while (f.evaluate().isEmpty) {
        if (sw.elapsedMilliseconds > maxMs) throw StateError('timeout waiting for $f');
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    report['open_app_to_list_ms'] = await time(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            attachmentStoreProvider.overrideWithValue(_NoFiles()),
            if (_glassPerf) glassTimingsSourceProvider.overrideWithValue(MeasurementGlassTimings()),
          ],
          child: const FikraApp(),
        ),
      );
      await until(find.byType(NoteCard).hitTestable(), maxMs: 120000);
    });
    report['rss_after_list_mb'] = ProcessInfo.currentRss ~/ (1024 * 1024);
    if (_glassPerf) {
      SchedulerBinding.instance.removeTimingsCallback(collect);
      final container = ProviderScope.containerOf(tester.element(find.byType(NoteCard).first));
      await runGlassPerformance(tester, binding, container);
      binding.reportData = {...?binding.reportData, ...report};
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      return;
    }

    final list = find.byType(Scrollable).last;
    report['scroll_notes'] = await frames(() async {
      for (var i = 0; i < 4; i++) {
        await tester.fling(list, const Offset(0, -1500), 3000);
        await tester.pumpAndSettle();
      }
    });

    report['search_type_ms'] = await time(() async {
      await tester.enterText(find.byType(TextField).first, 'الشبكات');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
    });
    report['search_frames'] = await frames(() async {
      await tester.enterText(find.byType(TextField).first, 'rag');
      await tester.pumpAndSettle();
    });
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pumpAndSettle();

    // Links Map
    report['open_links_ms'] = await time(() async {
      await tester.tap(find.byKey(const ValueKey('nav-1')));
      await until(find.byKey(LinksLibrarySegment.key(LinksLibrarySegment.map)));
      await tester.tap(find.byKey(LinksLibrarySegment.key(LinksLibrarySegment.map)));
      await until(find.byType(InteractiveViewer));
      await tester.pump();
    });
    report['links_frames_open'] = await frames(() => tester.pumpAndSettle());
    report['links_pan'] = await frames(() async {
      for (var i = 0; i < 3; i++) {
        await tester.drag(find.byType(InteractiveViewer), const Offset(-300, -400));
        await tester.pumpAndSettle();
      }
    });
    report['rss_after_links_mb'] = ProcessInfo.currentRss ~/ (1024 * 1024);

    // Ask tab (chat history)
    report['open_ask_ms'] = await time(() async {
      await tester.tap(find.byKey(const ValueKey('nav-2')));
      await tester.pumpAndSettle();
    });

    // A save while N notes exist: insert + every notes query re-runs.
    report['save_note_ms'] = await time(() async {
      await notesRepo.create(projectId: 'p', title: 'جديدة', text: 'نوت جديدة', source: NoteSource.text);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
    });

    // ---- real-time frame rate: frames run at the display's own vsync here.
    final hz = tester.view.display.refreshRate;
    report['display_hz'] = hz;
    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
    // Vsync times of the frames drawn inside each moving(...) window.
    final windows = <List<int>>[];
    var moving = false;
    SchedulerBinding.instance.addPersistentFrameCallback((_) {
      if (moving) windows.last.add(SchedulerBinding.instance.currentSystemFrameTimeStamp.inMicroseconds);
    });
    // Runs [f] as one window, then keeps it open until every animation it
    // started has drawn its last frame (transition tails, springs, scroll and
    // pan inertia), so the end of a motion is never cut off. [f] itself must
    // not idle: once nothing animates, the window closes.
    Future<void> during(Future<void> Function() f) async {
      windows.add([]);
      moving = true;
      try {
        await f();
        final scheduler = SchedulerBinding.instance;
        final deadline = DateTime.now().add(const Duration(seconds: 3));
        do {
          await scheduler.endOfFrame; // the recorder runs inside this frame
        } while (scheduler.transientCallbackCount > 0 && DateTime.now().isBefore(deadline));
      } finally {
        moving = false;
      }
    }

    Future<Map<String, Object>> live(String key, Future<void> Function() f) async {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      timings.clear();
      windows.clear();
      if (_trace) {
        debugProfileBuildsEnabled = true;
        debugProfileLayoutsEnabled = true;
        debugProfilePaintsEnabled = true;
        await binding.traceAction(f, reportKey: 'trace_$key');
        debugProfileBuildsEnabled = false;
        debugProfileLayoutsEnabled = false;
        debugProfilePaintsEnabled = false;
      } else {
        await f();
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return _fps(List.of(timings), List.of(windows), hz);
    }

    Future<void> wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

    await tester.tap(find.byKey(const ValueKey('nav-0')));
    await wait(800);
    final notesScroll = tester.state<ScrollableState>(find.byType(Scrollable).last).position;
    report['fps_notes_scroll'] = await live('notes_scroll', () async {
      await during(() async {
        for (var i = 0; i < 2; i++) {
          await notesScroll.animateTo(6000, duration: const Duration(milliseconds: 2500), curve: Curves.linear);
          await notesScroll.animateTo(0, duration: const Duration(milliseconds: 2500), curve: Curves.linear);
        }
      });
    });
    report['fps_notes_fling'] = await live('notes_fling', () async {
      for (var i = 0; i < 3; i++) {
        await during(() async {
          await tester.fling(find.byType(Scrollable).last, const Offset(0, -1400), 4000);
          while (notesScroll.isScrollingNotifier.value) {
            await wait(5);
          }
        });
        await wait(400);
      }
    });
    report['fps_tabs'] = await live('tabs', () async {
      for (final branch in [2, 3, 4, 1, 2, 1]) {
        await during(() async {
          await tester.tap(find.byKey(ValueKey(branch == 0 ? 'nav-add' : 'nav-${branch - 1}')));
          await wait(FikraMotion.enter.inMilliseconds);
        });
        await wait(450);
      }
    });
    await tester.tap(find.byKey(const ValueKey('nav-1')));
    await wait(1200);
    report['fps_map_pan'] = await live('map_pan', () async {
      for (var i = 0; i < 3; i++) {
        await during(
          () => tester.timedDrag(
            find.byType(InteractiveViewer),
            const Offset(-260, -320),
            const Duration(milliseconds: 900),
          ),
        );
        await wait(500);
      }
    });
    await tester.tap(find.byKey(const ValueKey('nav-0')));
    await wait(800);
    report['fps_open_note'] = await live('open_note', () async {
      for (var i = 0; i < 3; i++) {
        await during(() async {
          await tester.tap(find.byType(NoteCard).first);
          await wait(FikraMotion.push.inMilliseconds);
        });
        await wait(500);
        await during(() async {
          await tester.binding.handlePopRoute();
          await wait(FikraMotion.push.inMilliseconds);
        });
        await wait(500);
      }
    });

    report['rss_end_mb'] = ProcessInfo.currentRss ~/ (1024 * 1024);
    SchedulerBinding.instance.removeTimingsCallback(collect);
    binding.reportData = {...?binding.reportData, ...report};
    // ignore: avoid_print
    print('FIKRA_STRESS $report');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  }, timeout: const Timeout(Duration(minutes: 20)));
}
