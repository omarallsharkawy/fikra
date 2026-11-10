part of 'add_screen.dart';

/// Save: persist the attachments, create the note, queue analysis.
extension _AddSave on _AddScreenState {
  Future<void> _save() async {
    final project = ref.read(selectedProjectProvider);
    if (project == null || !_canSave) return;
    final store = ref.read(attachmentStoreProvider);
    // Snapshot the draft: nothing below reads mutable state after an await.
    final title = _title.text;
    final text = _text.text;
    final pdf = _pdf;
    final pdfBytes = _pdfBytes;
    final voicePath = _voicePath;
    final voiceMs = _voiceMs;
    final images = _images;
    _set(() => _saving = true);

    // A PDF, a recording and photos can share one note; all are copied in first.
    final stored = <String>[];
    try {
      String? pdfPath;
      String? voiceStored;
      if (pdf != null) {
        pdfPath = await store.persist(pdf.path!, extension: 'pdf');
        stored.add(pdfPath);
      }
      if (voicePath != null) {
        voiceStored = await store.persist(voicePath, extension: 'm4a');
        stored.add(voiceStored);
      }
      final imagePaths = <String>[];
      for (final image in images) {
        final path = await store.persist(image.path!, extension: AttachmentStore.imageExtension(image.name));
        stored.add(path);
        imagePaths.add(path);
      }
      final source = pdf != null
          ? NoteSource.pdf
          : voicePath != null
          ? NoteSource.voice
          : NoteSource.text;
      final note = await ref
          .read(notesRepoProvider)
          .create(
            projectId: project.id,
            title: text.trim().isEmpty && title.trim().isEmpty ? _fileOnlyTitle(pdf, voiceStored) : title,
            text: text,
            source: source,
            attachmentPath: pdfPath,
            attachmentName: pdf?.name,
            attachmentBytes: pdf != null ? pdfBytes : null,
            voicePath: voiceStored,
            durationMs: voiceStored != null ? voiceMs : null,
            imagePaths: imagePaths,
          );
      // Saved: only now is it safe to drop the temporary recording.
      if (voicePath != null) await AttachmentStore.deleteQuietly([voicePath]);
      await store.clearPickerCopies();
      unawaited(ref.read(noteProcessorProvider).process(note));
      if (!mounted) return;
      _title.clear();
      _text.clear();
      _set(() {
        _voicePath = null;
        _voiceMs = null;
        _pdf = null;
        _images = const [];
      });
      showToast(context, text.trim().isEmpty ? 'اتحفظت' : 'اتحفظت. فِكرة بتحللها دلوقتي');
      context.go('/notes');
    } catch (_) {
      await AttachmentStore.deleteQuietly(stored);
      if (mounted) showToast(context, 'معرفناش نحفظ النوت، جرّب تاني');
    } finally {
      _set(() => _saving = false);
    }
  }

  /// Nothing typed means no analysis, so no AI title will ever come.
  String _fileOnlyTitle(PlatformFile? pdf, String? voice) {
    if (pdf != null) return p.basenameWithoutExtension(pdf.name);
    return voice != null ? 'تسجيل صوتي' : 'صور';
  }
}
