import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/motion/motion.dart';
import '../../core/motion/pressable.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/local/database.dart';
import '../projects/project_header.dart';
import '../shared/note_presentation.dart';

class AskScreen extends ConsumerStatefulWidget {
  const AskScreen({super.key});

  @override
  ConsumerState<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends ConsumerState<AskScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _thinking = false;

  // Messages already on screen. Only ids that arrive later animate in, so the
  // first load and a project switch show the history as-is.
  String? _chatProject;
  Set<String>? _seen;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final q = (preset ?? _input.text).trim();
    final project = ref.read(selectedProjectProvider);
    if (q.isEmpty || project == null || _thinking) return;
    setState(() => _thinking = true);
    final chat = ref.read(chatRepoProvider);
    try {
      await chat.add(projectId: project.id, role: 'user', body: q);
      if (preset == null) _input.clear(); // keep the draft until it's stored
      _toBottom();
      final notes = await ref.read(notesRepoProvider).notesOf(project.id);
      final answer = await ref.read(aiServiceProvider).ask(q, notes).timeout(const Duration(seconds: 60));
      await chat.add(
        projectId: project.id,
        role: 'assistant',
        body: answer.text,
        sourceIds: answer.sourceIds,
        found: answer.found,
      );
    } catch (_) {
      if (mounted) showToast(context, context.l10n.askFailed);
    } finally {
      if (mounted) setState(() => _thinking = false);
      _toBottom();
    }
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      // During an empty ↔ chat swap the outgoing list can still be attached;
      // the newest position is the visible one.
      final position = _scroll.positions.last;
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
        position.jumpTo(position.maxScrollExtent);
      } else {
        position.animateTo(position.maxScrollExtent, duration: FikraMotion.expand, curve: FikraMotion.expandCurve);
      }
    });
  }

  Future<void> _clear() async {
    final project = ref.read(selectedProjectProvider);
    if (project == null || _thinking) return;
    final ok = await confirmDestructive(
      context,
      title: context.l10n.clearChatTitle,
      message: context.l10n.clearChatBody,
      confirmLabel: context.l10n.clear,
    );
    if (ok && mounted) await runAction(context, () => ref.read(chatRepoProvider).clear(project.id));
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(selectedChatProvider);
    final entries = chatAsync.value ?? const <ChatEntry>[];
    final projectId = ref.watch(selectedProjectProvider)?.id;
    if (projectId != _chatProject) {
      _chatProject = projectId;
      _seen = null;
    }
    final seen = _seen;
    final newMessages = seen == null
        ? const <String>{}
        : {
            for (final e in entries)
              if (!seen.contains(e.id)) e.id,
          };
    if (chatAsync.hasValue) _seen = {...?seen, for (final e in entries) e.id};
    final notes = ref.watch(selectedNotesProvider).value ?? const <Note>[];
    final notesById = {for (final n in notes) n.id: n};
    // Suggestions come from the user's own notes, so they always have an answer.
    final suggestions = [
      for (final n in notes.where((n) => n.title.trim().isNotEmpty).take(3)) context.l10n.askSuggestion(n.title.trim()),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProjectHeader(
          title: context.l10n.askTitle,
          trailing: entries.isEmpty || _thinking
              ? null
              : Pressable(
                  onTap: _clear,
                  minTarget: true,
                  semanticLabel: context.l10n.clearChatA11y,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.delete_sweep_outlined, color: context.colors.textSecondary),
                  ),
                ),
        ),
        if (isDemo)
          Padding(
            padding: EdgeInsets.fromLTRB(FikraSpace.screen, 0, FikraSpace.screen, 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: FikraBadge(kind: BadgeKind.demo, label: context.l10n.askDemoBadge),
            ),
          ),
        Expanded(
          child: FikraSwitcher(
            child: KeyedSubtree(
              key: ValueKey(
                chatAsync.hasError && !chatAsync.hasValue
                    ? 'error'
                    : entries.isEmpty && !_thinking
                    ? 'empty'
                    : 'chat',
              ),
              child: chatAsync.hasError && !chatAsync.hasValue
                  ? LoadErrorView(onRetry: () => ref.invalidate(selectedChatProvider))
                  : entries.isEmpty && !_thinking
                  ? ListView(
                      padding: const EdgeInsets.symmetric(horizontal: FikraSpace.screen),
                      children: [
                        EmptyState(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          icon: Icons.chat_bubble_outline_rounded,
                          title: context.l10n.askEmptyTitle,
                          description: notes.isEmpty ? context.l10n.askEmptyNoNotes : context.l10n.askEmptyBody,
                        ),
                        if (suggestions.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [for (final s in suggestions) FikraChip(label: s, onTap: () => _send(s))],
                          ),
                        ],
                      ],
                    )
                  : ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(FikraSpace.screen, 4, FikraSpace.screen, 16),
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      children: [
                        for (final e in entries)
                          Padding(
                            key: ValueKey(e.id),
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _MessageEnter(
                              animate: newMessages.contains(e.id),
                              child: e.isUser ? _UserBubble(e.body) : _AnswerBubble(entry: e, notesById: notesById),
                            ),
                          ),
                        FikraSwitcher(
                          child: _thinking
                              ? Align(
                                  key: const ValueKey('thinking'),
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: Glass(
                                    radius: FikraRadius.lg,
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: context.colors.accentLight,
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(key: ValueKey('idle')),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(FikraSpace.screen, 4, FikraSpace.screen, 8),
          child: Row(
            children: [
              Expanded(
                child: FikraField(
                  controller: _input,
                  hint: context.l10n.askHint,
                  textInputAction: TextInputAction.send,
                  maxLength: 500,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              Opacity(
                opacity: _input.text.trim().isEmpty || _thinking ? 0.4 : 1,
                child: Pressable(
                  onTap: _input.text.trim().isEmpty || _thinking ? null : _send,
                  semanticLabel: context.l10n.send,
                  child: Container(
                    width: FikraSpace.field,
                    height: FikraSpace.field,
                    decoration: BoxDecoration(gradient: context.colors.sendGradient, shape: BoxShape.circle),
                    child: Icon(Icons.arrow_upward_rounded, color: context.colors.textOnSend),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: context.colors.selectedGradient,
            borderRadius: BorderRadius.circular(FikraRadius.md),
          ),
          child: Text(text, style: context.text.body.copyWith(color: context.colors.textOnSelected)),
        ),
      ),
    );
  }
}

class _AnswerBubble extends StatelessWidget {
  const _AnswerBubble({required this.entry, required this.notesById});
  final ChatEntry entry;
  final Map<String, Note> notesById;

  @override
  Widget build(BuildContext context) {
    final sources = entry.sourceList;
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.88),
        child: Glass(
          radius: FikraRadius.lg,
          borderColor: entry.found ? context.colors.border : context.colors.warning.withValues(alpha: 0.5),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!entry.found) ...[
                Row(
                  children: [
                    Icon(Icons.search_off_rounded, size: 18, color: context.colors.warning),
                    const SizedBox(width: 6),
                    Text(
                      context.l10n.notFoundInNotes,
                      style: context.text.chip.copyWith(color: context.colors.warning),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Text(entry.body, style: context.text.answer),
              if (sources.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(context.l10n.sources, style: context.text.meta.copyWith(fontSize: 12)),
                const SizedBox(height: 6),
                for (var i = 0; i < sources.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _SourceRow(index: i + 1, note: notesById[sources[i]]),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.index, required this.note});
  final int index;
  final Note? note;

  @override
  Widget build(BuildContext context) {
    final n = note;
    return Pressable(
      pressedScale: 0.98,
      onTap: n == null ? null : () => context.push('/note/${n.id}'),
      semanticLabel: n == null
          ? context.l10n.sourceDeletedA11y(index)
          : context.l10n.sourceA11y(index, noteTitle(context, n)),
      child: Container(
        constraints: const BoxConstraints(minHeight: Pressable.minTargetSize),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: context.colors.pressed, borderRadius: BorderRadius.circular(FikraRadius.sm)),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: context.colors.selectedEnd, shape: BoxShape.circle),
              child: Text(
                '$index',
                style: context.text.meta.copyWith(color: context.colors.textOnSelected, height: 1.1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                n == null ? context.l10n.deletedNote : noteTitle(context, n),
                style: context.text.chip.copyWith(color: n == null ? context.colors.textMeta : context.colors.textLink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (n != null) Icon(Icons.chevron_right_rounded, size: 18, color: context.colors.textMeta),
          ],
        ),
      ),
    );
  }
}

/// A message animates once when appended, never when a stream updates it or
/// when an existing conversation is first loaded / another project is opened.
class _MessageEnter extends StatefulWidget {
  const _MessageEnter({required this.animate, required this.child});
  final bool animate;
  final Widget child;

  @override
  State<_MessageEnter> createState() => _MessageEnterState();
}

class _MessageEnterState extends State<_MessageEnter> with SingleTickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(vsync: this, value: 1);
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    if (widget.animate) {
      _enter.duration = FikraMotion.reduced(context) ? FikraMotion.reducedFade : FikraMotion.enter;
      _enter.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = FikraMotion.reduced(context);
    return AnimatedBuilder(
      animation: _enter,
      child: widget.child,
      builder: (context, child) {
        final progress = reduced ? _enter.value : FikraMotion.enterCurve.transform(_enter.value);
        return Transform.translate(
          offset: Offset(0, reduced ? 0 : FikraMotion.messageOffset * (1 - progress)),
          child: Opacity(opacity: progress, child: child),
        );
      },
    );
  }
}
