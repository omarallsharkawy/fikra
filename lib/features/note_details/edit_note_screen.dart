import 'dart:async';

import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/attachment_draft.dart';
import '../../data/local/database.dart';
import '../../data/note_edit_merge.dart';
import '../shared/attachment_editor.dart';
import '../shared/note_presentation.dart';
import '../shared/transcription_notifications.dart';

class EditNoteScreen extends ConsumerStatefulWidget {
  const EditNoteScreen({super.key, required this.noteId});
  final String noteId;

  @override
  ConsumerState<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends ConsumerState<EditNoteScreen> with AttachmentEditing<EditNoteScreen> {
  TextEditingController? _title;
  TextEditingController? _text;
  String _initialTitle = '';
  String _initialText = '';
  NoteEditBasis? _basis;
  List<String>? _initialFiles;
  List<AttachmentDraft> _initialAttachments = [];
  bool _titleEdited = false;
  bool _allowPop = false;
  @override
  bool get confirmAttachmentRemoval => true;

  bool get _dirty {
    if (_title == null) return false;
    if (_title!.text != _initialTitle || _text!.text != _initialText) return true;
    final initial = _initialFiles ?? const <String>[];
    if (draftFiles.length != initial.length) return true;
    return draftFiles.indexed.any(
      (entry) =>
          (entry.$2.id ?? entry.$2.path) != initial[entry.$1] ||
          entry.$2.policy != _initialAttachments[entry.$1].policy,
    );
  }

  @override
  void dispose() {
    _title?.dispose();
    _text?.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (attachmentBusy || _initialFiles == null) return;
    if (_text!.text.trim().isEmpty && draftFiles.isEmpty) {
      showToast(context, context.l10n.emptyNoteBlocked);
      return;
    }
    var title = _title!.text;
    final text = _text!.text;
    final draft = List<AttachmentDraft>.of(draftFiles);
    if (text.trim().isEmpty && !_titleEdited && title == _initialTitle && draft.isNotEmpty) {
      final keptIds = draft.map((a) => a.id).toSet();
      final removed = _initialAttachments.where((a) => !keptIds.contains(a.id));
      if (removed.any((a) => attachmentTitle(context.l10n, a) == _initialTitle)) {
        title = attachmentTitle(context.l10n, draft.first);
      }
    }
    setState(() => saving = true);
    try {
      var transcriptionPaths = <String>[];
      await saveAttachmentDraft(
        ref.read(attachmentStoreProvider),
        transcriptionDraft(draft, automatic: await ref.read(settingsRepoProvider).readAutoTranscribe()),
        (stored) {
          transcriptionPaths = newTranscriptionPaths(stored);
          return ref
              .read(notesRepoProvider)
              .edit(widget.noteId, title: title, text: text, attachments: stored, basis: _basis);
        },
      );
      unawaited(
        ref.read(transcriptionQueueProvider).saved(widget.noteId, transcriptionPaths).catchError((_) {
          if (mounted) showToast(context, context.l10n.trQueueFailed);
        }),
      );
      await cleanDraftRecordings();
      if (!mounted) return;
      showToast(context, context.l10n.changesSaved);
      if (transcriptionPaths.isNotEmpty) unawaited(askTranscriptionNotificationsOnce(context, ref));
      _exit();
    } catch (_) {
      if (mounted) showToast(context, context.l10n.changesSaveFailed);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  /// Leaves the screen, bypassing the unsaved-changes guard.
  void _exit() {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.pop();
    });
  }

  /// Back or Cancel: ask before throwing away unsaved edits.
  Future<void> _requestLeave() async {
    if (attachmentBusy) return;
    if (!_dirty) return _exit();
    final choice = await showFikraSheet<_Leave>(
      context,
      title: context.l10n.unsavedTitle,
      builder: (sheet) => Column(
        children: [
          SheetOption(
            label: context.l10n.saveChanges,
            icon: Icons.check_rounded,
            onTap: () => Navigator.pop(sheet, _Leave.save),
          ),
          SheetOption(
            label: context.l10n.discardChanges,
            icon: Icons.close_rounded,
            danger: true,
            onTap: () => Navigator.pop(sheet, _Leave.discard),
          ),
          SheetOption(
            label: context.l10n.keepEditing,
            icon: Icons.edit_outlined,
            onTap: () => Navigator.pop(sheet, _Leave.stay),
          ),
        ],
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case _Leave.save:
        await _save();
      case _Leave.discard:
        _exit();
      case _Leave.stay || null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final noteAsync = ref.watch(noteProvider(widget.noteId));
    final files = ref.watch(noteAttachmentsProvider(widget.noteId));
    if (files.hasValue && _initialFiles == null) {
      draftFiles = files.requireValue.map(AttachmentDraft.saved).toList();
      _initialFiles = draftFiles.map((a) => a.id!).toList();
      _initialAttachments = List.of(draftFiles);
    }
    final note = noteAsync.value;
    if (note != null && files.hasValue && _title == null) {
      _initialTitle = note.title;
      _initialText = note.displayText;
      _basis = NoteEditBasis(note, List.of(files.requireValue));
      _title = TextEditingController(text: _initialTitle);
      _text = TextEditingController(text: _initialText);
    }

    return PopScope(
      canPop: _allowPop || _title == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestLeave();
      },
      child: FikraScaffold(
        child: noteAsync.hasError && !noteAsync.hasValue
            ? LoadErrorView(onRetry: () => ref.invalidate(noteProvider(widget.noteId)))
            : note == null || _title == null
            ? (noteAsync.hasValue
                  ? EmptyState(
                      icon: Icons.search_off_rounded,
                      title: context.l10n.noteNotFoundTitle,
                      description: context.l10n.noteNotFoundBody,
                    )
                  : const SizedBox.shrink())
            : ListView(
                padding: const EdgeInsets.fromLTRB(FikraSpace.screen, 14, FikraSpace.screen, 24),
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      context.l10n.editNoteTitle,
                      style: context.text.title.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FikraField(
                    controller: _title,
                    onChanged: (_) => setState(() => _titleEdited = true),
                    hint: context.l10n.titleHint,
                    icon: Icons.title_rounded,
                    maxLength: 80,
                  ),
                  const SizedBox(height: 12),
                  SolidSurface(
                    radius: FikraRadius.lg,
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
                    child: Semantics(
                      label: context.l10n.noteTextA11y,
                      child: TextField(
                        controller: _text,
                        readOnly: saving,
                        onChanged: (_) => setState(() {}),
                        minLines: 8,
                        maxLines: 20,
                        maxLength: 5000,
                        style: context.text.bodyLarge,
                        decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(context.l10n.originalKeptHint, style: context.text.meta.copyWith(fontSize: 12)),
                  const SizedBox(height: 12),
                  if (files.hasError && !files.hasValue)
                    FikraButton.secondary(
                      label: context.l10n.retry,
                      onPressed: () => ref.invalidate(noteAttachmentsProvider(widget.noteId)),
                    ),
                  permissionCard(),
                  if (recording) recordingPreview(),
                  attachmentPreviews(),
                  attachmentToolbar(
                    canSave: !attachmentBusy && _initialFiles != null,
                    onSave: _save,
                    enabled: _initialFiles != null,
                    showSave: false,
                  ),
                  const SizedBox(height: 22),
                  FikraButton(
                    label: context.l10n.saveChanges,
                    icon: Icons.check_rounded,
                    loading: saving,
                    onPressed: attachmentBusy || _initialFiles == null ? null : _save,
                  ),
                  const SizedBox(height: 10),
                  FikraButton.secondary(label: context.l10n.cancel, onPressed: attachmentBusy ? null : _requestLeave),
                ],
              ),
      ),
    );
  }
}

enum _Leave { save, discard, stay }
