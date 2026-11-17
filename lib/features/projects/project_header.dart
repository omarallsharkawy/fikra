import 'dart:math' as math;

import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../core/motion/pressable.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/local/database.dart';
import '../../data/repositories.dart';
import '../shared/project_picker.dart';

class _HeaderLabelScope extends InheritedWidget {
  const _HeaderLabelScope({required this.showLabel, required super.child});
  final bool showLabel;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_HeaderLabelScope>()?.showLabel ?? true;

  @override
  bool updateShouldNotify(_HeaderLabelScope oldWidget) => showLabel != oldWidget.showLabel;
}

/// Compact header control: round surface icon with a short caption underneath
/// when [ProjectHeader] has room, or icon-only when space is tight or text is
/// scaled above 1.6x. Hit target is always at least 48×48 dp.
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

  @override
  Widget build(BuildContext context) {
    final showLabel = _HeaderLabelScope.of(context);
    final fg = iconColor ?? context.colors.textPrimary;
    Widget visual = showLabel
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SolidSurface(
                  radius: FikraRadius.full,
                  width: 30,
                  height: 30,
                  padding: EdgeInsets.zero,
                  child: Icon(icon, size: 16, color: fg),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.meta.copyWith(height: 1.15),
                ),
              ],
            ),
          )
        : SolidSurface(
            radius: FikraRadius.full,
            width: 40,
            height: 40,
            padding: EdgeInsets.zero,
            child: Icon(icon, size: 19, color: fg),
          );
    if (tooltip != null) {
      visual = Tooltip(message: tooltip!, excludeFromSemantics: true, child: visual);
    }
    return Pressable(onTap: onTap, semanticLabel: semanticLabel ?? label, minTarget: true, child: visual);
  }
}

