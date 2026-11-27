import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/redesign_tokens.dart';
import '../../core/widgets/redesign_widgets.dart';
import '../../data/product/models.dart';
import '../../l10n/localizations.dart';
import 'force_layout.dart';
import 'local_tags_controller.dart';

Color graphTagColor(BuildContext context, int? index) => switch (index) {
  0 => context.rd.purple,
  1 || 3 => context.rd.blue,
  2 => const Color(0xffe8913a),
  _ => context.rd.muted,
};

/// Forces determine geometry. Only repository nodes/edges become visible.
class ProductNoteGraph extends StatefulWidget {
  const ProductNoteGraph({super.key, required this.graph, this.categories = const {}, this.titles = const {}});
  final KnowledgeGraph graph;
  final Map<String, List<LocalTag>> categories;
  final Map<String, String> titles;
  @override
  State<ProductNoteGraph> createState() => _ProductNoteGraphState();
}

class _ProductNoteGraphState extends State<ProductNoteGraph> {
  Map<String, Offset> _positions = {};
  Set<String> _fixed = {};
  Size _viewport = Size.zero;
  String? _selected, _dragging;
  String _fingerprint = '';
  int _ticket = 0;
  bool _layingOut = true, _layoutFailed = false;
  double _scale = 1, _startScale = 1;
  double _gestureBase = 1;
  int _gesturePointers = 1;
  Offset? _pointerOrigin;
  String? _pressedNode;
  final _pointerPositions = <int, Offset>{};
  Offset _dragOffset = Offset.zero;
  Offset _translation = Offset.zero, _anchor = Offset.zero;
  String _title(KnowledgeGraphNode n) => widget.titles[n.id] ?? n.title ?? context.l10n.rdUntitled;
  Map<String, int> get _degree {
    final d = {for (final n in widget.graph.nodes) n.id: 0};
    for (final e in widget.graph.edges) {
      if (d.containsKey(e.source) && d.containsKey(e.target)) {
        d[e.source] = d[e.source]! + 1;
        d[e.target] = d[e.target]! + 1;
      }
    }
    return d;
  }

  @override
  void initState() {
    super.initState();
    _layout();
  }

  @override
  void didUpdateWidget(ProductNoteGraph old) {
    super.didUpdateWidget(old);
    _layout();
  }

  void _layout({bool dragged = false}) {
    final ids = widget.graph.nodes.map((n) => n.id).toList()..sort();
    final edges = widget.graph.edges.map((e) => (e.source, e.target)).toList();
    final sortedEdges = edges.map((e) => '${e.$1}:${e.$2}').toList()..sort();
    final fingerprint = '${ids.join(',')}|${sortedEdges.join(',')}';
    if (!dragged && _fingerprint == fingerprint) return;
    _fingerprint = fingerprint;
    _fixed = _fixed.intersection(ids.toSet());
    final input = ForceLayoutInput(ids, edges, previous: _positions, fixed: _fixed), ticket = ++_ticket;
    _layoutFailed = false;
    if (ids.length <= 80) {
      _positions = forceGraphLayout(input);
      _layingOut = false;
      if (!dragged) _fit();
    } else {
      _layingOut = true;
      unawaited(
        compute(forceGraphLayout, input)
            .then((result) {
              if (!mounted || ticket != _ticket) return;
              setState(() {
                _positions = result;
                _layingOut = false;
                if (!dragged) {
                  _fit();
                }
              });
            })
            .catchError((Object _) {
              if (mounted && ticket == _ticket) {
                setState(() {
                  _layingOut = false;
                  _layoutFailed = true;
                });
              }
            }),
      );
    }
    if (_selected != null && !ids.contains(_selected)) _selected = null;
  }

  void _fit() {
    if (_viewport.isEmpty || _positions.isEmpty) return;
    final degree = _degree;
    Rect extent(MapEntry<String, Offset> entry) {
      final p = entry.value, radius = (9 + (degree[entry.key] ?? 0) * 6).clamp(9, 45);
      return Rect.fromLTRB(p.dx - 65, p.dy - radius - 8, p.dx + 65, p.dy + radius + 28);
    }

    var bounds = extent(_positions.entries.first);
    for (final p in _positions.entries.skip(1)) {
      bounds = bounds.expandToInclude(extent(p));
    }
    _scale = math.min(_viewport.width / bounds.width, _viewport.height / bounds.height).clamp(.2, 1.15);
    _translation = _viewport.center(Offset.zero) - bounds.center * _scale;
  }

