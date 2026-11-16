import 'package:fikra/core/theme/fikra_theme.dart';
import 'package:fikra/core/theme/tokens.dart';
import 'package:fikra/core/widgets/fikra_widgets.dart';
import 'package:fikra/core/widgets/glass_power.dart';
import 'package:fikra/core/widgets/glass_watchdog.dart';
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
  testWidgets('frosted material has exactly one blur', (tester) async {
    await host(tester, const Glass(child: Text('تحكم')), tier: GlassTier.frosted);
    expect(find.byType(BackdropFilter), findsOneWidget);
    final filter = tester.widget<BackdropFilter>(find.byType(BackdropFilter));
    expect(filter.enabled, isTrue);
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
  testWidgets('MediaQuery reduce motion caps optical at frosted', (tester) async {
    await host(tester, const Glass(child: GlassLens(child: Text('تحكم'))), reduced: true);
    expect(find.byType(BackdropFilter), findsOneWidget);
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
}
