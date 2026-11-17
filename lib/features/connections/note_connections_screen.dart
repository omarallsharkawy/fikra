import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/motion/pressable.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/local/database.dart';
import '../../l10n/localizations.dart';
import '../shared/link_picker.dart';
import '../shared/note_groups.dart';
import '../shared/note_link_actions.dart';
import '../shared/note_links.dart';
import 'connection_link_card.dart';
import 'library_cards.dart';
import 'links_index.dart';
import 'links_library_provider.dart';
import 'suggestion_sliver.dart';

class NoteConnectionsScreen extends ConsumerStatefulWidget {
  const NoteConnectionsScreen({super.key, required this.noteId});
  final String noteId;

  @override
  ConsumerState<NoteConnectionsScreen> createState() => _NoteConnectionsScreenState();
}

class _NoteConnectionsScreenState extends ConsumerState<NoteConnectionsScreen> {
  late final _projectId = ref.read(selectedProjectProvider)?.id;
  bool _away = false;
  final _busy = <String>{};

  // Memoized by source identity, so a rebuild never re-maps 5,000 notes.
  List<Note>? _notesSeen;
  Map<String, Note> _notesById = const {};
  (String, List<NoteLink>, Map<String, Note>)? _confirmedSeen;
  List<NoteLinkEntry> _confirmed = const [];
  (LinksIndex, List<NoteLinkEntry>)? _suggestionsSeen;
  List<SuggestionEntry> _suggestions = const [];

  List<NoteLinkEntry> _confirmedOf(String noteId, List<NoteLink> links, List<Note> notes) {
    if (!identical(notes, _notesSeen)) {
      _notesSeen = notes;
      _notesById = {for (final n in notes) n.id: n};
    }
    final seen = _confirmedSeen;
    if (seen == null || seen.$1 != noteId || !identical(seen.$2, links) || !identical(seen.$3, _notesById)) {
      _confirmedSeen = (noteId, links, _notesById);
      _confirmed = linksOfNote(noteId, links, _notesById).where((e) => e.link.origin == LinkOrigin.user).toList();
    }
    return _confirmed;
  }

  /// The links stream can confirm a pair before the derived index drops its
  /// suggestion; a confirmed pair never shows under both headings.
  List<SuggestionEntry> _suggestionsOf(LinksIndex index, List<NoteLinkEntry> confirmed) {
    final seen = _suggestionsSeen;
    if (seen == null || !identical(seen.$1, index) || !identical(seen.$2, confirmed)) {
      _suggestionsSeen = (index, confirmed);
      final linked = {for (final e in confirmed) e.other.id};
      _suggestions = [
        for (final s in index.suggestions)
          if ((s.a.id == widget.noteId && !linked.contains(s.b.id)) ||
              (s.b.id == widget.noteId && !linked.contains(s.a.id)))
            s,
      ];
    }
    return _suggestions;
  }

  Future<void> _leave(Future<void> Function() action) async {
    if (_away || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
    _away = true;
    try {
      await action();
    } finally {
      _away = false;
    }
  }

  void _options(NoteLinkEntry entry) {
    final pair = pairKey(widget.noteId, entry.other.id);
    if (_busy.contains(pair)) return;
    final repo = ref.read(linksRepoProvider);
    _leave(
      () => showLinkOptions(
        context,
        entry,
        remove: (sheet) async {
          if (!_busy.add(pair)) return;
          try {
            await runAction(
              sheet,
              () => repo.removeLink(entry.link.id),
              success: sheet.l10n.linkRemoved,
              failure: sheet.l10n.linkUpdateFailed,
            );
          } finally {
            _busy.remove(pair);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(noteProvider(widget.noteId));
    final project = ref.watch(selectedProjectProvider)?.id;
    final note = live.value;
    final invalid = live.hasValue && (note == null || note.projectId != _projectId || project != _projectId);
    if (invalid && (ModalRoute.isCurrentOf(context) ?? false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) context.pop();
      });
    }
    final source = _projectId == null ? null : ref.watch(linksLibraryProvider(_projectId));
    final links = _projectId == null ? null : ref.watch(linksOfProjectProvider(_projectId));
    final notes = _projectId == null ? null : ref.watch(notesOfProjectProvider(_projectId));
    final index = source?.value;
    final confirmed = note == null
        ? <NoteLinkEntry>[]
        : _confirmedOf(note.id, links?.value ?? const [], notes?.value ?? const []);
    final suggestions = index == null ? <SuggestionEntry>[] : _suggestionsOf(index, confirmed);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            BackButton(onPressed: () => context.pop()),
            Expanded(child: Text(context.l10n.linksTitle, style: context.text.title)),
          ],
        ),
        Expanded(
          child: live.hasError || (source?.hasError ?? false)
              ? LoadErrorView(
                  onRetry: () {
                    ref.invalidate(noteProvider(widget.noteId));
                    if (_projectId != null) {
                      ref.invalidate(notesOfProjectProvider(_projectId));
                      ref.invalidate(linksOfProjectProvider(_projectId));
                      ref.invalidate(groupsOfProjectProvider(_projectId));
                    }
                  },
                )
              : note == null || index == null || invalid
              ? const SizedBox.shrink()
              : CustomScrollView(
                  key: const ValueKey('connections-list'),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(FikraSpace.screen),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Pressable(
                              key: const ValueKey('connections-note'),
                              onTap: () => _leave(() => context.push('/note/${note.id}', extra: note)),
                              child: SolidSurface(child: LibraryNoteText(note: projectNote(note), lines: 2)),
                            ),
                            const SizedBox(height: 12),
                            FikraButton.secondary(
                              key: const ValueKey('connections-link-picker'),
                              label: context.l10n.linkToNote,
                              growForText: true,
                              icon: Icons.add_link_rounded,
                              onPressed: () => _leave(() => showLinkPicker(context, source: note)),
                            ),
                            const SizedBox(height: 24),
                            Semantics(
                              header: true,
                              child: Text(context.l10n.linksConfirmed, style: context.text.section),
                            ),
                            const SizedBox(height: 10),
                            if (confirmed.isEmpty) Text(context.l10n.noteLinksEmpty, style: context.text.caption),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: FikraSpace.screen),
                      sliver: SliverList.builder(
                        itemCount: confirmed.length,
                        itemBuilder: (_, i) => ConnectionLinkCard(
                          key: ValueKey('connection-${confirmed[i].other.id}'),
                          entry: confirmed[i],
                          onOptions: () => _options(confirmed[i]),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(FikraSpace.screen),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(context.l10n.linksSuggestions, style: context.text.section),
                            ),
                            if (suggestions.isEmpty)
                              Text(context.l10n.linksSuggestionsEmpty, style: context.text.caption),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: FikraSpace.screen),
                      sliver: SuggestionSliver(entries: suggestions, here: widget.noteId),
                    ),
                    const SliverToBoxAdapter(child: NavigationInsetSpacer(extra: 24)),
                  ],
                ),
        ),
      ],
    );
  }
}
