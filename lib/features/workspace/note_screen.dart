import '../../l10n/localizations.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/product_runtime.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/product/models.dart';
import 'product_widgets.dart';

class ProductNoteScreen extends ConsumerStatefulWidget {
  const ProductNoteScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<ProductNoteScreen> createState() => _ProductNoteScreenState();
}

class _ProductNoteScreenState extends ConsumerState<ProductNoteScreen> {
  bool _editing = false;
  String _title = '', _content = '';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(productRuntimeProvider).workspace.openNote(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) => ProductView(
    builder: (context, r) {
      final w = r.workspace, n = r.workspace.detail;
      return ProductScaffold(
        title: context.l10n.productNote,
        back: true,
        footer: _editing && n != null && n.id == widget.id && !w.detailLoading
            ? FikraButton(
                label: context.l10n.productSaveEdit,
                loading: w.busy,
                onPressed: () async {
                  final ok = await w.edit(
                    NotePatch(
                      content: _content.trim(),
                      title: _title.trim().isEmpty ? null : _title.trim(),
                      includesTitle: true,
                    ),
                  );
                  if (ok && mounted) setState(() => _editing = false);
                },
              )
            : null,
        children: [
          if (w.detailLoading) const Center(child: CircularProgressIndicator()),
          if (w.detailFailure != null) ProductFailureView(w.detailFailure!, onRetry: () => w.openNote(widget.id)),
          if (w.proposalConflict) Text(context.l10n.productTheCurrentProposalWasReloadedReviewItBefore),
          if (!w.detailLoading && (n == null || n.id != widget.id) && w.detailFailure == null)
            Text(context.l10n.productThisNoteIsUnavailableInTheSelectedProject),
          if (n != null && n.id == widget.id) ...[
            Text(
              productTitle(context, n.title),
              textDirection: productContentDirection(productTitle(context, n.title)),
              style: context.text.title,
            ),
            Text(productTimestamp(context, n.createdAt), style: context.text.meta),
            const SizedBox(height: 8),
            Text(processingText(context, n.processing), key: const ValueKey('note-processing-state')),
            const SizedBox(height: 20),
            if (_editing) ...[
              ProductTextInput(
                key: const ValueKey('edit-title'),
                value: _title,
                onChanged: (v) => _title = v,
                enabled: !w.busy,
                label: context.l10n.productTitleOptional,
              ),
              ProductTextInput(
                key: const ValueKey('edit-content'),
                value: _content,
                onChanged: (v) => _content = v,
                lines: 6,
                enabled: !w.busy,
                label: context.l10n.productSavedContent,
              ),
              TextButton(
                onPressed: w.busy ? null : () => setState(() => _editing = false),
                child: Text(context.l10n.productCancelEditing),
              ),
            ] else ...[
              Text(context.l10n.productSavedContent, style: context.text.section),
              const SizedBox(height: 8),
              SelectableText(
                n.content,
                textDirection: productContentDirection(n.content),
                style: context.text.bodyLarge,
              ),
              TextButton.icon(
                onPressed: w.busy
                    ? null
                    : () => setState(() {
                        _editing = true;
                        _title = n.title ?? '';
                        _content = n.content;
                      }),
                icon: const Icon(Icons.edit_outlined),
                label: Text(context.l10n.productEditNote),
              ),
            ],
            if (n.processing == ProcessingState.completed) ...[
              if (n.concepts.isNotEmpty)
                Wrap(spacing: 8, children: [for (final concept in n.concepts) Chip(label: Text(concept))]),
              if (n.proposal != null) ...[
                const Divider(height: 32),
                Text(context.l10n.productRefinementProposal, style: context.text.section),
                const SizedBox(height: 12),
                SelectableText(
                  n.proposal!,
                  textDirection: productContentDirection(n.proposal!),
                  key: const ValueKey('refinement-proposal'),
                  style: context.text.body,
                ),
                const SizedBox(height: 16),
                FikraButton(
                  key: const ValueKey('accept-proposal'),
                  label: context.l10n.productAcceptAndReplaceSavedContent,
                  loading: w.busy,
                  growForText: true,
                  onPressed: () async {
                    final yes = await confirmDestructive(
                      context,
                      title: context.l10n.productReplaceSavedContent,
                      message: context.l10n.productAcceptancePermanentlyReplacesTheContentAndStartsProcessing,
                      confirmLabel: context.l10n.productAccept,
                    );
                    if (yes && context.mounted) {
                      await w.refine(RefinementAction.accept, reviewedNoteId: n.id, expectedGeneration: n.generation);
                    }
                  },
                ),
                TextButton(
                  onPressed: w.busy
                      ? null
                      : () => w.refine(RefinementAction.reject, reviewedNoteId: n.id, expectedGeneration: n.generation),
                  child: Text(context.l10n.productRejectProposal),
                ),
              ],
              TextButton(
                onPressed: w.busy
                    ? null
                    : () =>
                          w.refine(RefinementAction.regenerate, reviewedNoteId: n.id, expectedGeneration: n.generation),
                child: Text(context.l10n.productRequestAnotherProposal),
              ),
            ],
            if (!n.processing.pending)
              FikraButton.secondary(
                label: context.l10n.productRetryReprocess,
                loading: w.busy,
                onPressed: w.retryProcessing,
              ),
            if (n.processing.pending || n.processing == ProcessingState.unknown)
              TextButton(
                onPressed: w.busy ? null : () => w.openNote(widget.id),
                child: Text(context.l10n.productReloadStatus),
              ),
            const Divider(height: 32),
            Text(context.l10n.productRelatedNotes, style: context.text.section),
            if (w.related.isEmpty) Text(context.l10n.productNoCurrentRelationships),
            for (final related in w.related)
              ListTile(
                title: Text(productTitle(context, related.title)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/note/${related.noteId}'),
              ),
            const SizedBox(height: 24),
            FikraButton.danger(
              label: context.l10n.productDeleteNote,
              loading: w.busy,
              onPressed: () async {
                final yes = await confirmDestructive(
                  context,
                  title: context.l10n.productDeleteNote2,
                  message: context.l10n.productItsRelationshipsAndSourceCitationsWillAlsoBe,
                  confirmLabel: context.l10n.productDelete,
                );
                if (yes && context.mounted && await w.deleteNote() && context.mounted) context.pop();
              },
            ),
          ],
        ],
      );
    },
  );
}
