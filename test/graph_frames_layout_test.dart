import 'dart:isolate';
import 'dart:ui';

import 'package:fikra/features/links/graph_capsules.dart';
import 'package:fikra/features/links/graph_edge_paths.dart';
import 'package:fikra/features/links/graph_layout.dart';
import 'package:flutter_test/flutter_test.dart';

import 'graph_layout_test.dart' show note, link;

GraphGroup group(String id, {String? parent, String? name, int position = 0}) =>
    (id: id, parentId: parent, name: name ?? id, color: 1, position: position);
Rect rect(GraphPosition p) => Rect.fromLTWH(p.left, p.top, p.width, p.height);

void main() {
  final groups = [group('parent'), group('child', parent: 'parent'), group('empty', position: 1)];
  final notes = [note(0), note(1), note(2), note(3, cluster: 'later')];
  final membership = {'0': 'parent', '1': 'child'};
  GraphLayout layout({bool rtl = false}) =>
      GraphLayout.compute(notes, [link(0, 1), link(2, 3)], groups: groups, memberships: membership, rtl: rtl);

  test('child is inside parent after its notes, empty frame has a header, topics below all frames', () {
    final l = layout();
    final p = l.frames[0], c = l.frames[1], e = l.frames[2];
    expect(p.group.id, 'parent');
    expect(rect(p.bounds).contains(rect(c.bounds).topLeft), isTrue);
    expect(rect(p.bounds).contains(rect(c.bounds).bottomRight), isTrue);
    expect(c.bounds.top, greaterThan(l.positions['0']!.top + GraphLayout.nodeHeight));
    expect(rect(p.bounds).overlaps(rect(e.bounds)), isFalse);
    expect(e.count, 0);
    expect(e.bounds.height, greaterThanOrEqualTo(GraphLayout.headerHeight));
    expect(l.suggestedTop, greaterThan(e.bounds.top + e.bounds.height));
    expect(l.positions['2']!.top, greaterThan(l.suggestedTop!));
    expect(l.rows.where((r) => r.groupId == null).map((r) => r.cluster), ['cluster', 'later']);
    for (final n in l.positions.entries) {
      for (final other in l.positions.entries.where((o) => o.key != n.key)) {
        expect(rect(n.value).overlaps(rect(other.value)), isFalse);
      }
    }
  });

  test('no groups keeps the exact original geometry and small-project exception', () {
    final es = [link(0, 29)];
    final l = GraphLayout.compute([for (var i = 0; i < 30; i++) note(i, cluster: 'A')], es, rtl: false);
    expect(l.frames, isEmpty);
    expect(l.suggestedTop, isNull);
    expect(l.rows, hasLength(1));
    expect(l.width, 5126);
    expect(l.height, 180);
    for (var i = 0; i < 30; i++) {
      expect(l.positions['$i'], (left: 24.0 + i * 170, top: 58.0, width: 148.0, height: 54.0));
    }
    final bend = (18 + 24 * 29 / 30) * 4 / 3;
    final old = GraphEdge(
      es.single,
      (x: 98.0, y: 58.0),
      (x: 98.0, y: 58 - bend),
      (x: 5028.0, y: 58 - bend),
      (x: 5028.0, y: 58.0),
    );
    expect(l.edges.single.curves, old.curves);
    expect(l.edges.single.points, old.points);
    final label = l.labels.single;
    expect(label.control!.left, label.bounds.left + label.bounds.width + 8);
    for (final r in l.obstacles) {
      for (var i = 1; i < old.points.length; i++) {
        expect(graphSegmentIntersectsRect(old.points[i - 1], old.points[i], r), isFalse);
      }
    }
  });

  test('equal-sized suggested topics retain legacy chronology with reversed stream input', () {
    final reversed = [
      note(3, cluster: 'Last'),
      note(2, cluster: 'Last'),
      note(1, cluster: 'First'),
      note(0, cluster: 'First'),
    ];
    final legacy = GraphLayout.compute(reversed, []);
    final grouped = GraphLayout.compute(reversed, [], groups: [group('empty')]);
    expect(grouped.rows.map((r) => r.cluster), legacy.rows.map((r) => r.cluster));
    expect(grouped.rows.map((r) => r.cluster), ['First', 'Last']);
  });

  test('RTL mirrors frames, headers, cards, overflow and connectors', () {
    final a = layout(), b = layout(rtl: true);
    expect(a.width, b.width);
    expect(a.height, b.height);
    for (final (i, f) in a.frames.indexed) {
      final g = b.frames[i];
      expect(g.bounds.left, a.width - f.bounds.left - f.bounds.width);
      expect(g.header.top, f.header.top);
    }
    for (final n in a.nodes.keys) {
      expect(b.positions[n]!.left, a.width - a.positions[n]!.left - GraphLayout.nodeWidth);
      expect(b.positions[n]!.top, a.positions[n]!.top);
    }
    for (final (i, edge) in a.edges.indexed) {
      expect(b.edges[i].middle.x, closeTo(a.width - edge.middle.x, 1e-9));
      expect(b.edges[i].middle.y, edge.middle.y);
    }
  });

  test('global row/node budgets account for hidden notes in each frame and topic', () {
    final all = [for (var i = 0; i < 300; i++) note(i, cluster: 'topic ${i ~/ 20}')];
    final l = GraphLayout.compute(
      all,
      [],
      groups: groups,
      memberships: {for (var i = 0; i < 180; i++) '$i': i < 90 ? 'parent' : 'child'},
      maxRows: 5,
      maxNodes: 50,
    );
    expect(l.nodes, hasLength(50));
    expect(l.rows.where((r) => r.visible.isNotEmpty), hasLength(5));
    expect(l.rows.every((r) => r.visible.length <= 12), isTrue);
    expect(
      l.rows.fold<int>(0, (n, r) => n + r.notes.length) + l.hiddenRows.fold<int>(0, (n, r) => n + r.notes.length),
      300,
    );
    expect(l.rows.where((r) => r.groupId == 'child').single.hiddenCount, 90);
    expect(l.hiddenRows.fold<int>(0, (n, r) => n + r.hiddenCount), 120);
    final child = l.frames[1];
    final overflow = l.rows.firstWhere((r) => r.groupId == 'child');
    expect(rect(child.bounds).contains(rect(l.positionInRow(overflow.index, 0)).bottomRight), isTrue);
    expect(l.morePosition.top, greaterThan(l.suggestedTop!));
  });

  test('names never widen frames and only named topics offer conversion', () {
    final a = layout();
    final b = GraphLayout.compute(
      notes,
      [],
      groups: [
        group('parent', name: 'long ' * 200),
        ...groups.skip(1),
      ],
      memberships: membership,
      rtl: false,
    );
    expect(b.width, a.width);
    expect(b.frames.first.bounds, a.frames.first.bounds);
    final fallback = GraphLayout.compute(
      [note(1, cluster: ''), note(2, cluster: null)],
      [],
      groups: [group('empty')],
      generalLabel: 'General',
    );
    expect(fallback.rows.every((r) => !r.canMakeGroup && r.cluster == 'General'), isTrue);
  });

  test('same-row arcs and selected capsules stay clear of every frame header', () {
    final l = GraphLayout.compute(
      [note(0), note(1), note(2), note(3)],
      [link(0, 1), link(0, 2), link(2, 3)],
      groups: groups,
      memberships: {'0': 'parent', '1': 'parent', '2': 'child', '3': 'child'},
      rtl: false,
    );
    final headers = l.frames.map((f) => rect(f.header)).toList();
    for (final edge in l.edges.where((e) => e.start.y == e.end.y)) {
      for (final p in edge.points) {
        expect(headers.any((h) => h.contains(Offset(p.x, p.y))), isFalse);
      }
    }
    final capsules = layoutGraphCapsules(
      l,
      '0',
      obstacles: [...l.positions.values.map(rect)],
      measure: (label, width) => Size(width, 24),
    );
    // Compact arc lanes may omit a capsule rather than cover the header.
    for (final c in capsules) {
      expect(headers.any(c.rect.overlaps), isFalse);
    }
    final header = l.frames.first.header;
    expect(hitTestGraphEdge(l, (x: header.left + 20, y: header.top + 20), tolerance: 10000), isNull);
  });

  test('large text reserves a taller header without changing card or frame width', () {
    final normal = layout();
    final large = GraphLayout.compute(
      notes,
      [],
      groups: groups,
      memberships: membership,
      rtl: false,
      headerExtent: 192,
    );
    expect(large.width, normal.width);
    for (final f in large.frames) {
      expect(f.header.height, 192);
    }
    expect(large.positions['0']!.top, large.frames.first.header.top + 192 + 8);
    expect(
      GraphInput(notes, [], groups: groups).sameData(GraphInput(notes, [], groups: groups, headerExtent: 192)),
      isFalse,
    );
  });

  test('group input is isolate-sendable and memoises memberships and group edits', () async {
    final input = GraphInput(notes, [], groups: groups, memberships: membership);
    final l = await Isolate.run(() => GraphLayout.fromInput(input));
    expect(l.frames, hasLength(3));
    expect(input.sameData(GraphInput(notes, [], groups: groups, memberships: {'0': 'child'})), isFalse);
    expect(input.sameData(GraphInput(notes, [], groups: [group('renamed')], memberships: membership)), isFalse);
    expect(
      input.sameData(GraphInput([...notes.reversed], [], groups: [...groups.reversed], memberships: membership)),
      isTrue,
    );
  });

  test('240/1000 grouped geometry+cache stays within 10% of the same no-group workload', () {
    final all = [for (var i = 0; i < 240; i++) note(i, cluster: 'c${i ~/ 12}')];
    final edges = [for (var i = 0; i < 1000; i++) link(i ~/ 200, 40 + i % 200)];
    final gs = [for (var i = 0; i < 5; i++) group('g$i', position: i)];
    final members = {for (var i = 0; i < 240; i++) '$i': 'g${i ~/ 48}'};
    GraphEdgePaths build(bool grouped) =>
        GraphEdgePaths(GraphLayout.compute(all, edges, groups: grouped ? gs : [], memberships: grouped ? members : {}));
    for (var i = 0; i < 8; i++) {
      build(false);
      build(true);
    }
    final baseline = <int>[], grouped = <int>[];
    for (var i = 0; i < 21; i++) {
      // Alternate order to avoid assigning all first-run costs to either path.
      for (final g in i.isEven ? [false, true] : [true, false]) {
        final t = Stopwatch()..start();
        final p = build(g);
        final elapsed = t.elapsedMicroseconds;
        (g ? grouped : baseline).add(elapsed);
        expect(p.layout.nodes, hasLength(240));
        expect(p.edges, hasLength(1000));
      }
    }
    baseline.sort();
    grouped.sort();
    expect(grouped[10], lessThanOrEqualTo(baseline[10] * 1.10));
    // ignore: avoid_print
    print('240/1000 paired warm median: no groups ${baseline[10]} us; groups ${grouped[10]} us; margin 10%');
  });
}
