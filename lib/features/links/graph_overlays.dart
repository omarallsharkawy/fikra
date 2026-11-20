part of 'links_screen.dart';

extension _GraphOverlays on _LinksScreenState {
  Map<CustomSemanticsAction, VoidCallback> _linkSemantics(GraphLayout layout, String noteId) {
    final incident = layout.links
        .where((e) => !layout.isFoldedLink(e) && (e.sourceId == noteId || e.targetId == noteId))
        .toList();
    final labels = [
      for (final e in incident)
        context.l10n.linkOptionsA11y(
          _graphTitle(context, layout.nodes[e.sourceId == noteId ? e.targetId : e.sourceId]!),
        ),
    ];
    final counts = <String, int>{}, seen = <String, int>{};
    for (final label in labels) {
      counts.update(label, (n) => n + 1, ifAbsent: () => 1);
    }
    return {
      for (final (i, edge) in incident.indexed)
        // CustomSemanticsAction compares by label. Number repeated titles so
        // two untitled/identically named notes never collapse into one action.
        CustomSemanticsAction(
          label: counts[labels[i]] == 1
              ? labels[i]
              : '${labels[i]} (${seen.update(labels[i], (n) => n + 1, ifAbsent: () => 1)})',
        ): () {
          _openLink(edge);
        },
    };
  }

  List<GraphCapsule> _capsules(GraphLayout layout) {
    if (_selected == null) return const [];
    final direction = Directionality.of(context), scaler = MediaQuery.textScalerOf(context);
    Size textSize(String text, TextStyle style, double width) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: width);
      final size = painter.size;
      painter.dispose();
      return size;
    }

    final obstacles = <Rect>[
      for (final p in layout.positions.values) _rect(p),
      for (final row in layout.rows)
        if (row.hiddenCount > 0) _rect(layout.positionInRow(row.index, row.visible.length)),
      if (layout.hiddenRows.isNotEmpty) _rect(layout.morePosition),
      for (final p in layout.obstacles) _rect(p),
    ];
    return layoutGraphCapsules(
      layout,
      _selected,
      obstacles: obstacles,
      measure: (label, width) {
        final size = textSize(
          label,
          context.text.meta.copyWith(color: context.colors.accent, height: 1.25),
          width - 18,
        );
        return Size(size.width + 18, size.height + 8);
      },
    );
  }

  GraphTextSize _measureGraphText(String text, TextStyle style, double maxWidth) {
    final p = TextPainter(
      text: TextSpan(
        text: text,
        style: DefaultTextStyle.of(context).style
            .merge(style)
            .copyWith(fontWeight: MediaQuery.boldTextOf(context) ? FontWeight.bold : null),
      ),
      locale: Localizations.maybeLocaleOf(context),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    final size = (width: math.min(maxWidth, p.width.ceilToDouble() + 1), height: p.height.ceilToDouble() + 1);
    p.dispose();
    return size;
  }

  OrdinalSortKey _graphSort(GraphLayout l, GraphPosition p) {
    return OrdinalSortKey(p.top * (l.width + 1) + (l.rtl ? l.width - p.left - p.width : p.left));
  }
}