  Offset _screen(Offset p) => p * _scale + _translation;
  Offset _world(Offset p) => (p - _translation) / _scale;
  void _zoom(double factor) => setState(() {
    final world = _world(_viewport.center(Offset.zero));
    _scale = (_scale * factor).clamp(.2, 3);
    _translation = _viewport.center(Offset.zero) - world * _scale;
  });
  String? _hit(Offset point) {
    final candidates = _positions.entries.toList()
      ..sort(
        (a, b) => (_screen(a.value) - point).distanceSquared.compareTo((_screen(b.value) - point).distanceSquared),
      );
    final first = candidates.firstOrNull;
    if (first == null) return null;
    final radius = math.max(22.0, (9 + (_degree[first.key] ?? 0) * 6).clamp(9, 45) * _scale);
    return (_screen(first.value) - point).distance <= radius ? first.key : null;
  }

  Future<void> _controls() async => rdSheet<void>(
    context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        RdButton(context.l10n.productZoomIn, primary: false, onPressed: () => _zoom(1.2)),
        RdButton(context.l10n.uiZoomOut, primary: false, onPressed: () => _zoom(1 / 1.2)),
        RdButton(
          context.l10n.uiFitIdeas,
          onPressed: () {
            setState(_fit);
            Navigator.of(context, rootNavigator: true).pop();
          },
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final selected = widget.graph.nodes.where((n) => n.id == _selected).firstOrNull;
    final neighbors = widget.graph.edges
        .where((e) => e.source == _selected || e.target == _selected)
        .expand((e) => [e.source, e.target])
        .toSet();
    final degree = _degree;
    final tags = <String, LocalTag>{
      for (final values in widget.categories.values)
        for (final tag in values) tag.id: tag,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RdCard(
          padding: 6,
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: LayoutBuilder(
                  builder: (context, box) {
                    final size = Size(box.maxWidth, box.maxHeight);
                    if (_viewport != size) {
                      _viewport = size;
                      _fit();
                    }
                    return MediaQuery(
                      data: MediaQuery.of(context).copyWith(gestureSettings: const DeviceGestureSettings(touchSlop: 8)),
                      child: Semantics(
                        label: context.l10n.rdMap,
                        customSemanticsActions: {
                          CustomSemanticsAction(label: context.l10n.productZoomIn): () => _zoom(1.2),
                          CustomSemanticsAction(label: context.l10n.uiZoomOut): () => _zoom(1 / 1.2),
                          CustomSemanticsAction(label: context.l10n.uiFitIdeas): () => setState(_fit),
                        },
                        child: Listener(
                          onPointerDown: (event) {
                            _pointerPositions[event.pointer] = event.localPosition;
                            _pointerOrigin =
                                _pointerPositions.values.reduce((a, b) => a + b) / _pointerPositions.length.toDouble();
                            if (_pointerPositions.length == 1) {
                              _pressedNode = _hit(event.localPosition);
                            }
                          },
                          onPointerMove: (event) => _pointerPositions[event.pointer] = event.localPosition,
                          onPointerUp: (event) => _pointerPositions.remove(event.pointer),
                          onPointerCancel: (event) => _pointerPositions.remove(event.pointer),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            dragStartBehavior: DragStartBehavior.down,
                            onLongPress: _controls,
                            onScaleStart: (d) {
                              _startScale = _scale;
                              _gestureBase = 1;
                              _gesturePointers = d.pointerCount;
                              _anchor = _world(_pointerOrigin ?? d.localFocalPoint);
                              _dragging = d.pointerCount == 1 ? _pressedNode : null;
                              _dragOffset = _dragging == null ? Offset.zero : _positions[_dragging!]! - _anchor;
                            },
                            onScaleUpdate: (d) => setState(() {
                              if (_gesturePointers != d.pointerCount) {
                                _gesturePointers = d.pointerCount;
                                _gestureBase = d.scale;
                                _startScale = _scale;
                                _anchor = _world(d.localFocalPoint);
                                _dragging = null;
                              }
                              if (_dragging != null && d.pointerCount == 1) {
                                _positions[_dragging!] = _world(d.localFocalPoint) + _dragOffset;
                              } else {
                                _dragging = null;
                                _scale = (_startScale * d.scale / _gestureBase).clamp(.2, 3);
                                _translation = d.localFocalPoint - _anchor * _scale;
                              }
                            }),
                            onScaleEnd: (_) {
                              if (_dragging != null) {
                                _fixed.add(_dragging!);
                                setState(() => _layout(dragged: true));
                                _dragging = null;
                              }
                            },
                            child: ClipRect(
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _EdgesPainter(
                                        widget.graph.edges,
                                        {for (final e in _positions.entries) e.key: _screen(e.value)},
                                        context.rd.line,
                                        _selected,
                                      ),
                                    ),
                                  ),
                                  if (_layingOut) const Center(child: CircularProgressIndicator()),
                                  if (_layoutFailed)
                                    Center(
                                      child: RdButton(
                                        context.l10n.retry,
                                        onPressed: () => setState(() {
                                          _fingerprint = '';
                                          _layout();
                                        }),
                                      ),
                                    ),
                                  for (final note in widget.graph.nodes)
                                    if (_positions[note.id] != null)
                                      _node(
                                        note,
                                        degree[note.id] ?? 0,
                                        _selected != null && note.id != _selected && !neighbors.contains(note.id),
                                      ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        if (tags.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(top: 2, bottom: 12),
            child: Row(spacing: 6, children: [for (final tag in tags.values) _Legend(tag)]),
          ),
        if (selected != null)
          RdCard(
            child: Row(
              spacing: 8,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 6,
                    children: [
                      RdText(_title(selected), weight: FontWeight.w600),
                      if (widget.categories[selected.id]?.isNotEmpty ?? false)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [for (final tag in widget.categories[selected.id]!) RdChip(tag.label, small: true)],
                        ),
                    ],
                  ),
                ),
                RdButton(context.l10n.rdOpen, full: false, onPressed: () => context.push('/note/${selected.id}')),
              ],
            ),
          ),
      ],
    );
  }

  Widget _node(KnowledgeGraphNode note, int degree, bool dimmed) {
    final point = _screen(_positions[note.id]!), radius = (9 + degree * 6).clamp(9, 45) * _scale;
    final target = math.max(44.0, radius * 2), title = _title(note), chars = _title(note).characters;
    final label = chars.length > 16 ? '${chars.take(15)}…' : title;
    return Positioned(
      left: point.dx - target / 2,
      top: point.dy - target / 2,
      width: target,
      height: target,
      child: Semantics(
        label: title,
        button: true,
        selected: _selected == note.id,
        onTap: () => setState(() => _selected = _selected == note.id ? null : note.id),
        excludeSemantics: true,
        child: GestureDetector(
          key: ValueKey('graph-node-${note.id}'),
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _selected = _selected == note.id ? null : note.id),
          onPanUpdate: (event) => setState(() {
            _positions[note.id] = _positions[note.id]! + event.delta / _scale;
          }),
          onPanEnd: (_) {
            _fixed.add(note.id);
            setState(() => _layout(dragged: true));
          },
          child: AnimatedOpacity(
            duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 200),
            opacity: dimmed
                ? .25
                : degree == 0
                ? .6
                : 1,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Container(
                    width: radius * 2,
                    height: radius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: graphTagColor(context, widget.categories[note.id]?.firstOrNull?.color),
                      border: _selected == note.id ? Border.all(color: context.rd.lime, width: 3) : null,
                    ),
                  ),
                ),
                Positioned(
                  top: target / 2 + radius + 3 * _scale,
                  left: target / 2 - 65 * _scale,
                  width: 130 * _scale,
                  child: IgnorePointer(
                    child: RdText(label, size: 11 * _scale, height: 1.6, lines: 1, align: TextAlign.center),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.tag);
  final LocalTag tag;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 24),
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: context.rd.surface2,
      border: Border.all(color: context.rd.line),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: graphTagColor(context, tag.color)),
        ),
        RdText(tag.label, size: 12),
      ],
    ),
  );
}

class _EdgesPainter extends CustomPainter {
  _EdgesPainter(this.edges, this.positions, this.color, this.selected);
  final List<GraphRelationship> edges;
  final Map<String, Offset> positions;
  final Color color;
  final String? selected;
  @override
  void paint(Canvas canvas, Size size) {
    for (final e in edges) {
      final a = positions[e.source], b = positions[e.target];
      if (a == null || b == null) continue;
      canvas.drawLine(
        a,
        b,
        Paint()
          ..strokeWidth = 1.5
          ..color = color.withValues(alpha: selected != null && e.source != selected && e.target != selected ? .2 : 1),
      );
    }
  }

  @override
  bool shouldRepaint(_EdgesPainter old) =>
      old.positions != positions || old.edges != edges || old.color != color || old.selected != selected;
}
