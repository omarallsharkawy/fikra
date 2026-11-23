import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OrdinalSortKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/motion/motion.dart';
import '../../core/motion/stagger.dart';
import '../../core/motion/stagger_visibility.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../l10n/localizations.dart';
import '../projects/project_header.dart';
import '../shared/note_groups.dart';
import 'library_cards.dart';
import 'library_chips.dart';
import 'library_controls.dart';
import 'library_session.dart';
import 'links_index.dart';
import 'links_library_provider.dart';
import 'links_map.dart';
import 'note_connections_provider.dart';
import 'suggestion_sliver.dart';

class LinksLibraryScreen extends ConsumerStatefulWidget {
  const LinksLibraryScreen({super.key});
  @visibleForTesting
  static int builds = 0;
  @override
  ConsumerState<LinksLibraryScreen> createState() => _LinksLibraryScreenState();
}

class _ProjectView {
  final search = TextEditingController();
  final scrolls = {LinksLibrarySegment.browse: ScrollController(), LinksLibrarySegment.suggestions: ScrollController()};
  LibraryChip chip = (group: null, topic: null);
  LinksSort sort = LinksSort.newest;

  /// The trimmed, debounced search. Typing only rebuilds the field.
  String query = '';
  Timer? debounce;
  void dispose() {
    debounce?.cancel();
    search.dispose();
    for (final c in scrolls.values) {
      c.dispose();
    }
  }
}

class _LinksLibraryScreenState extends ConsumerState<LinksLibraryScreen> with TickerProviderStateMixin {
  final _projects = <String, _ProjectView>{};
  final _retired = <_ProjectView>[];
  late final StaggerController _browseStagger = StaggerController(this);
  late final StaggerController _suggestionsStagger = StaggerController(this);
  // Snapshot only: StaggerVisibility owns the inherited visibility dependency.
  bool get _tickerEnabled => TickerMode.getValuesNotifier(context).value.enabled;

  void _pruneDeletedProjects(List<Object> liveIds) {
    if (_projects.isEmpty) return;
    final live = Set<Object>.of(liveIds);
    final removed = <_ProjectView>[];
    _projects.removeWhere((id, view) {
      if (live.contains(id)) return false;
      view.debounce?.cancel();
      view.debounce = null;
      removed.add(view);
      return true;
    });
    if (removed.isEmpty) return;
    _retired.addAll(removed);
    WidgetsBinding.instance.addPostFrameCallback((_) => _disposeRetired());
  }

  void _disposeRetired() {
    for (final view in _retired) {
      view.dispose();
    }
    _retired.clear();
  }

  @override
  void dispose() {
    _browseStagger.dispose();
    _suggestionsStagger.dispose();
    _disposeRetired();
    for (final p in _projects.values) {
      p.dispose();
    }
    _projects.clear();
    super.dispose();
  }

