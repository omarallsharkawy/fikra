import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/motion/pressable.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import 'project_switcher.dart';

export 'project_switcher.dart';

class _HeaderLabelScope extends InheritedWidget {
  const _HeaderLabelScope({required this.showLabel, required super.child});
  final bool showLabel;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_HeaderLabelScope>()?.showLabel ?? true;

  @override
  bool updateShouldNotify(_HeaderLabelScope oldWidget) => showLabel != oldWidget.showLabel;
}

/// Header action control: a 48 dp tall [SolidSurface] pill with an icon and
/// label in one horizontal row when [ProjectHeader] has room, or a 48 dp
/// circular icon button when space is tight or text is scaled above 1.6x.
/// Hit target is always at least 48×48 dp.
class HeaderActionButton extends StatelessWidget {
  const HeaderActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.semanticLabel,
    this.tooltip,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? tooltip;
  final Color? iconColor;

  static const _pillPaddingX = FikraSpace.s12;
  static const _pillIconSize = 18.0;
  static const _pillGap = FikraSpace.s8;
  static const _circleIconSize = 24.0;

  @override
  Widget build(BuildContext context) {
    final showLabel = _HeaderLabelScope.of(context);
    final fg = iconColor ?? context.colors.textPrimary;
    Widget visual = showLabel
        ? SolidSurface(
            radius: FikraRadius.full,
            padding: EdgeInsets.zero,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: Pressable.minTargetSize - 2 * FikraSpace.hairline),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: _pillPaddingX, vertical: FikraSpace.s8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: _pillIconSize, color: fg),
                    const SizedBox(width: _pillGap),
                    Flexible(
                      child: SmartText(
                        label,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.chip,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : SolidSurface(
            radius: FikraRadius.full,
            width: Pressable.minTargetSize,
            height: Pressable.minTargetSize,
            padding: EdgeInsets.zero,
            child: Icon(icon, size: _circleIconSize, color: fg),
          );
    if (tooltip != null) {
      visual = Tooltip(message: tooltip!, excludeFromSemantics: true, child: visual);
    }
    return Pressable(onTap: onTap, semanticLabel: semanticLabel ?? label, minTarget: true, child: visual);
  }
}

/// Screen title + optional actions row above the current project pill.
class ProjectHeader extends ConsumerWidget {
  const ProjectHeader({super.key, required this.title, this.trailing, this.leading});
  final String title;
  final Widget? trailing;

  /// A 48 dp control before the title (a pushed page's Back), on the same row.
  final Widget? leading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(selectedProjectProvider);
    final titleStyle = context.text.title.copyWith(fontWeight: FontWeight.w700);
    final projectChip = Align(
      alignment: AlignmentDirectional.centerStart,
      child: Pressable(
        onTap: () => showProjectSwitcher(context, ref),
        minTarget: true,
        semanticLabel: context.l10n.projectPillA11y(project?.name ?? context.l10n.noProject),
        child: SolidSurface(
          radius: FikraRadius.full,
          padding: const EdgeInsetsDirectional.fromSTEB(14, FikraSpace.s8, 10, FikraSpace.s8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.folder_outlined, size: 18, color: context.colors.textSecondary),
              const SizedBox(width: 6),
              Flexible(
                child: SmartText(
                  project?.name ?? '—',
                  style: context.text.chip,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: context.colors.textSecondary),
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(FikraSpace.screen, 14, FikraSpace.screen, FikraSpace.s8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // A fixed breakpoint keeps header work cheap; Flexible owns text fit.
          final showLabel = constraints.maxWidth >= 340 && MediaQuery.textScalerOf(context).scale(1) <= 1.6;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 4)],
                  Expanded(
                    child: Semantics(header: true, child: SmartText(title, style: titleStyle)),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: constraints.maxWidth * .45),
                      child: _HeaderLabelScope(
                        showLabel: trailing is HeaderActionButton && showLabel,
                        child: trailing!,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: FikraSpace.s8),
              projectChip,
            ],
          );
        },
      ),
    );
  }
}
