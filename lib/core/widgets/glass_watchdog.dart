import 'dart:typed_data';
import 'dart:ui' show FramePhase;

import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ordered cheapest to most expensive.
enum GlassTier { solid, frosted, optical }

abstract interface class GlassTimingsSource {
  void add(TimingsCallback callback);
  void remove(TimingsCallback callback);
}

class SchedulerGlassTimings implements GlassTimingsSource {
  @override
  void add(TimingsCallback callback) => SchedulerBinding.instance.addTimingsCallback(callback);
  @override
  void remove(TimingsCallback callback) => SchedulerBinding.instance.removeTimingsCallback(callback);
}

final glassTimingsSourceProvider = Provider<GlassTimingsSource>((ref) => SchedulerGlassTimings());
final glassWatchdogProvider = NotifierProvider<GlassWatchdog, GlassTier>(GlassWatchdog.new);

/// Session lifetime, with no automatic promotion. Only visible glass registers
/// timings. Two fixed buffers; insertion sort in scratch once per 120 samples.
class GlassWatchdog extends Notifier<GlassTier> {
  static const windowSize = 120;
  final _raster = Float64List(windowSize);
  final _scratch = Float64List(windowSize);
  final _visibleRates = <Object, double>{};
  late GlassTimingsSource _source;
  late TimingsCallback _callback;
  var _cursor = 0;
  var _count = 0;
  var _sinceCheck = 0;
  double _budget = 6.5;

  static double budgetMs(double hz) => 6.5 * 120 / (hz > 0 ? hz : 60);

  @override
  GlassTier build() {
    _source = ref.read(glassTimingsSourceProvider);
    _callback = _timings;
    ref.onDispose(() {
      if (_visibleRates.isNotEmpty) _source.remove(_callback);
    });
    return GlassTier.optical;
  }

  void show(Object owner, double refreshHz) {
    final wasEmpty = _visibleRates.isEmpty;
    if (_visibleRates[owner] == refreshHz) return;
    _visibleRates[owner] = refreshHz;
    _updateBudget();
    _resetWindow();
    if (wasEmpty) _source.add(_callback);
  }

  void hide(Object owner) {
    if (_visibleRates.remove(owner) == null) return;
    _resetWindow();
    if (_visibleRates.isEmpty) {
      _source.remove(_callback);
    } else {
      _updateBudget();
    }
  }

  void _resetWindow() {
    _cursor = 0;
    _count = 0;
    _sinceCheck = 0;
  }

  void _updateBudget() {
    var hz = 0.0;
    for (final rate in _visibleRates.values) {
      if (rate > hz) hz = rate;
    }
    _budget = budgetMs(hz);
  }

  void _timings(List<FrameTiming> frames) {
    for (var frameIndex = 0; frameIndex < frames.length; frameIndex++) {
      final frame = frames[frameIndex];
      _raster[_cursor] =
          (frame.timestampInMicroseconds(FramePhase.rasterFinish) -
              frame.timestampInMicroseconds(FramePhase.rasterStart)) /
          1000;
      _cursor = (_cursor + 1) % windowSize;
      if (_count < windowSize) _count++;
      _sinceCheck++;
      if (_count < windowSize || _sinceCheck < windowSize) continue;
      _sinceCheck = 0;
      for (var i = 0; i < windowSize; i++) {
        _scratch[i] = _raster[i];
      }
      // In-place sorting; no List copies, closures or allocations per frame.
      for (var i = 1; i < windowSize; i++) {
        final value = _scratch[i];
        var j = i - 1;
        while (j >= 0 && _scratch[j] > value) {
          _scratch[j + 1] = _scratch[j];
          j--;
        }
        _scratch[j + 1] = value;
      }
      if (_scratch[(.95 * (windowSize - 1)).round()] > _budget && state != GlassTier.solid) {
        state = GlassTier.values[state.index - 1];
      }
    }
  }
}
