import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/links_repository.dart';
import '../../data/local/database.dart';
import '../../l10n/localizations.dart';
import 'note_links.dart';
import 'selection_actions.dart' show SelectionGuard;
import 'note_presentation.dart';

/// Claimed by an accept/reject of a suggested pair while it writes, and by its
/// Undo while it runs: one at a time app-wide, so a slow Undo can't race a
/// newer accept/reject and an action can't start on top of an Undo.
final suggestionBusyProvider = NotifierProvider<SelectionGuard, bool>(SelectionGuard.new);

/// Accepts or rejects the suggested pair [a]–[b] (safe if a re-analysis
/// replaced its row) and shows a toast with Undo, the same from the
/// Suggestions list, a connections page, note details and the graph. Undo puts
/// the pair back exactly as it was (`undoPairChange`), unless it changed
/// meanwhile. A call that changed nothing shows the toast without Undo; a
/// failure shows linkUpdateFailed. Returns whether the pair changed; false
/// too when another accept/reject or an Undo is running (then nothing runs).
///
/// [context] shows the toasts; when it is gone by then (a closed sheet), the
/// app's root navigator does.
Future<bool> changeSuggestedPair(
  BuildContext context, {
  required String a,
  required String b,
  required String expectedProjectId,
  required bool accept,
}) async {
  // The container outlives the page, so Undo works after it closed.
  final container = ProviderScope.containerOf(context, listen: false);
  final guard = container.read(suggestionBusyProvider.notifier);
  if (!guard.claim()) return false;
  final repo = container.read(linksRepoProvider);
  final root = Navigator.of(context, rootNavigator: true).context;
  BuildContext host() => context.mounted ? context : root;
  final l10n = context.l10n;
  PairChange? change;
  try {
    final result = accept
        ? await repo.acceptPairForUndo(a, b, expectedProjectId: expectedProjectId)
        : await repo.dismissPairForUndo(a, b, expectedProjectId: expectedProjectId);
    if (result is PairCommandStale) return false;
    change = result as PairChange?;
  } catch (_) {
    if (host().mounted) showToast(host(), l10n.linkUpdateFailed);
    return false;
  } finally {
    guard.release();
  }
  if (!host().mounted) return change != null;
  final undone = change;
  showToast(
    host(),
    accept ? l10n.linksAdded(undone == null ? 0 : 1) : l10n.linkSuggestionRejected,
    actionLabel: undone == null ? null : l10n.undo,
    onAction: undone == null
        ? null
        : () async {
            final failed = l10n.undoFailed;
            final messenger = ScaffoldMessenger.maybeOf(root);
            void fail() => showMessengerToast(messenger, failed);
            if (!guard.claim()) return fail();
            try {
              // Skipped quietly when the pair changed meanwhile, like undoLinks.
              await repo.undoPairChange(undone);
            } catch (_) {
              fail();
            } finally {
              guard.release();
            }
          },
  );
  return undone != null;
}

/// Options for one of your links: edit its reason, or remove it. Removing asks
/// first, because the analysis won't suggest that pair again. [remove] starts
/// with the options sheet's own (live) context and needs nothing from [context],
/// which may be gone by the time the confirmation ends. The sheet's content is
/// built from its own context for the same reason: it can rebuild after the
/// page under it is disposed.
Future<void> showLinkOptions(
  BuildContext context,
  NoteLinkEntry entry, {
  required Future<void> Function(BuildContext sheet) remove,
  Note? source,
}) {
  final l10n = context.l10n;
  final suggestion = entry.link.origin != LinkOrigin.user;
  var handled = false; // one choice per sheet, even on a double tap
  return showFikraSheet<void>(
    context,
    title: l10n.linkOptionsTitle,
    builder: (sheet) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          source == null
              ? noteTitle(sheet, entry.other)
              : '${noteTitle(sheet, source)} · ${noteTitle(sheet, entry.other)}',
          style: sheet.text.body.copyWith(color: sheet.colors.textSecondary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        if (suggestion) ...[
          const LinkSuggestedTag(),
          const SizedBox(height: 8),
          for (final accept in [true, false])
            SheetOption(
              label: accept ? l10n.acceptLink : l10n.rejectLink,
              icon: accept ? Icons.check_rounded : Icons.close_rounded,
              onTap: () async {
                if (handled) return;
                handled = true;
                // Toasts from the page: this sheet is closing.
                final done = changeSuggestedPair(
                  context.mounted ? context : sheet,
                  a: entry.link.sourceId,
                  b: entry.link.targetId,
                  expectedProjectId: entry.link.projectId,
                  accept: accept,
                );
                Navigator.pop(sheet);
                await done;
              },
            ),
        ] else ...[
          SheetOption(
            label: l10n.editLinkReason,
            icon: Icons.edit_outlined,
            onTap: () {
              if (handled) return;
              handled = true;
              Navigator.pop(sheet);
              // Opened from the page once this sheet is closing, not on top of it.
              if (!context.mounted) return;
              showFikraSheet<void>(
                context,
                title: l10n.editLinkReason,
                builder: (_) => _LinkReasonSheet(link: entry.link),
              );
            },
          ),
          SheetOption(
            label: l10n.removeLink,
            icon: Icons.link_off_rounded,
            danger: true,
            onTap: () async {
              if (handled) return;
              handled = true;
              final ok = await confirmDestructive(
                sheet,
                title: l10n.removeLinkTitle,
                message: l10n.removeLinkBody,
                confirmLabel: l10n.removeLinkConfirm,
              );
              if (!sheet.mounted) return;
              if (!ok) {
                handled = false;
                return;
              }
              final done = remove(sheet);
              Navigator.pop(sheet);
              await done;
            },
          ),
        ],
      ],
    ),
  );
}

/// Edits the reason of one of your links. An empty reason removes it. A link
/// removed meanwhile just closes the sheet (`updateLabel` is a no-op then).
class _LinkReasonSheet extends ConsumerStatefulWidget {
  const _LinkReasonSheet({required this.link});
  final NoteLink link;

  @override
  ConsumerState<_LinkReasonSheet> createState() => _LinkReasonSheetState();
}

class _LinkReasonSheetState extends ConsumerState<_LinkReasonSheet> {
  late final _reason = TextEditingController(text: widget.link.label);
  bool _busy = false;
  bool _failed = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    final route = ModalRoute.of(context);
    try {
      await ref.read(linksRepoProvider).updateLabel(widget.link.id, _reason.text);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _failed = true;
        });
      }
      return;
    }
    // Dismissed while saving: the sheet is already closing, and popping now
    // would close the page under it.
    if (mounted && (route?.isCurrent ?? false)) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinkReasonField(controller: _reason, autofocus: true, onSubmitted: (_) => _save()),
        if (_failed) ...[
          const SizedBox(height: 8),
          StatusBanner(kind: BannerKind.error, message: context.l10n.linkUpdateFailed),
        ],
        const SizedBox(height: 16),
        FikraButton(
          key: const ValueKey('link-reason-save'),
          label: context.l10n.save,
          loading: _busy,
          onPressed: _save,
        ),
      ],
    );
  }
}