/// Screen title + current project pill that opens the project switcher.
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
    const titleGap = 12.0;
    const unlabelledSettingsWidth = Pressable.minTargetSize + 4;
    // Padding, icons, internal gaps and the glass border, without the name.
    const chipChromeWidth = 24 + 18 + 6 + 4 + 18 + 2 * FikraSpace.hairline;
    const compactChipChromeWidth = 8 + 4 + 18 + 2 * FikraSpace.hairline;
    final unlabelledActionWidth = trailing == null ? 0.0 : Pressable.minTargetSize + 8;
    const leadingGap = 4.0;
    final leadingWidth = leading == null ? 0.0 : Pressable.minTargetSize + leadingGap;

    Widget projectChip({required bool compact}) => Pressable(
      onTap: () => showProjectSwitcher(context, ref),
      minTarget: true,
      semanticLabel: context.l10n.projectPillA11y(project?.name ?? context.l10n.noProject),
      child: SolidSurface(
        radius: FikraRadius.full,
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 4, vertical: 8)
            : const EdgeInsetsDirectional.fromSTEB(14, 8, 10, 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!compact) ...[
              Icon(Icons.folder_outlined, size: 18, color: context.colors.textSecondary),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Text(
                  project?.name ?? '—',
                  style: context.text.chip,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: context.colors.textSecondary),
          ],
        ),
      ),
    );

    // Label room is measured only for a bare HeaderActionButton. Anything else
    // (a wrapped button, another control) gets icon-only buttons inside it, so
    // a caption can never overflow the space reserved for it.
    final action = trailing;
    final trailingControl = action == null || action is HeaderActionButton
        ? action
        : _HeaderLabelScope(showLabel: false, child: action);

    Widget controls({required bool compact, required bool showLabels}) => _HeaderLabelScope(
      showLabel: showLabels,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ?trailingControl,
          if (trailing != null) const SizedBox(width: 8),
          Flexible(child: projectChip(compact: compact)),
          const SizedBox(width: 4),
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
      padding: const EdgeInsets.fromLTRB(FikraSpace.screen, 14, FikraSpace.screen, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScaler = MediaQuery.textScalerOf(context);
          final defaultTextStyle = DefaultTextStyle.of(context).style;
          double measureWidth(String value, TextStyle style, {bool mergeDefault = true}) {
            final painter = TextPainter(
              text: TextSpan(text: value, style: mergeDefault ? defaultTextStyle.merge(style) : style),
              textDirection: Directionality.of(context),
              textScaler: textScaler,
              locale: Localizations.localeOf(context),
              maxLines: 1,
            )..layout();
            final width = painter.width;
            painter.dispose();
            return width;
          }

          final titleWidth = measureWidth(title, titleStyle).ceilToDouble();
          // Keep an initial character and the renderer's ellipsis visible.
          final initialEllipsis = '${(project?.name ?? '—').characters.firstOrNull ?? ''}\u2026';
          final nameSpace = math.max(
            measureWidth(initialEllipsis, context.text.chip),
            measureWidth(initialEllipsis, context.text.chip, mergeDefault: false),
          );
          final minimumChipWidth = (compactChipChromeWidth + nameSpace).clamp(Pressable.minTargetSize, double.infinity);
          final labelStyle = context.text.meta.copyWith(height: 1.15);
          final labelledSettingsWidth =
              math.max(Pressable.minTargetSize, (measureWidth(context.l10n.settings, labelStyle) + 8).ceilToDouble()) +
              4;
          final labelledActionWidth = action == null
              ? 0.0
              : action is HeaderActionButton
              ? math.max(Pressable.minTargetSize, (measureWidth(action.label, labelStyle) + 8).ceilToDouble()) + 8
              : unlabelledActionWidth;
          final showLabels =
              textScaler.scale(1.0) <= 1.6 &&
              (constraints.maxWidth - labelledSettingsWidth - labelledActionWidth >= minimumChipWidth);
          final settingsWidth = showLabels ? labelledSettingsWidth : unlabelledSettingsWidth;
          final actionWidth = showLabels ? labelledActionWidth : unlabelledActionWidth;
          final chipWidth = constraints.maxWidth - leadingWidth - titleWidth - titleGap - settingsWidth - actionWidth;
          final text = Text(title, style: titleStyle, maxLines: 1, softWrap: false);
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
          // Preserve the full title and 48 dp controls when both cannot fit.
          if (chipWidth < minimumChipWidth) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                heading,
                const SizedBox(height: 8),
                controls(compact: false, showLabels: showLabels),
              ],
            );
          }
          return Row(
            children: [
              heading,
              const SizedBox(width: titleGap),
              Expanded(
                child: controls(compact: chipWidth < chipChromeWidth + nameSpace, showLabels: showLabels),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The projects sheet. [context] and [ref] belong to the caller (the header),
/// which outlives the sheet, so "New project" can close the sheet first and
/// then ask for the name from the page.
Future<void> showProjectSwitcher(BuildContext context, WidgetRef ref) {
  return showFikraSheet<void>(
    context,
    title: context.l10n.projectsTitle,
    builder: (sheetContext) => Consumer(
      builder: (sheetInner, sheetRef, _) {
        final current = sheetRef.watch(selectedProjectProvider);
        final projects = orderProjects(sheetRef.watch(projectsProvider).value ?? const [], currentId: current?.id);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final p in projects)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ProjectRow(
                  key: ValueKey('project-row-${p.project.id}'),
                  project: p.project,
                  count: p.noteCount,
                  selected: p.project.id == current?.id,
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await runAction(sheetInner, () => sheetRef.read(projectsRepoProvider).setCurrent(p.project.id));
                  },
                  onMore: () => _projectActions(sheetContext, sheetRef, p.project),
                ),
              ),
            const SizedBox(height: 8),
            FikraButton.secondary(
              key: const ValueKey('new-project'),
              label: sheetInner.l10n.newProject,
              icon: Icons.add_rounded,
              onPressed: () async {
                // One sheet at a time: close the projects sheet, then ask for
                // the name. Cancelling the name sheet changes nothing.
                Navigator.pop(sheetContext);
                if (!context.mounted) return;
                final name = await askProjectName(context, title: context.l10n.newProject, action: context.l10n.create);
                if (name == null || !context.mounted) return;
                await runAction(context, () => ref.read(projectsRepoProvider).create(name));
              },
            ),
          ],
        );
      },
    ),
  );
}

