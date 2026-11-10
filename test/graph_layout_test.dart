import 'package:fikra/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:fikra/features/links/graph_layout.dart';
import 'package:flutter/foundation.dart' as flutter;
import 'package:flutter_test/flutter_test.dart';

GraphNote note(int id, {String? cluster = 'cluster', int status = 1, String? title, int? createdAt}) =>
    (id: '$id', title: title ?? 'note $id', cluster: cluster, createdAt: createdAt ?? id, status: status);

GraphLink link(int source, int target, {double strength = 0.5, String label = 'related'}) =>
    (sourceId: '$source', targetId: '$target', label: label, strength: strength);

void main() {
  test('caps rows and nodes, accounts for every overflow note and cluster', () {
    final notes = [for (var i = 0; i < 1000; i++) note(i, cluster: 'cluster ${i ~/ 40}')];
    final layout = GraphLayout.compute(notes, []);
    expect(layout.rows, hasLength(20));
    expect(layout.hiddenRows, hasLength(5));
    expect(layout.nodes, hasLength(240));
    expect(layout.rows.every((r) => r.visible.length == 12 && r.hiddenCount == 28), isTrue);
    expect(layout.hiddenRows.every((r) => r.visible.isEmpty && r.hiddenCount == 40), isTrue);
    final accounted =
        layout.nodes.length +
        layout.rows.fold(0, (sum, row) => sum + row.hiddenCount) +
        layout.hiddenRows.fold(0, (sum, row) => sum + row.notes.length);
    expect(accounted, notes.length);
    expect(layout.width, 2236); // 12 nodes + overflow chip, with original gaps.
    expect(layout.height, 2820); // 20 rows + more-clusters affordance.
  });

  test('LTR graph mirrors the same geometry and memo input includes locale', () {
    final notes = [note(0), note(1)];
    final rtl = GraphLayout.compute(notes, []);
    final ltr = GraphLayout.compute(notes, [], rtl: false);
    for (final note in notes) {
      final a = rtl.positions[note.id]!;
      final b = ltr.positions[note.id]!;
      expect(b.left, rtl.width - a.left - a.width);
      expect(b.top, a.top);
    }
    expect(GraphInput(notes, []).sameData(GraphInput(notes, [], rtl: false)), isFalse);
    expect(GraphInput(notes, [], generalLabel: 'a').sameData(GraphInput(notes, [], generalLabel: 'b')), isFalse);
  });

  test('total cap also works when the final row has a partial node budget', () {
    final notes = [for (var i = 0; i < 100; i++) note(i, cluster: 'cluster ${i ~/ 20}')];
    final layout = GraphLayout.compute(notes, [], maxNodes: 17);
    expect(layout.nodes, hasLength(17));
    expect(layout.rows.map((r) => r.visible.length), [12, 5]);
    expect(layout.rows.map((r) => r.hiddenCount), [8, 15]);
    expect(layout.hiddenRows, hasLength(3));
  });

  test('ranks by degree, then newest; dangling and unready links do not rank', () {
    final notes = [for (var i = 0; i < 80; i++) note(i), note(80, status: 0), note(81, status: 2)];
    final layout = GraphLayout.compute(notes, [
      link(0, 1),
      link(2, 0),
      link(3, 4),
      link(5, 80),
      link(6, 999),
      link(7, 81),
    ]);
    expect(layout.rows.single.visible.map((n) => n.id).take(7), ['0', '4', '3', '2', '1', '79', '78']);
    expect(layout.readyCount, 80);
    expect(layout.nodes.containsKey('80'), isFalse);
    expect(layout.nodes.containsKey('81'), isFalse);
    expect(layout.rows.single.hiddenCount, 68);
  });

  test('rows start on the right and overflow follows the last visible note', () {
    final layout = GraphLayout.compute([for (var i = 0; i < 80; i++) note(i)], []);
    final visible = layout.rows.single.visible;
    final first = layout.positions[visible[0].id]!;
    final second = layout.positions[visible[1].id]!;
    expect(first.left + first.width, layout.width - GraphLayout.padding);
    expect(first.top, 58);
    expect(first.width, 148);
    expect(first.height, 54);
    expect(first.left - second.left, 170);
    final last = layout.positions[visible.last.id]!;
    final overflow = layout.positionInRow(0, visible.length);
    expect(last.left - overflow.left, 170);
    expect(overflow.left, GraphLayout.padding);
  });

  test('only links between visible notes are returned', () {
    final layout = GraphLayout.compute(
      [for (var i = 0; i < 100; i++) note(i)],
      [
        link(0, 1),
        link(1, 2),
        link(30, 31),
        link(50, 51),
        link(60, 61),
        link(70, 71),
        link(80, 81),
        link(90, 91),
        link(98, 99),
        link(200, 0),
      ],
    );
    expect(layout.links, isNotEmpty);
    expect(layout.links.length, lessThan(10));
    for (final edge in layout.links) {
      expect(layout.nodes.containsKey(edge.sourceId), isTrue);
      expect(layout.nodes.containsKey(edge.targetId), isTrue);
    }
  });

  test('dense large graphs bound painting work, retaining strongest edges', () {
    final layout = GraphLayout.compute(
      [for (var i = 0; i < 100; i++) note(i)],
      [for (var i = 0; i < 2000; i++) link(0, 1, strength: i / 2000)],
    );
    expect(layout.links, hasLength(1000));
    expect(layout.links.first.strength, 1999 / 2000);
    expect(layout.links.last.strength, 0.5);
  });

  test('small projects retain every node, edge, row, and chronological position', () {
    final notes = [for (var i = 59; i >= 0; i--) note(i)];
    final links = [for (var i = 0; i < 1100; i++) link(0, 59)];
    final layout = GraphLayout.compute(notes, links);
    expect(layout.nodes.keys, [for (var i = 0; i < 60; i++) '$i']);
    expect(layout.rows.single.hiddenCount, 0);
    expect(layout.links, links);
    expect(layout.width, 10226);
    expect(layout.height, 180);
    expect(layout.positions['0']!.left, 10054);
    expect(layout.positions['59']!.left, 24);
    final manyClusters = GraphLayout.compute([for (var i = 0; i < 60; i++) note(i, cluster: 'c$i')], []);
    expect(manyClusters.rows, hasLength(60));
    expect(manyClusters.hiddenRows, isEmpty);
  });

  test('empty, processing-only, and null clusters use original geometry/default', () {
    expect(GraphLayout.compute([], []).nodes, isEmpty);
    expect(GraphLayout.compute([note(1, status: 0)], []).readyCount, 0);
    final label = lookupAppLocalizations(const Locale('ar')).clusterGeneral;
    final layout = GraphLayout.compute([note(0, cluster: null), note(1, cluster: null)], [], generalLabel: label);
    expect(layout.rows.single.cluster, label);
    expect(layout.width, 366);
  });

  test('large projects remain capped while most notes are processing', () {
    final layout = GraphLayout.compute([for (var i = 0; i < 1000; i++) note(i, status: i < 60 ? 1 : 0)], []);
    expect(layout.readyCount, 60);
    expect(layout.nodes, hasLength(12));
    expect(layout.rows.single.hiddenCount, 48);
  });

  test('memo signature and equality are stable across copied/reordered input', () {
    final original = GraphInput([note(1), note(2)], [link(1, 2), link(2, 1)]);
    final copy = GraphInput([note(2), note(1)], [link(2, 1), link(1, 2)]);
    expect(original.signature, copy.signature);
    expect(original.sameData(copy), isTrue);
    // Preserve multiplicity, including duplicate endpoint pairs.
    expect(original.sameData(GraphInput([note(1), note(2)], [link(1, 2), link(1, 2)])), isFalse);
  });

  test('memo detects all layout and presentation changes', () {
    final original = GraphInput([note(1), note(2)], [link(1, 2)]);
    final changed = [
      GraphInput([note(3), note(2)], [link(1, 2)]),
      GraphInput([note(1, cluster: 'other'), note(2)], [link(1, 2)]),
      GraphInput([note(1, title: 'edited'), note(2)], [link(1, 2)]),
      GraphInput([note(1, status: 0), note(2)], [link(1, 2)]),
      GraphInput([note(1, createdAt: 100), note(2)], [link(1, 2)]),
      GraphInput([note(1), note(2)], [link(2, 1)]),
      GraphInput([note(1), note(2)], [link(1, 2, label: 'edited')]),
      GraphInput([note(1), note(2)], [link(1, 2, strength: 0.9)]),
      GraphInput([note(1)], []),
    ];
    for (final input in changed) {
      expect(input.signature, isNot(original.signature));
      expect(original.sameData(input), isFalse);
    }
  });

  test('10k notes / 20k links compute well under one second, including an isolate round trip', () async {
    final input = GraphInput(
      [for (var i = 0; i < 10000; i++) note(i, cluster: 'cluster ${i % 25}')],
      [for (var i = 0; i < 20000; i++) link(i % 10000, (i * 17 + 1) % 10000)],
    );
    final watch = Stopwatch()..start();
    final layout = GraphLayout.fromInput(input);
    watch.stop();
    final synchronousMs = watch.elapsedMilliseconds;
    // Includes cold/JIT execution; generous enough for a shared host, while
    // still catching accidental quadratic work (the original 17-second graph).
    expect(watch.elapsedMilliseconds, lessThan(750));
    expect(layout.nodes.length, lessThanOrEqualTo(240));
    watch.reset();
    watch.start();
    final isolated = await flutter.compute(GraphLayout.fromInput, input);
    watch.stop();
    expect(watch.elapsedMilliseconds, lessThan(750));
    expect(isolated.positions, layout.positions);
    // ignore: avoid_print
    print('10k/20k graph: sync $synchronousMs ms, isolate round trip ${watch.elapsedMilliseconds} ms');
  });
}
