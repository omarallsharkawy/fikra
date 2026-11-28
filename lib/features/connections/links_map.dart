import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../l10n/localizations.dart';
import '../shared/note_link_actions.dart';
import '../shared/note_presentation.dart';
import 'library_cards.dart';
import 'link_pair_busy.dart';
import 'links_index.dart';
import 'map_canvas.dart';
import 'map_index.dart';
import 'map_provider.dart';

class LinksMap extends ConsumerStatefulWidget {
  const LinksMap({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.query,
    required this.onSearchFocus,
    required this.active,
  });
  final String projectId, projectName, query;
  final bool active;
  final VoidCallback onSearchFocus;
  @override
  ConsumerState<LinksMap> createState() => _LinksMapState();
}

class _LinksMapState extends ConsumerState<LinksMap> {
  String? _cluster, _centre, _selected, _suggestionFrom;
  MapIndex? _revision;
  MapLevel? _level;
  Object? _levelKey;

  void _focus(MapIndex index, String id, {String? suggestionFrom}) {
    FocusManager.instance.primaryFocus?.unfocus();
    widget.onSearchFocus();
    setState(() {
      _centre = id;
      _suggestionFrom = suggestionFrom;
      _cluster = index.clusterOf[id];
      _selected = id;
    });
  }

  void _back() => setState(() {
    if (_centre != null) {
      _centre = null;
      _selected = _cluster;
    } else {
      _cluster = null;
      _selected = null;
    }
  });

