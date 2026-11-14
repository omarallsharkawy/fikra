import 'dart:isolate';
import 'dart:math' as math;

import 'package:fikra/features/links/graph_edge_paths.dart';
import 'package:fikra/features/links/graph_layout.dart';
import 'package:fikra/features/links/graph_search.dart';
import 'package:flutter_test/flutter_test.dart' hide group;

import 'graph_frames_layout_test.dart' show group, rect;
import 'graph_layout_test.dart' show note, link;

void main() {
  final groups = [group('parent', name: 'مَجموعة'), group('child', parent: 'parent'), group('other', position: 1)];
  final notes = [note(0), note(1), note(2), note(3), note(4)];
  final members = {'0': 'parent', '1': 'child', '2': 'child', '3': 'other'};
  final links = [link(0, 1), link(1, 2), link(0, 3), link(1, 3, isUser: true), link(2, 4)];
  GraphLayout layout(Set<String> folded, {bool rtl = false}) =>
      GraphLayout.compute(notes, links, groups: groups, memberships: members, collapsedGroups: folded, rtl: rtl);

  test('search indexes all ready titles, reasons and group names, with a hard result cap', () {
    final input = GraphInput(
      [
        (id: 'ar', title: 'فِكرة', cluster: null, createdAt: 0, status: 1),
        (id: 'en', title: 'Mixed CASE', cluster: null, createdAt: 1, status: 1),
        (id: 'waiting', title: 'Waiting', cluster: null, createdAt: 2, status: 0),
      ],
      [
        (id: 'reason', sourceId: 'ar', targetId: 'en', label: 'سَبب', strength: 1, isUser: true),
        (
          id: 'dismissed-by-status',
          sourceId: 'waiting',
          targetId: 'en',
          label: 'Waiting link',
          strength: 1,
          isUser: true,
        ),
      ],
      groups: groups,
      collapsedGroups: {'parent'},
      memberships: {'ar': 'parent'},
    );
    final index = GraphSearchIndex(input);
    expect(index.search('cAsE').single.id, 'en');
    expect(index.search('فِكرة').single.kind, GraphSearchKind.note);
    expect(index.search('سَبب').single.kind, GraphSearchKind.link);
    expect(index.search('مَجموعة').single.kind, GraphSearchKind.group);
    // No Arabic normaliser exists in this project; do not invent a parallel one.
    expect(index.search('Waiting'), isEmpty);
    expect(index.search('   '), isEmpty);
    expect(index.search('absent'), isEmpty);
    final many = GraphSearchIndex(GraphInput([for (var i = 0; i < 100; i++) note(i)], []));
    expect(many.search('Note'), hasLength(GraphSearchIndex.resultLimit));
  });

  for (final rtl in [false, true]) {
    test('folded parent packs children, reflows, merges user edges and routes clear (rtl=$rtl)', () {
      final before = layout({}, rtl: rtl), folded = layout({'parent'}, rtl: rtl);
      final capsule = folded.frames.first;
      expect(capsule.collapsed, isTrue);
      expect(capsule.count, 3);
      expect(capsule.noteIds, {'0', '1', '2'});
      expect(folded.frames.map((f) => f.group.id), ['parent', 'other']);
      expect(folded.nodes.keys.toSet(), {'3', '4'});
      expect(folded.foldedNotes, {'0': capsule.endpointId, '1': capsule.endpointId, '2': capsule.endpointId});
      expect(folded.positions[capsule.endpointId], capsule.bounds);
      expect(folded.height, lessThan(before.height));
      expect(folded.positions['3']!.top, lessThan(before.positions['3']!.top));
      expect(folded.links.map((e) => e.id).toSet(), {links[3].id, links[4].id});
      expect(folded.links.first.isUser, isTrue);
      expect(folded.links.every((e) => e.sourceId != e.targetId), isTrue);
      expect(folded.links.every((e) => folded.isFoldedLink(e)), isTrue);
      for (final p in folded.positions.entries) {
        for (final q in folded.positions.entries.where((q) => q.key != p.key)) {
          expect(rect(p.value).overlaps(rect(q.value)), isFalse);
        }
      }
      expect(rect(folded.frames[0].bounds).overlaps(rect(folded.frames[1].bounds)), isFalse);
      for (final e in folded.edges) {
        for (final obstacle in folded.obstacles) {
          for (var i = 1; i < e.points.length; i++) {
            expect(
              graphSegmentIntersectsRect(e.points[i - 1], e.points[i], obstacle),
              isFalse,
              reason: '${e.link.id} must clear text and controls',
            );
          }
        }
      }
    });
  }

  test('folds participate in collision-safe input equality and are isolate-sendable', () async {
    final expanded = GraphInput(notes, links, groups: groups, memberships: members);
    final folded = GraphInput(notes, links, groups: groups, memberships: members, collapsedGroups: {'parent'});
    expect(expanded.sameData(folded), isFalse);
    expect(
      folded.sameData(GraphInput(notes, links, groups: groups, memberships: members, collapsedGroups: {'parent'})),
      isTrue,
    );
    final result = await Isolate.run(() => GraphLayout.fromInput(folded));
    expect(result.frames.first.collapsed, isTrue);
  });

  test('a merged line carries a reason only when it stands for exactly one link', () {
    final l = GraphLayout.compute(
      notes,
      [link(0, 3, label: 'first'), link(1, 3, label: 'second'), link(2, 4, label: 'only')],
      groups: groups,
      memberships: members,
      collapsedGroups: {'parent'},
      rtl: false,
    );
    final capsule = l.frames.first.endpointId;
    GraphLink between(String other) =>
        l.links.singleWhere((e) => {e.sourceId, e.targetId}.containsAll({capsule, other}));
    expect(between('3').label, isEmpty);
    expect(between('4').label, 'only');
  });

  for (final rtl in [false, true]) {
    test('a gutter route between notes of one frame stays inside that frame (rtl=$rtl)', () {
      // Note 0 sits in the parent's row, note 2 in the child frame below: the
      // direct curve would cross the child's header, so a lane is needed.
      final l = GraphLayout.compute(
        [note(0), note(1), note(2)],
        [link(0, 2)],
        groups: [
          group('parent'),
          group('child', parent: 'parent'),
        ],
        memberships: {'0': 'parent', '1': 'parent', '2': 'child'},
        rtl: rtl,
      );
      final parent = rect(l.frames.first.bounds), child = rect(l.frames[1].bounds);
      final edge = l.edges.single;
      expect(edge.curves.length, greaterThan(1), reason: 'routed, not a direct curve');
      for (final p in edge.points) {
        expect(p.x, inExclusiveRange(parent.left, parent.right));
      }
      // The lane runs in the parent's padding strip, outside the child frame.
      final lane = edge.points.map((p) => p.x).reduce(rtl ? math.max : math.min);
      expect(rtl ? lane > child.right : lane < child.left, isTrue);
      for (final obstacle in l.obstacles) {
        for (var i = 1; i < edge.points.length; i++) {
          expect(graphSegmentIntersectsRect(edge.points[i - 1], edge.points[i], obstacle), isFalse);
        }
      }
    });
  }

  test('240/1000 builds: expanded vs no groups; fold cost vs the same graph with empty frames; fold vs open', () {
    final all = [for (var i = 0; i < 240; i++) note(i, cluster: 'c${i ~/ 12}')];
    final edges = [for (var i = 0; i < 1000; i++) link(i ~/ 200, 40 + i % 200)];
    final gs = [for (var i = 0; i < 5; i++) group('g$i', position: i)];
    final membership = {for (var i = 0; i < 240; i++) '$i': 'g${i ~/ 48}'};
    const folds = {'g1', 'g3'};
    // Baseline for the fold's own cost: the same visible graph where the two
    // folded groups are empty frames (same header obstacles, same links).
    bool kept(String id) => !folds.contains(membership[id]);
    final keptNotes = [
      for (final n in all)
        if (kept(n.id)) n,
    ];
    final keptEdges = [
      for (final e in edges)
        if (kept(e.sourceId) && kept(e.targetId)) e,
    ];
    GraphEdgePaths paths(List<GraphNote> n, List<GraphLink> e, {bool grouped = true, Set<String> fold = const {}}) =>
        GraphEdgePaths(
          GraphLayout.compute(
            n,
            e,
            groups: grouped ? gs : const [],
            memberships: grouped ? membership : const {},
            collapsedGroups: fold,
          ),
        );
    final cases = <String, GraphEdgePaths Function()>{
      'no groups': () => paths(all, edges, grouped: false),
      'expanded': () => paths(all, edges),
      'empty frames': () => paths(keptNotes, keptEdges),
      'folded, same links': () => paths(all, keptEdges, fold: folds),
      'folded': () => paths(all, edges, fold: folds),
    };
    expect(
      cases['folded, same links']!().layout.nodes.keys.toSet(),
      cases['empty frames']!().layout.nodes.keys.toSet(),
    );
    expect(cases['folded']!().layout.nodes, hasLength(144));
    // Paired warm medians, alternating order so first-run costs fall on neither.
    (int, int) pair(String a, String b) {
      for (var i = 0; i < 6; i++) {
        cases[a]!();
        cases[b]!();
      }
      final ta = <int>[], tb = <int>[];
      for (var i = 0; i < 21; i++) {
        for (final k in i.isEven ? [a, b] : [b, a]) {
          final watch = Stopwatch()..start();
          cases[k]!();
          (k == a ? ta : tb).add(watch.elapsedMicroseconds);
        }
      }
      ta.sort();
      tb.sort();
      return (ta[10], tb[10]);
    }

    final (expanded, noGroups) = pair('expanded', 'no groups');
    final (foldedSame, emptyFrames) = pair('folded, same links', 'empty frames');
    final (folded, open) = pair('folded', 'expanded');
    expect(expanded, lessThanOrEqualTo(noGroups * 1.10));
    expect(foldedSame, lessThanOrEqualTo(emptyFrames * 1.10));
    expect(folded, lessThanOrEqualTo(open * 1.10));
    // ignore: avoid_print
    print(
      '240/1000 paired warm medians (us): no groups $noGroups / expanded $expanded; '
      'empty frames $emptyFrames / folded same links $foldedSame; open $open / folded $folded',
    );
  });
}
