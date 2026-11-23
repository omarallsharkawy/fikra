part of 'attachment_editor.dart';

class _PdfChip extends StatelessWidget {
  const _PdfChip({required this.name, required this.bytes, required this.onRemove});
  final String name;
  final int bytes;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return SolidSurface(
      radius: FikraRadius.md,
      color: context.colors.chip,
      padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 12, 8),
      child: Row(
        children: [
          Icon(Icons.picture_as_pdf_outlined, color: context.colors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: context.text.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  Fmt.bytes(context.l10n, bytes),
                  textDirection: TextDirection.ltr,
                  style: context.text.meta.copyWith(color: context.colors.textSecondary),
                ),
              ],
            ),
          ),
          Pressable(
            onTap: onRemove,
            minTarget: true,
            semanticLabel: context.l10n.removeFile,
            child: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.close_rounded)),
          ),
        ],
      ),
    );
  }
}

class _ImageStrip extends StatelessWidget {
  const _ImageStrip({required this.images, required this.onRemove});
  final List<AttachmentDraft> images;
  final ValueChanged<AttachmentDraft>? onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final image = images[i];
          return SizedBox(
            key: ObjectKey(image),
            width: 84,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PhotoThumb(path: image.path),
                PositionedDirectional(
                  top: 0,
                  end: 0,
                  child: Pressable(
                    onTap: onRemove == null ? null : () => onRemove!(image),
                    minTarget: true,
                    semanticLabel: context.l10n.removePhoto(i + 1),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(color: context.colors.chip, shape: BoxShape.circle),
                      child: Icon(Icons.close_rounded, size: 16, color: context.colors.textPrimary),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
