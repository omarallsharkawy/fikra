import 'dart:math' as math;

import 'package:fikra/core/theme/fikra_theme.dart';
import 'package:fikra/features/links/graph_layout.dart';
import 'package:fikra/features/links/graph_minimap.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'graph_layout_test.dart' show note;
import 'graph_navigation_fixture.dart';

void main() {
  for (final rtl in [false, true]) {
    testWidgets('minimap visibility, scene rectangle, tap/drag and cached content (rtl=$rtl)', (t) async {
      final layout = GraphLayout.compute(
        [for (var i = 0; i < 80; i++) note(i, cluster: 'row ${i ~/ 8}')],
        [],
        rtl: rtl,
      );
      final tc = TransformationController();
      addTearDown(tc.dispose);
      var viewport = const Size(390, 500);
      // The host measures the viewport in its layout pass; start unknown.
      final size = ValueNotifier(Size.zero);
      addTearDown(size.dispose);
      var underneath = 0;
      await t.pumpWidget(
        MaterialApp(
          theme: buildFikraTheme(Brightness.dark),
          locale: Locale(rtl ? 'ar' : 'en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => underneath++,
                  child: const ColoredBox(color: Colors.transparent),
                ),
              ),
              PositionedDirectional(
                top: 20,
                end: 20,
                child: ValueListenableBuilder<Size>(
                  valueListenable: size,
                  builder: (context, viewportSize, _) => GraphMinimap(
                    layout: layout,
                    controller: tc,
                    viewportSize: viewportSize,
                    onMove: (p) {
                      final s = tc.value.entry(0, 0);
                      tc.value = Matrix4.translationValues(
                        viewport.width / 2 - p.dx * s,
                        viewport.height / 2 - p.dy * s,
                        0,
                      )..scaleByDouble(s, s, s, 1);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      await t.pump();
      final map = navKey('graph-minimap');
      // An unknown viewport draws nothing rather than a point-sized rectangle.
      expect(map, findsNothing);
      size.value = viewport;
      await t.pump();
      expect(map, findsOneWidget);
      final r = t.getRect(map);
      expect(rtl ? r.left : t.view.physicalSize.width / t.view.devicePixelRatio - r.right, closeTo(20, 1));
      final content = t.widget<CustomPaint>(navKey('graph-minimap-content')).painter!;
      final paints = (content as dynamic).paintCount as int;
      final scale = math.min((112 - 8) / layout.width, (84 - 8) / layout.height);
      final origin = Offset((112 - layout.width * scale) / 2, (84 - layout.height * scale) / 2);
      void check() {
        final inverse = Matrix4.inverted(tc.value);
        final scene = MatrixUtils.transformRect(inverse, Offset.zero & viewport);
        expect(graphViewportRect(tc.value, viewport), scene);
        final painter = t.widget<CustomPaint>(navKey('graph-minimap-viewport')).painter! as GraphMinimapViewport;
        expect(painter.rect.left, closeTo(origin.dx + scene.left * scale, 1e-8));
        expect(painter.rect.top, closeTo(origin.dy + scene.top * scale, 1e-8));
        expect(painter.rect.width, closeTo(scene.width * scale, 1e-8));
        expect(painter.rect.height, closeTo(scene.height * scale, 1e-8));
      }

      check();
      for (final s in [0.5, 2.5]) {
        tc.value = Matrix4.translationValues(-130, -240, 0)..scaleByDouble(s, s, s, 1);
        await t.pump();
        check();
        expect(identical(t.widget<CustomPaint>(navKey('graph-minimap-content')).painter, content), isTrue);
        expect((content as dynamic).paintCount, paints);
      }
      // Aim at actual painted card centres. Expected scene points come from
      // layout data, not from the production inverse mapping or border box.
      Offset centreOf(String id) {
        final p = layout.positions[id]!;
        return Offset(p.left + p.width / 2, p.top + p.height / 2);
      }

      final target = centreOf('20'), next = centreOf('75');
      for (final zoom in [0.5, 2.5]) {
        tc.value = Matrix4.diagonal3Values(zoom, zoom, zoom);
        await t.pump();
        final ink = t.getTopLeft(navKey('graph-minimap-content'));
        final tap = ink + origin + target * scale;
        final end = ink + origin + next * scale;
        await t.tapAt(tap);
        await t.pump();
        var centre = graphViewportRect(tc.value, viewport).center;
        expect(centre.dx, closeTo(target.dx, 0.01));
        expect(centre.dy, closeTo(target.dy, 0.01));
        final gesture = await t.startGesture(tap);
        await gesture.moveTo(Offset.lerp(tap, end, 0.7)!);
        await t.pump();
        await gesture.moveTo(end);
        await gesture.up();
        await t.pump();
        centre = graphViewportRect(tc.value, viewport).center;
        expect(centre.dx, closeTo(next.dx, 0.01));
        expect(centre.dy, closeTo(next.dy, 0.01));
        expect(tc.value.entry(0, 0), zoom);
        expect(underneath, 0);
        expect((content as dynamic).paintCount, paints);
        check();
      }
      // A shorter viewport without any pan redraws the rectangle.
      viewport = const Size(390, 300);
      size.value = viewport;
      await t.pump();
      check();
      tc.value = Matrix4.diagonal3Values(0.05, 0.05, 1);
      await t.pump();
      expect(map, findsNothing);
      tc.value = Matrix4.identity();
      await t.pump();
      expect(map, findsOneWidget);
      await t.pumpWidget(const SizedBox());
    });
  }
}
