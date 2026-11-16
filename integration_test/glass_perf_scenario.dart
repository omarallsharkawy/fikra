// Invoked by stress_test.dart after its isolated DB seed and notes-list open.
// flutter drive --profile -d <device> --dart-define=FIKRA_STRESS_N=5000 \
//   --dart-define=FIKRA_GLASS_PERF=true --driver=test_driver/integration_test.dart \
//   --target=integration_test/stress_test.dart
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:fikra/core/widgets/glass_quality.dart';
import 'package:fikra/core/widgets/glass_watchdog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Controlled comparison disables only automatic frame-based drops. Production
/// never uses this source. Battery saver and MediaQuery caps still apply, and
/// the scenario refuses a capped tier instead of mislabelling its measurements.
class MeasurementGlassTimings implements GlassTimingsSource {
  @override
  void add(TimingsCallback callback) {}
  @override
  void remove(TimingsCallback callback) {}
}

Map<String, Object> glassFrameReport(List<FrameTiming> frames, double hz) {
  final budget = GlassWatchdog.budgetMs(hz);
  final builds = [for (final f in frames) f.buildDuration.inMicroseconds / 1000]..sort();
  final rasters = [for (final f in frames) f.rasterDuration.inMicroseconds / 1000]..sort();
  double percentile(List<double> values, double q) => values[(q * (values.length - 1)).round()];
  return {
    'frames': frames.length,
    'refresh_hz': hz,
    'phase_budget_ms': budget,
    'display_budget_ms': 1000 / hz,
    for (final (name, values) in [('build', builds), ('raster', rasters)])
      name: {
        if (values.isNotEmpty)
          for (final (label, q) in [('p50', .50), ('p90', .90), ('p95', .95), ('p99', .99)])
            label: percentile(values, q),
        'over_budget': values.where((ms) => ms > budget).length,
      },
    'frames_over_budget': frames
        .where((f) => f.buildDuration.inMicroseconds / 1000 > budget || f.rasterDuration.inMicroseconds / 1000 > budget)
        .length,
    'frames_over_display_budget': frames
        .where(
          (f) =>
              f.buildDuration.inMicroseconds / 1000 > 1000 / hz || f.rasterDuration.inMicroseconds / 1000 > 1000 / hz,
        )
        .length,
  };
}

Future<void> runGlassPerformance(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  ProviderContainer container,
) async {
  final previousPolicy = binding.framePolicy;
  addTearDown(() => binding.framePolicy = previousPolicy);
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  final hz = tester.view.display.refreshRate;
  final results = <String, Object>{};
  final timings = <FrameTiming>[];
  void collect(List<FrameTiming> frames) => timings.addAll(frames);
  SchedulerBinding.instance.addTimingsCallback(collect);
  addTearDown(() => SchedulerBinding.instance.removeTimingsCallback(collect));
  final position = tester.state<ScrollableState>(find.byType(Scrollable).last).position;
  final reduced = MediaQuery.disableAnimationsOf(tester.element(find.byType(Scrollable).last));
  for (final tier in GlassTier.values) {
    container.read(glassTierOverrideProvider.notifier).force(tier);
    position.jumpTo(0);
    // Warm shader/loading and flush previous FrameTiming batches outside trace.
    await Future<void>.delayed(const Duration(seconds: 2));
    final effective = container.read(glassTierProvider(reduced));
    expect(
      effective,
      tier,
      reason: 'Turn off Android battery saver and Remove animations before the controlled tier comparison.',
    );
    timings.clear();
    await binding.traceAction(() async {
      // Six identical 2-second traversals = 12 seconds of continuous scrolling
      // per tier, including the optical lens above the same scrolling notes.
      for (var sweep = 0; sweep < 6; sweep++) {
        await position.animateTo(
          sweep.isEven ? math.min(6000, position.maxScrollExtent) : 0,
          duration: const Duration(seconds: 2),
          curve: Curves.linear,
        );
      }
    }, reportKey: 'glass_trace_${tier.name}');
    await Future<void>.delayed(const Duration(milliseconds: 500));
    expect(timings, isNotEmpty, reason: 'FrameTiming must be delivered in the profile drive.');
    results[tier.name] = {
      'requested_tier': tier.name,
      'effective_tier': effective.name,
      'scroll_duration_seconds': 12,
      'live_refraction_supported': ui.ImageFilter.isShaderFilterSupported,
      ...glassFrameReport(timings, hz),
    };
  }
  SchedulerBinding.instance.removeTimingsCallback(collect);
  binding.reportData = {...?binding.reportData, 'glass_tiers': results};
}
