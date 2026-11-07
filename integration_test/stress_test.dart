// Scale test on a real device: seeds N notes and measures queries, screens,
// scrolling, search, the graph, the demo AI and memory.
//
//   flutter drive --profile -d <device> --dart-define=FIKRA_STRESS_N=5000 \
//     --driver=test_driver/integration_test.dart --target=integration_test/stress_test.dart
//
// Results: build/integration_response_data.json. Uses its own database file and
// never touches the app's real data or attachment files. Profile builds install
// as com.fikra.app.stress (android/app/build.gradle.kts), a separate app.
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:fikra/app/app.dart';
import 'package:fikra/app/providers.dart';
import 'package:fikra/data/ai/demo_ai_service.dart';
import 'package:fikra/data/files/attachment_store.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/features/notes/note_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'dart:ui' show FramePhase;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';

const _n = int.fromEnvironment('FIKRA_STRESS_N', defaultValue: 1000);

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

/// Real-time frame rate over an animation: average FPS, 1% / 0.1% lows (from
/// the slowest frame intervals) and frames that missed a vsync.
Map<String, Object> _fps(List<FrameTiming> t, double refreshHz) {
  if (t.length < 10) return {'frames': t.length};
  final ends = [for (final f in t) f.timestampInMicroseconds(FramePhase.rasterFinish)]..sort();
  // Gaps over 250 ms are pauses between gestures, not frames of the animation.
  final gaps = [for (var i = 1; i < ends.length; i++) (ends[i] - ends[i - 1]) / 1000].where((g) => g < 250).toList();
  if (gaps.isEmpty) return {'frames': t.length};
  final sorted = [...gaps]..sort();
  double pct(double q) => sorted[(q * (sorted.length - 1)).round()];
  final budget = 1000 / refreshHz;
  final avg = gaps.reduce((a, b) => a + b) / gaps.length;
  double r(double x) => (x * 10).round() / 10;
  final total = [for (final f in t) f.totalSpan.inMicroseconds / 1000];
  return {
    'frames': t.length,
    'avg_fps': r(1000 / avg),
    'low_1pct_fps': r(1000 / pct(.99)),
    'low_01pct_fps': r(1000 / pct(.999)),
    'missed_vsync': gaps.where((g) => g > budget * 1.5).length,
    'missed_pct': r(100 * gaps.where((g) => g > budget * 1.5).length / gaps.length),
    'worst_frame_ms': r(total.reduce(max)),
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
    final rnd = Random(42);

    Future<double> time(Future<void> Function() f) async {
      final sw = Stopwatch()..start();
      await f();
      return sw.elapsedMicroseconds / 1000;
    }

    // ---- seed: N notes, ~2 links each, 40 chat entries
    final now = DateTime.now();
    final ids = <String>[];
    report['seed_ms'] = await time(() async {
      await db.into(db.projects).insert(Project(id: 'p', name: 'ضغط', createdAt: now));
      await db.into(db.settings).insert(Setting(key: 'current_project', value: 'p'));
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
              Note(
                id: id,
                projectId: 'p',
                title: '$topic ${i + 1}',
                originalText: text,
                source: NoteSource.text,
                status: ProcessingStatus.ready,
                rewrite: RewriteStatus.none,
                concepts: [topic, 'مراجعة', 'نوت ${i % 50}'].join('|'),
                cluster: topic,
                createdAt: now.subtract(Duration(minutes: i * 37)),
                updatedAt: now,
              ),
            );
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
                targetId: 'n${rnd.nextInt(i)}',
                label: 'مرتبطة',
                strength: rnd.nextDouble(),
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
          overrides: [databaseProvider.overrideWithValue(db), attachmentStoreProvider.overrideWithValue(_NoFiles())],
          child: const FikraApp(),
        ),
      );
      await until(find.byType(NoteCard).hitTestable(), maxMs: 120000);
    });
    report['rss_after_list_mb'] = ProcessInfo.currentRss ~/ (1024 * 1024);

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

    // Links graph
    report['open_links_ms'] = await time(() async {
      await tester.tap(find.byKey(const ValueKey('nav-2')));
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
      await tester.tap(find.byKey(const ValueKey('nav-3')));
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
    Future<Map<String, Object>> live(Future<void> Function() f) async {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      timings.clear();
      await f();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return _fps(List.of(timings), hz);
    }

    Future<void> wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

    await tester.tap(find.byKey(const ValueKey('nav-1')));
    await wait(800);
    final notesScroll = tester.state<ScrollableState>(find.byType(Scrollable).last).position;
    report['fps_notes_scroll'] = await live(() async {
      for (var i = 0; i < 2; i++) {
        await notesScroll.animateTo(6000, duration: const Duration(milliseconds: 2500), curve: Curves.linear);
        await notesScroll.animateTo(0, duration: const Duration(milliseconds: 2500), curve: Curves.linear);
      }
    });
    report['fps_notes_fling'] = await live(() async {
      for (var i = 0; i < 3; i++) {
        await tester.fling(find.byType(Scrollable).last, const Offset(0, -1400), 4000);
        await wait(1400);
      }
    });
    report['fps_tabs'] = await live(() async {
      for (final tab in [2, 3, 0, 1, 2, 1]) {
        await tester.tap(find.byKey(ValueKey('nav-$tab')));
        await wait(700);
      }
    });
    await tester.tap(find.byKey(const ValueKey('nav-2')));
    await wait(1200);
    report['fps_graph_pan'] = await live(() async {
      for (var i = 0; i < 3; i++) {
        await tester.timedDrag(
          find.byType(InteractiveViewer),
          const Offset(-260, -320),
          const Duration(milliseconds: 900),
        );
        await wait(500);
      }
    });
    await tester.tap(find.byKey(const ValueKey('nav-1')));
    await wait(800);
    report['fps_open_note'] = await live(() async {
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byType(NoteCard).first);
        await wait(900);
        await tester.binding.handlePopRoute();
        await wait(900);
      }
    });

    report['rss_end_mb'] = ProcessInfo.currentRss ~/ (1024 * 1024);
    SchedulerBinding.instance.removeTimingsCallback(collect);
    binding.reportData = report;
    // ignore: avoid_print
    print('FIKRA_STRESS $report');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
    await db.close();
    file.deleteSync();
  }, timeout: const Timeout(Duration(minutes: 20)));
}
