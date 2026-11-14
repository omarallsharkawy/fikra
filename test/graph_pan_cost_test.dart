import 'package:fikra/features/links/graph_edge_paths.dart';
import 'package:fikra/features/links/links_screen.dart' show debugGraphDashVertices;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'graph_fixture.dart';
import 'graph_navigation_fixture.dart' show navController, viewScale;
import 'support/app_harness.dart';

// Impeller has no raster cache: the canvas picture is replayed on every pan
// frame, and drawRawPoints(PointMode.lines) becomes one draw per dash. On the
// 5,000-note phone run that took pan raster p90 from 5.3 to 19.7 ms.
void main() {
  test('cap steps follow Impeller round caps', () {
    expect(
      [
        for (final r in [0.3, 1.05, 1.8, 2.1, 4.2, 5.25, 9.0]) graphCapDivisions(r),
      ],
      [2, 3, 3, 4, 4, 5, 6],
    );
  });

  fikraTest(
    'a pan frame replays a few draws per dashed connector and repaints no graph layer',
    locale: const Locale('en'),
    (t, db) async {
      t.view.devicePixelRatio = 3;
      t.view.physicalSize = const Size(390 * 3, 844 * 3);
      addTearDown(t.view.reset);
      debugGraphDashVertices = true;
      addTearDown(() => debugGraphDashVertices = null);
      await seedGraph(t, db);

      final paths = graphPaths(t);
      final dashed = [
        for (final e in paths.edges)
          if (!e.geometry.link.isUser) e,
      ];
      expect(dashed, isNotEmpty);
      dynamic painter() => t.widget<CustomPaint>(graphPaint).painter;
      final divisions = painter().capDivisions as int;
      expect(divisions, graphCapDivisions(graphSuggestionStroke / 2 * 3 * viewScale(t)));
      final runs = dashed.fold<int>(0, (n, e) => n + e.dashVertices(divisions).length);
      final dashes = dashed.fold<int>(0, (n, e) => n + e.dashPoints.length ~/ 4);
      expect(runs, lessThan(dashes));
      final ink = t.renderObject(graphPaint);
      expect(ink, paintsExactlyCountTimes(#drawRawPoints, 0));
      expect(ink, paintsExactlyCountTimes(#drawLine, 0));
      expect(ink, paintsExactlyCountTimes(#drawVertices, runs));
      expect(ink, paintsExactlyCountTimes(#drawPath, paths.edges.length - dashed.length));

      // A repaint replaces a boundary's picture layers; panning only moves them.
      final canvas = t.renderObject<RenderRepaintBoundary>(
        find.descendant(of: find.byType(InteractiveViewer), matching: find.byType(RepaintBoundary)).first,
      );
      final edges = t.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('graph-edges-layer')));
      List<PictureLayer> pictures(RenderRepaintBoundary b) {
        final out = <PictureLayer>[];
        void walk(Layer layer) {
          if (layer is PictureLayer) out.add(layer);
          if (layer is ContainerLayer) {
            for (var child = layer.firstChild; child != null; child = child.nextSibling) {
              walk(child);
            }
          }
        }

        walk(b.debugLayer!);
        return out;
      }

      bool same(List<PictureLayer> a, List<PictureLayer> b) =>
          a.length == b.length && [for (var i = 0; i < a.length; i++) identical(a[i], b[i])].every((v) => v);
      final edgeInk = pictures(edges), all = pictures(canvas);
      expect(all.length, greaterThan(edgeInk.length));
      final first = painter(), paints = first.paintCount as int;

      // A real pan from the empty top padding, so no card press animates.
      final before = navController(t).value.getTranslation();
      final start = t.getTopLeft(find.byType(InteractiveViewer)) + const Offset(6, 6);
      await t.dragFrom(start, const Offset(-120, -60));
      for (var i = 0; i < 8; i++) {
        await t.pump(const Duration(milliseconds: 16));
      }
      expect(navController(t).value.getTranslation(), isNot(before));
      expect(same(pictures(canvas), all), isTrue);
      expect(identical(painter(), first), isTrue);
      expect(first.paintCount, paints);

      // Zoom repaints the edges only when Impeller would round caps differently.
      Future<void> zoom(double s) async {
        navController(t).value = Matrix4.diagonal3Values(s, s, s);
        await t.pump();
      }

      await zoom(1.5);
      final zoomed = painter();
      expect(zoomed.capDivisions, isNot(divisions));
      expect(zoomed.paintCount, 1);
      expect(same(pictures(edges), edgeInk), isFalse);
      final rest = pictures(canvas).where((p) => !pictures(edges).contains(p)).toList();
      expect(same(rest, all.where((p) => !edgeInk.contains(p)).toList()), isTrue);
      await zoom(2.5);
      expect(identical(painter(), zoomed), isTrue);
      expect(zoomed.paintCount, 1);
    },
  );
}
