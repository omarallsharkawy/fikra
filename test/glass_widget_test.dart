import 'dart:ui' show ImageFilter;

import 'package:fikra/app/tab_bar/floating_navigation.dart';
import 'package:fikra/core/theme/fikra_theme.dart';
import 'package:fikra/core/theme/tokens.dart';
import 'package:fikra/core/widgets/fikra_widgets.dart';
import 'package:fikra/core/widgets/glass_power.dart';
import 'package:fikra/core/widgets/glass_watchdog.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderBackdropFilter;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import 'glass_test_fakes.dart';

void main() {
  Future<ProviderContainer> host(
    WidgetTester tester,
    Widget child, {
    GlassTier tier = GlassTier.optical,
    bool powerSave = false,
    bool reduced = false,
  }) async {
    final container = ProviderContainer(
      overrides: [
        glassPowerSaveProvider.overrideWithValue(AsyncData(powerSave)),
        glassTimingsSourceProvider.overrideWithValue(FakeGlassTimings()),
      ],
    );
    addTearDown(container.dispose);
    container.read(glassTierOverrideProvider.notifier).force(tier);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildFikraTheme(Brightness.light),
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: Scaffold(body: Center(child: child)),
          ),
        ),
      ),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
    });
    return container;
  }

  testWidgets('reading surface is opaque with a line and no backdrop filter', (tester) async {
    await host(tester, const SolidSurface(child: Text('ملاحظة')));
    expect(find.byType(BackdropFilter), findsNothing);
    final container = tester.widget<Container>(
      find.descendant(of: find.byType(SolidSurface), matching: find.byType(Container)).first,
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, FikraPalette.light.surface);
    expect(decoration.color!.a, 1);
    expect(decoration.gradient, isNull);
    expect((decoration.border! as Border).top.color, FikraPalette.light.line);
  });
  testWidgets('solid material has no backdrop filter', (tester) async {
    await host(tester, const Glass(child: Text('تحكم')), tier: GlassTier.solid);
    expect(find.byType(BackdropFilter), findsNothing);
  });
  testWidgets('frosted material has exactly one sigma-16 blur and theme backing alpha', (tester) async {
    await host(tester, const Glass(child: Text('تحكم')), tier: GlassTier.frosted);
    expect(find.byType(BackdropFilter), findsOneWidget);
    final filter = tester.widget<BackdropFilter>(find.byType(BackdropFilter));
    expect(filter.enabled, isTrue);
    expect(filter.filter, ImageFilter.blur(sigmaX: 16, sigmaY: 16));
    final backing = tester.widget<ColoredBox>(
      find.descendant(of: find.byType(Glass), matching: find.byType(ColoredBox)).first,
    );
    expect(backing.color.a, closeTo(FikraPalette.light.glassBackingAlpha, 1e-6));
  });
  testWidgets('dark frosted glass uses 0.72 backing alpha with sigma-16 blur', (tester) async {
    final container = ProviderContainer(
      overrides: [
        glassPowerSaveProvider.overrideWithValue(const AsyncData(false)),
        glassTimingsSourceProvider.overrideWithValue(FakeGlassTimings()),
      ],
    );
    addTearDown(container.dispose);
    container.read(glassTierOverrideProvider.notifier).force(GlassTier.frosted);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildFikraTheme(Brightness.dark),
          home: const Scaffold(
            body: Center(child: Glass(child: Text('تحكم'))),
          ),
        ),
      ),
    );
    addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));
    final filter = tester.widget<BackdropFilter>(find.byType(BackdropFilter));
    expect(filter.filter, ImageFilter.blur(sigmaX: 16, sigmaY: 16));
    final backing = tester.widget<ColoredBox>(
      find.descendant(of: find.byType(Glass), matching: find.byType(ColoredBox)).first,
    );
    expect(backing.color.a, closeTo(0.72, 1e-6));
  });
  testWidgets('non-overlapping siblings share a BackdropGroup key', (tester) async {
    await host(
      tester,
      BackdropGroup(
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Glass(child: Text('أ')),
            Glass(child: Text('ب')),
          ],
        ),
      ),
      tier: GlassTier.frosted,
    );
    final elements = find.byType(BackdropFilter).evaluate().toList();
    expect(elements, hasLength(2));
    final first = BackdropGroup.of(elements.first)!.backdropKey;
    final second = BackdropGroup.of(elements.last)!.backdropKey;
    expect(first, same(second));
    for (final e in elements) {
      expect((e.renderObject! as RenderBackdropFilter).backdropKey, same(first));
    }
  });
  testWidgets('battery saver wins even over an optical request', (tester) async {
    await host(tester, const Glass(child: GlassLens(child: Text('تحكم'))), powerSave: true);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.byType(LiquidGlassLens), findsNothing);
  });
  testWidgets('MediaQuery reduce motion forces solid with no backdrop filter', (tester) async {
    await host(tester, const Glass(child: GlassLens(child: Text('تحكم'))), reduced: true);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.byType(LiquidGlassLens), findsNothing);
  });
  testWidgets('optical wrapper supplies the Pearl package lens recipe', (tester) async {
    await host(
      tester,
      const SizedBox(
        width: 240,
        height: 88,
        child: Glass(child: GlassLens(child: Text('فكرة'))),
      ),
    );
    final lens = tester.widget<LiquidGlassLens>(find.byType(LiquidGlassLens));
    expect(lens.style.blur, 7);
    expect(lens.style.saturation, 1.02);
    expect(lens.style.color, FikraPalette.light.surface.withValues(alpha: .20));
    expect(lens.style.refractionIndex, 1.02);
    expect(lens.style.dispersion, 0);
    expect(lens.touch, isNull);
    expect(lens.style.adaptivity, isNull);
  });
  testWidgets('optical fade uses shader opacity without isolating the backdrop', (tester) async {
    await host(tester, const SizedBox(width: 108, height: 88, child: GlassLens(opacity: .5, child: SizedBox.expand())));
    final lens = tester.widget<LiquidGlassLens>(find.byType(LiquidGlassLens));
    expect(lens.opacity, .5);
    expect(lens.style.blur, 3.5);
    // Only GlassLens's own subtree: every route wraps its page in an Opacity.
    final isolating = find.ancestor(of: find.byType(LiquidGlassLens), matching: find.byType(Opacity));
    expect(find.descendant(of: find.byType(GlassLens), matching: isolating), findsNothing);
  });
  for (final tier in [GlassTier.solid, GlassTier.frosted]) {
    testWidgets('lens stays visible with its capsule material at $tier', (tester) async {
      await host(
        tester,
        const SizedBox(width: 108, height: 88, child: GlassLens(child: SizedBox.expand())),
        tier: tier,
      );
      expect(find.byType(Glass), findsOneWidget);
      expect(find.byType(LiquidGlassLens), findsNothing);
      expect(find.byType(BackdropFilter), tier == GlassTier.solid ? findsNothing : findsOneWidget);
      expect(tester.getSize(find.byType(Glass)), const Size(108, 88));
    });
  }
  testWidgets('offstage glass stops watchdog collection without resetting its ceiling', (tester) async {
    final source = FakeGlassTimings();
    final container = ProviderContainer(
      overrides: [
        glassPowerSaveProvider.overrideWithValue(const AsyncData(false)),
        glassTimingsSourceProvider.overrideWithValue(source),
      ],
    );
    addTearDown(container.dispose);
    final visible = ValueNotifier(true);
    addTearDown(visible.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildFikraTheme(Brightness.light),
          home: ValueListenableBuilder<bool>(
            valueListenable: visible,
            builder: (_, value, child) => TickerMode(enabled: value, child: child!),
            child: const Center(child: Glass(child: Text('فكرة'))),
          ),
        ),
      ),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
    });
    expect(source.callbacks, hasLength(1));
    source.frames(20);
    expect(container.read(glassWatchdogProvider), GlassTier.frosted);
    visible.value = false;
    await tester.pump();
    expect(source.callbacks, isEmpty);
    visible.value = true;
    await tester.pump();
    expect(container.read(glassWatchdogProvider), GlassTier.frosted);
  });

  testWidgets('keyboard-hidden FloatingNavigation stops watchdog sampling and does not downgrade ceiling', (
    tester,
  ) async {
    final source = FakeGlassTimings();
    final container = ProviderContainer(
      overrides: [
        glassPowerSaveProvider.overrideWithValue(const AsyncData(false)),
        glassTimingsSourceProvider.overrideWithValue(source),
      ],
    );
    addTearDown(container.dispose);
    final keyboardOpen = ValueNotifier(false);
    addTearDown(keyboardOpen.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildFikraTheme(Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ar'),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 358,
                child: ValueListenableBuilder<bool>(
                  valueListenable: keyboardOpen,
                  builder: (_, hidden, _) => FloatingNavigation(branch: 1, keyboardOpen: hidden, onSelect: (_, _) {}),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));

    expect(source.callbacks, hasLength(1));
    source.frames(20, count: 60); // partial window while visible
    expect(container.read(glassWatchdogProvider), GlassTier.optical);

    // Hide navigation via keyboard: callback unregisters, frames do not downgrade, partial window resets.
    keyboardOpen.value = true;
    await tester.pump();
    expect(source.callbacks, isEmpty);
    source.frames(25, count: 240);
    expect(container.read(glassWatchdogProvider), GlassTier.optical);

    // Reshow: 60 slow frames are not enough (partial window was cleared); 120 total visible frames downgrade.
    keyboardOpen.value = false;
    await tester.pump();
    expect(source.callbacks, hasLength(1));
    source.frames(20, count: 60);
    expect(container.read(glassWatchdogProvider), GlassTier.optical);
    source.frames(20, count: 60);
    expect(container.read(glassWatchdogProvider), GlassTier.frosted);
  });

  testWidgets('policy-forced solid (battery saver, reduce motion, high contrast) never samples or lowers ceiling', (
    tester,
  ) async {
    final source = FakeGlassTimings();
    final power = FakeGlassPower();
    addTearDown(power.dispose);
    final container = ProviderContainer(
      overrides: [
        glassPowerSourceProvider.overrideWithValue(power),
        glassTimingsSourceProvider.overrideWithValue(source),
      ],
    );
    addTearDown(container.dispose);
    final reduced = ValueNotifier(false);
    final highContrast = ValueNotifier(false);
    addTearDown(reduced.dispose);
    addTearDown(highContrast.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildFikraTheme(Brightness.light),
          home: ValueListenableBuilder<bool>(
            valueListenable: reduced,
            builder: (_, isReduced, _) => ValueListenableBuilder<bool>(
              valueListenable: highContrast,
              builder: (_, isHighContrast, _) => MediaQuery(
                data: MediaQueryData(disableAnimations: isReduced, highContrast: isHighContrast),
                child: const Scaffold(
                  body: Center(child: Glass(child: Text('فكرة'))),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));

    // Unknown power state defaults to solid: no callback registered.
    expect(source.callbacks, isEmpty);
    source.frames(25, count: 240);
    expect(container.read(glassWatchdogProvider), GlassTier.optical);

    // Battery saver explicitly on: stays solid, no callback.
    power.values.add(true);
    await tester.pump();
    expect(source.callbacks, isEmpty);
    source.frames(25, count: 240);
    expect(container.read(glassWatchdogProvider), GlassTier.optical);

    // Battery saver off: optical active, registers callback.
    power.values.add(false);
    await tester.pump();
    expect(source.callbacks, hasLength(1));
    source.frames(25, count: 60);

    // Reduce motion forces solid, unregisters callback, and clears partial window.
    reduced.value = true;
    await tester.pump();
    expect(source.callbacks, isEmpty);
    source.frames(25, count: 240);
    expect(container.read(glassWatchdogProvider), GlassTier.optical);

    // High contrast forces solid, unregisters callback.
    reduced.value = false;
    highContrast.value = true;
    await tester.pump();
    expect(source.callbacks, isEmpty);
    source.frames(25, count: 240);
    expect(container.read(glassWatchdogProvider), GlassTier.optical);

    // All caps lifted: ceiling is still optical, and visible active frames can downgrade it.
    highContrast.value = false;
    await tester.pump();
    expect(source.callbacks, hasLength(1));
    source.frames(25, count: 120);
    await tester.pump();
    expect(container.read(glassWatchdogProvider), GlassTier.frosted);
  });
}
