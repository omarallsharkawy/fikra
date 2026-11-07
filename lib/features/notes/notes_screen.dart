import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
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

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(Note n) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return n.title.toLowerCase().contains(q) ||
        n.displayText.toLowerCase().contains(q) ||
        n.concepts.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(selectedNotesProvider);
    final all = notesAsync.value ?? const <Note>[];
    final notes = all.where(_matches).toList();

    // Group by calendar day, newest first (list already sorted desc).
    final groups = <String, List<Note>>{};
    for (final n in notes) {
      groups.putIfAbsent(Fmt.dayHeader(n.createdAt), () => []).add(n);
    }

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
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
        Expanded(
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
              : notes.isEmpty
              ? FillScroll(
                  child: EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'مفيش نتايج',
                    description: 'مفيش نوت فيها «$_query». جرّب كلمة تانية.',
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(FikraSpace.screen, 4, FikraSpace.screen, 24),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    for (final e in groups.entries) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 10),
                        child: Text(e.key, style: context.text.section.copyWith(color: context.colors.textSecondary)),
                      ),
                      for (final n in e.value)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: NoteCard(note: n, onTap: () => context.push('/note/${n.id}')),
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
