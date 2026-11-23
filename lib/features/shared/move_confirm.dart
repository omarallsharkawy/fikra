import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/widgets/fikra_widgets.dart';

/// What a move removes: links and suggestions to notes left behind, each
/// note pair counted once (`NotesRepository.moveImpact`).
typedef MoveImpact = ({int userLinks, int suggestions});

/// The move confirmation for [notes] notes: the files go along; links to notes
/// left behind are counted, and counts at zero are left out. One note keeps
/// the single-note wording.
String moveMessage(AppLocalizations l10n, MoveImpact impact, {int notes = 1}) {
  if (impact.userLinks + impact.suggestions == 0) {
    return notes == 1 ? l10n.moveNoteBodyNoLinks : l10n.moveNotesBodyNoLinks(notes);
  }
  final lost = Fmt.list(l10n, [
    if (impact.userLinks > 0) Fmt.links(l10n, impact.userLinks),
    if (impact.suggestions > 0) Fmt.suggestions(l10n, impact.suggestions),
  ]);
  return notes == 1 ? l10n.moveNoteBody(lost) : l10n.moveNotesBody(notes, lost);
}

/// Asks to confirm a move, saying what it loses. The numbers are read again
/// after the confirmation, and the dialog shows again while they changed (an
/// analysis added a suggestion, say). Returns true only for a confirmation of
/// the current numbers; false when cancelled, when [impact] fails ([failure]
/// is shown) or when [context] is gone.
Future<bool> confirmMove(
  BuildContext context, {
  required Future<MoveImpact> Function() impact,
  required String title,
  required String Function(MoveImpact impact) message,
  required String failure,
}) async {
  final l10n = context.l10n;
  Future<MoveImpact?> count() async {
    try {
      return await impact();
    } catch (_) {
      if (context.mounted) showToast(context, failure);
      return null;
    }
  }

  var shown = await count();
  while (true) {
    if (shown == null || !context.mounted) return false;
    final ok = await confirmDestructive(
      context,
      title: title,
      message: message(shown),
      confirmLabel: l10n.moveConfirm,
      danger: shown.userLinks + shown.suggestions > 0,
    );
    if (!ok || !context.mounted) return false;
    final now = await count();
    if (now == shown) return true;
    shown = now;
  }
}
