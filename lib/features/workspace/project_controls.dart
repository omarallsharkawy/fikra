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
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
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
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: w.busy ? null : () => _name(context),
                icon: const Icon(Icons.add),
                label: Text(context.l10n.productNewProject),
              ),
              if (w.selected != null)
                TextButton(
                  onPressed: w.busy ? null : () => _name(context, rename: true),
                  child: Text(context.l10n.productRename),
                ),
              if (w.selected != null && !w.selected!.isGeneral)
                TextButton(
                  onPressed: w.busy
                      ? null
                      : () async {
                          final yes = await confirmDestructive(
                            context,
                            title: context.l10n.productDeleteProject,
                            message: context.l10n.productThisPermanentlyDeletesItsNotesConversationsAndKnowledge,
                            confirmLabel: context.l10n.productDelete,
                          );
                          if (yes && context.mounted) await w.deleteProject();
                        },
                  child: Text(context.l10n.productDeleteProject2),
                ),
            ],
          ),
          if (w.failure != null) ProductFailureView(w.failure!, onRetry: w.retryWorkspace),
        ],
      ),
    );
  }
}
