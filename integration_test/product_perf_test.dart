// Real-device profile benchmark for Product UI workloads (Notes, Composer, Chat SSE, Graph, Navigation).
// Run on device:
// flutter drive --profile -d <device> --driver=test_driver/integration_test.dart --target=integration_test/product_perf_test.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:fikra/app/app.dart';
import 'package:fikra/app/product_runtime.dart';
import 'package:fikra/app/providers.dart';
import 'package:fikra/data/product/development/development_auth.dart';
import 'package:fikra/data/product/development/development_knowledge.dart';
import 'package:fikra/data/product/models.dart';
import 'package:fikra/features/capture/capture_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class _PerfCaptureDevice implements CaptureDevice {
  @override
  Future<void> start() async {}
  @override
  Future<RecordedClip?> stop(Duration duration) async => RecordedClip('/perf.m4a', 'audio/m4a', duration);
  @override
  Future<void> cancel() async {}
  @override
  Future<void> dispose() async {}
}

class _PerfKnowledgeRepo extends DevelopmentKnowledgeRepository {
  _PerfKnowledgeRepo() : super(stepDelay: Duration.zero) {
    final base = DateTime.utc(2026, 11, 1, 10, 0);
    _seededNotes = [
      for (var i = 0; i < 200; i++)
        KnowledgeNote(
          id: 'perf-note-$i',
          projectId: _projectId,
          title: i.isEven ? 'فكرة معمارية رقم $i عن الاستقرار' : 'Architecture stability note #$i',
          content: i.isEven
              ? 'هذه ملاحظة عربية طويلة رقم $i لتجربة سرعة التمرير وفحص اتجاه النص بدون إعادة بناء الشاشات المخفية في التطبيق.'
              : 'This is a bilingual stress note #$i validating lazy SliverList scrolling, cached DateFormat, and O(1) script direction.',
          concepts: ['perf', 'topic-${i % 10}'],
          proposal: i % 5 == 0 ? 'Refined proposal for note #$i' : null,
          revision: 1,
          generation: 1,
          processing: ProcessingState.completed,
          createdAt: base.add(Duration(minutes: i * 17)),
          updatedAt: base.add(Duration(minutes: i * 17)),
        ),
    ];
    _seededGraph = KnowledgeGraph(
      nodes: [
        for (var i = 0; i < 60; i++)
          KnowledgeGraphNode(
            id: 'perf-note-$i',
            title: i.isEven ? 'عقدة $i' : 'Node $i',
            concepts: ['c${i % 8}'],
            updatedAt: base.add(Duration(minutes: i)),
          ),
      ],
      edges: [
        for (var i = 0; i < 60; i++) ...[
          GraphRelationship('perf-note-$i', 'perf-note-${(i + 1) % 60}', ['c${i % 8}']),
          if (i.isEven) GraphRelationship('perf-note-$i', 'perf-note-${(i + 7) % 60}', ['c${i % 8}']),
        ],
      ],
    );
    _seededConversation = Conversation(
      id: 'perf-conv-1',
      projectId: _projectId,
      title: 'Performance Conversation',
      createdAt: base,
      updatedAt: base,
    );
    _seededMessages = [
      for (var i = 0; i < 60; i++)
        KnowledgeMessage(
          id: 'perf-msg-$i',
          role: i.isEven ? 'user' : 'assistant',
          content: i.isEven
              ? 'سؤال رقم $i عن الملاحظات المحفوظة في المشروع؟'
              : 'إجابة مفصلة رقم $i مبنية على الملاحظات المرتبطة وتوضح استقرار الأداء وتقليل إعادة البناء أثناء البث.',
          supported: i.isEven ? null : true,
          createdAt: base.add(Duration(minutes: i)),
        ),
    ];
  }

  static const _projectId = 'perf-general';
  late final List<KnowledgeNote> _seededNotes;
  late final KnowledgeGraph _seededGraph;
  late final Conversation _seededConversation;
  late List<KnowledgeMessage> _seededMessages;

