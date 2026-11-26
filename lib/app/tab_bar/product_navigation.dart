import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../l10n/localizations.dart';

/// Stable branch identities with the capture action in the reference's center.
class ProductNavigation extends StatelessWidget {
  const ProductNavigation({super.key, required this.branch, required this.onSelect, this.hidden = false});
  final int branch;
  final bool hidden;
  final void Function(int branch, bool reselect) onSelect;

  @override
  Widget build(BuildContext context) {
    if (hidden) return const SizedBox.shrink();
    final c = context.colors;
    final large = MediaQuery.textScalerOf(context).scale(1) >= 1.4;
    Widget tab(int id, int index, String label, IconData icon) => Expanded(
      child: Semantics(
        selected: branch == id,
        button: true,
        onTap: () => onSelect(id, branch == id),
        label: label,
        excludeSemantics: true,
        child: Tooltip(
          message: label,
          child: InkWell(
            key: ValueKey('nav-$index'),
            borderRadius: BorderRadius.circular(20),
            onTap: () => onSelect(id, branch == id),
            child: SizedBox(
              height: 56,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 23, color: branch == id ? c.brandBlueFg : c.textSecondary),
                  if (!large) ...[
                    const SizedBox(height: 3),
                    Text(
                      label,
                      maxLines: 1,
                      style: context.text.nav.copyWith(
                        fontSize: 12.5,
                        color: branch == id ? c.textPrimary : c.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Row(
            key: const ValueKey('product-navigation'),
            children: [
              tab(1, 0, context.l10n.navHome, Icons.home_outlined),
              tab(2, 1, context.l10n.navMap, Icons.hub_outlined),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: IconButton.filled(
                  key: const ValueKey('nav-add'),
                  tooltip: context.l10n.navAdd,
                  onPressed: () => onSelect(0, branch == 0),
                  style: IconButton.styleFrom(
                    backgroundColor: c.brandBlue,
                    foregroundColor: c.onBrandBlue,
                    minimumSize: const Size(54, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
                  ),
                  icon: const Icon(Icons.add, size: 28),
                ),
              ),
              tab(3, 2, context.l10n.navAsk, Icons.chat_bubble_outline_rounded),
              tab(4, 3, context.l10n.navMe, Icons.person_outline_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