  void _more(MapIndex index) {
    final ids = _centre == null
        ? index.clusters.firstWhere((c) => c.id == _cluster).notes
        : [
            ...index.adjacency[_centre] ?? const <String>[],
            for (final s in index.library.suggestionsByNote[_centre] ?? const <SuggestionEntry>[])
              s.a.id == _centre ? s.b.id : s.a.id,
          ];
    showFikraSheet<void>(
      context,
      title: context.l10n.mapShowMore,
      builder: (sheet) => SizedBox(
        height: MediaQuery.sizeOf(context).height * .55,
        child: ListView.builder(
          key: const ValueKey('map-more-list'),
          itemCount: ids.length,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
            child: SolidSurface(
              padding: EdgeInsets.zero,
              child: Material(
                type: MaterialType.transparency,
                child: ListTile(
                  key: ValueKey('map-more-${ids[i]}'),
                  title: SmartText(noteTitleText(context, index.notes[ids[i]]!.title)),
                  subtitle: SmartText(context.l10n.mapConnections(index.degree(ids[i]))),
                  onTap: () {
                    Navigator.pop(sheet);
                    _focus(index, ids[i]);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final source = ref.watch(linksMapProvider(widget.projectId));
    final index = source.value;
    if (index == null) {
      if (source.hasError) return LoadErrorView(onRetry: () => ref.invalidate(linksMapProvider(widget.projectId)));
      return const Center(
        child: SizedBox(width: 160, height: 64, child: SolidSurface(child: SizedBox())),
      );
    }
    if (_centre != null && !index.notes.containsKey(_centre)) {
      _centre = null;
      _selected = _cluster;
    }
    if (_cluster != null && !index.clusters.any((c) => c.id == _cluster)) {
      _cluster = null;
      _centre = null;
      _selected = null;
    }
    if (_selected != null && !index.notes.containsKey(_selected) && !index.clusters.any((c) => c.id == _selected)) {
      _selected = _centre ?? _cluster;
    }
    final levelKey = (_cluster, _centre);
    if (!identical(_revision, index) || _levelKey != levelKey) {
      _revision = index;
      _levelKey = levelKey;
      _level = _centre != null
          ? index.ego(_centre!)
          : _cluster != null
          ? index.cluster(_cluster!)
          : index.overview();
    }
    final level = _level!;
    final cluster = index.clusters.where((c) => c.id == _cluster).firstOrNull;
    final selectedCluster = index.clusters.where((c) => c.id == _selected).firstOrNull;
    final note = index.notes[_selected];
    final suggestion = _centre == null || _suggestionFrom == null
        ? null
        : index.library.suggestionsByNote[_centre]
              ?.where((s) => s.a.id == _suggestionFrom || s.b.id == _suggestionFrom)
              .firstOrNull;
    final matches = widget.query.isEmpty ? const <LibraryNote>[] : index.search(widget.query);
    final interceptBack =
        widget.active && TickerMode.valuesOf(context).enabled && (_cluster != null || _centre != null);
    return PopScope(
      canPop: !interceptBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && interceptBack) _back();
      },
      child: ColoredBox(
        color: context.colors.canvas,
        child: Padding(
          padding: EdgeInsets.only(bottom: NavigationInset.of(context)),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = MediaQuery.textScalerOf(context).scale(1) >= 1.3 || constraints.maxHeight < 420;
              final content = Column(
                mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        if (_cluster != null || _centre != null)
                          BackButton(key: const ValueKey('map-back'), onPressed: _back),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              key: const ValueKey('map-breadcrumbs'),
                              children: [
                                TextButton(
                                  key: const ValueKey('map-project'),
                                  onPressed: () => setState(() {
                                    _cluster = null;
                                    _centre = null;
                                    _selected = null;
                                  }),
                                  child: SmartText(widget.projectName),
                                ),
                                if (cluster != null) ...[
                                  const Icon(Icons.chevron_right_rounded),
                                  TextButton(
                                    onPressed: () => setState(() {
                                      _centre = null;
                                      _selected = _cluster;
                                    }),
                                    child: SmartText(cluster.name ?? context.l10n.mapOthers),
                                  ),
                                ],
                                if (_centre != null) ...[
                                  const Icon(Icons.chevron_right_rounded),
                                  SmartText(
                                    noteTitleText(context, index.notes[_centre]!.title),
                                    style: context.text.meta,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 8),
                    child: SmartText(
                      context.l10n.mapTotals(level.total, level.confirmed, level.suggestions, level.omitted),
                      key: const ValueKey('map-totals'),
                      style: context.text.meta,
                    ),
                  ),
                  if (_centre != null)
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 8),
                      child: SmartText(
                        context.l10n.mapPanHint,
                        content: ReadOnlyContent.chrome,
                        style: context.text.meta,
                      ),
                    ),
                  if (widget.query.isNotEmpty)
                    _MapSection(
                      compact: compact,
                      search: true,
                      child: SolidSurface(
                        padding: EdgeInsets.zero,
                        child: matches.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(16),
                                child: SmartText(context.l10n.noResultsBody(widget.query)),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: matches.length,
                                itemBuilder: (_, i) {
                                  final n = matches[i];
                                  return Material(
                                    type: MaterialType.transparency,
                                    child: ListTile(
                                      key: ValueKey('map-search-${n.id}'),
                                      title: SmartText(
                                        noteTitleText(context, n.title),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: SmartText(context.l10n.mapConnections(index.degree(n.id))),
                                      onTap: () => _focus(index, n.id),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  _MapSection(
                    compact: compact,
                    canvas: true,
                    child: AnimatedSwitcher(
                      duration: FikraMotion.reduced(context) ? Duration.zero : FikraMotion.roll,
                      switchInCurve: FikraMotion.rollCurve,
                      layoutBuilder: (child, previous) => Stack(
                        fit: StackFit.expand,
                        children: [
                          for (final old in previous) ExcludeSemantics(child: IgnorePointer(child: old)),
                          ?child,
                        ],
                      ),
                      child: level.nodes.isEmpty
                          ? EmptyState(
                              icon: Icons.hub_outlined,
                              title: context.l10n.linksEmptyTitle,
                              description: context.l10n.noteLinksEmpty,
                            )
                          : MapCanvas(
                              key: ValueKey(levelKey),
                              index: index,
                              level: level,
                              ego: _centre != null,
                              selected: _selected,
                              onNode: (node) {
                                switch (node.kind) {
                                  case MapNodeKind.more:
                                    _more(index);
                                  case MapNodeKind.cluster:
                                    setState(() {
                                      _cluster = node.id;
                                      _selected = node.id;
                                      _centre = null;
                                    });
                                  case MapNodeKind.suggestion:
                                    _focus(index, node.id, suggestionFrom: _centre);
                                  case MapNodeKind.note:
                                    _focus(index, node.id);
                                }
                              },
                            ),
                    ),
                  ),
                  if (level.omitted > 0)
                    TextButton(
                      key: const ValueKey('map-show-more'),
                      onPressed: () => _more(index),
                      child: SmartText('${context.l10n.mapShowMore} +${level.omitted}'),
                    ),
                  if (note != null || selectedCluster != null)
                    _MapSection(
                      compact: compact,
                      child: SingleChildScrollView(
                        key: const ValueKey('map-card-scroll'),
                        padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 8),
                        child: SolidSurface(
                          key: const ValueKey('map-card'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (note != null) ...[
                                LibraryNoteText(note: note, lines: 2),
                                const SizedBox(height: 8),
                                SmartText(context.l10n.mapConnections(index.degree(note.id)), style: context.text.meta),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    TextButton(
                                      key: const ValueKey('map-open-note'),
                                      onPressed: () => context.push('/note/${note.id}'),
                                      child: SmartText(context.l10n.mapOpen),
                                    ),
                                    if (suggestion != null) _MapPairActions(entry: suggestion),
                                  ],
                                ),
                              ] else if (selectedCluster != null) ...[
                                SmartText(selectedCluster.name ?? context.l10n.mapOthers, style: context.text.body),
                                SmartText(
                                  context.l10n.mapNotes(selectedCluster.notes.length),
                                  style: context.text.meta,
                                ),
                                TextButton(
                                  key: const ValueKey('map-open-cluster'),
                                  onPressed: () => setState(() {
                                    _cluster = selectedCluster.id;
                                    _centre = null;
                                  }),
                                  child: SmartText(context.l10n.mapOpen),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
              return compact
                  ? ClipRect(
                      child: SingleChildScrollView(key: const ValueKey('map-page-scroll'), child: content),
                    )
                  : content;
            },
          ),
        ),
      ),
    );
  }
}

class _MapPairActions extends ConsumerWidget {
  const _MapPairActions({required this.entry});
  final SuggestionEntry entry;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pair = pairKey(entry.a.id, entry.b.id), project = entry.link.projectId;
    final key = '$project:$pair';
    final busy =
        ref.watch(linkPairBusyProvider.select((pairs) => pairs.containsKey(key))) ||
        entry.a.projectId != project ||
        entry.b.projectId != project;
    Future<void> act(bool accept) async {
      final guard = ref.read(linkPairBusyProvider.notifier);
      if (!guard.claim(key, project: project, pair: pair)) return;
      var success = false;
      try {
        success = await changeSuggestedPair(
          context,
          a: entry.a.id,
          b: entry.b.id,
          accept: accept,
          expectedProjectId: project,
        );
      } finally {
        guard.finish(key, success: success);
      }
    }

    final label =
        '${Fmt.isolate(noteTitleText(context, entry.a.title))} · ${Fmt.isolate(noteTitleText(context, entry.b.title))}';
    return Wrap(
      spacing: 8,
      children: [
        for (final accept in [true, false])
          Semantics(
            label: accept ? context.l10n.acceptLinkA11y(label) : context.l10n.rejectLinkA11y(label),
            button: true,
            enabled: !busy,
            excludeSemantics: true,
            onTap: busy ? null : () => act(accept),
            child: TextButton.icon(
              key: ValueKey('map-${accept ? 'accept' : 'reject'}'),
              onPressed: busy ? null : () => act(accept),
              icon: Icon(accept ? Icons.check_rounded : Icons.close_rounded),
              label: SmartText(accept ? context.l10n.acceptLink : context.l10n.rejectLink),
            ),
          ),
      ],
    );
  }
}

/// Large text/short screens scroll above a fixed opaque navigation clearance.
/// Canvas and actions keep their natural readable/tappable sizes.
class _MapSection extends StatelessWidget {
  const _MapSection({required this.compact, required this.child, this.canvas = false, this.search = false});
  final bool compact, canvas, search;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (!compact) return canvas ? Expanded(flex: 2, child: child) : Flexible(child: child);
    if (canvas) return SizedBox(height: 220 + MediaQuery.textScalerOf(context).scale(50), child: child);
    if (search) return SizedBox(height: 200, child: child);
    return child;
  }
}
