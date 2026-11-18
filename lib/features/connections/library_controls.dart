import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/pressable.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../l10n/localizations.dart';
import 'links_index.dart';

/// Map controls are opaque; list controls retain the existing Glass chrome.
class LibraryControls extends StatefulWidget {
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

  static double controlHeight(BuildContext context) => math.max(52, MediaQuery.textScalerOf(context).scale(24) + 28);
  static double segmentHeight(BuildContext context) =>
      math.max(Pressable.minTargetSize + 10, MediaQuery.textScalerOf(context).scale(20) + 36);
  static double extent(BuildContext context) => controlHeight(context) + segmentHeight(context) + 20;

  @override
  State<LibraryControls> createState() => _LibraryControlsState();
}

class _LibraryControlsState extends State<LibraryControls> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _clearSearch() {
    // Keep the keyboard only if it was up: a field the user scrolled away from
    // (keyboard dismissed) stays unfocused after clearing.
    final hadFocus = _focus.hasFocus;
    widget.search.clear();
    widget.onSearch('');
    if (hadFocus) _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final height = LibraryControls.controlHeight(context);
    Widget surface({required Widget child, required EdgeInsetsGeometry padding}) =>
        widget.segment == 0 ? SolidSurface(padding: padding, child: child) : Glass(padding: padding, child: child);
    return ColoredBox(
      color: widget.segment == 0 ? context.colors.canvas : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: FikraSpace.screen),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            surface(
              padding: const EdgeInsetsDirectional.only(start: 18, end: 4),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: height),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const ValueKey('links-search'),
                        controller: widget.search,
                        focusNode: _focus,
                        onChanged: widget.onSearch,
                        textInputAction: TextInputAction.search,
                        style: context.text.field,
                        decoration: InputDecoration(
                          hintText: l10n.searchLinksHint,
                          hintStyle: context.text.field.copyWith(color: context.colors.textSecondary),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: widget.search,
                      builder: (context, value, _) => value.text.isNotEmpty
                          ? TextFieldTapRegion(
                              child: Pressable(
                                key: const ValueKey('links-search-clear'),
                                minTarget: true,
                                semanticLabel: l10n.clearSearch,
                                onTap: _clearSearch,
                                child: Icon(Icons.close_rounded, size: 20, color: context.colors.textSecondary),
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsetsDirectional.only(end: 8),
                              child: Icon(Icons.search_rounded, size: 20, color: context.colors.textSecondary),
                            ),
                    ),
                    if (widget.segment != 0) Container(width: 1, height: 24, color: context.colors.line),
                    if (widget.segment != 0)
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
                                  selected: order == widget.sort,
                                  icon: order == widget.sort ? Icons.check_rounded : Icons.sort_rounded,
                                  onTap: () {
                                    widget.onSort(order);
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
              height: LibraryControls.segmentHeight(context),
              selected: widget.segment,
              onChanged: widget.onSegment,
              segmentKeys: const [
                ValueKey('links-segment-0'),
                ValueKey('links-segment-1'),
                ValueKey('links-segment-2'),
              ],
              // No count while nothing waits: just «اقتراحات».
              options: [
                l10n.linksMap,
                l10n.linksBrowse,
                widget.suggestions > 0 ? l10n.linksSuggestionsCount(widget.suggestions) : l10n.linksSuggestions,
              ],
              semanticLabels: [
                l10n.linksMap,
                l10n.linksBrowse,
                widget.suggestions > 0 ? l10n.linksSuggestionsCountA11y(widget.suggestions) : l10n.linksSuggestions,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String sortLabel(BuildContext context, LinksSort sort) => switch (sort) {
  LinksSort.newest => context.l10n.linksNewest,
  LinksSort.mostLinks => context.l10n.linksMostLinked,
  LinksSort.oldest => context.l10n.linksOldest,
};
