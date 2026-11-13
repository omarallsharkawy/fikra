import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../core/motion/pressable.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../core/widgets/photo_thumb.dart';
import '../../core/widgets/voice_player.dart';
import '../../data/links_repository.dart';
import '../../data/local/database.dart';
import '../shared/link_picker.dart';
import '../shared/note_links.dart';
import '../shared/note_presentation.dart';
import '../shared/open_attachment.dart';

part 'note_details_body.dart';
part 'note_details_cards.dart';
part 'note_link_actions.dart';
part 'note_link_row.dart';
part 'note_links_section.dart';

/// One note: content (improved / original), AI proposal, attachments,
/// topics and links. Data is scoped to the note's own project, so
/// it works even when that isn't the selected project.
class NoteDetailsScreen extends ConsumerStatefulWidget {
  const NoteDetailsScreen({super.key, required this.noteId, this.initial});
  final String noteId;

  /// The note as the caller last saw it. Shown until the live query's first
  /// result, which replaces it without a transition.
  final Note? initial;

  @override
  ConsumerState<NoteDetailsScreen> createState() => _NoteDetailsScreenState();
}

const _improvedView = 0, _originalView = 1;

class _NoteDetailsScreenState extends ConsumerState<NoteDetailsScreen> {
  int _view = _improvedView;

  Future<void> _showOptions(Note note) {
    final repo = ref.read(notesRepoProvider);
    return showFikraSheet<void>(
      context,
      title: context.l10n.noteOptions,
      builder: (sheet) => Column(
        children: [
          SheetOption(
            label: context.l10n.edit,
            icon: Icons.edit_outlined,
            onTap: () {
              Navigator.pop(sheet);
              context.push('/note/${note.id}/edit');
            },
          ),
          if (note.hasImprovedVersion)
            SheetOption(
              label: context.l10n.restoreOriginal,
              icon: Icons.restore_rounded,
              onTap: () async {
                Navigator.pop(sheet);
                await runAction(context, () => repo.restoreOriginal(note.id), success: context.l10n.originalRestored);
              },
            ),
          SheetOption(
            label: context.l10n.deleteNote,
            icon: Icons.delete_outline_rounded,
            danger: true,
            onTap: () async {
              final ok = await confirmDestructive(
                sheet,
                title: context.l10n.deleteNoteTitle,
                message: context.l10n.deleteNoteBody,
              );
              if (!ok || !sheet.mounted) return;
              Navigator.pop(sheet);
              if (!mounted) return;
              final deleted = await runAction(context, () => repo.delete(note.id), success: context.l10n.noteDeleted);
              if (deleted && mounted) context.pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(noteProvider(widget.noteId));
    final noteAsync = live.hasValue || live.hasError || widget.initial == null
        ? live
        : AsyncData<Note?>(widget.initial);
    final note = noteAsync.value;

    return FikraScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                FikraIconButton(icon: Icons.arrow_back_rounded, label: context.l10n.back, onTap: () => context.pop()),
                const Spacer(),
                if (note != null)
                  FikraIconButton(
                    icon: Icons.more_horiz_rounded,
                    label: context.l10n.options,
                    onTap: () => _showOptions(note),
                  ),
              ],
            ),
          ),
          Expanded(
            child: AsyncBody<Note?>(
              value: noteAsync,
              onRetry: () => ref.invalidate(noteProvider(widget.noteId)),
              data: (note) => note == null
                  ? EmptyState(
                      icon: Icons.search_off_rounded,
                      title: context.l10n.noteNotFoundTitle,
                      description: context.l10n.noteNotFoundBody,
                    )
                  : _Body(note: note, view: _view, onView: (v) => setState(() => _view = v)),
            ),
          ),
        ],
      ),
    );
  }
}