Future<void> _projectActions(BuildContext context, WidgetRef ref, Project project) {
  // One delete at a time per sheet: a double tap would otherwise count twice
  // and open two dialogs. Reset when the flow ends (cancel included).
  var deleting = false;
  return showFikraSheet<void>(
    context,
    title: project.name,
    builder: (sheet) => Column(
      children: [
        SheetOption(
          label: context.l10n.renameProject,
          icon: Icons.edit_outlined,
          onTap: () async {
            final name = await askProjectName(
              sheet,
              title: context.l10n.renameProject,
              action: context.l10n.save,
              initial: project.name,
            );
            if (name == null || !sheet.mounted) return;
            Navigator.pop(sheet);
            await runAction(context, () => ref.read(projectsRepoProvider).rename(project.id, name));
          },
        ),
        SheetOption(
          label: context.l10n.deleteProject,
          icon: Icons.delete_outline_rounded,
          danger: true,
          onTap: () async {
            if (deleting) return;
            deleting = true;
            try {
              final l10n = context.l10n;
              final repo = ref.read(projectsRepoProvider);
              Future<ProjectDeleteImpact?> count() async {
                try {
                  return await repo.deleteImpact(project.id);
                } catch (_) {
                  if (sheet.mounted) showToast(sheet, l10n.genericError);
                  return null;
                }
              }

              var shown = await count();
              while (true) {
                if (shown == null) return;
                // Dismissed while counting: no dialog over whatever is there now.
                if (!sheet.mounted || !(ModalRoute.of(sheet)?.isCurrent ?? false)) return;
                final ok = await confirmDestructive(
                  sheet,
                  title: l10n.deleteProjectTitle(Fmt.isolate(project.name)),
                  message: deleteProjectMessage(l10n, shown),
                );
                if (!ok || !sheet.mounted) return;
                // The numbers changed while the dialog was open (a note was
                // analysed or added): ask again with the new ones.
                final now = await count();
                if (now == shown) break;
                shown = now;
              }
              if (!sheet.mounted) return;
              Navigator.pop(sheet);
              await runAction(context, () => repo.delete(project.id), success: l10n.projectDeleted);
            } finally {
              deleting = false;
            }
          },
        ),
      ],
    ),
  );
}

/// The project delete confirmation in numbers; counts at zero are left out.
/// A project with no notes says it is empty, or that its chat goes.
@visibleForTesting
String deleteProjectMessage(AppLocalizations l10n, ProjectDeleteImpact impact) {
  if (impact.notes == 0) return impact.chat ? l10n.deleteProjectEmptyChatBody : l10n.deleteProjectEmptyBody;
  return l10n.deleteProjectBody(
    Fmt.list(l10n, [
      Fmt.notes(l10n, impact.notes),
      if (impact.files > 0) Fmt.files(l10n, impact.files),
      if (impact.links > 0) Fmt.links(l10n, impact.links),
    ]),
  );
}

/// Name prompt used by create & rename. Returns null when cancelled. [hint]
/// defaults to `projectNameHint`; the first project passes its own example.
Future<String?> askProjectName(
  BuildContext context, {
  required String title,
  required String action,
  String initial = '',
  String? hint,
}) {
  final controller = TextEditingController(text: initial);
  return showFikraSheet<String>(
    context,
    title: title,
    builder: (sheet) => StatefulBuilder(
      builder: (sheet, setState) {
        final valid = controller.text.trim().isNotEmpty;
        void submit() {
          if (controller.text.trim().isNotEmpty) Navigator.pop(sheet, controller.text.trim());
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FikraField(
              controller: controller,
              hint: hint ?? context.l10n.projectNameHint,
              icon: Icons.folder_outlined,
              autofocus: true,
              maxLength: 40,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => submit(),
            ),
            const SizedBox(height: 16),
            FikraButton(label: action, onPressed: valid ? submit : null),
          ],
        );
      },
    ),
  );
}
