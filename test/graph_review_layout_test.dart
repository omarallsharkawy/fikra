import 'dart:math' as math;

import 'package:fikra/features/links/graph_layout.dart';
import 'package:fikra/features/links/graph_edge_paths.dart';
import 'package:flutter_test/flutter_test.dart' hide group;

import 'graph_route_assertions.dart';
import 'graph_layout_test.dart' show note, link;
import 'graph_frames_layout_test.dart' show group;

void clearInk(GraphLayout l) => expectClearGraphInk(l);

void main() {
  for (final rtl in [false, true]) {
    test('measured topic control follows label and all fixtures clear text/controls (rtl=$rtl)', () {
      final ns = [
        note(0, cluster: 'Ideas'),
        note(1, cluster: 'Ideas'),
        note(2, cluster: 'Trials'),
        note(3, cluster: 'Trials'),
        note(4, cluster: 'Later'),
        note(5, cluster: 'Later'),
      ];
      final es = [link(0, 1), link(0, 2), link(0, 3), link(2, 3), link(4, 5)];
      for (final framed in [false, true]) {
        final l = GraphLayout.compute(
          ns,
          es,
          rtl: rtl,
          groups: framed ? [group('p'), group('c', parent: 'p'), group('empty', position: 2)] : [],
          memberships: framed ? {'0': 'p', '1': 'p', '2': 'c'} : {},
          labelSizes: {
            'Ideas': (width: 39, height: 20),
            'Trials': (width: 35, height: 20),
            'Later': (width: 30, height: 20),
          },
        );
        for (final label in l.labels.where((l) => l.row != null)) {
          final c = label.control!, b = label.bounds;
          expect(rtl ? b.left - c.left - c.width : c.left - b.left - b.width, 8);
          expect(c.top + c.height / 2, b.top + b.height / 2);
          expect(c.width, 48);
          expect(c.height, 48);
          expect(hitTestGraphEdge(l, (x: c.left + 24, y: c.top + 24)), isNull);
        }
        clearInk(l);
      }
    });
  }

  test('separate gutter channels keep routed line taps distinguishable', () {
    final l = GraphLayout.compute(
      [note(0), note(1), note(2)],
      [link(0, 1), link(0, 2)],
      groups: [
        group('p'),
        group('c', parent: 'p'),
      ],
      memberships: {'0': 'p', '1': 'c'},
      rtl: false,
    );
    expect(l.edges.every((e) => e.curves.length > 1), isTrue);
    for (final e in l.edges) {
      expect(hitTestGraphEdge(l, e.middle)?.link.id, e.link.id);
    }
    clearInk(l);
  });

  test('cached solid paths and dashed ink follow the routed curves outside all text', () {
    final l = GraphLayout.compute(
      [note(0), note(1), note(2)],
      [link(0, 1, isUser: true), link(0, 2)],
      groups: [
        group('p'),
        group('c', parent: 'p'),
      ],
      memberships: {'0': 'p', '1': 'c'},
      rtl: false,
    );
    for (final e in GraphEdgePaths(l).edges) {
      for (final metric in e.path.computeMetrics()) {
        for (var d = 0.0; d < metric.length; d += 2) {
          final p = metric.getTangentForOffset(d)!.position;
          for (final r in graphRouteObstacles(l, e.geometry)) {
            expect(p.dx > r.left && p.dx < r.left + r.width && p.dy > r.top && p.dy < r.top + r.height, isFalse);
          }
        }
      }
      final ink = e.dashPoints;
      for (var i = 0; i < ink.length; i += 4) {
        for (final r in graphRouteObstacles(l, e.geometry)) {
          expect(graphSegmentIntersectsRect((x: ink[i], y: ink[i + 1]), (x: ink[i + 2], y: ink[i + 3]), r), isFalse);
        }
      }
    }
  });

  test('no-group cards and unobstructed curves keep their pre-change geometry', () {
    final es = [link(0, 1), link(0, 2)];
    final l = GraphLayout.compute(
      [note(0, cluster: 'A'), note(1, cluster: 'A'), note(2, cluster: 'B')],
      es,
      rtl: false,
      labelSizes: {'A': (width: 8, height: 20), 'B': (width: 8, height: 20)},
    );
    expect(l.positions['0'], (left: 24.0, top: 58.0, width: 148.0, height: 54.0));
    expect(l.positions['1'], (left: 194.0, top: 58.0, width: 148.0, height: 54.0));
    expect(l.positions['2'], (left: 24.0, top: 190.0, width: 148.0, height: 54.0));
    final old = [
      GraphEdge(es[0], (x: 98.0, y: 58.0), (x: 98.0, y: 18.0), (x: 268.0, y: 18.0), (x: 268.0, y: 58.0)),
      GraphEdge(es[1], (x: 98.0, y: 112.0), (x: 98.0, y: 151.0), (x: 98.0, y: 151.0), (x: 98.0, y: 190.0)),
    ];
    for (final (i, e) in old.indexed) {
      expect(l.edges[i].curves, e.curves);
      expect(l.edges[i].points, e.points);
    }
    clearInk(l);
  });

  test('compact first-row clearance follows its actual arc, with an 8 dp minimum', () {
    final ns = [note(0), note(1)];
    final noArc = GraphLayout.compute(ns, [], groups: [group('p')], memberships: {'0': 'p', '1': 'p'}, rtl: false);
    double gap(GraphLayout l) => l.positions['0']!.top - l.frames.first.header.top - l.frames.first.header.height;
    expect(gap(noArc), 8);
    final arc = GraphLayout.compute(
      ns,
      [link(0, 1)],
      groups: [group('p')],
      memberships: {'0': 'p', '1': 'p'},
      rtl: false,
    );
    final e = arc.edges.single;
    final span = (e.end.x - e.start.x).abs() / (GraphLayout.nodeWidth + GraphLayout.gapX);
    expect(gap(arc), closeTo(math.max(8, 18 + 24 * span / (1 + span) + 6), 1e-8));
    clearInk(arc);
  });

  test('scaled suggested title reserves its full height before the topic controls', () {
    final l = GraphLayout.compute(
      [note(0), note(1)],
      [],
      groups: [group('empty')],
      labelSizes: {'cluster': (width: 250, height: 60)},
      suggestedSize: (width: 300, height: 78),
    );
    final title = l.labels.first.bounds, topic = l.labels.last;
    expect(topic.bounds.top, greaterThanOrEqualTo(title.top + title.height));
    expect(topic.control!.top, greaterThanOrEqualTo(title.top + title.height));
  });

  test('processing group notes are counted and have an explicit overflow card', () {
    final l = GraphLayout.compute(
      [note(0, status: 0), note(1, status: 2), note(2)],
      [],
      groups: [group('p')],
      memberships: {'0': 'p', '1': 'p', '2': 'p'},
    );
    expect(l.frames.single.count, 3);
    expect(l.nodes.keys, ['2']);
    expect(l.rows.single.hiddenNotes.map((n) => n.id).toSet(), {'0', '1'});
    final waiting = GraphLayout.compute([note(0, status: 0)], [], groups: [group('p')], memberships: {'0': 'p'});
    expect(waiting.nodes, isEmpty);
    expect(waiting.rows.single.hiddenCount, 1);
    expect(waiting.frames.single.count, 1);
    expect(waiting.frames.single.bounds.height, greaterThan(GraphLayout.headerHeight + GraphLayout.nodeHeight));
  });

  test('blank, whitespace and null topics share one general row in both paths', () {
    final ns = [note(0, cluster: null), note(1, cluster: ''), note(2, cluster: '   ')];
    for (final gs in [
      <GraphGroup>[],
      [group('empty')],
    ]) {
      final l = GraphLayout.compute(ns, [], groups: gs, generalLabel: 'General');
      expect(l.rows, hasLength(1));
      expect(l.rows.single.cluster, 'General');
      expect(l.rows.single.notes, hasLength(3));
      expect(l.rows.single.canMakeGroup, isFalse);
    }
  });

  test('frame overflow stores exactly the hidden notes, excluding the last visible slice', () {
    final ns = [for (var i = 0; i < 30; i++) note(i)];
    final l = GraphLayout.compute(
      ns,
      [],
      groups: [group('p')],
      memberships: {for (final n in ns) n.id: 'p'},
      maxNodes: 13,
      preserveSmallProjectsUpTo: 0,
    );
    expect(l.nodes, hasLength(13));
    final row = l.rows.last;
    expect(row.notes, hasLength(18));
    expect(row.visible, hasLength(1));
    expect(row.hiddenNotes, hasLength(17));
    expect(row.hiddenNotes.any((n) => l.nodes.containsKey(n.id)), isFalse);
  });

  test('deep groups, cycles and missing parents fall back without disappearing or duplicating', () {
    final gs = [
      group('a'),
      group('b', parent: 'a'),
      group('deep', parent: 'b'),
      group('cycle1', parent: 'cycle2'),
      group('cycle2', parent: 'cycle1'),
      group('orphan', parent: 'gone'),
    ];
    final ns = [for (var i = 0; i < gs.length; i++) note(i)];
    final l = GraphLayout.compute(ns, [], groups: gs, memberships: {for (final (i, g) in gs.indexed) '$i': g.id});
    expect(l.frames.map((f) => f.group.id).toSet(), gs.map((g) => g.id).toSet());
    expect(l.frames, hasLength(gs.length));
    expect(l.nodes, hasLength(gs.length));
    for (final n in ns) {
      final frame = l.frames.singleWhere((f) => f.group.id == gs[int.parse(n.id)].id);
      final p = l.positions[n.id]!;
      expect(p.top, greaterThan(frame.header.top + frame.header.height));
      expect(p.top + p.height, lessThan(frame.bounds.top + frame.bounds.height));
    }
  });
}
