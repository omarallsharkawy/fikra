import 'package:fikra/l10n/localizations.dart';

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
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
import '../shared/note_groups.dart';
import '../shared/group_options.dart';
import '../shared/group_filter.dart';
import '../shared/group_form.dart';
import '../shared/selection_bar.dart';
import '../shared/note_selection_actions.dart';
import '../shared/selection_actions.dart';
import 'graph_capsules.dart';
import 'graph_edge_paths.dart';
import 'graph_layout.dart';
import 'graph_search.dart';
import 'graph_session.dart';
import 'graph_minimap.dart';

part 'edges_painter.dart';
part 'graph_nodes.dart';
part 'links_graph_data.dart';
part 'links_navigation.dart';
part 'links_viewport.dart';
part 'graph_frames.dart';
part 'graph_selection.dart';
part 'graph_hold.dart';
part 'graph_overlays.dart';
part 'graph_cards.dart';
part 'links_search.dart';
part 'links_jump.dart';
part 'links_surface.dart';

/// Knowledge graph: one row per cluster, notes as nodes, links as curves.
class LinksScreen extends ConsumerStatefulWidget {
  const LinksScreen({super.key});

  /// Test probes: screen builds, and viewport animation ticks (one per frame,
  /// however many jumps ran before).
  @visibleForTesting
  static int builds = 0;
  @visibleForTesting
  static int travelTicks = 0;

  @override
  ConsumerState<LinksScreen> createState() => _LinksScreenState();
}

class _LinksScreenState extends ConsumerState<LinksScreen> with SingleTickerProviderStateMixin {
  final _search = TextEditingController();
  bool _searchOpen = false;
  String? _chipGroup;
  Set<String> _collapsed = {};
  GraphSearchIndex? _searchIndex;
  GraphSearchResult? _pendingJump;
  GraphInput? _installedInput;
  late final _travel = AnimationController(vsync: this, duration: FikraMotion.expand)..addListener(_onTravel);
  Matrix4Tween? _travelValue;
  final _tc = TransformationController();
  String? _selected;
  Set<String>? _selection;
  List<NoteGroup>? _groupsSource;
  final _pointers = <int>{};
  VoidCallback? _cancelHold;
  bool _groupOptionsOpen = false;
  String? _fittedFor;
  Size _viewportSize = Size.zero;
  double _canvasW = 0;

  List<Note>? _notesSource;
  List<NoteLink>? _linksSource;
  String? _projectId;
  int? _labelStyle;
  GraphInput? _input;
  GraphInput? _pending;
  GraphLayout? _layout;
  GraphEdgePaths? _edgePaths;
  bool _linkOptionsOpen = false;
  bool _workerRunning = false;
  bool _layoutError = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!TickerMode.valuesOf(context).enabled) {
      _cancelHold?.call();
      _pointers.clear();
      _selection = null;
    }
  }

  @override
  void dispose() {
    _travel.dispose();
    _search.dispose();
    _tc.dispose();
    super.dispose();
  }

  /// `setState` is protected, so the extensions in the part files call it
  /// through this forwarder.
  void _setState(VoidCallback fn) => setState(fn);

  // An instance method: extension tear-offs are never equal, so they could not
  // be removed and would pile up one listener per jump.
  void _onTravel() {
    final tween = _travelValue;
    if (tween == null) return;
    LinksScreen.travelTicks++;
    _tc.value = tween.transform(FikraMotion.expandCurve.transform(_travel.value));
  }

  @override
  Widget build(BuildContext context) {
    LinksScreen.builds++;
    final notesAsync = ref.watch(selectedNotesProvider);
    final linksAsync = ref.watch(selectedLinksProvider);
    final notes = notesAsync.value ?? const <Note>[];
    final links = linksAsync.value ?? const <NoteLink>[];
    final projectId = ref.watch(selectedProjectProvider)?.id;
    _setProject(projectId);
    final groupsAsync = projectId == null
        ? const AsyncData(<NoteGroup>[])
        : ref.watch(groupsOfProjectProvider(projectId));
    final groups = groupsAsync.value ?? const <NoteGroup>[];
    if (notesAsync.hasValue && linksAsync.hasValue && groupsAsync.hasValue) _updateGraph(notes, links, groups);
    if (notesAsync.hasValue && _selection != null) {
      final ids = notes.map((n) => n.id).toSet();
      _selection!.removeWhere((id) => !ids.contains(id) || !(_layout?.nodes.containsKey(id) ?? false));
      if (_selection!.isEmpty) _selection = null;
    }
    if (_pendingJump != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _finishJump();
      });
    }
    final layout = _layout;
    final selected = _selection == null ? layout?.nodes[_selected] : null;
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
        _layoutError ||
        (groupsAsync.hasError && !groupsAsync.hasValue) ||
        (notesAsync.hasError && !notesAsync.hasValue) ||
        (linksAsync.hasError && !linksAsync.hasValue);
    final loading = !notesAsync.hasValue || !linksAsync.hasValue || !groupsAsync.hasValue || layout == null;
    final empty = (layout?.readyCount ?? 0) < 2 && groups.isEmpty;

    return PopScope(
      canPop: _selection == null && !_searchOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (_searchOpen) {
            _closeSearch();
          } else {
            _endSelection();
          }
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_selection == null)
            ProjectHeader(
              title: context.l10n.linksTitle,
              trailing: FikraIconButton(
                key: const ValueKey('graph-search-open'),
                icon: Icons.search_rounded,
                label: context.l10n.graphSearchHint,
                onTap: () => setState(() {
                  _searchOpen = true;
                  _cancelHold?.call();
                }),
              ),
            )
          else
            SelectionHeader(count: _selection!.length, onClose: _endSelection),
          // Kept (dimmed) in selection mode so the graph never moves under the finger.
          if (groups.isNotEmpty && !_searchOpen)
            GroupFilterRow(
              groups: groups,
              selectedId: _chipGroup,
              navigation: true,
              enabled: _selection == null,
              onOptions: (g) => _groupOptions(g.id),
              onSelect: (id) {
                if (id == null) return;
                _chipGroup = id;
                _pickSearch(GraphSearchResult(GraphSearchKind.group, id, ''));
              },
            ),
          Expanded(
            key: const ValueKey('links-content'),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ExcludeSemantics(
                    excluding: _searchOpen,
                    child: IgnorePointer(
                      ignoring: _searchOpen,
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
                                      _groupsSource = null;
                                      _layoutError = false;
                                    });
                                    ref.invalidate(selectedNotesProvider);
                                    ref.invalidate(selectedLinksProvider);
                                    if (projectId != null) ref.invalidate(groupsOfProjectProvider(projectId));
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
                              : _surface(layout, notes, links, selected, reasons),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_searchOpen)
                  Positioned.fill(
                    child: Material(
                      color: context.colors.screen,
                      child: _GraphSearchPanel(
                        controller: _search,
                        index: _searchIndex,
                        onPick: _pickSearch,
                        onClose: _closeSearch,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_selection != null) _selectionBar(_selection!.length),
        ],
      ),
    );
  }
}