  @override
  Future<List<KnowledgeProject>> projects(String accountId) async => [
    KnowledgeProject(id: _projectId, name: 'General', isGeneral: true, createdAt: DateTime.utc(2026, 1, 1)),
  ];

  @override
  Future<List<KnowledgeNote>> notes(String accountId, String projectId) async => _seededNotes;

  @override
  Future<KnowledgeNote> readNote(String accountId, String noteId) async =>
      _seededNotes.firstWhere((n) => n.id == noteId, orElse: () => _seededNotes.first);

  @override
  Future<List<NoteSourceReference>> related(String accountId, String noteId) async => [
    NoteSourceReference(_seededNotes[1].id, _seededNotes[1].title),
    NoteSourceReference(_seededNotes[2].id, _seededNotes[2].title),
  ];

  @override
  Future<KnowledgeGraph> graph(String accountId, String projectId) async => _seededGraph;

  @override
  Future<List<Conversation>> conversations(String accountId, String projectId) async => [_seededConversation];

  @override
  Future<ConversationHistory> history(String accountId, String conversationId) async =>
      ConversationHistory(_seededConversation, _seededMessages);

  @override
  Stream<ChatEvent> send(String accountId, String conversationId, String text) async* {
    final buffer = StringBuffer();
    for (var i = 0; i < 60; i++) {
      final chunk = i.isEven ? 'كلمة_$i ' : 'token_$i ';
      buffer.write(chunk);
      yield ChatDelta(chunk);
      await Future<void>.delayed(const Duration(milliseconds: 12));
    }
    final userMsg = KnowledgeMessage(
      id: 'perf-msg-u-${_seededMessages.length}',
      role: 'user',
      content: text,
      supported: null,
      createdAt: DateTime.utc(2026, 11, 28),
    );
    final botMsg = KnowledgeMessage(
      id: 'perf-msg-a-${_seededMessages.length + 1}',
      role: 'assistant',
      content: buffer.toString(),
      supported: true,
      createdAt: DateTime.utc(2026, 11, 28),
    );
    _seededMessages = [..._seededMessages, userMsg, botMsg];
    yield ChatComplete(_seededConversation, userMsg, botMsg);
  }
}

