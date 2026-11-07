import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../core/motion/pressable.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/local/database.dart';
import '../projects/project_header.dart';
import 'graph_layout.dart';

/// Knowledge graph: one row per cluster, notes as nodes, links as curves.
class LinksScreen extends ConsumerStatefulWidget {
  const LinksScreen({super.key});

  @override
  ConsumerState<LinksScreen> createState() => _LinksScreenState();
}

class _LinksScreenState extends ConsumerState<LinksScreen> {
  final _tc = TransformationController();
  String? _selected;
  String? _fittedFor;
  double _viewportW = 0;
  double _canvasW = 0;

  /// RTL canvas: start the view at its right edge, where each row begins.
  Matrix4 _home() => Matrix4.translationValues(math.min(0, _viewportW - _canvasW), 0, 0);

  List<Note>? _notesSource;
  List<NoteLink>? _linksSource;
  String? _projectId;
  GraphInput? _input;
  GraphInput? _pending;
  GraphLayout? _layout;
  bool _workerRunning = false;
  bool _layoutError = false;

  void _setProject(String? projectId) {
    if (_projectId != projectId) {
      _projectId = projectId;
      _notesSource = null;
      _linksSource = null;
      _input = null;
      _pending = null;
      _layout = null;
      _layoutError = false;
      _selected = null;
      _fittedFor = null;
    }
  }

  // Project only after a stream emission, not on selection/zoom/theme rebuilds.
  // Content-only writes produce the same projection and retain the layout.
  void _updateGraph(List<Note> notes, List<NoteLink> links) {
    final notesChanged = !identical(notes, _notesSource);
    final linksChanged = !identical(links, _linksSource);
    if (!notesChanged && !linksChanged) return;
    _notesSource = notes;
    _linksSource = links;
    final input = GraphInput(
      notesChanged
          ? [
              for (final n in notes)
                (
                  id: n.id,
                  title: n.title,
                  cluster: n.cluster,
                  createdAt: n.createdAt.microsecondsSinceEpoch,
                  status: n.status.index,
                ),
            ]
          : _input!.notes,
      linksChanged
          ? [for (final l in links) (sourceId: l.sourceId, targetId: l.targetId, label: l.label, strength: l.strength)]
          : _input!.links,
    );
    if (_input?.sameData(input) ?? false) return;
    _input = input;
    _layoutError = false;
    if (input.notes.length > 300 || (input.notes.length > GraphLayout.smallProjectLimit && input.links.length > 600)) {
      // An empty layout is not a useful placeholder for the first large graph.
      if ((_layout?.readyCount ?? 0) < 2) _layout = null;
      // One worker at a time; replace queued work with the latest emission.
      _pending = input;
      if (!_workerRunning) unawaited(_computePending());
    } else {
      _pending = null;
      _acceptLayout(GraphLayout.fromInput(input));
    }
  }

  void _acceptLayout(GraphLayout layout) {
    _layout = layout;
    if (!layout.nodes.containsKey(_selected)) _selected = null;
  }

  Future<void> _computePending() async {
    _workerRunning = true;
    try {
      while (_pending != null) {
        final input = _pending!;
        _pending = null;
        try {
          final layout = await compute(GraphLayout.fromInput, input, debugLabel: 'links-layout');
          if (!mounted) return;
          // Never install an obsolete layout, including after a project switch.
          if (identical(input, _input)) setState(() => _acceptLayout(layout));
        } catch (_) {
          if (!mounted) return;
          if (identical(input, _input)) setState(() => _layoutError = true);
        }
      }
    } finally {
      _workerRunning = false;
    }
  }

  /// Opens a note, handing over the full row when the graph still has it so
  /// the details screen draws it on its first frame.
  void _openNote(String id) {
    Note? full;
    for (final n in _notesSource ?? const <Note>[]) {
      if (n.id == id) {
        full = n;
        break;
      }
    }
    context.push('/note/$id', extra: full);
  }

