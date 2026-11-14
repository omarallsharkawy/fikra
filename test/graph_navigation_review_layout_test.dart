import 'package:fikra/features/links/graph_layout.dart';
import 'package:fikra/features/links/graph_search.dart';
import 'package:flutter_test/flutter_test.dart' hide group;

import 'graph_frames_layout_test.dart' show group;
import 'graph_layout_test.dart' show note, link;
import 'graph_route_assertions.dart';

void main() {
  for (final rtl in [false, true]) {
    for (final reverse in [false, true]) {
      for (final folded in [false, true]) {
        test('connector clears sibling cards and capsules (rtl=$rtl reverse=$reverse folded=$folded)', () {
          final l = GraphLayout.compute(
            [for (var i = 0; i < 5; i++) note(i)],
            [reverse ? link(4, 2) : link(2, 4)],
            groups: [
              group('p'),
              group('c', parent: 'p'),
              group('d', parent: 'p', position: 1),
            ],
            memberships: {'0': 'p', '1': 'p', '2': 'p', '3': 'c', '4': 'd'},
            collapsedGroups: folded ? {'d'} : {},
            rtl: rtl,
          );
          expect(l.edges, hasLength(1));
          // The old folded direct curve ran through child c's only card.
          expect(l.edges.single.curves.length, greaterThan(1));
          expectClearGraphInk(l);
        });
      }
      test('routes clear overflow cards and other frames (rtl=$rtl reverse=$reverse)', () {
        final l = GraphLayout.compute(
          [for (var i = 0; i < 80; i++) note(i)],
          [for (var i = 0; i < 10; i++) reverse ? link(79, i) : link(i, 79)],
          groups: [
            group('p'),
            group('c', parent: 'p'),
            group('d', parent: 'p', position: 1),
          ],
          memberships: {for (var i = 0; i < 50; i++) '$i': i < 12 ? 'p' : 'c', '79': 'd'},
          collapsedGroups: {'d'},
          maxNodes: 15,
          rtl: rtl,
        );
        expect(l.rows.any((r) => r.hiddenCount > 0), isTrue);
        expect(l.edges, isNotEmpty);
        expectClearGraphInk(l);
      });
    }
  }

  test('pending link resolves a replacement reverse pair, preferring its user row', () {
    final ns = [note(0), note(1)];
    final old = link(0, 1, label: 'find me');
    final result = GraphSearchIndex(GraphInput(ns, [old])).search('find me').single;
    final suggestion = (id: 'new-ai', sourceId: '0', targetId: '1', label: '', strength: 1.0, isUser: false);
    final user = (id: 'new-user', sourceId: '1', targetId: '0', label: 'kept', strength: 0.1, isUser: true);
    expect(resolveGraphSearchLink(GraphInput(ns, [suggestion, user]), result), user);
    expect(resolveGraphSearchLink(GraphInput(ns, []), result), isNull);
  });
}
