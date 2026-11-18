import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/motion/container_transform.dart';
import '../../core/motion/pressable.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../core/widgets/pearl_canvas.dart';
import '../../l10n/localizations.dart';
import '../shared/link_picker.dart';
import '../shared/note_groups.dart';
import '../shared/note_link_actions.dart';
import '../shared/note_links.dart';
import 'connection_link_card.dart';
import 'connections_placeholder.dart';
import 'note_connections_provider.dart';
import 'links_index.dart';
import 'links_library_provider.dart';
import 'suggestion_sliver.dart';

class NoteConnectionsScreen extends ConsumerStatefulWidget {
  const NoteConnectionsScreen({super.key, required this.noteId, this.initial});
  final String noteId;
  final LibraryNote? initial;

  @override
  ConsumerState<NoteConnectionsScreen> createState() => _NoteConnectionsScreenState();
}

class _NoteConnectionsScreenState extends ConsumerState<NoteConnectionsScreen> {
  late final _projectId = ref.read(selectedProjectProvider)?.id;
  bool _away = false;
  final _busy = <String>{};

  Animation<double>? _entrance;
  bool _entered = false;
  bool _captured = false;
  NoteConnections? _entryData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animation = ModalRoute.of(context)?.animation;
    if (!identical(animation, _entrance)) {
      _entrance?.removeStatusListener(_onStatus);
      _entrance = animation;
      animation?.addStatusListener(_onStatus);
      if (animation?.isCompleted ?? false) {
        // A newly built route can report completed before didPush starts it.
        // Only latch an already-completed entrance after that first frame.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && identical(animation, _entrance) && animation!.isCompleted) {
            _onStatus(AnimationStatus.completed);
          }
        });
      }
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_entered) setState(() => _entered = true);
  }

  @override
  void dispose() {
    _entrance?.removeStatusListener(_onStatus);
    super.dispose();
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
    final source = ref.watch(noteConnectionsProvider(widget.noteId));
    if (!_captured) {
      _captured = true;
      _entryData = note == null ? null : source.value;
    }
    // Freeze only the initial push. Once entered, keep live data through Back
    // and any later route animation instead of restoring the entry snapshot.
    final data = _entered || _entrance == null ? source.value : _entryData;
    final loading = note == null || data == null || invalid;
    final preview = note != null
        ? projectNote(note)
        : widget.initial?.id == widget.noteId
        ? widget.initial
        : null;
    final confirmed = data?.confirmed ?? const <NoteLinkEntry>[];
    final suggestions = data?.suggestions ?? const <SuggestionEntry>[];
    return PearlCanvas(
      key: const ValueKey('connections-page'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              BackButton(onPressed: () => context.pop()),
              Expanded(
                child: Semantics(header: true, child: Text(context.l10n.linksTitle, style: context.text.title)),
              ),
            ],
          ),
          Expanded(
            child: live.hasError || source.hasError
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
                : CustomScrollView(
                    key: ValueKey(loading ? 'connections-placeholder' : 'connections-list'),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(FikraSpace.screen),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Builder(
                                builder: (cardContext) => Pressable(
                                  key: const ValueKey('connections-note'),
                                  onTap: note == null
                                      ? null
                                      : () => _leave(
                                          () => context.push(
                                            '/note/${note.id}',
                                            extra: (
                                              note,
                                              CardOrigin.fromContext(cardContext, borderRadius: FikraRadius.md),
                                            ),
                                          ),
                                        ),
                                  child: ConnectionsNoteHeader(note: preview),
                                ),
                              ),
                              const SizedBox(height: 12),
                              FikraButton.secondary(
                                key: const ValueKey('connections-link-picker'),
                                label: context.l10n.linkToNote,
                                growForText: true,
                                icon: Icons.add_link_rounded,
                                onPressed: note == null
                                    ? null
                                    : () => _leave(() => showLinkPicker(context, source: note)),
                              ),
                              const SizedBox(height: 24),
                              Semantics(
                                header: true,
                                child: Text(context.l10n.linksConfirmed, style: context.text.section),
                              ),
                              const SizedBox(height: 10),
                              if (!loading && confirmed.isEmpty)
                                Text(context.l10n.noteLinksEmpty, style: context.text.caption),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: FikraSpace.screen),
                        sliver: loading
                            ? const SliverToBoxAdapter(child: ConnectionsSectionPlaceholder())
                            : SliverList.builder(
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
                              if (!loading && suggestions.isEmpty)
                                Text(context.l10n.linksSuggestionsEmpty, style: context.text.caption),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: FikraSpace.screen),
                        sliver: loading
                            ? const SliverToBoxAdapter(child: ConnectionsSectionPlaceholder())
                            : SuggestionSliver(entries: suggestions, here: widget.noteId),
                      ),
                      const SliverToBoxAdapter(child: NavigationInsetSpacer(extra: 24)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
