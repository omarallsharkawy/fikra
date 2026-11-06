import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
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
    final project = ref.watch(currentProjectProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(FikraSpace.screen, 14, FikraSpace.screen, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: FikraText.title.copyWith(fontWeight: FontWeight.w700)),
          ),
          ?trailing,
          if (trailing != null) const SizedBox(width: 8),
          Pressable(
            onTap: () => showProjectSwitcher(context, ref),
            semanticLabel: 'تغيير المشروع',
            child: Glass(
              radius: FikraRadius.full,
              padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.folder_outlined, size: 18, color: FikraColors.accentLight),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 130),
                    child: Text(project?.name ?? '—', style: FikraText.chip, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: FikraColors.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showProjectSwitcher(BuildContext context, WidgetRef ref) {
  return showFikraSheet<void>(
    context,
    title: 'المشاريع',
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) {
        final projects = ref.watch(projectsProvider).value ?? const [];
        final current = ref.watch(currentProjectProvider);
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
                  onTap: () {
                    ref.read(projectsRepoProvider).setCurrent(p.project.id);
                    Navigator.pop(sheetContext);
                  },
                  onMore: () => _projectActions(sheetContext, ref, p.project),
                ),
              ),
            const SizedBox(height: 8),
            FikraButton.secondary(
              label: 'مشروع جديد',
              icon: Icons.add_rounded,
              onPressed: () async {
                final name = await askProjectName(sheetContext, title: 'مشروع جديد', action: 'إنشاء');
                if (name != null) await ref.read(projectsRepoProvider).create(name);
                if (sheetContext.mounted) Navigator.pop(sheetContext);
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
      child: Glass(
        radius: FikraRadius.md,
        gradient: selected ? FikraColors.selectedGradient : FikraColors.glassGradient,
        borderColor: selected ? Colors.transparent : FikraColors.border,
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Icon(selected ? Icons.check_circle_rounded : Icons.folder_outlined, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(project.name, style: FikraText.section.copyWith(fontWeight: FontWeight.w600)),
                  Text('$count نوت', style: FikraText.meta.copyWith(color: FikraColors.textSecondary)),
                ],
              ),
            ),
            Pressable(
              onTap: onMore,
              semanticLabel: 'خيارات المشروع',
              child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.more_horiz_rounded)),
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
          label: 'إعادة تسمية',
          icon: Icons.edit_outlined,
          onTap: () async {
            final name = await askProjectName(sheet, title: 'إعادة تسمية', action: 'حفظ', initial: project.name);
            if (name != null) await ref.read(projectsRepoProvider).rename(project.id, name);
            if (sheet.mounted) Navigator.pop(sheet);
          },
        ),
        SheetOption(
          label: 'حذف المشروع',
          icon: Icons.delete_outline_rounded,
          danger: true,
          onTap: () async {
            final ok = await confirmDestructive(
              sheet,
              title: 'تحذف «${project.name}»؟',
              message: 'كل النوتس والروابط والمحادثات اللي في المشروع هتتحذف، ومش هينفع ترجّعها.',
            );
            if (ok) await ref.read(projectsRepoProvider).delete(project.id);
            if (sheet.mounted) Navigator.pop(sheet);
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
              hint: 'اسم المشروع',
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
