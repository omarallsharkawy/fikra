part of 'add_screen.dart';

extension _AddSave on _AddScreenState {
  Future<void> _save() async {
    final project = ref.read(selectedProjectProvider);
    if (project == null || !_canSave) return;
    final store = ref.read(attachmentStoreProvider);
    final title = _title.text;
    final text = _text.text;
    final draft = List<AttachmentDraft>.of(draftFiles);
    final fileOnlyTitle = draft.isEmpty ? '' : attachmentTitle(context.l10n, draft.first);
    final source = draft.any((a) => a.kind == AttachmentKind.pdf)
        ? NoteSource.pdf
        : draft.any((a) => a.kind == AttachmentKind.voice)
        ? NoteSource.voice
        : NoteSource.text;
    _set(() => saving = true);
    try {
      var transcriptionPaths = <String>[];
      final note = await saveAttachmentDraft(
        store,
        transcriptionDraft(draft, automatic: await ref.read(settingsRepoProvider).readAutoTranscribe()),
        (stored) {
          transcriptionPaths = newTranscriptionPaths(stored);
          return ref
              .read(notesRepoProvider)
              .create(
                projectId: project.id,
                title: text.trim().isEmpty && title.trim().isEmpty ? fileOnlyTitle : title,
                text: text,
                source: source,
                attachments: stored,
              );
        },
      );
      unawaited(
        ref.read(transcriptionQueueProvider).saved(note.id, transcriptionPaths).catchError((_) {
          if (mounted) showToast(context, context.l10n.trQueueFailed);
        }),
      );
      // No operation after commit is allowed to roll back committed files.
      await cleanDraftRecordings();
      await store.clearPickerCopies();
      unawaited(ref.read(noteProcessorProvider).process(note));
      if (!mounted) return;
      _title.clear();
      _text.clear();
      _set(() => draftFiles = []);
      showToast(context, text.trim().isEmpty ? context.l10n.noteSaved : context.l10n.noteSavedAnalyzing);
      context.go('/notes');
    } catch (_) {
      if (mounted) showToast(context, context.l10n.noteSaveFailed);
    } finally {
      _set(() => saving = false);
    }
  }
}
