import 'package:fikra/core/widgets/glass_power.dart';
import 'package:fikra/core/widgets/glass_quality.dart';
import 'package:fikra/core/widgets/glass_watchdog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'glass_test_fakes.dart';

void main() {
  test('native power stream is fakeable and defaults to solid until known', () async {
    final power = FakeGlassPower();
    final container = ProviderContainer(overrides: [glassPowerSourceProvider.overrideWithValue(power)]);
    addTearDown(power.dispose);
    addTearDown(container.dispose);
    // Glass widgets watch the tier. Riverpod 3 pauses an unlistened provider,
    // so its stream events never reach a bare read; listen like they do.
    final tier = container.listen(glassTierProvider(false), (_, _) {});
    expect(tier.read(), GlassTier.solid);
    power.values.add(false);
    await container.pump();
    expect(tier.read(), GlassTier.optical);
    power.values.add(true);
    await container.pump();
    expect(tier.read(), GlassTier.solid);
  });

  for (final powerSave in [false, true]) {
    for (final reduced in [false, true]) {
      for (final forced in [null, ...GlassTier.values]) {
        test('minimum: battery=$powerSave reduced=$reduced override=$forced', () {
          final container = ProviderContainer(
            overrides: [glassPowerSaveProvider.overrideWithValue(AsyncData(powerSave))],
          );
          addTearDown(container.dispose);
          container.read(glassTierOverrideProvider.notifier).force(forced);
          final expected = powerSave || reduced || forced == GlassTier.solid
              ? GlassTier.solid
              : forced == GlassTier.frosted
              ? GlassTier.frosted
              : GlassTier.optical;
          expect(container.read(glassTierProvider(reduced)), expected);
        });
      }
    }
  }
  test('watchdog collects only visible frames, scales budget and never auto-raises', () {
    final timings = FakeGlassTimings();
    final container = ProviderContainer(
      overrides: [
        glassTimingsSourceProvider.overrideWithValue(timings),
        glassPowerSaveProvider.overrideWithValue(const AsyncData(false)),
      ],
    );
    addTearDown(container.dispose);
    final watchdog = container.read(glassWatchdogProvider.notifier);
    expect(timings.callbacks, isEmpty);
    final owner = Object();
    watchdog.show(owner, 120);
    expect(timings.callbacks, hasLength(1));
    timings.frames(8, count: 119);
    expect(container.read(glassTierProvider(false)), GlassTier.optical);
    timings.frames(8, count: 1);
    expect(container.read(glassTierProvider(false)), GlassTier.frosted);
    container.read(glassTierOverrideProvider.notifier).force(GlassTier.optical);
    expect(container.read(glassTierProvider(false)), GlassTier.frosted);
    timings.frames(1, count: 240);
    expect(container.read(glassTierProvider(false)), GlassTier.frosted);
    timings.frames(8);
    expect(container.read(glassTierProvider(false)), GlassTier.solid);
    watchdog.hide(owner);
    expect(timings.callbacks, isEmpty);
    watchdog.show(owner, 60);
    timings.frames(1);
    expect(container.read(glassTierProvider(false)), GlassTier.solid);
    watchdog.hide(owner);
    expect(GlassWatchdog.budgetMs(120), 6.5);
    expect(GlassWatchdog.budgetMs(60), 13);
    expect(GlassWatchdog.budgetMs(144), closeTo(5.4167, .001));
  });
  test('p95 tolerates isolated slow frames; 60 Hz gets a 13 ms budget', () {
    final timings = FakeGlassTimings();
    final container = ProviderContainer(overrides: [glassTimingsSourceProvider.overrideWithValue(timings)]);
    addTearDown(container.dispose);
    final watchdog = container.read(glassWatchdogProvider.notifier);
    watchdog.show(Object(), 60);
    timings.frames(8);
    expect(container.read(glassWatchdogProvider), GlassTier.optical);
    timings.frames(1, count: 115);
    timings.frames(30, count: 5);
    expect(container.read(glassWatchdogProvider), GlassTier.optical);
    timings.frames(14);
    expect(container.read(glassWatchdogProvider), GlassTier.frosted);
  });
}
