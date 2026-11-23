import '../../l10n/localizations.dart';

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/product_runtime.dart';
import '../../core/theme/tokens.dart';
import '../../data/product/models.dart';
import 'product_widgets.dart';
import 'project_controls.dart';

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
      title: context.l10n.productKnowledgeMap,
      trailing: IconButton(
        tooltip: context.l10n.productReloadMap,
        onPressed: r.workspace.graphLoading ? null : r.workspace.loadGraph,
        icon: const Icon(Icons.refresh),
      ),
      children: [
        ProductProjectControls(runtime: r),
        Text(context.l10n.productEveryNodeIsANoteLinesShowSupplied),
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
  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cols = math.max(2, math.sqrt(widget.graph.nodes.length).ceil());
    for (final (i, n) in widget.graph.nodes.indexed) {
      _positions.putIfAbsent(n.id, () => Offset(30 + (i % cols) * 230, 40 + (i ~/ cols) * 150));
    }
    _positions.removeWhere((id, _) => !widget.graph.nodes.any((n) => n.id == id));
    final width = math.max(600.0, cols * 250.0),
        height = math.max(500.0, (widget.graph.nodes.length / cols).ceil() * 170.0);
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: context.l10n.productZoomIn,
              onPressed: () {
                _transform.value = _transform.value.clone()..scaleByDouble(1.2, 1.2, 1, 1);
              },
              icon: const Icon(Icons.add),
            ),
            IconButton(
              tooltip: context.l10n.productResetView,
              onPressed: () => _transform.value = Matrix4.identity(),
              icon: const Icon(Icons.center_focus_strong),
            ),
            Expanded(
              child: Text(
                context.l10n.productGraphCounts(widget.graph.nodes.length, widget.graph.edges.length),
                style: context.text.meta,
              ),
            ),
          ],
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: ColoredBox(
              color: context.colors.surface,
              child: InteractiveViewer(
                transformationController: _transform,
                constrained: false,
                minScale: .25,
                maxScale: 3,
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
                            context.colors.brandBlue,
                          ),
                        ),
                      ),
                      for (final note in widget.graph.nodes)
                        Positioned(
                          left: _positions[note.id]!.dx,
                          top: _positions[note.id]!.dy,
                          child: GestureDetector(
                            onPanUpdate: (event) => setState(() {
                              final next = _positions[note.id]! + event.delta;
                              _positions[note.id] = Offset(
                                next.dx.clamp(0, width - 190),
                                next.dy.clamp(0, height - 100),
                              );
                            }),
                            child: SizedBox(
                              width: 190,
                              child: Card(
                                child: ListTile(
                                  title: Text(
                                    productTitle(context, note.title),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    note.concepts.join(' · '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () => context.push('/note/${note.id}'),
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
          ),
        ),
      ],
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
      ..color = color.withValues(alpha: .5)
      ..strokeWidth = 2;
    for (final edge in edges) {
      final a = positions[edge.source], b = positions[edge.target];
      if (a != null && b != null) canvas.drawLine(a + const Offset(95, 45), b + const Offset(95, 45), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RelationshipPainter old) =>
      old.positions != positions || old.edges != edges || old.color != color;
}
