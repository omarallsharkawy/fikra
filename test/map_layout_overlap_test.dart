import 'package:fikra/features/connections/map_index.dart';
import 'package:flutter_test/flutter_test.dart';

MapLevel _ego(int outer) => MapLevel(
  nodes: [
    (id: 'centre', kind: MapNodeKind.note, count: outer),
    for (var i = 0; i < outer; i++) (id: 'n$i', kind: MapNodeKind.note, count: 1),
  ],
  edges: const [],
  total: outer + 1,
  omitted: 0,
  confirmed: outer,
  suggestions: 0,
);

bool _overlaps(MapLayout l, MapPosition a, MapPosition b) =>
    (a.x - b.x).abs() < l.nodeWidth && (a.y - b.y).abs() < l.nodeHeight;

void main() {
  for (final textScale in [1.0, 1.3]) {
    for (final outer in [1, 2, 3, 5, 8, 12]) {
      test('ego layout with $outer neighbours at ${textScale}x has no overlapping boxes', () {
        final layout = MapLayout.build(_ego(outer), ego: true, width: 360, textScale: textScale, rtl: true);
        final ids = layout.positions.keys.toList();
        expect(ids.length, outer + 1);
        for (var i = 0; i < ids.length; i++) {
          for (var j = i + 1; j < ids.length; j++) {
            expect(
              _overlaps(layout, layout.positions[ids[i]]!, layout.positions[ids[j]]!),
              isFalse,
              reason: '${ids[i]} overlaps ${ids[j]}',
            );
          }
        }
      });
    }
  }
}
