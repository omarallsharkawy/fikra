import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../l10n/localizations.dart';
import '../shared/note_groups.dart';
import '../shared/note_presentation.dart';
import 'map_index.dart';

typedef MapCacheKey = ({
  Object revision,
  MapLevel level,
  FikraPalette palette,
  TextStyle style,
  Locale locale,
  TextScaler scaler,
  bool rtl,
  double width,
  String? selected,
});

/// Owns all native pictures and paragraph layouts. No source or text work is
/// performed by paint(), hit testing, or the viewport's animation frames.
class MapPictureCache {
  MapCacheKey? key;
  ui.Picture? picture;
  final texts = <TextPainter>[];
  int builds = 0;
  bool matches(MapCacheKey next) => key == next;
  void invalidate() {
    picture?.dispose();
    picture = null;
    for (final text in texts) {
      text.dispose();
    }
    texts.clear();
    key = null;
  }

  void dispose() => invalidate();
}

class MapCanvas extends StatefulWidget {
  const MapCanvas({
    super.key,
    required this.index,
    required this.level,
    required this.ego,
    required this.selected,
    required this.onNode,
  });
  final MapIndex index;
  final MapLevel level;
  final bool ego;
  final String? selected;
  final ValueChanged<MapNode> onNode;

  @override
  State<MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<MapCanvas> {
  final _transform = TransformationController();
  final _cache = MapPictureCache();
  Object? _fit;
  Size _viewport = Size.zero;
  Object? _geometryKey;
  MapLayout? _layout;

  @override
  void dispose() {
    _transform.dispose();
    _cache.dispose();
    super.dispose();
  }

  String _title(MapNode node) {
    final l10n = context.l10n;
    return switch (node.kind) {
      MapNodeKind.cluster => widget.index.clusters.firstWhere((c) => c.id == node.id).name ?? l10n.mapOthers,
      MapNodeKind.more => '${l10n.mapShowMore} +${node.count}',
      _ => noteTitleText(context, widget.index.notes[node.id]?.title ?? ''),
    };
  }

  void _zoom(double factor) {
    final scale = _transform.value.getMaxScaleOnAxis();
    final next = (scale * factor).clamp(.25, 2.5);
    final anchor = _transform.toScene(_viewport.center(Offset.zero));
    _transform.value = Matrix4.identity()
      ..translateByDouble(_viewport.width / 2 - anchor.dx * next, _viewport.height / 2 - anchor.dy * next, 0, 1)
      ..scaleByDouble(next, next, next, 1);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final rtl = Directionality.of(context) == TextDirection.rtl;
      final scaler = MediaQuery.textScalerOf(context);
      final geometryKey = (widget.level, widget.ego, constraints.maxWidth, scaler.scale(1), rtl);
      if (_geometryKey != geometryKey) {
        _geometryKey = geometryKey;
        _layout = MapLayout.build(
          widget.level,
          ego: widget.ego,
          width: constraints.maxWidth,
          textScale: scaler.scale(1),
          rtl: rtl,
        );
      }
      final layout = _layout!;
      _viewport = Size(constraints.maxWidth, math.max(0, constraints.maxHeight - 48));
      final fit = (widget.ego, widget.level, constraints.biggest, rtl);
      if (_fit != fit) {
        _fit = fit;
        // Preserve native text and touch sizes. The neighborhood is a world
        // to pan through, rather than shrinking large text to fit the screen.
        const scale = 1.0;
        _transform.value = Matrix4.identity()
          ..translateByDouble(
            (constraints.maxWidth - layout.width * scale) / 2,
            widget.ego ? (_viewport.height - layout.height * scale) / 2 : 0,
            0,
            1,
          )
          ..scaleByDouble(scale, scale, scale, 1);
      }
      final key = (
        revision: widget.index as Object,
        level: widget.level,
        palette: context.colors,
        style: context.text.meta,
        locale: Localizations.localeOf(context),
        scaler: scaler,
        rtl: rtl,
        width: constraints.maxWidth,
        selected: widget.selected,
      );
      if (!_cache.matches(key)) {
        _cache.invalidate();
        _cache.key = key;
        _cache.builds++;
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        final paint = Paint()..style = PaintingStyle.stroke;
        for (final edge in widget.level.edges) {
          final a = layout.positions[edge.a], b = layout.positions[edge.b];
          if (a == null || b == null) continue;
          final from = Offset(a.x, a.y), to = Offset(b.x, b.y);
          paint
            ..color = edge.suggested ? context.colors.textSecondary.withValues(alpha: .45) : context.colors.borderGraph
            ..strokeWidth = edge.suggested ? 1.2 : 1.5 + math.log(edge.count) * 1.4;
          if (edge.suggested) {
            final vector = to - from;
            final distance = vector.distance;
            final unit = vector / distance;
            // Four suggestions maximum, short straight dashes; no path metrics.
            for (double d = 0; d < distance; d += 14) {
              canvas.drawLine(from + unit * d, from + unit * math.min(d + 7, distance), paint);
            }
          } else {
            canvas.drawLine(from, to, paint);
          }
        }
        for (final node in widget.level.nodes) {
          final p = layout.positions[node.id]!;
          final rect = Rect.fromCenter(center: Offset(p.x, p.y), width: layout.nodeWidth, height: layout.nodeHeight);
          final selected = node.id == widget.selected;
          final cluster = node.kind == MapNodeKind.cluster
              ? widget.index.clusters.firstWhere((c) => c.id == node.id)
              : null;
          final hue = groupColor(context, cluster?.color) ?? context.colors.borderGraph;
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(24)),
            Paint()..color = selected ? context.colors.selected : context.colors.surface,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(24)),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = selected ? 2 : 1.5
              ..color = selected ? context.colors.accent : hue,
          );
          final title = TextPainter(
            text: TextSpan(
              text: _title(node),
              style: context.text.meta.copyWith(
                color: selected ? context.colors.accent : context.colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
            textScaler: scaler,
            locale: key.locale,
            maxLines: 1,
            ellipsis: '…',
          )..layout(maxWidth: rect.width - 20);
          final count = TextPainter(
            text: TextSpan(
              text: (node.kind == MapNodeKind.cluster || node.kind == MapNodeKind.more)
                  ? context.l10n.mapNotes(node.count)
                  : context.l10n.mapConnections(node.count),
              style: context.text.meta.copyWith(color: context.colors.textSecondary),
            ),
            textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
            textScaler: scaler,
            locale: key.locale,
            maxLines: 1,
            ellipsis: '…',
          )..layout(maxWidth: rect.width - 20);
          _cache.texts.addAll([title, count]);
          final top = rect.center.dy - (title.height + count.height + 4) / 2;
          title.paint(canvas, Offset(rect.center.dx - title.width / 2, top));
          count.paint(canvas, Offset(rect.center.dx - count.width / 2, top + title.height + 4));
        }
        _cache.picture = recorder.endRecording();
      }
      return Column(
        children: [
          Expanded(
            child: ClipRect(
              child: ColoredBox(
                color: context.colors.canvas,
                child: Semantics(
                  label: context.l10n.mapCanvasSummary(widget.level.total, widget.level.omitted),
                  container: true,
                  hint: context.l10n.mapPanHint,
                  child: InteractiveViewer(
                    key: const ValueKey('map-viewport'),
                    transformationController: _transform,
                    constrained: false,
                    boundaryMargin: const EdgeInsets.all(400),
                    minScale: .25,
                    maxScale: 2.5,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) {
                        // Gesture coordinates are already transformed into the child world.
                        for (final node in widget.level.nodes) {
                          final p = layout.positions[node.id]!;
                          if (Rect.fromCenter(
                            center: Offset(p.x, p.y),
                            width: layout.nodeWidth,
                            height: layout.nodeHeight,
                          ).contains(details.localPosition)) {
                            widget.onNode(node);
                            break;
                          }
                        }
                      },
                      child: RepaintBoundary(
                        child: CustomPaint(
                          key: const ValueKey('map-paint'),
                          size: Size(layout.width, layout.height),
                          painter: LinksMapPainter(
                            picture: _cache.picture!,
                            layout: layout,
                            nodes: widget.level.nodes,
                            labels: [
                              for (final n in widget.level.nodes)
                                '${_title(n)}, ${context.l10n.mapConnections(n.kind == MapNodeKind.cluster ? widget.index.edges.where((e) => e.a == n.id || e.b == n.id).fold(0, (v, e) => v + e.count) : n.count)}',
                            ],
                            rtl: rtl,
                            onNode: widget.onNode,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Solid controls occupy layout space, never cover the edges.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FikraIconButton(
                key: const ValueKey('map-zoom-out'),
                size: 48,
                label: context.l10n.zoomOut,
                onTap: () => _zoom(1 / 1.25),
                icon: Icons.remove_rounded,
              ),
              FikraIconButton(
                key: const ValueKey('map-zoom-in'),
                size: 48,
                label: context.l10n.zoomIn,
                onTap: () => _zoom(1.25),
                icon: Icons.add_rounded,
              ),
            ],
          ),
        ],
      );
    },
  );
}

/// ONE painter records nodes, labels and edges; semantics adds no node widgets.
class LinksMapPainter extends CustomPainter {
  LinksMapPainter({
    required this.picture,
    required this.layout,
    required this.nodes,
    required this.labels,
    required this.rtl,
    required this.onNode,
  });
  final ui.Picture picture;
  final MapLayout layout;
  final List<MapNode> nodes;
  final List<String> labels;
  final bool rtl;
  final ValueChanged<MapNode> onNode;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawPicture(picture);
  @override
  bool shouldRepaint(LinksMapPainter oldDelegate) => oldDelegate.picture != picture;
  @override
  bool shouldRebuildSemantics(LinksMapPainter oldDelegate) => oldDelegate.picture != picture;
  @override
  SemanticsBuilderCallback get semanticsBuilder =>
      (_) => [
        for (final (i, node) in nodes.indexed)
          CustomPainterSemantics(
            key: ValueKey('map-node-${node.id}'),
            rect: Rect.fromCenter(
              center: Offset(layout.positions[node.id]!.x, layout.positions[node.id]!.y),
              width: layout.nodeWidth,
              height: layout.nodeHeight,
            ),
            properties: SemanticsProperties(
              label: labels[i],
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
              button: true,
              focused: false,
              sortKey: OrdinalSortKey(i.toDouble()),
              onTap: () => onNode(node),
            ),
          ),
      ];
}
