import 'package:fikra/l10n/localizations.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/local/database.dart';
import '../projects/project_header.dart';
import '../shared/group_filter.dart';
import '../shared/group_options.dart';
import '../shared/note_groups.dart';
import '../shared/selection_bar.dart';
import '../shared/note_selection_actions.dart';
import 'note_card.dart';

part 'notes_selection.dart';

enum NotesSort { newest, oldest }

class NotesSortNotifier extends Notifier<NotesSort> {
  @override
  NotesSort build() => NotesSort.newest;

  void set(NotesSort sort) => state = sort;
}

/// Session-scoped sort order for the notes list.
final notesSortProvider = NotifierProvider<NotesSortNotifier, NotesSort>(NotesSortNotifier.new);

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> with _Selection {
  final _search = TextEditingController();
  String _query = '';
  Timer? _debounce;

  /// The group filter: a group id (with its sub-groups), or null for all.
  String? _filter;

  // Lower-cased search text per note, rebuilt only when the note changes, so
  // a keystroke doesn't re-lowercase thousands of notes.
  final _haystacks = <String, (String, String, String, String)>{};

  // The filtered + grouped list, recomputed only when the notes, the groups,
  // the filter, the sort or the query change (not on every rebuild).
  List<Note>? _lastAll;
  List<NoteGroup>? _lastGroups;
  String? _lastFilter;
  NotesSort? _lastSort;
  String? _lastQuery;
  DateTime? _lastDay;
  String? _lastLocale;
  List<_Row> _rows = const [];
  Map<String, int> _rowOf = const {};
  Map<String, NoteGroup> _groupsById = const {};
  int _matchCount = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    // Short debounce: typing stays smooth on big projects; clearing is instant.
    final q = v.trim();
    if (q.isEmpty) {
      setState(() => _query = '');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => _query = q);
    });
  }

  void _showSortSheet(BuildContext context, NotesSort current) {
    final l10n = context.l10n;
    showFikraSheet<void>(
      context,
      title: l10n.notesSort,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (order, label) in [(NotesSort.newest, l10n.linksNewest), (NotesSort.oldest, l10n.linksOldest)])
            SheetOption(
              key: ValueKey('notes-sort-${order.name}'),
              label: label,
              selected: order == current,
              icon: order == current ? Icons.check_rounded : Icons.sort_rounded,
              onTap: () {
                ref.read(notesSortProvider.notifier).set(order);
                Navigator.pop(sheet);
              },
            ),
        ],
      ),
    );
  }

  String _haystack(Note n) {
    // Keyed on the searchable fields themselves (updatedAt only has 1 s
    // resolution): string equality is cheap and never serves stale text.
    final cached = _haystacks[n.id];
    if (cached != null && cached.$1 == n.title && cached.$2 == n.displayText && cached.$3 == n.concepts) {
      return cached.$4;
    }
    final h = '${n.title}\n${n.displayText}\n${n.concepts}'.toLowerCase();
    _haystacks[n.id] = (n.title, n.displayText, n.concepts, h);
    return h;
  }

  void _rebuildRows(List<Note> all, List<NoteGroup> groups, NotesSort sort) {
    // Rebuild date labels when the locale or calendar day changes.
    final now = ref.read(appClockProvider)();
    final today = DateTime(now.year, now.month, now.day);
    if (identical(all, _lastAll) &&
        identical(groups, _lastGroups) &&
        _filter == _lastFilter &&
        sort == _lastSort &&
        _query == _lastQuery &&
        today == _lastDay &&
        _lastLocale == context.l10n.localeName) {
      return;
    }
    _lastAll = all;
    _lastGroups = groups;
    _lastFilter = _filter;
    _lastSort = sort;
    _lastQuery = _query;
    _lastDay = today;
    _lastLocale = context.l10n.localeName;
    _groupsById = {for (final g in groups) g.id: g};
    final q = _query.toLowerCase();
    final filter = _filter;
    final inGroup = filter == null ? null : groupWithChildren(groups, filter);
    final filtered = q.isEmpty && inGroup == null
        ? all
        : [
            for (final n in all)
              if ((inGroup == null || inGroup.contains(n.groupId)) && (q.isEmpty || _haystack(n).contains(q))) n,
          ];
    // watchNotes orders by createdAt DESC, so oldest-first is that list
    // reversed (ties mirror the newest order, as the former sort did).
    final notes = sort == NotesSort.newest ? filtered : filtered.reversed.toList();
    if (_haystacks.length > all.length * 2) {
      final live = {for (final n in all) n.id};
      _haystacks.removeWhere((id, _) => !live.contains(id));
    }
    // Group by calendar day; one header per day.
    final rows = <_Row>[];
    DateTime? day;
    for (final n in notes) {
      final d = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      if (d != day) {
        day = d;
        rows.add(_Row.header(Fmt.dayHeader(context.l10n, d, now: now)));
      }
      rows.add(_Row.note(n));
    }
    _rows = rows;
    _rowOf = {for (var i = 0; i < rows.length; i++) ?rows[i].note?.id: i};
    _matchCount = notes.length;
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(selectedProjectProvider);
    // Another project: its own filter, and no selection carried over.
    ref.listen(selectedProjectProvider, (previous, next) {
      if (previous?.id == next?.id) return;
      setState(() {
        _filter = null;
        _selection = null;
      });
    });
    final sort = ref.watch(notesSortProvider);
    final notesAsync = ref.watch(selectedNotesProvider);
    final all = notesAsync.value ?? const <Note>[];
    final groupsAsync = project == null
        ? const AsyncData(<NoteGroup>[])
        : ref.watch(groupsOfProjectProvider(project.id));
    final groups = groupsAsync.value ?? const <NoteGroup>[];
    // The filtered group was deleted: back to all notes.
    if (_filter != null && groupsAsync.hasValue && !groups.any((g) => g.id == _filter)) _filter = null;
    _rebuildRows(all, groups, sort);
    if (notesAsync.hasValue) _keepVisible(_rowOf);
    final rows = _rows;
    final selection = _selection;

    return PopScope(
      // Back ends a selection first and stays on the screen.
      canPop: selection == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _endSelection();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (selection == null)
            ProjectHeader(title: context.l10n.notesTitle)
          else
            SelectionHeader(count: selection.length, onClose: _endSelection),
          if (all.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(FikraSpace.screen, 0, FikraSpace.screen, 8),
              child: Row(
                children: [
                  Expanded(
                    child: FikraField(
                      key: const ValueKey('notes-search'),
                      controller: _search,
                      hint: context.l10n.searchNotesHint,
                      icon: Icons.search_rounded,
                      textInputAction: TextInputAction.search,
                      clearable: true,
                      clearButtonKey: const ValueKey('notes-search-clear'),
                      onChanged: _onSearch,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FikraIconButton(
                    key: const ValueKey('notes-sort'),
                    icon: Icons.tune_rounded,
                    label: context.l10n.notesSort,
                    size: FikraSpace.field,
                    onTap: () => _showSortSheet(context, sort),
                  ),
                ],
              ),
            ),
          if (groups.isNotEmpty)
            GroupFilterRow(
              groups: groups,
              selectedId: _filter,
              // Another filter starts with no selection.
              onSelect: (id) => setState(() {
                _filter = id;
                _selection = null;
              }),
              onOptions: (group) => showGroupOptions(context, ref, group),
            ),
          Expanded(
            child: FikraSwitcher(
              child: KeyedSubtree(
                key: ValueKey(
                  notesAsync.hasError && !notesAsync.hasValue
                      ? 'error'
                      : !notesAsync.hasValue
                      ? 'loading'
                      : all.isEmpty
                      ? 'empty'
                      : _matchCount == 0
                      ? (_query.isEmpty ? 'group-empty' : 'no-results')
                      : 'list',
                ),
                child: notesAsync.hasError && !notesAsync.hasValue
                    ? LoadErrorView(onRetry: () => ref.invalidate(selectedNotesProvider))
                    : !notesAsync.hasValue
                    ? const SizedBox.shrink()
                    : all.isEmpty
                    ? FillScroll(
                        child: EmptyState(
                          icon: Icons.sticky_note_2_outlined,
                          title: context.l10n.notesEmptyTitle,
                          description: context.l10n.notesEmptyBody,
                          action: FikraButton(
                            label: context.l10n.addFirstNote,
                            icon: Icons.add_rounded,
                            expand: false,
                            onPressed: () => context.go('/add'),
                          ),
                        ),
                      )
                    : _matchCount == 0
                    ? FillScroll(
                        child: _query.isEmpty
                            ? EmptyState(
                                icon: Icons.folder_copy_outlined,
                                title: context.l10n.groupEmptyTitle,
                                description: context.l10n.groupEmptyBody,
                              )
                            : EmptyState(
                                icon: Icons.search_off_rounded,
                                title: context.l10n.noResultsTitle,
                                description: context.l10n.noResultsBody(_query),
                              ),
                      )
                    // Built lazily: only the visible rows exist, whatever the size.
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(
                          FikraSpace.screen,
                          4,
                          FikraSpace.screen,
                          24 + NavigationInset.of(context),
                        ),
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        itemCount: rows.length,
                        findChildIndexCallback: (key) => key is ValueKey<String> ? _rowOf[key.value] : null,
                        itemBuilder: (context, i) {
                          final row = rows[i];
                          final n = row.note;
                          if (n == null) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 10, bottom: 10),
                              child: Text(
                                row.header!,
                                style: context.text.section.copyWith(color: context.colors.textSecondary),
                              ),
                            );
                          }
                          return Padding(
                            key: ValueKey(n.id),
                            padding: const EdgeInsets.only(bottom: 10),
                            child: NoteCard(
                              note: n,
                              group: _groupsById[n.groupId],
                              selected: selection?.contains(n.id),
                              onTap: selection != null
                                  ? () => _toggle(n.id)
                                  : () => context.push('/note/${n.id}', extra: n),
                              onLongPress: () => selection != null ? _toggle(n.id) : _startSelection(n.id),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
          if (selection != null) NavigationInsetPadding(child: _actionBar(context, selection.length)),
        ],
      ),
    );
  }
}

/// One list row: a day header or a note.
class _Row {
  const _Row.header(String this.header) : note = null;
  const _Row.note(Note this.note) : header = null;
  final String? header;
  final Note? note;
}
