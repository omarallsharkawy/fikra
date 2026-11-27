import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../core/motion/pressable.dart';
import '../../core/motion/rolling_text.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/local/database.dart';
import '../../data/repositories.dart';

/// Orders [projects] with [currentId] first, then the rest from most recent
/// ([Project.createdAt] descending; equal-second ties keep later entries first).
List<ProjectSummary> orderProjects(List<ProjectSummary> projects, {String? currentId}) {
  final indexed = projects.indexed.toList()
    ..sort((a, b) {
      final aCurrent = a.$2.project.id == currentId;
      final bCurrent = b.$2.project.id == currentId;
      if (aCurrent != bCurrent) return aCurrent ? -1 : 1;
      final time = b.$2.project.createdAt.compareTo(a.$2.project.createdAt);
      return time != 0 ? time : b.$1.compareTo(a.$1);
    });
  return [for (final (_, p) in indexed) p];
}

/// Opens a sheet listing every project except [excludeProjectId], each with
/// its note count, and returns the one picked (null when dismissed). [empty]
/// is shown if no other project is left.
Future<Project?> showProjectPicker(
  BuildContext context, {
  required String title,
  required String excludeProjectId,
  required String empty,
}) {
  return showFikraSheet<Project>(
    context,
    title: title,
    builder: (sheet) => Consumer(
      builder: (sheet, ref, _) {
        final currentId = ref.watch(selectedProjectProvider)?.id;
        final projects = [
          for (final p in orderProjects(ref.watch(projectsProvider).value ?? const [], currentId: currentId))
            if (p.project.id != excludeProjectId) p,
        ];
        if (projects.isEmpty) {
          return SmartText(
            empty,
            key: const ValueKey('project-picker-empty'),
            style: sheet.text.body.copyWith(color: sheet.colors.textSecondary),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final p in projects)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ProjectRow(
                  key: ValueKey('project-pick-${p.project.id}'),
                  project: p.project,
                  count: p.noteCount,
                  onTap: () => Navigator.pop(sheet, p.project),
                ),
              ),
          ],
        );
      },
    ),
  );
}

/// One project in a sheet: name, note count, and an optional options control.
class ProjectRow extends StatelessWidget {
  const ProjectRow({
    super.key,
    required this.project,
    required this.count,
    required this.onTap,
    this.selected = false,
    this.onMore,
  });
  final Project project;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final onMore = this.onMore;
    return Pressable(
      onTap: onTap,
      pressedScale: 0.98,
      selected: selected,
      child: SolidSurface(
        radius: FikraRadius.md,
        color: selected ? context.colors.selected : context.colors.surface,
        borderColor: selected ? Colors.transparent : context.colors.line,
        padding: EdgeInsetsDirectional.fromSTEB(onMore == null ? 16 : 8, 12, 16, 12),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.folder_outlined,
              size: 20,
              color: selected ? context.colors.accent : context.colors.textPrimary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SmartText(
                    project.name,
                    style: context.text.section.copyWith(
                      fontWeight: FontWeight.w600,
                      color: selected ? context.colors.accent : context.colors.textPrimary,
                    ),
                  ),
                  RollingText(
                    Fmt.notes(context.l10n, count),
                    key: ValueKey('project-row-count-${project.id}'),
                    style: context.text.meta.copyWith(
                      color: selected ? context.colors.accent : context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (onMore != null)
              Pressable(
                onTap: onMore,
                minTarget: true,
                semanticLabel: context.l10n.projectOptionsA11y(project.name),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.more_horiz_rounded,
                    color: selected ? context.colors.accent : context.colors.textPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
