part of 'attachment_editor.dart';

extension AttachmentFiles<T extends ConsumerStatefulWidget> on AttachmentEditing<T> {
  Future<void> pickPdf() => _pickFiles(AttachmentKind.pdf);
  Future<void> pickImages() => _pickFiles(AttachmentKind.image);

  Future<void> _pickFiles(AttachmentKind kind) async {
    if (attachmentBusy) return;
    updateDraft(() => picking = true);
    FocusScope.of(context).unfocus();
    try {
      final picked = await FilePicker.pickFiles(
        type: kind == AttachmentKind.pdf ? FileType.custom : FileType.image,
        allowedExtensions: kind == AttachmentKind.pdf ? const ['pdf'] : null,
      );
      final additions = <AttachmentDraft>[];
      for (final f in picked) {
        if (f.path == null) continue;
        if (kind == AttachmentKind.pdf && p.extension(f.name).toLowerCase() != '.pdf') {
          if (mounted) showToast(context, context.l10n.pdfOnly);
          continue;
        }
        additions.add(AttachmentDraft(kind: kind, path: f.path!, name: f.name, bytes: await File(f.path!).length()));
      }
      updateDraft(() => draftFiles = [...draftFiles, ...additions]);
    } catch (_) {
      if (mounted) {
        showToast(context, kind == AttachmentKind.pdf ? context.l10n.fileOpenFailed : context.l10n.photosOpenFailed);
      }
    } finally {
      updateDraft(() => picking = false);
    }
  }
}
