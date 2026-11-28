import 'package:flutter/material.dart';

import '../theme/redesign_tokens.dart';
import 'redesign_widgets.dart';

/// Preserve the CSS's 36px visible segments and 8px margins, while extending
/// each hit area four pixels into that margin to reach the 44px minimum.
class RdSegments<T> extends StatelessWidget {
  const RdSegments({super.key, required this.values, required this.selected, required this.onChanged});
  final Map<T, String> values;
  final T selected;
  final ValueChanged<T>? onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Stack(
      children: [
        Positioned.fill(
          top: 4,
          bottom: 4,
          child: DecoratedBox(
            decoration: BoxDecoration(color: context.rd.surface2, borderRadius: BorderRadius.circular(12)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(3),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final e in values.entries)
                  Expanded(
                    child: Semantics(
                      selected: e.key == selected,
                      button: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: onChanged == null ? null : () => onChanged!(e.key),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 44),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (e.key == selected)
                                Positioned.fill(
                                  top: 4,
                                  bottom: 4,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: context.rd.surface,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Center(
                                  child: RdText(
                                    e.value,
                                    size: 13,
                                    weight: e.key == selected ? FontWeight.w600 : FontWeight.w400,
                                    align: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
