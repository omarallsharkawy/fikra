import 'dart:async';

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
import 'voice_transcript.dart';
import '../shared/link_picker.dart';
import '../shared/move_confirm.dart';
import '../shared/note_links.dart';
import '../shared/note_link_actions.dart';
import '../shared/note_presentation.dart';
import '../shared/open_attachment.dart';
import '../shared/project_picker.dart';

part 'note_details_body.dart';
part 'note_details_cards.dart';
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

/// The move confirmation: the files go along; links to notes left behind are
/// counted, and counts at zero are left out.
@visibleForTesting
String moveNoteMessage(AppLocalizations l10n, MoveImpact impact) => moveMessage(l10n, impact);

class _NoteDetailsScreenState extends ConsumerState<NoteDetailsScreen> {
  int _view = _improvedView;

  /// A move is between its picker and its result; a second one can't start,
  /// and the options (so Edit) stay shut until it ends.
  bool _moving = false;

  Future<void> _showOptions(Note note) async {
    if (_moving) return;
    final repo = ref.read(notesRepoProvider);
    // Hidden, like "restore original", when there is nowhere to move to.
    final canMove = (ref.read(projectsProvider).value ?? const []).any((p) => p.project.id != note.projectId);
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
          if (canMove)
            SheetOption(
              key: const ValueKey('note-move'),
              label: context.l10n.moveToProject,
              icon: Icons.drive_file_move_outline,
              onTap: () {
                // Close this sheet, then open the picker from the page.
                Navigator.pop(sheet);
                _move(note);
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

  /// Picks another project, says what the move loses, then moves the note,
  /// re-links it there in the background and leaves for the notes list. Any
  /// failure (the target deleted meanwhile, too) keeps the page as it was.
  Future<void> _move(Note note) async {
    if (_moving) return;
    _moving = true;
    try {
      final l10n = context.l10n;
      final target = await showProjectPicker(
        context,
        title: l10n.moveToProject,
        excludeProjectId: note.projectId,
        empty: l10n.moveNoOtherProject,
      );
      if (target == null || !mounted) return;
      final repo = ref.read(notesRepoProvider);
      final processor = ref.read(noteProcessorProvider);
      final route = ModalRoute.of(context);
      // Asks again if the numbers change while the dialog is open.
      final confirmed = await confirmMove(
        context,
        impact: () => repo.moveImpact([note.id], target.id),
        title: l10n.moveNoteTitle(Fmt.isolate(target.name)),
        message: (impact) => moveNoteMessage(l10n, impact),
        failure: l10n.moveNoteFailed,
      );
      if (!confirmed || !mounted) return;
      var moved = const <String>[];
      final done = await runAction(
        context,
        () async => moved = await repo.moveNotes([note.id], target.id),
        failure: l10n.moveNoteFailed,
      );
      // Nothing moved: the note was deleted meanwhile and the page says so.
      if (!done || moved.isEmpty) return;
      unawaited(processor.relink(moved));
      if (!mounted) return;
      showToast(context, l10n.noteMoved(Fmt.isolate(target.name)));
      // Only from this page: a page opened on top of it (another note, its
      // editor) stays, so nothing unsaved is thrown away.
      if (route?.isCurrent ?? false) context.go('/notes');
    } finally {
      _moving = false;
    }
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
