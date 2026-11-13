import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';

import '../../core/motion/pressable.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';

/// The header of a selection mode: a close control and how many are selected.
class SelectionHeader extends StatelessWidget {
  const SelectionHeader({super.key, required this.count, required this.onClose});
  final int count;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(FikraSpace.screen - 4, 14, FikraSpace.screen, 12),
      child: Row(
        children: [
          FikraIconButton(
            key: const ValueKey('selection-close'),
            icon: Icons.close_rounded,
            label: context.l10n.closeSelection,
            size: 40,
            onTap: onClose,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                context.l10n.selectedCount(count),
                key: const ValueKey('selection-count'),
                style: context.text.cardTitle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One action in a [SelectionActionBar]. Disabled when [onTap] is null;
/// [disabledHint] then tells a screen reader why.
class SelectionAction {
  const SelectionAction({
    required this.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
    this.disabledHint,
  });
  final Key key;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;
  final String? disabledHint;
}

/// Bottom bar of actions for a selection. Each action is at least 48 dp and
/// labelled. The actions share the width when their labels fit on one line;
/// otherwise (large text, long words) the bar scrolls sideways at their
/// natural width, so no label is ever clipped. [note] is an optional line
/// above the actions (why one is disabled).
class SelectionActionBar extends StatelessWidget {
  const SelectionActionBar({super.key, required this.actions, this.note});
  final List<SelectionAction> actions;
  final String? note;

  static const _itemPadding = 8.0;

  @override
  Widget build(BuildContext context) {
    final note = this.note;
    return Padding(
      padding: const EdgeInsets.fromLTRB(FikraSpace.screen - 8, 6, FikraSpace.screen - 8, 8),
      child: Glass(
        radius: FikraRadius.lg,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (note != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
                child: Text(
                  note,
                  key: const ValueKey('selection-note'),
                  style: context.text.caption.copyWith(color: context.colors.textSecondary),
                ),
              ),
            LayoutBuilder(
              builder: (context, box) {
                // Measured as the label is drawn (the ambient style merged in).
                final style = DefaultTextStyle.of(context).style.merge(context.text.chip);
                final scaler = MediaQuery.textScalerOf(context);
                final direction = Directionality.of(context);
                final locale = Localizations.maybeLocaleOf(context);
                final widths = [
                  for (final a in actions)
                    () {
                      final painter = TextPainter(
                        text: TextSpan(text: a.label, style: style),
                        textDirection: direction,
                        textScaler: scaler,
                        locale: locale,
                        maxLines: 1,
                      )..layout();
                      final w = painter.width;
                      painter.dispose();
                      // One spare dp against rounding, so a label never wraps by a hair.
                      return (w + 2 * _itemPadding + 1).clamp(Pressable.minTargetSize, double.infinity).ceilToDouble();
                    }(),
                ];
                final total = widths.fold(0.0, (a, b) => a + b);
                if (total <= box.maxWidth) {
                  // Each keeps its one-line width and gets an equal share of the rest.
                  final extra = (box.maxWidth - total) / actions.length;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (i, a) in actions.indexed)
                        SizedBox(
                          width: widths[i] + extra,
                          child: _ActionItem(action: a),
                        ),
                    ],
                  );
                }
                return SingleChildScrollView(
                  key: const ValueKey('selection-bar-scroll'),
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (i, a) in actions.indexed)
                        SizedBox(
                          width: widths[i],
                          child: _ActionItem(action: a),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({required this.action});
  final SelectionAction action;

  @override
  Widget build(BuildContext context) {
    final enabled = action.onTap != null;
    final fg = action.danger ? context.colors.danger : context.colors.textPrimary;
    return Semantics(
      hint: enabled ? null : action.disabledHint,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Pressable(
          key: action.key,
          onTap: action.onTap,
          semanticLabel: action.label,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Pressable.minTargetSize + 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: SelectionActionBar._itemPadding, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(action.icon, size: 22, color: fg),
                  const SizedBox(height: 2),
                  Text(
                    action.label,
                    textAlign: TextAlign.center,
                    style: context.text.chip.copyWith(color: fg),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
