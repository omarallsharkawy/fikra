import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/product_runtime.dart';
import '../../app/tab_bar/product_navigation.dart';
import '../../core/widgets/redesign_widgets.dart';
import '../../l10n/localizations.dart';
import 'note_undo_controller.dart';
import 'product_widgets.dart';

void showNoteUndo(BuildContext context, ProductRuntime runtime, UndoNoteAction action) {
  final messenger = ScaffoldMessenger.of(context), l = context.l10n;
  final remaining = action.deadline.difference(runtime.undo.clock());
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(action.kind == UndoNoteKind.delete ? l.rdDeleted : l.rdApplied),
      duration: remaining.isNegative ? const Duration(seconds: 2) : remaining,
      margin: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        math.max(84, ProductNavigation.barHeight(context) + 54 + MediaQuery.paddingOf(context).bottom),
      ),
      action: remaining.isNegative
          ? null
          : SnackBarAction(
              label: l.rdUndo,
              onPressed: () async {
                final ok = await runtime.undo.undo(action.id);
                if (!ok && messenger.mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(runtime.undo.failure == null ? l.rdUndoExpired : l.rdUndoFailed)),
                  );
                }
              },
            ),
    ),
  );
}

class NoteUndoFeedback extends StatelessWidget {
  const NoteUndoFeedback({super.key, required this.runtime});
  final ProductRuntime runtime;
  @override
  Widget build(BuildContext context) {
    final undo = runtime.undo;
    if (undo.failure == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProductFailureView(undo.failure!),
        for (final a in undo.actions.where(undo.retryable))
          Row(
            children: [
              Expanded(child: RdButton(context.l10n.retry, primary: false, onPressed: () => undo.retry(a.id))),
              TextButton(
                onPressed: () async {
                  if (await undo.discardFailed(a.id)) await runtime.workspace.retryWorkspace();
                },
                child: Text(context.l10n.rdDismiss),
              ),
            ],
          ),
      ],
    );
  }
}
