part of 'graph_layout.dart';

typedef GraphTextSize = ({double width, double height});

/// Measured text and controls are sendable, shared layout/routing/hit obstacles.
class GraphLabel {
  const GraphLabel(this.row, this.bounds, this.control);
  final GraphRow? row; // null is the Suggested topics title
  final GraphPosition bounds;
  final GraphPosition? control;
}

List<GraphLabel> _graphLabels(GraphLayout layout) {
  GraphPosition box(double start, double top, double width, double height) =>
      (left: layout.rtl ? layout.width - start - width : start, top: top, width: width, height: height);
  return [
    if (layout.suggestedTop != null)
      GraphLabel(
        null,
        box(GraphLayout.padding, layout.suggestedTop!, layout.suggestedSize.width, layout.suggestedSize.height),
        null,
      ),
    for (final row in layout.rows.where((r) => r.groupId == null && r.notes.isNotEmpty))
      (() {
        final size =
            layout.labelSizes[row.cluster] ?? (width: math.min(264.0, row.cluster.runes.length * 8.0), height: 20.0);
        final maxWidth = math.min(320.0, layout.width - 2 * row.start);
        final w = math.min(size.width, maxWidth - (row.canMakeGroup ? 56 : 0));
        // A 6 dp exit lane keeps the 48 dp target above the arc/port band.
        final top = row.labelTop - math.max(6, size.height / 2 - 4);
        return GraphLabel(
          row,
          box(row.start, top, w, size.height),
          row.canMakeGroup ? box(row.start + w + 8, top + (size.height - 48) / 2, 48, 48) : null,
        );
      })(),
  ];
}