  void _onSearch(_ProjectView state, String value) {
    state.debounce?.cancel();
    // Same short debounce as Notes: typing stays smooth on big projects;
    // clearing is instant.
    final query = value.trim();
    if (query == state.query) return;
    if (query.isEmpty) {
      setState(() => state.query = '');
      return;
    }
    state.debounce = Timer(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => state.query = query);
    });
  }

  @override
  Widget build(BuildContext context) {
    LinksLibraryScreen.builds++;
    final project = ref.watch(selectedProjectProvider);
    ref.listen(projectsProvider, (_, next) {
      final list = next.value;
      if (list != null) _pruneDeletedProjects([for (final p in list) p.project.id]);
    });
    ref.listen(selectedProjectProvider, (previous, next) {
      if (previous?.id == next?.id) return;
      _browseStagger.onProjectChanged(next?.id, tickerEnabled: _tickerEnabled);
      _suggestionsStagger.onProjectChanged(next?.id, tickerEnabled: _tickerEnabled);
    });
    if (project == null) return const SizedBox.shrink();
    // Warm shared adjacency before a tap; completion does not rebuild the library.
    ref.listen(connectionsIndexProvider(project.id), (_, _) {});
    final state = _projects.putIfAbsent(project.id, _ProjectView.new);
    final savedSegment = ref.watch(linksSegmentProvider)[project.id];
    final requestedSegment = ref.watch(linksLibraryRequestedSegmentProvider);
    final segment = requestedSegment ?? savedSegment ?? LinksLibrarySegment.map;
    if (requestedSegment != null) {
      Future<void>.microtask(() {
        if (!mounted ||
            ref.read(selectedProjectProvider)?.id != project.id ||
            ref.read(linksLibraryRequestedSegmentProvider) != requestedSegment) {
          return;
        }
        ref.read(linksSegmentProvider.notifier).select(project.id, requestedSegment);
        ref.read(linksLibraryRequestedSegmentProvider.notifier).clear();
      });
    }
    final source = ref.watch(linksLibraryProvider(project.id));
    final liveGroups = ref.watch(groupsOfProjectProvider(project.id));
    final groups = liveGroups.value ?? const [];
    final index = source.value;
    // Groups come from their own stream; the derived index can lag behind it.
    if (liveGroups.hasValue && state.chip.group != null && !groups.any((g) => g.id == state.chip.group)) {
      state.chip = (group: null, topic: null);
    }
    if (index != null && state.chip.topic != null && !index.topicCounts.containsKey(state.chip.topic)) {
      state.chip = (group: null, topic: null);
    }
    final view = index?.filter(chip: state.chip, search: state.query, sort: state.sort);
    if (index != null && view != null) {
      final tickerEnabled = _tickerEnabled;
      final reduced = FikraMotion.reduced(context);
      if (segment == LinksLibrarySegment.browse) {
        _browseStagger.maybeStart(
          projectId: project.id,
          visibleIds: view.browse.map((e) => e.note.id),
          tickerEnabled: tickerEnabled,
          reduced: reduced,
        );
      } else if (segment == LinksLibrarySegment.suggestions) {
        _suggestionsStagger.maybeStart(
          projectId: project.id,
          visibleIds: view.suggestions.map((e) => pairKey(e.a.id, e.b.id)),
          tickerEnabled: tickerEnabled,
          reduced: reduced,
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StaggerVisibility(controllers: [_browseStagger, _suggestionsStagger]),
        ProjectHeader(title: context.l10n.linksTitle),
        Expanded(
          child: source.hasError && !source.hasValue
              ? LoadErrorView(
                  onRetry: () {
                    ref.invalidate(notesOfProjectProvider(project.id));
                    ref.invalidate(linksOfProjectProvider(project.id));
                    ref.invalidate(groupsOfProjectProvider(project.id));
                  },
                )
              : index == null || view == null
              ? const SizedBox.shrink()
              : Stack(
                  children: [
                    Semantics(
                      container: true,
                      sortKey: const OrdinalSortKey(1),
                      child: IndexedStack(
                        index: segment,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: LibraryControls.extent(context)),
                            child: LinksMap(
                              key: ValueKey('map-${project.id}'),
                              projectId: project.id,
                              active: segment == LinksLibrarySegment.map,
                              projectName: project.name,
                              query: state.query,
                              onSearchFocus: () {
                                state.search.clear();
                                _onSearch(state, '');
                              },
                            ),
                          ),
                          for (final listSegment in state.scrolls.keys)
                            CustomScrollView(
                              key: LinksLibrarySegment.listKey(project.id, listSegment),
                              controller: state.scrolls[listSegment],
                              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                              slivers: [
                                SliverToBoxAdapter(child: SizedBox(height: LibraryControls.extent(context))),
                                SliverToBoxAdapter(
                                  child: LibraryChips(
                                    key: ValueKey('links-chips-${project.id}'),
                                    index: index,
                                    groups: groups,
                                    chip: state.chip,
                                    onChip: (chip) => setState(() => state.chip = chip),
                                  ),
                                ),
                                if (listSegment == LinksLibrarySegment.browse && view.browse.isEmpty)
                                  SliverToBoxAdapter(child: _empty(project.id, state, index, suggestions: false))
                                else if (listSegment == LinksLibrarySegment.browse)
                                  SliverPadding(
                                    padding: const EdgeInsets.symmetric(horizontal: FikraSpace.screen),
                                    sliver: SliverList.builder(
                                      itemCount: view.browse.length,
                                      itemBuilder: (_, i) {
                                        final id = view.browse[i].note.id;
                                        return StaggeredEntry(
                                          key: ValueKey('browse-slot-$id'),
                                          stagger: _browseStagger,
                                          itemId: id,
                                          child: BrowseNoteCard(key: ValueKey('browse-$id'), entry: view.browse[i]),
                                        );
                                      },
                                    ),
                                  )
                                else ...[
                                  SliverPadding(
                                    padding: const EdgeInsets.symmetric(horizontal: FikraSpace.screen),
                                    sliver: SuggestionSliver(
                                      key: ValueKey((project.id, state.chip, state.query)),
                                      entries: view.suggestions,
                                      empty: _empty(project.id, state, index, suggestions: true),
                                      stagger: _suggestionsStagger,
                                    ),
                                  ),
                                ],
                                const SliverToBoxAdapter(child: NavigationInsetSpacer(extra: 24)),
                              ],
                            ),
                        ],
                      ),
                    ),
                    Semantics(
                      container: true,
                      sortKey: const OrdinalSortKey(0),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: LibraryControls(
                          key: ValueKey('links-controls-${project.id}'),
                          search: state.search,
                          onSearch: (value) => _onSearch(state, value),
                          suggestions: index.suggestions.length,
                          segment: segment,
                          onSegment: (i) => ref.read(linksSegmentProvider.notifier).select(project.id, i),
                          sort: state.sort,
                          onSort: (sort) => setState(() => state.sort = sort),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _empty(String projectId, _ProjectView state, LinksIndex index, {required bool suggestions}) {
    final searching = state.query.isNotEmpty;
    final filtered = searching || state.chip.group != null || state.chip.topic != null;
    return EmptyState(
      icon: filtered
          ? Icons.search_off_rounded
          : suggestions
          ? Icons.auto_awesome_outlined
          : Icons.link_rounded,
      title: filtered
          ? context.l10n.noResultsTitle
          : suggestions
          ? context.l10n.linksSuggestionsEmpty
          : context.l10n.linksEmptyTitle,
      description: searching
          ? context.l10n.noResultsBody(state.query)
          : filtered
          ? context.l10n.linksFilterEmptyBody
          : suggestions
          ? context.l10n.linksSuggestionsEmptyBody
          : index.suggestions.isNotEmpty
          ? context.l10n.linksBrowseSuggestionsBody
          : context.l10n.noteLinksEmpty,
      action: !suggestions && !filtered && index.suggestions.isNotEmpty
          ? FikraButton.secondary(
              label: context.l10n.linksSuggestions,
              growForText: true,
              onPressed: () =>
                  ref.read(linksSegmentProvider.notifier).select(projectId, LinksLibrarySegment.suggestions),
            )
          : null,
    );
  }
}
