import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/pressable.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../l10n/localizations.dart';
import 'links_index.dart';

/// Both tiers of floating navigation share Glass's recipe and tier provider.
class LibraryControls extends StatelessWidget {
  const LibraryControls({
    super.key,
    required this.search,
    required this.onSearch,
    required this.suggestions,
    required this.segment,
    required this.onSegment,
    required this.sort,
    required this.onSort,
  });
  final TextEditingController search;
  final ValueChanged<String> onSearch;
  final int suggestions, segment;
  final ValueChanged<int> onSegment;
  final LinksSort sort;
  final ValueChanged<LinksSort> onSort;

  static double controlHeight(BuildContext context) => math.max(52, MediaQuery.textScalerOf(context).scale(20) + 28);
  static double segmentHeight(BuildContext context) =>
      math.max(Pressable.minTargetSize + 10, MediaQuery.textScalerOf(context).scale(20) + 36);
  static double extent(BuildContext context) => controlHeight(context) + segmentHeight(context) + 20;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final height = controlHeight(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: FikraSpace.screen),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Glass(
            padding: const EdgeInsetsDirectional.only(start: 18, end: 4),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: height),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('links-search'),
                      controller: search,
                      onChanged: onSearch,
                      textInputAction: TextInputAction.search,
                      style: context.text.field,
                      decoration: InputDecoration(
                        hintText: l10n.searchLinksHint,
                        hintStyle: context.text.field.copyWith(color: context.colors.textSecondary),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  Icon(Icons.search_rounded, size: 20, color: context.colors.textSecondary),
                  const SizedBox(width: 8),
                  Container(width: 1, height: 24, color: context.colors.line),
                  FikraIconButton(
                    key: const ValueKey('links-sort'),
                    icon: Icons.tune_rounded,
                    label: l10n.linksSort,
                    onTap: () => showFikraSheet<void>(
                      context,
                      title: l10n.linksSort,
                      builder: (sheet) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final order in LinksSort.values)
                            SheetOption(
                              key: ValueKey('links-sort-${order.name}'),
                              label: sortLabel(context, order),
                              selected: order == sort,
                              icon: order == sort ? Icons.check_rounded : Icons.sort_rounded,
                              onTap: () {
                                onSort(order);
                                Navigator.pop(sheet);
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          SegmentedPill(
            height: segmentHeight(context),
            selected: segment,
            onChanged: onSegment,
            segmentKeys: const [ValueKey('links-segment-0'), ValueKey('links-segment-1')],
            // No count while nothing waits: just «اقتراحات».
            options: [
              l10n.linksBrowse,
              suggestions > 0 ? l10n.linksSuggestionsCount(suggestions) : l10n.linksSuggestions,
            ],
            semanticLabels: [
              l10n.linksBrowse,
              suggestions > 0 ? l10n.linksSuggestionsCountA11y(suggestions) : l10n.linksSuggestions,
            ],
          ),
        ],
      ),
    );
  }
}

String sortLabel(BuildContext context, LinksSort sort) => switch (sort) {
  LinksSort.newest => context.l10n.linksNewest,
  LinksSort.mostLinks => context.l10n.linksMostLinked,
  LinksSort.oldest => context.l10n.linksOldest,
};
