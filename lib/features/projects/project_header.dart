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

/// Screen title + current project pill that opens the project switcher.
class ProjectHeader extends ConsumerWidget {
  const ProjectHeader({super.key, required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(selectedProjectProvider);
    final titleStyle = context.text.title.copyWith(fontWeight: FontWeight.w700);
    const titleGap = 12.0;
    const settingsWidth = Pressable.minTargetSize + 4;
    // Padding, icons, internal gaps and the glass border, without the name.
    const chipChromeWidth = 24 + 18 + 6 + 4 + 18 + 2 * FikraSpace.hairline;
    const compactChipChromeWidth = 8 + 4 + 18 + 2 * FikraSpace.hairline;
    final actionWidth = trailing == null ? 0.0 : Pressable.minTargetSize + 8;

    Widget projectChip({required bool compact}) => Pressable(
      onTap: () => showProjectSwitcher(context, ref),
      minTarget: true,
      semanticLabel: context.l10n.projectPillA11y(project?.name ?? context.l10n.noProject),
      child: Glass(
        radius: FikraRadius.full,
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 4, vertical: 8)
            : const EdgeInsetsDirectional.fromSTEB(14, 8, 10, 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!compact) ...[
              Icon(Icons.folder_outlined, size: 18, color: context.colors.accentLight),
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

    Widget controls({required bool compact}) => Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ?trailing,
        if (trailing != null) const SizedBox(width: 8),
        Flexible(child: projectChip(compact: compact)),
        const SizedBox(width: 4),
        FikraIconButton(
          icon: Icons.settings_outlined,
          label: context.l10n.settings,
          size: 40,
          onTap: () => context.push('/settings'),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(FikraSpace.screen, 14, FikraSpace.screen, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScaler = MediaQuery.textScalerOf(context);
          final measurement = TextPainter(
            text: TextSpan(text: title, style: titleStyle),
            textDirection: Directionality.of(context),
            textScaler: textScaler,
            locale: Localizations.localeOf(context),
            maxLines: 1,
          )..layout();
          final chipWidth = constraints.maxWidth - measurement.width - titleGap - settingsWidth - actionWidth;
          measurement.dispose();
          // Keep an initial character and the renderer's ellipsis visible.
          final nameMeasurement = TextPainter(
            text: TextSpan(
              text: '${(project?.name ?? '—').characters.firstOrNull ?? ''}\u2026',
              style: context.text.chip,
            ),
            textDirection: Directionality.of(context),
            textScaler: textScaler,
            locale: Localizations.localeOf(context),
            maxLines: 1,
          )..layout();
          final nameSpace = nameMeasurement.width;
          nameMeasurement.dispose();
          final minimumChipWidth = (compactChipChromeWidth + nameSpace).clamp(Pressable.minTargetSize, double.infinity);
          final heading = Text(title, style: titleStyle, maxLines: 1, softWrap: false);
          // Preserve the full title and 48 dp controls when both cannot fit.
          if (chipWidth < minimumChipWidth) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [heading, const SizedBox(height: 8), controls(compact: false)],
            );
          }
          return Row(
            children: [
              heading,
              const SizedBox(width: titleGap),
              Expanded(child: controls(compact: chipWidth < chipChromeWidth + nameSpace)),
            ],
          );
        },
      ),
    );
  }
}

Future<void> showProjectSwitcher(BuildContext context, WidgetRef ref) {
  return showFikraSheet<void>(
    context,
    title: context.l10n.projectsTitle,
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) {
        final projects = ref.watch(projectsProvider).value ?? const [];
        final current = ref.watch(selectedProjectProvider);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final p in projects)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ProjectRow(
                  project: p.project,
                  count: p.noteCount,
                  selected: p.project.id == current?.id,
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await runAction(context, () => ref.read(projectsRepoProvider).setCurrent(p.project.id));
                  },
                  onMore: () => _projectActions(sheetContext, ref, p.project),
                ),
              ),
            const SizedBox(height: 8),
            FikraButton.secondary(
              label: context.l10n.newProject,
              icon: Icons.add_rounded,
              onPressed: () async {
                final name = await askProjectName(
                  sheetContext,
                  title: context.l10n.newProject,
                  action: context.l10n.create,
                );
                if (name == null || !sheetContext.mounted) return;
                Navigator.pop(sheetContext);
                await runAction(context, () => ref.read(projectsRepoProvider).create(name));
              },
            ),
          ],
        );
      },
    ),
  );
}

class _ProjectRow extends StatelessWidget {
  const _ProjectRow({
    required this.project,
    required this.count,
    required this.selected,
    required this.onTap,
    required this.onMore,
  });
  final Project project;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.98,
      selected: selected,
      child: Glass(
        radius: FikraRadius.md,
        gradient: selected ? context.colors.selectedGradient : context.colors.glassGradient,
        borderColor: selected ? Colors.transparent : context.colors.border,
        padding: const EdgeInsetsDirectional.fromSTEB(8, 12, 16, 12),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.folder_outlined,
              size: 20,
              color: selected ? context.colors.textOnSelected : context.colors.textPrimary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: context.text.section.copyWith(
                      fontWeight: FontWeight.w600,
                      color: selected ? context.colors.textOnSelected : context.colors.textPrimary,
                    ),
                  ),
                  Text(
                    Fmt.notes(context.l10n, count),
                    style: context.text.meta.copyWith(
                      color: selected ? context.colors.textOnSelected : context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Pressable(
              onTap: onMore,
              minTarget: true,
              semanticLabel: context.l10n.projectOptionsA11y(project.name),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.more_horiz_rounded,
                  color: selected ? context.colors.textOnSelected : context.colors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _projectActions(BuildContext context, WidgetRef ref, Project project) {
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
            final ok = await confirmDestructive(
              sheet,
              title: context.l10n.deleteProjectTitle(project.name),
              message: context.l10n.deleteProjectBody,
            );
            if (!ok || !sheet.mounted) return;
            Navigator.pop(sheet);
            await runAction(
              context,
              () => ref.read(projectsRepoProvider).delete(project.id),
              success: context.l10n.projectDeleted,
            );
          },
        ),
      ],
    ),
  );
}

/// Name prompt used by create & rename. Returns null when cancelled.
Future<String?> askProjectName(
  BuildContext context, {
  required String title,
  required String action,
  String initial = '',
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
              hint: context.l10n.projectNameHint,
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
