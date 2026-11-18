import 'dart:math' as math;

import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  static const _pillChromeWidth = _pillPaddingX * 2 + _pillIconSize + _pillGap + 2 * FikraSpace.hairline;

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
                      child: Text(
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

/// Screen title + settings/actions row above the current project pill.
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
    const titleGap = FikraSpace.s12;
    const actionGap = FikraSpace.s8;
    const leadingGap = FikraSpace.s4;
    final leadingWidth = leading == null ? 0.0 : Pressable.minTargetSize + leadingGap;

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
                child: Text(
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

    // Label room is measured only for a bare HeaderActionButton. Anything else
    // (a wrapped button, another control) gets icon-only buttons inside it, so
    // a label can never overflow the space reserved for it.
    final action = trailing;
    final trailingControl = action == null || action is HeaderActionButton
        ? action
        : _HeaderLabelScope(showLabel: false, child: action);

    Widget controls({required bool showLabels}) => _HeaderLabelScope(
      showLabel: showLabels,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ?trailingControl,
          if (trailing != null) const SizedBox(width: actionGap),
          HeaderActionButton(
            key: const ValueKey('header-settings'),
            icon: Icons.settings_outlined,
            label: context.l10n.settings,
            onTap: () => context.push('/settings'),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(FikraSpace.screen, 14, FikraSpace.screen, FikraSpace.s8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScaler = MediaQuery.textScalerOf(context);
          final boldText = MediaQuery.boldTextOf(context);
          final lineHeightScaleFactor = MediaQuery.maybeLineHeightScaleFactorOverrideOf(context);
          final letterSpacing = MediaQuery.maybeLetterSpacingOverrideOf(context);
          final wordSpacing = MediaQuery.maybeWordSpacingOverrideOf(context);
          final spacingOverride = lineHeightScaleFactor != null || letterSpacing != null || wordSpacing != null
              ? TextStyle(height: lineHeightScaleFactor, letterSpacing: letterSpacing, wordSpacing: wordSpacing)
              : null;
          final defaultTextStyle = DefaultTextStyle.of(context).style;
          double measureWidth(String value, TextStyle style) {
            var effectiveStyle = style.inherit ? defaultTextStyle.merge(style) : style;
            if (boldText) {
              effectiveStyle = effectiveStyle.merge(const TextStyle(fontWeight: FontWeight.bold));
            }
            if (spacingOverride != null) {
              effectiveStyle = effectiveStyle.merge(spacingOverride);
            }
            final painter = TextPainter(
              text: TextSpan(text: value, style: effectiveStyle),
              textDirection: Directionality.of(context),
              textScaler: textScaler,
              locale: Localizations.maybeLocaleOf(context),
              maxLines: 1,
            )..layout();
            final width = painter.width;
            painter.dispose();
            return width;
          }

          double pillWidth(String label) => math.max(
            Pressable.minTargetSize,
            HeaderActionButton._pillChromeWidth + measureWidth(label, context.text.chip).ceilToDouble() + 1,
          );

          final titleWidth = measureWidth(title, titleStyle).ceilToDouble();
          final headingWidth = leadingWidth + titleWidth;
          final labelledSettingsWidth = pillWidth(context.l10n.settings);
          final labelledActionWidth = action == null
              ? 0.0
              : (action is HeaderActionButton ? pillWidth(action.label) : Pressable.minTargetSize) + actionGap;
          final minControlsWidth =
              Pressable.minTargetSize + (action == null ? 0.0 : Pressable.minTargetSize + actionGap);

          final showLabels =
              textScaler.scale(1.0) <= 1.6 &&
              headingWidth + titleGap + labelledActionWidth + labelledSettingsWidth <= constraints.maxWidth;
          final controlsWidth = showLabels ? labelledActionWidth + labelledSettingsWidth : minControlsWidth;
          final singleRow = headingWidth + titleGap + controlsWidth <= constraints.maxWidth;
          final titleFitsWidth = headingWidth <= constraints.maxWidth;

          final text = Semantics(
            header: true,
            child: Text(
              title,
              style: titleStyle,
              maxLines: titleFitsWidth ? 1 : 2,
              softWrap: !titleFitsWidth,
              overflow: TextOverflow.ellipsis,
            ),
          );
          final heading = leading == null
              ? text
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    leading!,
                    const SizedBox(width: leadingGap),
                    Flexible(child: text),
                  ],
                );

          final row1 = singleRow
              ? Row(
                  children: [
                    heading,
                    const SizedBox(width: titleGap),
                    Expanded(child: controls(showLabels: showLabels)),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(alignment: AlignmentDirectional.centerStart, child: heading),
                    const SizedBox(height: FikraSpace.s8),
                    controls(showLabels: false),
                  ],
                );

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              row1,
              const SizedBox(height: FikraSpace.s8),
              projectChip,
            ],
          );
        },
      ),
    );
  }
}
