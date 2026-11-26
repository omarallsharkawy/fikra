import '../../l10n/localizations.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import 'idea_card.dart';
import 'product_widgets.dart';
import 'project_controls.dart';

class ProductNotesScreen extends StatelessWidget {
  const ProductNotesScreen({super.key});
  @override
  Widget build(BuildContext context) => ProductView(
    builder: (context, r) {
      final w = r.workspace;
      final email = r.session.account?.email ?? '';
      return ProductScaffold(
        title: context.l10n.productNotes,
        header: Row(
          children: [
            IconButton(
              tooltip: context.l10n.uiProfile,
              onPressed: () => context.go('/me'),
              style: IconButton.styleFrom(
                backgroundColor: context.colors.brandPurple,
                foregroundColor: context.colors.onBrandPurple,
              ),
              icon: Text(
                email.isEmpty ? 'F' : email.substring(0, 1).toUpperCase(),
                style: context.text.cardTitle.copyWith(color: context.colors.onBrandPurple),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.productNotes, style: context.text.title),
                  Text(context.l10n.productCaptureAThought, style: context.text.caption),
                ],
              ),
            ),
            IconButton(
              tooltip: context.l10n.productReload,
              onPressed: w.loading ? null : w.retryWorkspace,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        children: [
          ProductProjectControls(runtime: r),
          ProductTextInput(
            key: ValueKey('search-${w.selectedProjectId}'),
            value: w.query,
            label: context.l10n.uiSearchIdeas,
            onChanged: (v) {
              w.query = v;
            },
            onSubmitted: w.search,
            suffix: IconButton(
              tooltip: context.l10n.productSearch,
              onPressed: w.searching ? null : () => w.search(w.query),
              icon: const Icon(Icons.search),
            ),
          ),
          Text(context.l10n.productDevelopmentSearchUsesLiteralFixtureMatchingNotSemantic, style: context.text.meta),
          if (w.searchFailure != null) ProductFailureView(w.searchFailure!, onRetry: () => w.search(w.query)),
          if (w.loading || w.searching)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (w.stillProcessing) Text(context.l10n.productStillProcessingReloadLaterTheSavedNoteIs),
          const SizedBox(height: 16),
          if (w.results != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(context.l10n.productSearchResults, style: context.text.section),
            ),
            if (w.results!.isEmpty) Text(context.l10n.productNoResultsInThisProject),
            for (final n in w.results!)
              ProductIdeaCard(
                title: productTitle(context, n.title),
                content: n.content,
                onOpen: () => context.push('/note/${n.noteId}'),
              ),
            TextButton(onPressed: () => w.search(''), child: Text(context.l10n.productShowAllSavedNotes)),
          ] else ...[
            if (!w.loading && w.notes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    const Icon(Icons.note_add_outlined, size: 52),
                    const SizedBox(height: 16),
                    Text(context.l10n.productNoNotesYet, style: context.text.section),
                    const SizedBox(height: 12),
                    FikraButton(
                      label: context.l10n.productCaptureAThought,
                      onPressed: () => context.go('/add'),
                      growForText: true,
                    ),
                  ],
                ),
              ),
            for (final n in w.notes)
              ProductIdeaCard(
                key: ValueKey('product-note-${n.id}'),
                title: productTitle(context, n.title),
                content: n.content,
                caption: processingText(context, n.processing),
                timestamp: productTimestamp(context, n.createdAt),
                onOpen: () => context.push('/note/${n.id}'),
              ),
          ],
        ],
      );
    },
  );
}