  Future<void> _showCluster(GraphRow row) => showFikraSheet<void>(
    context,
    title: row.cluster,
    builder: (sheetContext) => SizedBox(
      height: MediaQuery.sizeOf(sheetContext).height * 0.55,
      child: ListView.builder(
        itemExtent: 64,
        itemCount: row.notes.length,
        itemBuilder: (context, index) {
          final note = row.notes[index];
          return ListTile(
            title: Text(_graphTitle(note), style: context.text.body, maxLines: 2, overflow: TextOverflow.ellipsis),
            onTap: () {
              Navigator.pop(sheetContext);
              _openNote(note.id);
            },
          );
        },
      ),
    ),
  );

  Future<void> _showMoreClusters(GraphLayout layout) async {
    final row = await showFikraSheet<GraphRow>(
      context,
      title: 'مجموعات أكتر',
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * 0.55,
        child: ListView.builder(
          itemExtent: 72,
          itemCount: layout.hiddenRows.length,
          itemBuilder: (context, index) {
            final row = layout.hiddenRows[index];
            return ListTile(
              title: Text(row.cluster, style: context.text.body, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(Fmt.notes(row.notes.length), style: context.text.meta),
              onTap: () => Navigator.pop(sheetContext, row),
            );
          },
        ),
      ),
    );
    if (mounted && row != null) await _showCluster(row);
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  void _zoom(double factor) {
    final m = _tc.value.clone();
    final s = (m.getMaxScaleOnAxis() * factor).clamp(0.5, 2.5) / m.getMaxScaleOnAxis();
    final size = context.size ?? const Size(400, 600);
    final c = Offset(size.width / 2, size.height / 2);
    _tc.value = Matrix4.identity()
      ..translateByDouble(c.dx, c.dy, 0, 1)
      ..scaleByDouble(s, s, 1, 1)
      ..translateByDouble(-c.dx, -c.dy, 0, 1)
      ..multiply(m);
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(selectedNotesProvider);
    final linksAsync = ref.watch(selectedLinksProvider);
    final notes = notesAsync.value ?? const <Note>[];
    final links = linksAsync.value ?? const <NoteLink>[];
    final projectId = ref.watch(selectedProjectProvider)?.id;
    _setProject(projectId);
    if (notesAsync.hasValue && linksAsync.hasValue) _updateGraph(notes, links);
    final layout = _layout;
    final width = layout?.width ?? 360.0;
    final height = layout?.height ?? 0.0;
    final selected = layout?.nodes[_selected];
    // Why the selected note is connected: "<other title> · <label>".
    final reasons = <String, String>{};
    if (selected != null && layout != null) {
      for (final l in layout.links) {
        if (l.sourceId != selected.id && l.targetId != selected.id) continue;
        final other = layout.nodes[l.sourceId == selected.id ? l.targetId : l.sourceId];
        if (other != null) reasons.putIfAbsent(other.id, () => '${_graphTitle(other)} · ${l.label}');
      }
    }

    final loadError =
        _layoutError || (notesAsync.hasError && !notesAsync.hasValue) || (linksAsync.hasError && !linksAsync.hasValue);
    final loading = !notesAsync.hasValue || !linksAsync.hasValue || layout == null;
    final empty = (layout?.readyCount ?? 0) < 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProjectHeader(title: 'الروابط'),
        Expanded(
          child: FikraSwitcher(
            child: KeyedSubtree(
              key: ValueKey(
                loadError
                    ? 'error'
                    : loading
                    ? 'loading'
                    : empty
                    ? 'empty'
                    : 'graph',
              ),
              child: loadError
                  ? LoadErrorView(
                      onRetry: () {
                        setState(() {
                          _input = null;
                          _notesSource = null;
                          _linksSource = null;
                          _layoutError = false;
                        });
                        ref.invalidate(selectedNotesProvider);
                        ref.invalidate(selectedLinksProvider);
                      },
                    )
                  : loading
                  ? const SizedBox.shrink()
                  : empty
                  ? FillScroll(
                      child: EmptyState(
                        icon: Icons.hub_outlined,
                        title: 'الروابط بتظهر هنا',
                        description: 'ضيف نوتين أو أكتر عن مواضيع قريبة، وفِكرة هتربطهم ببعض.',
                        action: FikraButton(
                          label: 'ضيف نوت',
                          icon: Icons.add_rounded,
                          expand: false,
                          onPressed: () => context.go('/add'),
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Viewport tools live above the graph, never on top of it.
                        Padding(
                          padding: const EdgeInsets.fromLTRB(FikraSpace.screen, 0, FikraSpace.screen, 8),
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${Fmt.notes(notes.length)} · ${Fmt.links(links.length)}',
                                  style: context.text.meta.copyWith(fontSize: 12, color: context.colors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Spacer(),
                              FikraIconButton(
                                icon: Icons.add_rounded,
                                label: 'تكبير',
                                size: 40,
                                onTap: () => _zoom(1.25),
                              ),
                              FikraIconButton(
                                icon: Icons.remove_rounded,
                                label: 'تصغير',
                                size: 40,
                                onTap: () => _zoom(0.8),
                              ),
                              FikraIconButton(
                                icon: Icons.center_focus_strong_outlined,
                                label: 'رجّع العرض',
                                size: 40,
                                onTap: () => _tc.value = _home(),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: LayoutBuilder(
                                  builder: (context, box) {
                                    final key = '${ref.read(selectedProjectProvider)?.id}|$width|${box.maxWidth}';
                                    if (key != _fittedFor) {
                                      _fittedFor = key;
                                      _viewportW = box.maxWidth;
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
                                          onTap: () => setState(() => _selected = null),
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
                                                  Positioned(
                                                    top: GraphLayout.padding + row.index * GraphLayout.rowHeight,
                                                    right: GraphLayout.padding,
                                                    child: Text(
                                                      row.cluster,
                                                      style: context.text.chip.copyWith(
                                                        color: context.colors.textSecondary,
                                                      ),
                                                    ),
                                                  ),
                                                for (final n in layout.nodes.values)
                                                  Positioned.fromRect(
                                                    rect: _rect(layout.positions[n.id]!),
                                                    child: _Node(
                                                      key: ValueKey(n.id),
                                                      note: n,
                                                      selected: n.id == _selected,
                                                      onTap: () =>
                                                          setState(() => _selected = n.id == _selected ? null : n.id),
                                                    ),
                                                  ),
                                                for (final row in layout.rows)
                                                  if (row.hiddenCount > 0)
                                                    Positioned.fromRect(
                                                      rect: _rect(layout.positionInRow(row.index, row.visible.length)),
                                                      child: _OverflowNode(
                                                        label: '+${row.hiddenCount}',
                                                        semanticLabel:
                                                            'عرض ${Fmt.notes(row.notes.length)} في ${row.cluster}',
                                                        numbersOnly: true,
                                                        onTap: () => _showCluster(row),
                                                      ),
                                                    ),
                                                if (layout.hiddenRows.isNotEmpty)
                                                  Positioned.fromRect(
                                                    rect: _rect(layout.positionInRow(layout.rows.length, 0)),
                                                    child: _OverflowNode(
                                                      label: 'مجموعات أكتر (${layout.hiddenRows.length})',
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
                                ),
                              ),
                              if (links.isEmpty && selected == null)
                                const Positioned(
                                  left: FikraSpace.screen,
                                  right: FikraSpace.screen,
                                  bottom: 16,
                                  child: StatusBanner(
                                    kind: BannerKind.info,
                                    message: 'لسه مفيش روابط. النوتس اللي فيها مفاهيم مشتركة هتترابط.',
                                  ),
                                ),
                              Positioned(
                                left: FikraSpace.screen,
                                right: FikraSpace.screen,
                                bottom: 12,
                                child: FikraSwitcher(
                                  animateSize: true,
                                  alignment: Alignment.bottomCenter,
                                  child: selected == null
                                      ? const SizedBox.shrink(key: ValueKey('no-preview'))
                                      : KeyedSubtree(
                                          key: ValueKey(selected.id),
                                          child: _NodePreview(
                                            note: selected,
                                            reasons: reasons.values.toList(),
                                            onOpen: () => _openNote(selected.id),
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

Rect _rect(GraphPosition position) => Rect.fromLTWH(position.left, position.top, position.width, position.height);

String _graphTitle(GraphNote note) => note.title.trim().isEmpty ? 'نوت جديدة' : note.title;

class _OverflowNode extends StatelessWidget {
  const _OverflowNode({required this.label, required this.onTap, this.semanticLabel, this.numbersOnly = false});

  final String label;
  final String? semanticLabel;
  final bool numbersOnly;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    semanticLabel: semanticLabel ?? label,
    child: Glass(
      radius: FikraRadius.sm,
      child: Center(
        child: Text(
          label,
          textDirection: numbersOnly ? TextDirection.ltr : TextDirection.rtl,
          style: context.text.chip,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ),
  );
}

/// Bottom card for the selected node: what it is and why it's connected.
class _NodePreview extends StatelessWidget {
  const _NodePreview({required this.note, required this.reasons, required this.onOpen});
  final GraphNote note;
  final List<String> reasons;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: FikraRadius.xl,
      color: context.colors.glass,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_graphTitle(note), style: context.text.cardTitleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(
            '${note.cluster ?? 'أفكار عامة'} · ${Fmt.links(reasons.length)}',
            style: context.text.meta.copyWith(fontSize: 12, color: context.colors.textSecondary),
          ),
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final r in reasons.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    Icon(Icons.link_rounded, size: 14, color: context.colors.textLink),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        r,
                        style: context.text.caption.copyWith(color: context.colors.textLink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 12),
          FikraButton(label: 'فتح النوت', icon: Icons.open_in_new_rounded, onPressed: onOpen),
        ],
      ),
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({super.key, required this.note, required this.selected, required this.onTap});
  final GraphNote note;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: _graphTitle(note),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: AlignmentDirectional.centerStart,
        decoration: BoxDecoration(
          gradient: selected ? context.colors.selectedGradient : context.colors.glassGradient,
          color: selected ? null : context.colors.glass,
          borderRadius: BorderRadius.circular(FikraRadius.sm),
          border: Border.all(
            color: selected ? context.colors.accentLight : context.colors.borderGraph,
            width: selected ? 1.2 : FikraSpace.hairline,
          ),
        ),
        child: Text(
          note.title,
          style: context.text.chip.copyWith(
            color: selected ? context.colors.textOnSelected : context.colors.textPrimary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _EdgesPainter extends CustomPainter {
  _EdgesPainter({
    required this.links,
    required this.pos,
    required this.selected,
    required this.edgeColor,
    required this.light,
  });
  final Color edgeColor;
  final bool light;
  final List<GraphLink> links;
  final Map<String, GraphPosition> pos;
  final String? selected;

  @override
  void paint(Canvas canvas, Size size) {
    for (final l in links) {
      final a = _rect(pos[l.sourceId]!).center;
      final b = _rect(pos[l.targetId]!).center;
      final active = selected != null && (l.sourceId == selected || l.targetId == selected);
      final dim = selected != null && !active;
      var opacity = 1.0;
      if (dim) {
        opacity = light ? 0.35 : 0.12;
      } else if (!active) {
        opacity = light ? 0.8 + l.strength * 0.2 : 0.35 + l.strength * 0.4;
      }
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = active ? 2.2 : 1 + l.strength * 1.5
        ..color = edgeColor.withValues(alpha: opacity);
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
      final bend = a.dy == b.dy ? -40.0 : 0.0; // same-row links arc upward
      final ctrl = Offset(mid.dx, mid.dy + bend);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, b.dx, b.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_EdgesPainter old) =>
      old.links != links ||
      old.selected != selected ||
      old.pos != pos ||
      old.edgeColor != edgeColor ||
      old.light != light;
}
