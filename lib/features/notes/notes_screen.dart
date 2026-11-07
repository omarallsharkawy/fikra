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
import 'note_card.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final _search = TextEditingController();
  String _query = '';
  Timer? _debounce;

  // Lower-cased search text per note, rebuilt only when the note changes, so
  // a keystroke doesn't re-lowercase thousands of notes.
  final _haystacks = <String, (String, String, String, String)>{};

  // The filtered + grouped list, recomputed only when the notes or the query
  // change (not on every rebuild).
  List<Note>? _lastAll;
  String? _lastQuery;
  DateTime? _lastDay;
  List<_Row> _rows = const [];
  Map<String, int> _rowOf = const {};
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

  void _rebuildRows(List<Note> all) {
    // Day headers are relative ("النهارده"), so a new calendar day rebuilds too.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (identical(all, _lastAll) && _query == _lastQuery && today == _lastDay) return;
    _lastAll = all;
    _lastQuery = _query;
    _lastDay = today;
    final q = _query.toLowerCase();
    final notes = q.isEmpty
        ? all
        : [
            for (final n in all)
              if (_haystack(n).contains(q)) n,
          ];
    if (_haystacks.length > all.length * 2) {
      final live = {for (final n in all) n.id};
      _haystacks.removeWhere((id, _) => !live.contains(id));
    }
    // Group by calendar day (list is newest first); one header per day.
    final rows = <_Row>[];
    DateTime? day;
    for (final n in notes) {
      final d = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      if (d != day) {
        day = d;
        rows.add(_Row.header(Fmt.dayHeader(d)));
      }
      rows.add(_Row.note(n));
    }
    _rows = rows;
    _rowOf = {for (var i = 0; i < rows.length; i++) ?rows[i].note?.id: i};
    _matchCount = notes.length;
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(selectedNotesProvider);
    final all = notesAsync.value ?? const <Note>[];
    _rebuildRows(all);
    final rows = _rows;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProjectHeader(title: 'النوتس'),
        if (all.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(FikraSpace.screen, 0, FikraSpace.screen, 8),
            child: FikraField(
              controller: _search,
              hint: 'دوّر في النوتس',
              icon: Icons.search_rounded,
              textInputAction: TextInputAction.search,
              onChanged: _onSearch,
            ),
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
                    ? 'no-results'
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
                        title: 'لسه مفيش نوتس',
                        description: 'اكتب فكرة أو سجّل صوت أو ارفع PDF، وفِكرة هتنظمها وتربطها لوحدها.',
                        action: FikraButton(
                          label: 'ضيف أول نوت',
                          icon: Icons.add_rounded,
                          expand: false,
                          onPressed: () => context.go('/add'),
                        ),
                      ),
                    )
                  : _matchCount == 0
                  ? FillScroll(
                      child: EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'مفيش نتايج',
                        description: 'مفيش نوت فيها «$_query». جرّب كلمة تانية.',
                      ),
                    )
                  // Built lazily: only the visible rows exist, whatever the size.
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(FikraSpace.screen, 4, FikraSpace.screen, 24),
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
                          child: NoteCard(note: n, onTap: () => context.push('/note/${n.id}')),
                        );
                      },
                    ),
            ),
          ),
        ),
      ],
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
