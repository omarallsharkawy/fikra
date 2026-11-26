import '../../l10n/localizations.dart';

import 'package:flutter/material.dart';

import '../../app/product_runtime.dart';
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!w.projects.any((p) => !p.isGeneral))
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                key: const ValueKey('new-product-project'),
                onPressed: w.busy || w.loading || w.selected == null ? null : () => _name(context),
                icon: const Icon(Icons.add),
                label: Text(context.l10n.productNewProject),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('project-${w.selectedProjectId}'),
                    initialValue: w.selectedProjectId,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: context.l10n.productProject),
                    items: [
                      for (final p in w.projects)
                        DropdownMenuItem(
                          value: p.id,
                          child: Text(p.isGeneral ? '${p.name} ★' : p.name, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: w.busy
                        ? null
                        : (id) {
                            if (id != null) w.selectProject(id);
                          },
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  tooltip: context.l10n.projectsTitle,
                  enabled: !w.busy,
                  icon: const Icon(Icons.more_horiz),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'create', child: Text(context.l10n.productNewProject)),
                    if (w.selected != null) PopupMenuItem(value: 'rename', child: Text(context.l10n.productRename)),
                    if (w.selected != null && !w.selected!.isGeneral)
                      PopupMenuItem(value: 'delete', child: Text(context.l10n.productDeleteProject2)),
                  ],
                  onSelected: (action) async {
                    if (action == 'create') {
                      await _name(context);
                      return;
                    }
                    if (action == 'rename') {
                      await _name(context, rename: true);
                      return;
                    }
                    final selectedId = w.selectedProjectId;
                    final yes = await confirmDestructive(
                      context,
                      title: context.l10n.productDeleteProject,
                      message: context.l10n.productThisPermanentlyDeletesItsNotesConversationsAndKnowledge,
                      confirmLabel: context.l10n.productDelete,
                    );
                    if (yes && context.mounted && w.selectedProjectId == selectedId) await w.deleteProject();
                  },
                ),
              ],
            ),
          if (w.failure != null) ProductFailureView(w.failure!, onRetry: w.retryWorkspace),
        ],
      ),
    );
  }
}
