import '../../l10n/localizations.dart';

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/product_runtime.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/product/models.dart';
import 'product_widgets.dart';

class ProductGraphScreen extends ConsumerStatefulWidget {
  const ProductGraphScreen({super.key});
  @override
  ConsumerState<ProductGraphScreen> createState() => _ProductGraphScreenState();
}

class _ProductGraphScreenState extends ConsumerState<ProductGraphScreen> {
  ProductRuntime? _runtime;
  String? _project;
  int _revision = -1;
  @override
  void initState() {
    super.initState();
    _runtime = ref.read(productRuntimeProvider);
    _runtime!.workspace.addListener(_changed);
    _changed();
  }

  void _changed() {
    final id = _runtime!.workspace.selectedProjectId;
    if (_project == id && _revision == _runtime!.workspace.knowledgeRevision) return;
    _project = id;
    _revision = _runtime!.workspace.knowledgeRevision;
    scheduleMicrotask(() {
      if (mounted) _runtime!.workspace.loadGraph();
    });
  }

  @override
  void dispose() {
    _runtime?.workspace.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ProductView(
    builder: (context, r) => ProductScaffold(
      title: context.l10n.uiIdeaMap,
      subtitle: r.workspace.projects.any((p) => !p.isGeneral)
          ? context.l10n.uxProjectContext(r.workspace.selected?.name ?? '')
          : null,
      trailing: IconButton(
        tooltip: context.l10n.productReloadMap,
        onPressed: r.workspace.graphLoading ? null : r.workspace.loadGraph,
        icon: const Icon(Icons.refresh),
      ),
      children: [
        if (r.workspace.failure != null) ProductFailureView(r.workspace.failure!, onRetry: r.workspace.retryWorkspace),
        Text(context.l10n.uiMapHint, style: context.text.caption),
        const SizedBox(height: 12),
        if (r.workspace.graphLoading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (r.workspace.graphFailure != null)
          ProductFailureView(r.workspace.graphFailure!, onRetry: r.workspace.loadGraph),
        if (!r.workspace.graphLoading && r.workspace.graph.nodes.isEmpty && r.workspace.graphFailure == null)
          Padding(padding: const EdgeInsets.all(24), child: Text(context.l10n.productNoCompletedNotesInThisProjectYet)),
        if (r.workspace.graph.nodes.isNotEmpty)
          SizedBox(
            height: 420,
            child: ProductNoteGraph(key: ValueKey(r.workspace.selectedProjectId), graph: r.workspace.graph),
          ),
      ],
    ),
  );
}

/// Geometry and gestures are local presentation. It never creates an edge.
class ProductNoteGraph extends StatefulWidget {
  const ProductNoteGraph({super.key, required this.graph});
  final KnowledgeGraph graph;
  @override
  State<ProductNoteGraph> createState() => _ProductNoteGraphState();
}

class _ProductNoteGraphState extends State<ProductNoteGraph> {
  final _transform = TransformationController();
  final _positions = <String, Offset>{};
  Size _viewport = Size.zero;
  String? _selected;
  Size _nodeSize = const Size(130, 90);

  void _zoom(double factor) {
    final old = _transform.value;
    final scale = old.getMaxScaleOnAxis();
    final next = (scale * factor).clamp(.4, 3.0);
    final ratio = next / scale;
    final center = _viewport.center(Offset.zero);
    final t = old.getTranslation();
    _transform.value = Matrix4.identity()
      ..translateByDouble(center.dx + (t.x - center.dx) * ratio, center.dy + (t.y - center.dy) * ratio, 0, 1)
      ..scaleByDouble(next, next, 1, 1);
  }

  void _fit() {
    if (_viewport.isEmpty || _positions.isEmpty) return;
    var bounds = _positions.values.first & _nodeSize;
    for (final p in _positions.values.skip(1)) {
      bounds = bounds.expandToInclude(p & _nodeSize);
    }
    final scale = math
        .min((_viewport.width - 40) / bounds.width, (_viewport.height - 70) / bounds.height)
        .clamp(.4, 1.6);
    _transform.value = Matrix4.identity()
      ..translateByDouble(
        _viewport.width / 2 - bounds.center.dx * scale,
        _viewport.height / 2 - bounds.center.dy * scale,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _nodeSize = Size(130, math.max(90, 44 + MediaQuery.textScalerOf(context).scale(12.5) * 3));
    final ids = widget.graph.nodes.map((n) => n.id).toSet();
    _positions.removeWhere((id, _) => !ids.contains(id));
    final cols = math.max(2, math.sqrt(ids.length).ceil());
    for (final (i, n) in widget.graph.nodes.indexed) {
      _positions.putIfAbsent(n.id, () => Offset(70 + (i % cols) * 180, 80 + (i ~/ cols) * 150));
    }
    final selected = widget.graph.nodes.where((n) => n.id == _selected).firstOrNull;
    final connected = widget.graph.edges
        .where((e) => e.source == _selected || e.target == _selected)
        .map((e) => e.source == _selected ? e.target : e.source)
        .toSet();
    final width = math.max(600.0, cols * 210.0);
    final height = math.max(500.0, (ids.length / cols).ceil() * 180.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        if (_viewport != size) {
          _viewport = size;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _fit();
          });
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.surface,
              border: Border.all(color: context.colors.line),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    transformationController: _transform,
                    constrained: false,
                    minScale: .4,
                    maxScale: 3,
                    boundaryMargin: const EdgeInsets.all(240),
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _RelationshipPainter(
                                widget.graph.edges,
                                Map.of(_positions),
                                context.colors.textSecondary,
                              ),
                            ),
                          ),
                          for (final note in widget.graph.nodes)
                            Positioned(
                              left: _positions[note.id]!.dx,
                              top: _positions[note.id]!.dy,
                              child: GestureDetector(
                                onPanUpdate: (event) => setState(() {
                                  final next =
                                      _positions[note.id]! + event.delta / _transform.value.getMaxScaleOnAxis();
                                  _positions[note.id] = Offset(
                                    next.dx.clamp(0, width - _nodeSize.width),
                                    next.dy.clamp(0, height - _nodeSize.height),
                                  );
                                }),
                                child: Semantics(
                                  button: true,
                                  onTap: () => setState(() => _selected = note.id),
                                  selected: _selected == note.id,
                                  label: productTitle(context, note.title),
                                  excludeSemantics: true,
                                  child: InkWell(
                                    key: ValueKey('graph-node-${note.id}'),
                                    onTap: () => setState(() => _selected = note.id),
                                    child: SizedBox(
                                      width: _nodeSize.width,
                                      height: _nodeSize.height,
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 30,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: context.colors.brandBlue,
                                              border: Border.all(
                                                color: _selected == note.id
                                                    ? context.colors.brandLime
                                                    : context.colors.brandBlueFg,
                                                width: 3,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            productTitle(context, note.title),
                                            style: context.text.meta,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: 10,
                  end: 10,
                  child: Column(
                    children: [
                      IconButton.filledTonal(
                        tooltip: context.l10n.productZoomIn,
                        onPressed: () => _zoom(1.2),
                        icon: const Icon(Icons.add),
                      ),
                      IconButton.filledTonal(
                        tooltip: context.l10n.uiZoomOut,
                        onPressed: () => _zoom(1 / 1.2),
                        icon: const Icon(Icons.remove),
                      ),
                      IconButton.filledTonal(
                        tooltip: context.l10n.uiFitIdeas,
                        onPressed: _fit,
                        icon: const Icon(Icons.center_focus_strong),
                      ),
                    ],
                  ),
                ),
                PositionedDirectional(
                  start: 12,
                  top: 12,
                  child: IgnorePointer(
                    child: Text(
                      context.l10n.productGraphCounts(ids.length, widget.graph.edges.length),
                      style: context.text.meta,
                    ),
                  ),
                ),
                if (selected != null)
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: size.height * .55),
                      child: Material(
                        color: context.colors.canvas,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                          side: BorderSide(color: context.colors.line),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(productTitle(context, selected.title), style: context.text.cardTitle),
                                  ),
                                  IconButton(
                                    tooltip: context.l10n.productCloseComposer,
                                    onPressed: () => setState(() => _selected = null),
                                    icon: const Icon(Icons.close),
                                  ),
                                ],
                              ),
                              if (selected.concepts.isNotEmpty)
                                Text(selected.concepts.join(' · '), style: context.text.caption),
                              if (connected.isNotEmpty)
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    for (final n in widget.graph.nodes.where((n) => connected.contains(n.id)))
                                      ActionChip(
                                        label: Text(productTitle(context, n.title)),
                                        onPressed: () => setState(() => _selected = n.id),
                                      ),
                                  ],
                                ),
                              const SizedBox(height: 10),
                              FikraButton(
                                label: context.l10n.uiOpenNote,
                                growForText: true,
                                onPressed: () => context.push('/note/${selected.id}'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RelationshipPainter extends CustomPainter {
  _RelationshipPainter(this.edges, this.positions, this.color);
  final List<GraphRelationship> edges;
  final Map<String, Offset> positions;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: .4)
      ..strokeWidth = 1.5;
    for (final edge in edges) {
      final a = positions[edge.source], b = positions[edge.target];
      if (a != null && b != null) canvas.drawLine(a + const Offset(65, 15), b + const Offset(65, 15), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RelationshipPainter old) =>
      old.positions != positions || old.edges != edges || old.color != color;
}
