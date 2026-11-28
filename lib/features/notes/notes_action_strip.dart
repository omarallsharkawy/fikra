import 'dart:async';

import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/motion/pressable.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/local/database.dart';
import '../connections/library_session.dart';
import '../connections/links_library_provider.dart';

enum NotesActionKind { failed, suggestions, rewrites }

class _DismissedActionStrips extends Notifier<Set<(String, NotesActionKind)>> {
  @override
  Set<(String, NotesActionKind)> build() => const {};

  void dismiss(String projectId, NotesActionKind kind) => state = {...state, (projectId, kind)};
}

/// Session-scoped dismissed action strips per project.
final dismissedActionStripsProvider = NotifierProvider<_DismissedActionStrips, Set<(String, NotesActionKind)>>(
  _DismissedActionStrips.new,
);

/// Rolling 7-day distinct calendar-day count with at least one note created.
int activeDaysThisWeek(Iterable<Note> notes, DateTime now) {
  final today = DateTime.utc(now.year, now.month, now.day);
  final days = <(int, int, int)>{};
  for (final n in notes) {
    final d = DateTime.utc(n.createdAt.year, n.createdAt.month, n.createdAt.day);
    final diff = today.difference(d).inDays;
    if (diff >= 0 && diff < 7) {
      days.add((n.createdAt.year, n.createdAt.month, n.createdAt.day));
    }
  }
  return days.length;
}

/// Compact read-only chip showing active writing days in the rolling 7-day window.
/// Hidden at 0; never displays a broken-streak state.
class ActiveDaysChip extends StatelessWidget {
  const ActiveDaysChip({super.key, required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    if (days <= 0) return const SizedBox.shrink();
    final c = context.colors;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(FikraSpace.screen, 0, FikraSpace.screen, 8),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Container(
          key: const ValueKey('notes-active-days'),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: c.brandPurpleTint, borderRadius: BorderRadius.circular(FikraRadius.full)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_fire_department_rounded, size: 15, color: c.brandPurpleFg),
              const SizedBox(width: 5),
              Flexible(
                child: SmartText(
                  context.l10n.activeDaysThisWeek(days),
                  style: context.text.meta.copyWith(color: c.brandPurpleFg, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Conditional 48 dp action strip under the Notes search bar.
/// Priority: (1) failed analysis → retry, (2) new link suggestions → Links,
/// (3) pending rewrites → review. Dismissible for the session.
class NotesActionStrip extends StatelessWidget {
  const NotesActionStrip({
    super.key,
    required this.kind,
    required this.count,
    required this.onAction,
    required this.onDismiss,
  });

  final NotesActionKind kind;
  final int count;
  final VoidCallback onAction;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final (IconData icon, String message, Color fg, Color bg, String? trailing) = switch (kind) {
      NotesActionKind.failed => (
        Icons.refresh_rounded,
        l10n.actionStripFailed(count),
        c.danger,
        c.dangerBg,
        l10n.actionStripRetry,
      ),
      NotesActionKind.suggestions => (
        Icons.auto_awesome_outlined,
        l10n.actionStripSuggestions(count),
        c.brandLimeFg,
        c.selected,
        null,
      ),
      NotesActionKind.rewrites => (
        Icons.edit_note_rounded,
        l10n.actionStripRewrites(count),
        c.warning,
        c.warningBg,
        null,
      ),
    };

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(FikraSpace.screen, 0, FikraSpace.screen, 8),
      child: SolidSurface(
        key: const ValueKey('notes-action-strip'),
        radius: FikraRadius.md,
        color: bg,
        borderColor: fg.withValues(alpha: 0.25),
        padding: EdgeInsets.zero,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Pressable.minTargetSize),
          child: Row(
            children: [
              Expanded(
                child: Pressable(
                  key: const ValueKey('notes-action-strip-tap'),
                  onTap: onAction,
                  pressedScale: 0.99,
                  minTarget: true,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 8, 10),
                    child: Row(
                      children: [
                        Icon(icon, size: 18, color: fg),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SmartText(
                            message,
                            style: context.text.chip.copyWith(color: fg, fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (trailing != null) ...[
                          const SizedBox(width: 8),
                          SmartText(
                            trailing,
                            style: context.text.meta.copyWith(color: fg, fontWeight: FontWeight.w700),
                          ),
                        ] else
                          Icon(Icons.chevron_right_rounded, size: 18, color: fg),
                      ],
                    ),
                  ),
                ),
              ),
              Pressable(
                key: const ValueKey('notes-action-strip-dismiss'),
                onTap: onDismiss,
                minTarget: true,
                semanticLabel: l10n.actionStripDismiss,
                child: Icon(Icons.close_rounded, size: 18, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Resolves the highest-priority non-dismissed action strip for [projectId], or null.
Widget? resolveNotesActionStrip(
  BuildContext context,
  WidgetRef ref, {
  required String projectId,
  required List<Note> notes,
  required int suggestionsCount,
}) {
  final dismissed = ref.watch(dismissedActionStripsProvider);
  final failed = [
    for (final n in notes)
      if (n.status == ProcessingStatus.failed) n,
  ];
  if (failed.isNotEmpty && !dismissed.contains((projectId, NotesActionKind.failed))) {
    return NotesActionStrip(
      kind: NotesActionKind.failed,
      count: failed.length,
      onAction: () {
        final processor = ref.read(noteProcessorProvider);
        for (final n in failed) {
          unawaited(processor.retry(n.id));
        }
      },
      onDismiss: () => ref.read(dismissedActionStripsProvider.notifier).dismiss(projectId, NotesActionKind.failed),
    );
  }
  if (suggestionsCount > 0 && !dismissed.contains((projectId, NotesActionKind.suggestions))) {
    return NotesActionStrip(
      kind: NotesActionKind.suggestions,
      count: suggestionsCount,
      onAction: () {
        ref.read(linksLibraryRequestedSegmentProvider.notifier).request(LinksLibrarySegment.suggestions);
        context.go('/links');
      },
      onDismiss: () => ref.read(dismissedActionStripsProvider.notifier).dismiss(projectId, NotesActionKind.suggestions),
    );
  }
  final rewrites = [
    for (final n in notes)
      if (n.status == ProcessingStatus.ready && n.rewrite == RewriteStatus.pending) n,
  ];
  if (rewrites.isNotEmpty && !dismissed.contains((projectId, NotesActionKind.rewrites))) {
    return NotesActionStrip(
      kind: NotesActionKind.rewrites,
      count: rewrites.length,
      onAction: () => context.push('/note/${rewrites.first.id}', extra: rewrites.first),
      onDismiss: () => ref.read(dismissedActionStripsProvider.notifier).dismiss(projectId, NotesActionKind.rewrites),
    );
  }
  return null;
}