Map<String, Object> _summarizeFrames(List<FrameTiming> frames, double hz) {
  final budget = 1000.0 / hz;
  final builds = [for (final f in frames) f.buildDuration.inMicroseconds / 1000.0]..sort();
  final rasters = [for (final f in frames) f.rasterDuration.inMicroseconds / 1000.0]..sort();
  final totals = [for (final f in frames) f.totalSpan.inMicroseconds / 1000.0]..sort();
  double pct(List<double> v, double q) => v.isEmpty ? 0 : double.parse(v[(q * (v.length - 1)).round()].toStringAsFixed(2));
  Map<String, Object> stats(List<double> v) => {
    'p50': pct(v, .50),
    'p90': pct(v, .90),
    'p95': pct(v, .95),
    'p99': pct(v, .99),
    'max': v.isEmpty ? 0 : double.parse(v.last.toStringAsFixed(2)),
    'over_budget': v.where((ms) => ms > budget).length,
  };
  return {
    'frames': frames.length,
    'hz': double.parse(hz.toStringAsFixed(1)),
    'budget_ms': double.parse(budget.toStringAsFixed(2)),
    'build': stats(builds),
    'raster': stats(rasters),
    'total': stats(totals),
    'jank_frames': frames
        .where((f) => f.buildDuration.inMicroseconds / 1000.0 > budget || f.rasterDuration.inMicroseconds / 1000.0 > budget)
        .length,
  };
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('Product UI profile benchmarks on real device', (tester) async {
    await initializeDateFormatting();
    final repo = _PerfKnowledgeRepo();
    final container = ProviderContainer(
      overrides: [
        appModeProvider.overrideWithValue(AppMode.development),
        appThemeProvider.overrideWith((_) => Stream.value(AppTheme.dark)),
        appLanguageProvider.overrideWith((_) => Stream.value(AppLanguage.en)),
        productAuthProvider.overrideWithValue(DevelopmentAuthRepository()),
        productKnowledgeProvider.overrideWithValue(repo),
        productVaultProvider.overrideWithValue(MemorySessionVault()),
        productAttemptsProvider.overrideWithValue(MemoryAttemptStore()),
        productCaptureDeviceProvider.overrideWithValue(_PerfCaptureDevice()),
      ],
    );
    addTearDown(container.dispose);

    final runtime = container.read(productRuntimeProvider);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const FikraApp()));
    await runtime.session.login('reader@example.invalid', 'fixture-only');
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    final hz = math.max(60.0, tester.view.display.refreshRate);
    final timings = <FrameTiming>[];
    void collect(List<FrameTiming> frames) => timings.addAll(frames);

    Future<Map<String, Object>> measure(String name, Future<void> Function() action) async {
      await tester.pumpAndSettle();
      timings.clear();
      SchedulerBinding.instance.addTimingsCallback(collect);
      try {
        await action();
        await tester.pumpAndSettle();
      } finally {
        SchedulerBinding.instance.removeTimingsCallback(collect);
      }
      final summary = _summarizeFrames(List.of(timings), hz);
      debugPrint('PERF_BENCH $name ${jsonEncode(summary)}');
      return summary;
    }

    final report = <String, Object>{};

    // Warm up all branches so offstage tabs are mounted (worst-case real usage).
    await tester.tap(find.byKey(const ValueKey('nav-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-2')));
    await tester.pumpAndSettle();
    await runtime.chat.open('perf-conv-1');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-0')));
    await tester.pumpAndSettle();

    // 1. Notes scrolling (200 bilingual notes).
    report['notes_scroll_200'] = await measure('notes_scroll_200', () async {
      final list = find.byType(CustomScrollView).first;
      for (var i = 0; i < 4; i++) {
        await tester.fling(list, const Offset(0, -1400), 2200);
        await tester.pump(const Duration(milliseconds: 350));
      }
      for (var i = 0; i < 4; i++) {
        await tester.fling(list, const Offset(0, 1400), 2200);
        await tester.pump(const Duration(milliseconds: 350));
      }
    });

    // 2. Composer typing while 200 notes + 60-node graph + 60-msg chat stay mounted offstage.
    await tester.tap(find.byKey(const ValueKey('nav-add')));
    await tester.pumpAndSettle();
    report['composer_typing'] = await measure('composer_typing', () async {
      for (var i = 0; i < 30; i++) {
        runtime.workspace.updateDraft(
          content: 'فكرة سريعة رقم $i لاختبار عدم إعادة بناء التابات المخفية ' * 3,
          fromInput: true,
        );
        await tester.pump(const Duration(milliseconds: 16));
      }
    });
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // 3. Chat SSE streaming (60 chunks over 60 historical messages).
    await tester.tap(find.byKey(const ValueKey('nav-2')));
    await tester.pumpAndSettle();
    report['chat_sse_stream'] = await measure('chat_sse_stream', () async {
      runtime.chat.updateDraft('ما هو ملخص الأداء الحالي؟');
      await tester.pump(const Duration(milliseconds: 16));
      await runtime.chat.send();
    });

    // 4. Graph drag & pan (60 nodes, 90 edges) — pick a node centered in the fitted viewport.
    await tester.tap(find.byKey(const ValueKey('nav-1')));
    await tester.pumpAndSettle();
    report['graph_drag_60_nodes'] = await measure('graph_drag_60_nodes', () async {
      final node = find.byKey(const ValueKey('graph-node-perf-note-27'));
      for (var i = 0; i < 3; i++) {
        await tester.drag(node, const Offset(70, 50));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.drag(node, const Offset(-70, -50));
        await tester.pump(const Duration(milliseconds: 50));
      }
    });

    // 5. Tab switches & note detail push/pop transition.
    report['tab_switch_and_push'] = await measure('tab_switch_and_push', () async {
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const ValueKey('nav-0')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('nav-1')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('nav-2')));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const ValueKey('nav-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('product-note-perf-note-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
    });

    binding.reportData = report;
    debugPrint('PERF_BENCH_SUMMARY ${jsonEncode(report)}');
  });
}
