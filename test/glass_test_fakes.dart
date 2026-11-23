import 'dart:async';

import 'package:fikra/core/widgets/glass_power.dart';
import 'package:fikra/core/widgets/glass_watchdog.dart';
import 'package:flutter/scheduler.dart';

class FakeGlassPower implements GlassPowerSource {
  final values = StreamController<bool>.broadcast(sync: true);
  @override
  Stream<bool> watchPowerSaveMode() => values.stream;
  void dispose() {
    values.close();
  }
}

class FakeGlassTimings implements GlassTimingsSource {
  final callbacks = <TimingsCallback>[];
  @override
  void add(TimingsCallback callback) => callbacks.add(callback);
  @override
  void remove(TimingsCallback callback) => callbacks.remove(callback);
  void frames(double rasterMs, {int count = GlassWatchdog.windowSize}) {
    final frame = FrameTiming(
      vsyncStart: 0,
      buildStart: 0,
      buildFinish: 1000,
      rasterStart: 1000,
      rasterFinishWallTime: 0,
      rasterFinish: 1000 + (rasterMs * 1000).round(),
    );
    for (final callback in List.of(callbacks)) {
      callback(List.filled(count, frame));
    }
  }
}
