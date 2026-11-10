part of 'links_screen.dart';

/// Viewport: initial view, zoom buttons and the interactive canvas.
extension _LinksViewport on _LinksScreenState {
  /// RTL canvas: start the view at its right edge, where each row begins.
  Matrix4 _home() => Matrix4.translationValues(
    Directionality.of(context) == TextDirection.rtl ? math.min(0, _viewportSize.width - _canvasW) : 0,
    0,
    0,
  );

  void _zoom(double factor) {
    if (_viewportSize.isEmpty) return;
    final m = _tc.value.clone();
    final s = (m.getMaxScaleOnAxis() * factor).clamp(0.5, 2.5) / m.getMaxScaleOnAxis();
    final c = _viewportSize.center(Offset.zero);
    _tc.value = Matrix4.identity()
      ..translateByDouble(c.dx, c.dy, 0, 1)
      ..scaleByDouble(s, s, 1, 1)
      ..translateByDouble(-c.dx, -c.dy, 0, 1)
      ..multiply(m);
  }

  /// The pannable, zoomable canvas: edges, row labels, nodes and overflow
  /// nodes, fitted to the viewport once per project, canvas and viewport width.
  Widget _graphCanvas(GraphLayout layout, double width, double height) {
    return LayoutBuilder(
      builder: (context, box) {
        // Refresh height even when width (and the reading-start fit) is unchanged.
        _viewportSize = box.biggest;
        final key = '${ref.read(selectedProjectProvider)?.id}|$width|${box.maxWidth}|${layout.rtl}';
        if (key != _fittedFor) {
          _fittedFor = key;
          _canvasW = width;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _tc.value = _home();
          });
        }
        return InteractiveViewer(
          transformationController: _tc,
          constrained: false,
          minScale: 0.5,
          maxScale: 2.5,
          boundaryMargin: const EdgeInsets.all(200),
          // Panning/zooming only moves this layer: the nodes and
          // edges are painted once, not on every frame.
          child: RepaintBoundary(
            child: GestureDetector(
              onTap: () => _setState(() => _selected = null),
              child: SizedBox(
                width: width,
                height: height,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _EdgesPainter(
                          links: layout.links,
                          pos: layout.positions,
                          selected: _selected,
                          edgeColor: context.colors.graphEdge,
                          light: Theme.of(context).brightness == Brightness.light,
                        ),
                      ),
                    ),
                    for (final row in layout.rows)
                      PositionedDirectional(
                        top: GraphLayout.padding + row.index * GraphLayout.rowHeight,
                        start: GraphLayout.padding,
                        child: Text(
                          row.cluster,
                          style: context.text.chip.copyWith(color: context.colors.textSecondary),
                        ),
                      ),
                    for (final n in layout.nodes.values)
                      Positioned.fromRect(
                        rect: _rect(layout.positions[n.id]!),
                        child: _Node(
                          key: ValueKey(n.id),
                          note: n,
                          selected: n.id == _selected,
                          onTap: () => _setState(() => _selected = n.id == _selected ? null : n.id),
                        ),
                      ),
                    for (final row in layout.rows)
                      if (row.hiddenCount > 0)
                        Positioned.fromRect(
                          rect: _rect(layout.positionInRow(row.index, row.visible.length)),
                          child: _OverflowNode(
                            label: '+${row.hiddenCount}',
                            semanticLabel: context.l10n.showGroupA11y(
                              Fmt.notes(context.l10n, row.notes.length),
                              row.cluster,
                            ),
                            numbersOnly: true,
                            onTap: () => _showCluster(row),
                          ),
                        ),
                    if (layout.hiddenRows.isNotEmpty)
                      Positioned.fromRect(
                        rect: _rect(layout.positionInRow(layout.rows.length, 0)),
                        child: _OverflowNode(
                          label: context.l10n.moreGroupsCount(layout.hiddenRows.length),
                          onTap: () => _showMoreClusters(layout),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
