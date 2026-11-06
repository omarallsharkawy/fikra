import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/motion/pressable.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/local/database.dart';
import '../projects/project_header.dart';

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

  static const _nodeW = 148.0;
  static const _nodeH = 54.0;
  static const _gapX = 22.0;
  static const _rowH = 132.0;
  static const _pad = 24.0;

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
    final notes =
        (ref.watch(notesProvider).value ?? const <Note>[]).where((n) => n.status == ProcessingStatus.ready).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final links = ref.watch(linksProvider).value ?? const <NoteLink>[];

    final clusters = <String, List<Note>>{};
    for (final n in notes) {
      clusters.putIfAbsent(n.cluster ?? 'أفكار عامة', () => []).add(n);
    }
    final ordered = clusters.entries.toList()..sort((a, b) => b.value.length.compareTo(a.value.length));
    final maxCols = ordered.fold<int>(1, (m, e) => math.max(m, e.value.length));
    final width = math.max(360.0, _pad * 2 + maxCols * _nodeW + (maxCols - 1) * _gapX);
    final height = _pad * 2 + ordered.length * _rowH;

    // RTL: first note of each row sits on the right.
    final pos = <String, Rect>{};
    for (var r = 0; r < ordered.length; r++) {
      final row = ordered[r].value;
      final y = _pad + r * _rowH + 34;
      for (var i = 0; i < row.length; i++) {
        final x = width - _pad - (i + 1) * _nodeW - i * _gapX;
        pos[row[i].id] = Rect.fromLTWH(x, y, _nodeW, _nodeH);
      }
    }
    final visibleLinks = links.where((l) => pos.containsKey(l.sourceId) && pos.containsKey(l.targetId)).toList();
    final selected = notes.where((n) => n.id == _selected).firstOrNull;
    final selectedLinks = selected == null
        ? 0
        : visibleLinks.where((l) => l.sourceId == selected.id || l.targetId == selected.id).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProjectHeader(title: 'الروابط'),
        Expanded(
          child: notes.length < 2
              ? EmptyState(
                  icon: Icons.hub_outlined,
                  title: 'الروابط بتظهر هنا',
                  description: 'ضيف نوتين أو أكتر عن مواضيع قريبة، وفِكرة هتربطهم ببعض.',
                  action: FikraButton(
                    label: 'ضيف نوت',
                    icon: Icons.add_rounded,
                    expand: false,
                    onPressed: () => context.go('/add'),
                  ),
                )
              : Stack(
                  children: [
                    Positioned.fill(
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final key = '${ref.read(currentProjectProvider)?.id}|$width|${box.maxWidth}';
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
                            child: GestureDetector(
                              onTap: () => setState(() => _selected = null),
                              child: SizedBox(
                                width: width,
                                height: height,
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: _EdgesPainter(links: visibleLinks, pos: pos, selected: _selected),
                                      ),
                                    ),
                                    for (var r = 0; r < ordered.length; r++)
                                      Positioned(
                                        top: _pad + r * _rowH,
                                        right: _pad,
                                        child: Text(
                                          ordered[r].key,
                                          style: FikraText.chip.copyWith(color: FikraColors.textSecondary),
                                        ),
                                      ),
                                    for (final n in notes)
                                      Positioned.fromRect(
                                        rect: pos[n.id]!,
                                        child: _Node(
                                          note: n,
                                          selected: n.id == _selected,
                                          onTap: () => setState(() => _selected = n.id == _selected ? null : n.id),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    PositionedDirectional(
                      start: FikraSpace.screen,
                      top: 4,
                      child: Column(
                        children: [
                          _ZoomBtn(icon: Icons.add_rounded, label: 'تكبير', onTap: () => _zoom(1.25)),
                          const SizedBox(height: 8),
                          _ZoomBtn(icon: Icons.remove_rounded, label: 'تصغير', onTap: () => _zoom(0.8)),
                          const SizedBox(height: 8),
                          _ZoomBtn(
                            icon: Icons.center_focus_strong_outlined,
                            label: 'رجّع العرض',
                            onTap: () => _tc.value = _home(),
                          ),
                        ],
                      ),
                    ),
                    if (visibleLinks.isEmpty && selected == null)
                      const Positioned(
                        left: FikraSpace.screen,
                        right: FikraSpace.screen,
                        bottom: 16,
                        child: StatusBanner(
                          kind: BannerKind.info,
                          message: 'لسه مفيش روابط. النوتس اللي فيها مفاهيم مشتركة هتترابط.',
                        ),
                      ),
                    if (selected != null)
                      Positioned(
                        left: FikraSpace.screen,
                        right: FikraSpace.screen,
                        bottom: 12,
                        child: Glass(
                          radius: FikraRadius.xl,
                          color: FikraColors.glass,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                selected.title,
                                style: FikraText.cardTitleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${selected.cluster ?? 'أفكار عامة'} · $selectedLinks روابط',
                                style: FikraText.meta.copyWith(fontSize: 12),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                selected.displayText,
                                style: FikraText.caption,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              FikraButton(
                                label: 'فتح النوت',
                                icon: Icons.open_in_new_rounded,
                                onPressed: () => context.push('/note/${selected.id}'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({required this.note, required this.selected, required this.onTap});
  final Note note;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: note.title,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: AlignmentDirectional.centerStart,
        decoration: BoxDecoration(
          gradient: selected ? FikraColors.selectedGradient : FikraColors.glassGradient,
          color: selected ? null : FikraColors.glass,
          borderRadius: BorderRadius.circular(FikraRadius.sm),
          border: Border.all(
            color: selected ? FikraColors.accentLight : FikraColors.borderGraph,
            width: selected ? 1.2 : FikraSpace.hairline,
          ),
        ),
        child: Text(note.title, style: FikraText.chip, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _EdgesPainter extends CustomPainter {
  _EdgesPainter({required this.links, required this.pos, required this.selected});
  final List<NoteLink> links;
  final Map<String, Rect> pos;
  final String? selected;

  @override
  void paint(Canvas canvas, Size size) {
    for (final l in links) {
      final a = pos[l.sourceId]!.center;
      final b = pos[l.targetId]!.center;
      final active = selected != null && (l.sourceId == selected || l.targetId == selected);
      final dim = selected != null && !active;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = active ? 2.2 : 1 + l.strength * 1.5
        ..color = FikraColors.graphEdge.withValues(alpha: dim ? 0.12 : (active ? 1 : 0.35 + l.strength * 0.4));
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
  bool shouldRepaint(_EdgesPainter old) => old.links != links || old.selected != selected || old.pos != pos;
}

class _ZoomBtn extends StatelessWidget {
  const _ZoomBtn({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Glass(
        radius: FikraRadius.full,
        width: 42,
        height: 42,
        padding: EdgeInsets.zero,
        color: FikraColors.glass,
        child: Icon(icon, size: 20),
      ),
    );
  }
}
