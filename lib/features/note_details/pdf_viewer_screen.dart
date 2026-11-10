import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../app/providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/local/database.dart';
import '../../l10n/localizations.dart';
import '../shared/open_attachment.dart';
import 'pdf_document_provider.dart';

/// Only the note ID comes from navigation; file paths always come from storage.
class PdfViewerScreen extends ConsumerWidget {
  const PdfViewerScreen({super.key, required this.noteId});
  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final note = ref.watch(noteProvider(noteId));
    final path = note.value?.hasPdf == true ? note.value!.attachmentPath : null;
    return FikraScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                FikraIconButton(
                  icon: Icons.arrow_back_rounded,
                  label: context.l10n.back,
                  onTap: () => context.canPop() ? context.pop() : context.go('/notes'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    note.value?.attachmentName ?? context.l10n.pdfFile,
                    style: context.text.cardTitleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                FikraIconButton(
                  key: const ValueKey('pdf-open-elsewhere'),
                  icon: Icons.open_in_new_rounded,
                  label: context.l10n.pdfOpenElsewhere,
                  onTap: path == null ? null : () => openAttachment(context, ref, path),
                ),
              ],
            ),
          ),
          Expanded(
            child: note.isLoading && !note.hasValue && !note.hasError
                ? const Center(child: CircularProgressIndicator())
                : path == null
                ? LoadErrorView(
                    description: context.l10n.pdfLoadFailed,
                    onRetry: () => ref.invalidate(noteProvider(noteId)),
                  )
                : _Document(key: ValueKey(path), path: path),
          ),
        ],
      ),
    );
  }
}

class _Document extends ConsumerStatefulWidget {
  const _Document({super.key, required this.path});
  final String path;

  @override
  ConsumerState<_Document> createState() => _DocumentState();
}

class _DocumentState extends ConsumerState<_Document> {
  final _page = ValueNotifier<int>(1);

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final document = ref.watch(pdfDocumentProvider(widget.path));
    void retry() => ref.invalidate(pdfDocumentProvider(widget.path));
    if (document.hasError) {
      return LoadErrorView(description: context.l10n.pdfLoadFailed, onRetry: retry);
    }
    if (!document.hasValue) return const Center(child: CircularProgressIndicator());

    final loaded = document.requireValue;
    final chromeDirection = Directionality.of(context);
    return Stack(
      children: [
        // Treat PDF pages as a canvas. pdfrx's built-in page semantics contain
        // English labels; expose our localized page indicator instead.
        ExcludeSemantics(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: PdfViewer(
              // Riverpod owns disposal, including loads that finish after popping.
              PdfDocumentRefDirect(loaded, autoDispose: false),
              params: PdfViewerParams(
                backgroundColor: Colors.transparent,
                // Keep the default vertical continuous layout, pinch and double-tap zoom.
                maxImageBytesCachedOnMemory: 32 * 1024 * 1024,
                horizontalCacheExtent: 0,
                verticalCacheExtent: 1,
                textSelectionParams: const PdfTextSelectionParams(enabled: false),
                onPageChanged: (page) {
                  if (mounted) _page.value = page ?? 1;
                },
                loadingBannerBuilder: (_, _, _) => const Center(child: CircularProgressIndicator()),
                errorBannerBuilder: (_, _, _, _) => Directionality(
                  textDirection: chromeDirection,
                  child: LoadErrorView(description: context.l10n.pdfLoadFailed, onRetry: retry),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 12,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Center(
              child: Glass(
                radius: FikraRadius.full,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: context.colors.glass,
                child: ValueListenableBuilder<int>(
                  valueListenable: _page,
                  builder: (context, page, _) =>
                      Text(context.l10n.pdfPageOf(page, loaded.pages.length), style: context.text.meta),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
