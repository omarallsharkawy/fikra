import 'package:fikra/features/workspace/force_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('force geometry is finite, deterministic and independent of input ordering', () {
    const ids = ['c', 'a', 'b', 'isolated'];
    const edges = [('a', 'b'), ('b', 'c'), ('missing', 'a')];
    final result = forceGraphLayout(const ForceLayoutInput(ids, edges));
    expect(result, forceGraphLayout(ForceLayoutInput(ids.reversed.toList(), edges.reversed.toList())));
    expect(result.keys.toSet(), ids.toSet());
    for (final p in result.values) {
      expect(p.dx, inInclusiveRange(40, 320));
      expect(p.dy, inInclusiveRange(40, 302));
    }
    expect((result['a']! - result['b']!).distance, lessThan((result['a']! - result['isolated']!).distance));
    expect(result.values.toSet(), hasLength(4));
  });
  test('empty and single-node graphs do not invent nodes or positions', () {
    expect(forceGraphLayout(const ForceLayoutInput([], [])), isEmpty);
    expect(forceGraphLayout(const ForceLayoutInput(['only'], [])), {'only': const Offset(180, 180)});
  });
  test('dragged nodes stay fixed while their real connected neighbors settle', () {
    const dragged = Offset(70, 80);
    final result = forceGraphLayout(
      const ForceLayoutInput(['a', 'b'], [('a', 'b')], previous: {'a': dragged}, fixed: {'a'}),
    );
    expect(result['a'], dragged);
    expect((result['b']! - dragged).distance, greaterThan(40));
  });
  test('large graph uses scalable local forces and retains every supplied node', () {
    final ids = List.generate(800, (i) => 'note-$i');
    final result = forceGraphLayout(ForceLayoutInput(ids, [for (var i = 1; i < ids.length; i++) (ids[i - 1], ids[i])]));
    expect(result, hasLength(ids.length));
    expect(result.values.every((p) => p.dx.isFinite && p.dy.isFinite), isTrue);
  });
}
