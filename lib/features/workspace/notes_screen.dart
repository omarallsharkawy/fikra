import '../../l10n/localizations.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import 'product_widgets.dart';
import 'project_controls.dart';

class ProductNotesScreen extends StatelessWidget {
  const ProductNotesScreen({super.key});
  @override
  Widget build(BuildContext context) => ProductView(
    builder: (context, r) {
      final w = r.workspace;
      final locale = Localizations.localeOf(context).languageCode;
      return ProductScaffold(
        title: context.l10n.productNotes,
        trailing: IconButton(
          tooltip: context.l10n.productReload,
          onPressed: w.loading ? null : w.retryWorkspace,
          icon: const Icon(Icons.refresh),
        ),
        children: [
          ProductProjectControls(runtime: r),
          ProductTextInput(
            key: ValueKey('search-${w.selectedProjectId}'),
            value: w.query,
            label: context.l10n.productSearchThisProject,
            onChanged: (v) {
              w.query = v;
            },
            onSubmitted: w.search,
          ),
          FikraButton.secondary(
            label: context.l10n.productSearch,
            loading: w.searching,
            onPressed: () => w.search(w.query),
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
            Text(context.l10n.productSearchResults, style: context.text.section),
            if (w.results!.isEmpty) Text(context.l10n.productNoResultsInThisProject),
            for (final n in w.results!)
              Card(
                child: ListTile(
                  title: Text(productTitle(context, n.title)),
                  subtitle: Text(n.content, maxLines: 3, overflow: TextOverflow.ellipsis),
                  onTap: () => context.push('/note/${n.noteId}'),
                ),
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
                    FikraButton(label: context.l10n.productCaptureAThought, onPressed: () => context.go('/add')),
                  ],
                ),
              ),
            for (final n in w.notes)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SolidSurface(
                  child: Material(
                    type: MaterialType.transparency,
                    child: ListTile(
                      key: ValueKey('product-note-${n.id}'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(productTitle(context, n.title), style: context.text.cardTitle),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.content, maxLines: 3, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),
                          Text(processingText(context, n.processing), style: context.text.meta),
                          Text(
                            DateFormat('EEEE, yMMMd · HH:mm', locale).format(n.createdAt.toLocal()),
                            style: context.text.meta,
                          ),
                        ],
                      ),
                      onTap: () => context.push('/note/${n.id}'),
                    ),
                  ),
                ),
              ),
          ],
        ],
      );
    },
  );
}
