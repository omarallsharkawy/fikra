import 'package:fikra/l10n/localizations.dart';

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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
import '../shared/note_presentation.dart';
import '../shared/note_link_actions.dart';
import '../shared/link_pairs.dart';
import 'graph_capsules.dart';
import 'graph_edge_paths.dart';
import 'graph_layout.dart';

part 'edges_painter.dart';
part 'graph_nodes.dart';
part 'links_graph_data.dart';
part 'links_navigation.dart';
part 'links_viewport.dart';

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
  Size _viewportSize = Size.zero;
  double _canvasW = 0;

  List<Note>? _notesSource;
  List<NoteLink>? _linksSource;
  String? _projectId;
  GraphInput? _input;
  GraphInput? _pending;
  GraphLayout? _layout;
  GraphEdgePaths? _edgePaths;
  bool _linkOptionsOpen = false;
  bool _workerRunning = false;
  bool _layoutError = false;

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  /// `setState` is protected, so the extensions in the part files call it
  /// through this forwarder.
  void _setState(VoidCallback fn) => setState(fn);

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
        if (other != null) {
          reasons.putIfAbsent(
            other.id,
            () => l.label.trim().isEmpty ? _graphTitle(context, other) : '${_graphTitle(context, other)} · ${l.label}',
          );
        }
      }
    }

    final loadError =
        _layoutError || (notesAsync.hasError && !notesAsync.hasValue) || (linksAsync.hasError && !linksAsync.hasValue);
    final loading = !notesAsync.hasValue || !linksAsync.hasValue || layout == null;
    final empty = (layout?.readyCount ?? 0) < 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProjectHeader(title: context.l10n.linksTitle),
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
                        title: context.l10n.linksEmptyTitle,
                        description: context.l10n.linksEmptyBody,
                        action: FikraButton(
                          label: context.l10n.addNote,
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
                                  context.l10n.linksSummary(
                                    Fmt.notes(context.l10n, notes.length),
                                    Fmt.links(context.l10n, layout.linkCount),
                                  ),
                                  style: context.text.meta.copyWith(fontSize: 12, color: context.colors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Spacer(),
                              FikraIconButton(
                                icon: Icons.add_rounded,
                                label: context.l10n.zoomIn,
                                size: 40,
                                onTap: () => _zoom(1.25),
                              ),
                              FikraIconButton(
                                icon: Icons.remove_rounded,
                                label: context.l10n.zoomOut,
                                size: 40,
                                onTap: () => _zoom(0.8),
                              ),
                              FikraIconButton(
                                icon: Icons.center_focus_strong_outlined,
                                label: context.l10n.resetView,
                                size: 40,
                                onTap: () => _tc.value = _home(),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Stack(
                            children: [
                              Positioned.fill(child: _graphCanvas(layout, width, height)),
                              if (links.isEmpty && selected == null)
                                Positioned(
                                  left: FikraSpace.screen,
                                  right: FikraSpace.screen,
                                  bottom: 16,
                                  child: StatusBanner(kind: BannerKind.info, message: context.l10n.noLinksYet),
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
