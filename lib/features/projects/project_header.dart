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

/// The projects sheet. [context] and [ref] belong to the caller (the header),
/// which outlives the sheet, so "New project" can close the sheet first and
/// then ask for the name from the page.
Future<void> showProjectSwitcher(BuildContext context, WidgetRef ref) {
  return showFikraSheet<void>(
    context,
    title: context.l10n.projectsTitle,
    builder: (sheetContext) => Consumer(
      builder: (sheetInner, sheetRef, _) {
        final projects = sheetRef.watch(projectsProvider).value ?? const [];
        final current = sheetRef.watch(selectedProjectProvider);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final p in projects)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ProjectRow(
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
