import '../../l10n/localizations.dart';

import 'package:flutter/material.dart';

import '../../app/product_runtime.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import 'product_widgets.dart';

class ProductProjectControls extends StatelessWidget {
  const ProductProjectControls({super.key, required this.runtime});
  final ProductRuntime runtime;
  Future<void> _name(BuildContext context, {bool rename = false}) async {
    final projectId = runtime.workspace.selectedProjectId;
    var value =
        runtime.workspace.projectDraft.isNotEmpty && runtime.workspace.projectDraftId == (rename ? projectId : null)
        ? runtime.workspace.projectDraft
        : rename
        ? runtime.workspace.selected?.name ?? ''
        : '';
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(rename ? context.l10n.productRenameProject : context.l10n.productNewProject),
        content: TextFormField(
          initialValue: value,
          autofocus: true,
          maxLength: 120,
          decoration: InputDecoration(labelText: context.l10n.productName),
          onChanged: (v) => value = v,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.productCancel)),
          TextButton(
            onPressed: () {
              if (value.trim().isNotEmpty) Navigator.pop(context, value);
            },
            child: Text(context.l10n.productSave),
          ),
        ],
      ),
    );
    if (result != null && context.mounted && (!rename || runtime.workspace.selectedProjectId == projectId)) {
      await runtime.workspace.saveProject(result, id: rename ? projectId : null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = runtime.workspace;
    final custom = w.projects.any((p) => !p.isGeneral);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.l10n.uxProjectsHelp, style: context.text.caption),
        const SizedBox(height: 16),
        FikraButton.secondary(
          key: const ValueKey('new-product-project'),
          growForText: true,
          label: context.l10n.productNewProject,
          icon: Icons.create_new_folder_outlined,
          onPressed: w.busy || w.loading || w.selected == null ? null : () => _name(context),
        ),
        const SizedBox(height: 16),
        if (custom)
          for (final project in w.projects)
            Card(
              child: ListTile(
                key: ValueKey('select-project-${project.id}'),
                selected: project.id == w.selectedProjectId,
                enabled: !w.busy && !w.loading,
                leading: Icon(project.id == w.selectedProjectId ? Icons.check_circle_outline : Icons.folder_outlined),
                title: Text(project.name),
                onTap: () => w.selectProject(project.id),
                trailing: project.id != w.selectedProjectId
                    ? null
                    : PopupMenuButton<String>(
                        tooltip: context.l10n.projectOptionsA11y(project.name),
                        enabled: !w.busy && !w.loading,
                        itemBuilder: (_) => [
                          PopupMenuItem(value: 'rename', child: Text(context.l10n.productRename)),
                          if (!project.isGeneral)
                            PopupMenuItem(value: 'delete', child: Text(context.l10n.productDeleteProject2)),
                        ],
                        onSelected: (action) async {
                          if (w.selectedProjectId != project.id) return;
                          if (action == 'rename') {
                            await _name(context, rename: true);
                            return;
                          }
                          final selectedId = project.id;
                          final yes = await confirmDestructive(
                            context,
                            title: context.l10n.productDeleteProject,
                            message: context.l10n.productThisPermanentlyDeletesItsNotesConversationsAndKnowledge,
                            confirmLabel: context.l10n.productDelete,
                          );
                          if (yes && context.mounted && w.selectedProjectId == selectedId) await w.deleteProject();
                        },
                      ),
              ),
            ),
        if (w.failure != null) ProductFailureView(w.failure!, onRetry: w.retryWorkspace),
      ],
    );
  }
}

class ProductProjectsScreen extends StatelessWidget {
  const ProductProjectsScreen({super.key});
  @override
  Widget build(BuildContext context) => ProductView(
    builder: (context, runtime) => ProductScaffold(
      title: context.l10n.projectsTitle,
      back: true,
      children: [ProductProjectControls(runtime: runtime)],
    ),
  );
}
