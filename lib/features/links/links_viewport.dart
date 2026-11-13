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

  Map<CustomSemanticsAction, VoidCallback> _linkSemantics(GraphLayout layout, String noteId) {
    final incident = layout.links.where((e) => e.sourceId == noteId || e.targetId == noteId).toList();
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
      if (layout.hiddenRows.isNotEmpty) _rect(layout.positionInRow(layout.rows.length, 0)),
      for (final row in layout.rows)
        (() {
          final size = textSize(row.cluster, context.text.chip, math.min(320, layout.width - 2 * GraphLayout.padding));
          return Rect.fromLTWH(
            layout.rtl ? layout.width - GraphLayout.padding - size.width : GraphLayout.padding,
            GraphLayout.padding + row.index * GraphLayout.rowHeight,
            size.width,
            size.height,
          );
        })(),
    ];
    return layoutGraphCapsules(
      layout,
      _selected,
      obstacles: obstacles,
      measure: (label, width) {
        final size = textSize(label, context.text.meta.copyWith(color: context.colors.textLink), width - 18);
        return Size(size.width + 18, size.height + 8);
      },
    );
  }

  /// The pannable, zoomable canvas: edges, row labels, nodes and overflow
  /// nodes, fitted to the viewport once per project, canvas and viewport width.
  Widget _graphCanvas(GraphLayout layout, double width, double height) {
    final paths = _edgePaths!;
    final focus = paths.focus(_selected);
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
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTapUp: (details) {
                final p = details.localPosition;
                final edge = hitTestGraphEdge(layout, (x: p.dx, y: p.dy), scale: _tc.value.entry(0, 0).abs());
                if (edge != null) {
                  _openLink(edge.link);
                } else {
                  _setState(() => _selected = null);
                }
              },
              child: SizedBox(
                width: width,
                height: height,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: RepaintBoundary(
                        key: const ValueKey('graph-edges-layer'),
                        child: CustomPaint(
                          key: const ValueKey('graph-edges'),
                          painter: _EdgesPainter(
                            paths: paths,
                            selected: _selected,
                            accent: context.colors.accent,
                            suggestionColor: context.colors.graphEdge,
                          ),
                        ),
                      ),
                    ),
                    for (final row in layout.rows)
                      PositionedDirectional(
                        top: GraphLayout.padding + row.index * GraphLayout.rowHeight,
                        start: GraphLayout.padding,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: math.min(320, width - 2 * GraphLayout.padding)),
                          child: Text(
                            row.cluster,
                            key: ValueKey('graph-cluster-${row.index}'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.chip.copyWith(
                              color: _selected == null ? context.colors.textSecondary : _mutedGraphText(context),
                            ),
                          ),
                        ),
                      ),
                    for (final n in layout.nodes.values)
                      Positioned.fromRect(
                        rect: _rect(layout.positions[n.id]!),
                        child: KeyedSubtree(
                          key: ValueKey('graph-focus-${n.id}'),
                          child: Semantics(
                            customSemanticsActions: n.id == _selected ? _linkSemantics(layout, n.id) : null,
                            child: _Node(
                              key: ValueKey(n.id),
                              note: n,
                              selected: n.id == _selected,
                              dimmed: _selected != null && !focus.contains(n.id),
                              onTap: () => _setState(() => _selected = n.id == _selected ? null : n.id),
                            ),
                          ),
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
                            dimmed: _selected != null,
                            onTap: () => _showCluster(row),
                          ),
                        ),
                    if (layout.hiddenRows.isNotEmpty)
                      Positioned.fromRect(
                        rect: _rect(layout.positionInRow(layout.rows.length, 0)),
                        child: _OverflowNode(
                          label: context.l10n.moreGroupsCount(layout.hiddenRows.length),
                          dimmed: _selected != null,
                          onTap: () => _showMoreClusters(layout),
                        ),
                      ),
                    for (final capsule in _capsules(layout))
                      Positioned.fromRect(
                        rect: capsule.rect,
                        child: _ReasonCapsule(
                          key: ValueKey('graph-reason-${capsule.edge.link.id}'),
                          label: capsule.edge.link.label,
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
