import 'package:fikra/features/links/graph_edge_paths.dart';
import 'package:fikra/features/links/graph_layout.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/painting.dart';
import 'package:fikra/features/links/graph_capsules.dart';

import 'graph_layout_test.dart' show note, link;

void main() {
  GraphLayout fixture({bool rtl = false}) => GraphLayout.compute(
    [note(0), note(1), note(2), note(3, cluster: 'lower'), note(4, cluster: 'lower')],
    [link(0, 3), link(0, 4), link(0, 2), link(1, 3)],
    rtl: rtl,
  );

  test('ports are borders, cubic tangents are vertical; same-row arc is above cards', () {
    final layout = fixture();
    for (final e in layout.edges) {
      final a = layout.positions[e.link.sourceId]!, b = layout.positions[e.link.targetId]!;
      expect(e.start.x, inInclusiveRange(a.left + 18, a.left + a.width - 18));
      expect(e.end.x, inInclusiveRange(b.left + 18, b.left + b.width - 18));
      expect(e.control1.x, e.start.x);
      expect(e.control2.x, e.end.x);
      if (a.top == b.top) {
        expect(e.start.y, a.top);
        expect(e.end.y, b.top);
        expect(e.control1.y, lessThan(a.top));
        expect(e.control2.y, lessThan(b.top));
        expect(e.points.skip(1).take(e.points.length - 2).every((p) => p.y < a.top), isTrue);
      } else {
        expect(e.start.y, a.top + a.height);
        expect(e.end.y, b.top);
        expect(e.control1.y, greaterThan(e.start.y));
        expect(e.control2.y, lessThan(e.end.y));
      }
    }
    // A reversed stored direction still leaves the upper card first.
    final reversed = GraphLayout.compute([note(0), note(3, cluster: 'lower')], [link(3, 0)], rtl: false);
    expect(reversed.edges.single.start.y, reversed.positions['0']!.top + GraphLayout.nodeHeight);
    expect(reversed.edges.single.end.y, reversed.positions['3']!.top);
  });

  test('shared border ports are distinct, ordered by other card, independent of input order', () {
    final l = fixture();
    final a = l.edges.firstWhere((e) => e.link.targetId == '3' && e.link.sourceId == '0');
    final b = l.edges.firstWhere((e) => e.link.targetId == '4');
    expect(a.start.x, lessThan(b.start.x));
    final c = l.edges.firstWhere((e) => e.link.sourceId == '1');
    expect(a.end.x, lessThan(c.end.x));
    final reordered = GraphLayout.compute(l.nodes.values.toList(), l.links.reversed.toList(), rtl: false);
    for (final edge in l.edges) {
      final other = reordered.edges.firstWhere((e) => e.link.id == edge.link.id);
      expect(other.start, edge.start);
      expect(other.end, edge.end);
    }
  });

  test('RTL mirrors ports, controls and all sampled points exactly', () {
    final ltr = fixture(), rtl = fixture(rtl: true);
    for (var i = 0; i < ltr.edges.length; i++) {
      final a = ltr.edges[i], b = rtl.edges[i];
      for (final pair in [(a.start, b.start), (a.control1, b.control1), (a.control2, b.control2), (a.end, b.end)]) {
        expect(pair.$2.x, closeTo(ltr.width - pair.$1.x, 1e-9));
        expect(pair.$2.y, pair.$1.y);
      }
      expect(a.points.length, b.points.length);
    }
  });

  test('legacy reverse rows choose the user, otherwise the first suggestion, with no self links', () {
    final mine = link(1, 0, label: 'mine', isUser: true);
    final first = link(0, 2, label: 'first');
    final l = GraphLayout.compute(
      [note(0), note(1), note(2)],
      [link(0, 1), mine, link(0, 1, isUser: true, label: 'later user'), first, link(2, 0), link(0, 0)],
    );
    expect(l.links, [mine, first]);
    expect(l.edges, hasLength(2));
  });

  test('hit testing finds near lines, rejects distant taps and card interiors', () {
    final l = fixture();
    final e = l.edges.first;
    final p = e.middle;
    expect(hitTestGraphEdge(l, p)?.link, e.link);
    expect(hitTestGraphEdge(l, (x: p.x + 2, y: p.y + 2)), isNotNull);
    expect(hitTestGraphEdge(l, (x: -100, y: -100)), isNull);
    for (final card in l.positions.values) {
      expect(hitTestGraphEdge(l, (x: card.left + card.width / 2, y: card.top + 1)), isNull);
    }
  });

  test('nearest of two lines wins, and 24 screen dp tolerance follows zoom', () {
    final l = GraphLayout.compute(
      [note(0), note(1), note(2, cluster: 'lower'), note(3, cluster: 'lower')],
      [link(0, 2), link(1, 3)],
      rtl: false,
    );
    final e = l.edges.last;
    final p = (x: e.middle.x + 16, y: e.middle.y);
    expect(hitTestGraphEdge(l, p)?.link, e.link);
    expect(hitTestGraphEdge(l, p, scale: 2), isNull);
    expect(hitTestGraphEdge(l, p, scale: 0.5)?.link, e.link);
    // Both candidates are inside a deliberately enlarged reach; nearer wins
    // even when it is last in the iteration.
    expect(hitTestGraphEdge(l, (x: e.middle.x - 3, y: e.middle.y), tolerance: 200)?.link, e.link);
  });

  test('240 nodes / 1000 edges geometry and engine paths build within 750 ms each', () {
    final notes = [for (var i = 0; i < 240; i++) note(i, cluster: 'c${i ~/ 12}')];
    final links = [for (var i = 0; i < 2000; i++) link(i ~/ 200, 40 + i % 200, strength: i / 2000)];
    final watch = Stopwatch()..start();
    final l = GraphLayout.compute(notes, links);
    final geometryMs = watch.elapsedMilliseconds;
    expect(l.nodes, hasLength(240));
    expect(l.links, hasLength(1000));
    expect(l.edges, hasLength(1000));
    expect(geometryMs, lessThan(750));
    watch.reset();
    final cache = GraphEdgePaths(l);
    final pathsMs = watch.elapsedMilliseconds;
    expect(pathsMs, lessThan(750));
    expect(cache.edges, hasLength(1000));
    final firstPath = cache.edges.first.path;
    cache.focus('0');
    cache.focus(null);
    expect(identical(firstPath, cache.edges.first.path), isTrue);
    // ignore: avoid_print
    print('240/1000 connectors: geometry $geometryMs ms, paths/dashes $pathsMs ms');
  });
  test('top arc ports sit outside incoming connectors without an avoidable crossing', () {
    final l = GraphLayout.compute(
      [note(0, cluster: 'upper'), note(1, cluster: 'upper'), note(2), note(3)],
      [link(0, 3), link(2, 3)],
      rtl: false,
    );
    final incoming = l.edges.first, arc = l.edges.last;
    expect(arc.end.x, lessThan(incoming.end.x));
    double cross(GraphPoint a, GraphPoint b, GraphPoint c) => (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
    for (var i = 1; i < incoming.points.length; i++) {
      for (var j = 1; j < arc.points.length; j++) {
        final a = incoming.points[i - 1], b = incoming.points[i], c = arc.points[j - 1], d = arc.points[j];
        expect(cross(a, b, c) * cross(a, b, d) < 0 && cross(c, d, a) * cross(c, d, b) < 0, isFalse);
      }
    }
  });

  test('nested arcs have distinct increasing rises and stay below the previous row', () {
    final l = GraphLayout.compute(
      [for (var i = 0; i < 6; i++) note(i)],
      [link(0, 5), link(1, 4), link(2, 3)],
      rtl: false,
    );
    final rises = l.edges.map((e) => e.start.y - e.middle.y).toList();
    expect(rises[0], greaterThan(rises[1]));
    expect(rises[1], greaterThan(rises[2]));
    expect(rises.every((v) => v < 42 && v > 18), isTrue);
    expect(l.edges.every((e) => e.middle.y > e.start.y - (GraphLayout.rowHeight - GraphLayout.nodeHeight)), isTrue);
  });

  test('30 edges share at most twelve well separated straight-border ports', () {
    final l = GraphLayout.compute(
      [note(0, cluster: 'hub'), for (var i = 1; i <= 30; i++) note(i)],
      [for (var i = 1; i <= 30; i++) link(0, i)],
      rtl: false,
    );
    final hub = l.positions['0']!;
    final ports = l.edges.map((e) => e.end).toSet().toList()..sort((a, b) => a.x.compareTo(b.x));
    expect(ports, hasLength(12));
    for (final p in ports) {
      expect(p.y, hub.top);
      expect(p.x, inInclusiveRange(hub.left + 18, hub.left + hub.width - 18));
    }
    for (var i = 1; i < ports.length; i++) {
      expect(ports[i].x - ports[i - 1].x, greaterThanOrEqualTo(6));
    }
  });

  test('capsules slide, narrow or hide and never collide with cards, labels or each other', () {
    final l = GraphLayout.compute(
      [for (var i = 0; i < 8; i++) note(i)],
      [for (var i = 1; i < 8; i++) link(0, i, label: 'A long label for this connection')],
      rtl: false,
    );
    final obstacles = [
      for (final p in l.positions.values) Rect.fromLTWH(p.left, p.top, p.width, p.height),
      const Rect.fromLTWH(24, 24, 320, 24),
    ];
    final placed = layoutGraphCapsules(l, '0', obstacles: obstacles, measure: (_, width) => Size(width, 24));
    expect(placed, isNotEmpty);
    for (final c in placed) {
      expect(obstacles.any(c.rect.overlaps), isFalse);
      for (final other in placed) {
        if (!identical(c, other)) expect(c.rect.overlaps(other.rect), isFalse);
      }
    }
    expect(
      layoutGraphCapsules(l, '0', obstacles: [Rect.fromLTWH(0, 0, l.width, l.height)], measure: (_, w) => Size(w, 24)),
      isEmpty,
    );
  });

  test('count includes unique project pairs before the edge cap, not reverse or self rows', () {
    final notes = [for (var i = 0; i < 240; i++) note(i, cluster: 'c${i ~/ 12}')];
    final links = [for (var i = 0; i < 2000; i++) link(i ~/ 200, 40 + i % 200), link(40, 0, isUser: true), link(0, 0)];
    final l = GraphLayout.compute(notes, links);
    expect(l.linkCount, 2000);
    expect(l.links, hasLength(1000));
  });

  test('240/1000 full cache and one-link change reuse all unaffected drawing data', () {
    final notes = [for (var i = 0; i < 240; i++) note(i, cluster: 'c${i ~/ 12}')];
    final links = [for (var i = 0; i < 1000; i++) link(i ~/ 200, 40 + i % 200)];
    final watch = Stopwatch()..start();
    final first = GraphEdgePaths(GraphLayout.compute(notes, links));
    final fullUs = watch.elapsedMicroseconds;
    expect(first.rebuiltEdges, 1000);
    watch.reset();
    final old = links[0];
    links[0] = (
      id: old.id,
      sourceId: old.sourceId,
      targetId: old.targetId,
      label: old.label,
      strength: old.strength,
      isUser: true,
    );
    final next = GraphEdgePaths(GraphLayout.compute(notes, links), previous: first);
    final editUs = watch.elapsedMicroseconds;
    expect(next.rebuiltEdges, 1);
    for (var i = 1; i < 1000; i++) {
      expect(identical(next.edges[i].ink, first.edges[i].ink), isTrue);
    }
    final renamed = notes
        .map(
          (n) => (id: n.id, title: 'Renamed ${n.title}', cluster: n.cluster, createdAt: n.createdAt, status: n.status),
        )
        .toList();
    final rename = GraphEdgePaths(GraphLayout.compute(renamed, links), previous: next);
    expect(rename.rebuiltEdges, 0);
    expect(rename.layout.nodes['0']!.title, startsWith('Renamed'));
    expect(fullUs, lessThan(750000));
    expect(editUs, lessThan(750000));
    // ignore: avoid_print
    print('240/1000 total geometry+cache: full $fullUs us; one changed link $editUs us; rebuilt ${next.rebuiltEdges}');
  });
}
