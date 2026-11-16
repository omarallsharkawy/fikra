part of 'links_screen.dart';

/// Viewport: initial view, zoom buttons and the interactive canvas.
extension _LinksViewport on _LinksScreenState {
  /// RTL canvas: start the view at its right edge, where each row begins.
  Matrix4 _home() => Matrix4.translationValues(
    Directionality.of(context) == TextDirection.rtl ? _viewportSize.width - _canvasW : 0,
    0,
    0,
  );

  void _zoom(double factor) {
    _travel.stop();
    if (_viewportSize.isEmpty) return;
    final m = _tc.value.clone();
    // Read the x scale: matrices from older builds or tests may leave z at 1,
    // which made getMaxScaleOnAxis report 1 and lifted the zoom-out floor.
    final current = _scaleOf(m);
    final s = (current * factor).clamp(_minScale, _maxScale) / current;
    final c = _viewportSize.center(Offset.zero);
    _tc.value = Matrix4.identity()
      ..translateByDouble(c.dx, c.dy, 0, 1)
      ..scaleByDouble(s, s, s, 1)
      ..translateByDouble(-c.dx, -c.dy, 0, 1)
      ..multiply(m);
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
        // Scaffold consumes the keyboard inset. Its resize can lay out this
        // builder without rebuilding LinksScreen; finish a waiting jump here.
        if (_pendingJump != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _finishJump();
          });
        }
        final key = '${ref.read(selectedProjectProvider)?.id}|${box.maxWidth}|${layout.rtl}';
        _canvasW = width;
        if (key != _fittedFor) {
          _fittedFor = key;
          _canvasW = width;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _tc.value = _home();
          });
        }
        return Listener(
          onPointerDown: (e) {
            _travel.stop();
            _pointers.add(e.pointer);
            if (_pointers.length > 1) _cancelHold?.call();
          },
          onPointerUp: (e) => _pointers.remove(e.pointer),
          onPointerCancel: (e) => _pointers.remove(e.pointer),
          child: InteractiveViewer(
            transformationController: _tc,
            onInteractionStart: (_) => _cancelHold?.call(),
            constrained: false,
            minScale: _minScale,
            maxScale: _maxScale,
            boundaryMargin: const EdgeInsets.all(200),
            // Panning/zooming only moves this layer: the nodes and
            // edges are painted once, not on every frame.
            child: RepaintBoundary(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                onTapUp: (details) {
                  if (_selection != null) return;
                  final p = details.localPosition;
                  if (layout.obstacles.any((r) => _rect(r).contains(p))) return;
                  final edge = hitTestGraphEdge(layout, (x: p.dx, y: p.dy), scale: _scaleOf(_tc.value));
                  if (edge != null) {
                    _openLink(edge.link);
                  } else {
                    _setState(() => _selected = null);
                  }
                },
                child: SizedBox(
                  width: width,
                  height: height,
                  child: Semantics(
                    container: true,
                    explicitChildNodes: true,
                    child: Stack(
                      children: [
                        for (final frame in layout.frames)
                          Positioned.fromRect(rect: _rect(frame.bounds), child: _frame(layout, frame, focus)),
                        Positioned.fill(
                          child: RepaintBoundary(
                            key: const ValueKey('graph-edges-layer'),
                            child: IgnorePointer(
                              child: _CapResolution(
                                controller: _tc,
                                builder: (capDivisions) => CustomPaint(
                                  key: const ValueKey('graph-edges'),
                                  painter: _EdgesPainter(
                                    paths: paths,
                                    selected: _selected,
                                    accent: context.colors.accent,
                                    suggestionColor: context.colors.graphEdge,
                                    capDivisions: capDivisions,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        for (final label in layout.labels) ...[
                          Positioned.fromRect(
                            rect: _rect(label.bounds),
                            child: Semantics(
                              container: true,
                              sortKey: _graphSort(layout, label.bounds),
                              child: ColoredBox(
                                color: context.colors.canvas,
                                child: label.row == null
                                    ? Text(
                                        context.l10n.suggestedTopics,
                                        style: context.text.section,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    : _topicLabel(label.row!),
                              ),
                            ),
                          ),
                          if (label.control != null)
                            Positioned.fromRect(rect: _rect(label.control!), child: _topicControl(label.row!)),
                        ],
                        for (final n in layout.nodes.values) _positionedCard(layout, n, focus),
                        for (final row in layout.rows)
                          if (row.hiddenCount > 0)
                            Positioned.fromRect(
                              rect: _rect(layout.positionInRow(row.index, row.visible.length)),
                              child: _OverflowNode(
                                label: '+${row.hiddenCount}',
                                semanticLabel: context.l10n.showGroupA11y(
                                  Fmt.notes(context.l10n, row.hiddenCount),
                                  row.cluster,
                                ),
                                numbersOnly: true,
                                dimmed: _selected != null || _selection != null,
                                onTap: _selection == null ? () => _showCluster(row) : null,
                              ),
                            ),
                        if (layout.hiddenRows.isNotEmpty)
                          Positioned.fromRect(
                            rect: _rect(layout.morePosition),
                            child: _OverflowNode(
                              label: context.l10n.moreTopicsCount(layout.hiddenRows.length),
                              dimmed: _selected != null,
                              onTap: _selection == null ? () => _showMoreClusters(layout) : null,
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
            ),
          ),
        );
      },
    );
  }
}
