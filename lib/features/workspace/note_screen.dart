import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../app/product_runtime.dart';
import '../../core/theme/redesign_tokens.dart';
import '../../core/widgets/redesign_widgets.dart';
import '../../core/widgets/redesign_segments.dart';
import '../../data/ids.dart';
import '../../data/product/models.dart';
import '../../l10n/localizations.dart';
import 'idea_card.dart';
import 'note_share.dart';
import 'note_undo_controller.dart';
import 'note_undo_feedback.dart';
import 'notes_screen.dart' show rdNoteTitle;
import 'product_widgets.dart';
import 'tag_picker.dart';
import 'word_diff.dart';
import '../account/redesign_auth_field.dart';

String rdNoteTimestamp(BuildContext context, DateTime timestamp) {
  final date = timestamp.toLocal(), now = DateTime.now(), l = context.l10n;
  final today = date.year == now.year && date.month == now.month && date.day == now.day;
  return '${today ? l.rdToday : DateFormat.yMMMd(l.localeName).format(date)} · ${DateFormat.jm(l.localeName).format(date)}';
}

enum _NoteAction { edit, reprocess, pin, share, delete }

enum _DiffMode { before, after, changes }

class ProductNoteScreen extends ConsumerStatefulWidget {
  const ProductNoteScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<ProductNoteScreen> createState() => _ProductNoteScreenState();
}

class _ProductNoteScreenState extends ConsumerState<ProductNoteScreen> {
  final _scroll = ScrollController();
  bool _scrolled = false, _sharing = false;
  _DiffMode _mode = _DiffMode.changes;
  String? _before, _after;
  List<WordChange> _changes = const [];
  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final value = _scroll.offset > 40;
      if (value != _scrolled) setState(() => _scrolled = value);
    });
    _open();
  }

  void _open() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) ref.read(productRuntimeProvider).workspace.openNote(widget.id);
  });
  @override
  void didUpdateWidget(ProductNoteScreen old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) {
      _mode = _DiffMode.changes;
      _open();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _tags(ProductRuntime r, KnowledgeNote n) async {
    final selected = await pickNoteTags(context, r.tags, r.tags.forNote(n.id).map((t) => t.id).toSet());
    if (selected != null) await r.tags.assign(n.id, selected);
  }

  Future<void> _apply(ProductRuntime r, KnowledgeNote n) async {
    final action = await r.undo.queue(n, UndoNoteKind.apply);
    if (action != null && mounted) showNoteUndo(context, r, action);
  }

  Future<void> _delete(ProductRuntime r, KnowledgeNote n) async {
    final l = context.l10n;
    final yes = await rdConfirm(context, title: l.rdDelq, message: l.rdDelb, confirm: l.rdDel, danger: true);
    if (!yes || !mounted) return;
    final action = await r.undo.queue(n, UndoNoteKind.delete);
    if (action != null && mounted) {
      showNoteUndo(context, r, action);
      context.go('/notes');
    }
  }

  Future<void> _share(ProductRuntime r, KnowledgeNote n) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final sharing = ref.read(noteSharingProvider);
      final bytes = await noteCardPng(
        context,
        title: rdNoteTitle(context, n.title, n.content),
        content: n.content,
        timestamp: rdNoteTimestamp(context, n.createdAt),
        tags: r.tags.forNote(n.id).map((t) => t.label).toList(),
      );
      if (!mounted) return;
      await sharing.share(bytes, filename: 'fikrah-note-${newId()}.png', mime: 'image/png');
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.rdShareFailed)));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _menu(ProductRuntime r, KnowledgeNote n) async {
    final l = context.l10n, pending = r.undo.forNote(n.id) != null;
    final action = await rdSheet<_NoteAction>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MenuItem(
            icon: 'file',
            label: l.productEditNote,
            value: _NoteAction.edit,
            enabled: !pending && !r.workspace.busy,
          ),
          _MenuItem(
            icon: 're',
            label: l.rdReana,
            value: _NoteAction.reprocess,
            enabled: !pending && !r.workspace.busy && !n.processing.pending,
          ),
          if (r.workspace.supportsFavorite)
            _MenuItem(
              icon: 'pin',
              label: n.isFavorite ? l.rdUnpin : l.rdPin,
              value: _NoteAction.pin,
              enabled: !r.workspace.busy,
            ),
          if (ref.read(noteSharingProvider).available)
            _MenuItem(icon: 'share', label: l.rdShare, value: _NoteAction.share, enabled: !_sharing),
          _MenuItem(
            icon: 'del',
            label: l.rdDel,
            value: _NoteAction.delete,
            danger: true,
            enabled: !pending && !r.undo.loading && !r.workspace.busy,
          ),
        ],
      ),
    );
    if (!mounted || action == null || r.workspace.detail?.id != n.id) return;
    switch (action) {
      case _NoteAction.edit:
        await rdSheet<void>(
          context,
          child: _NoteEditForm(runtime: r, note: n),
        );
      case _NoteAction.reprocess:
        await r.workspace.retryProcessing();
      case _NoteAction.pin:
        await r.workspace.setFavorite(!n.isFavorite, reviewedNoteId: n.id);
      case _NoteAction.share:
        await _share(r, n);
      case _NoteAction.delete:
        await _delete(r, n);
    }
  }

  Widget _proposal(BuildContext context, ProductRuntime r, KnowledgeNote n) {
    final l = context.l10n;
    if (_before != n.content || _after != n.proposal) {
      _before = n.content;
      _after = n.proposal;
      _changes = wordDiff(n.content, n.proposal!);
    }
    return RdCard(
      ai: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            spacing: 6,
            children: [
              RdIcon('spark', color: context.rd.purple),
              RdText(l.rdAisug, size: 13, weight: FontWeight.w600, color: context.rd.purple),
            ],
          ),
          RdSegments(
            values: {_DiffMode.before: l.rdBefore, _DiffMode.after: l.rdAfter, _DiffMode.changes: l.rdChg},
            selected: _mode,
            onChanged: (value) => setState(() => _mode = value),
          ),
          if (_mode != _DiffMode.changes)
            RdText(_mode == _DiffMode.before ? n.content : n.proposal!, selectable: true)
          else
            SelectableText.rich(
              TextSpan(
                style: RdTokens.style(context),
                children: [
                  for (final change in _changes)
                    TextSpan(
                      text: rdIsolate(change.text),
                      style: TextStyle(
                        backgroundColor: change.kind == DiffKind.added
                            ? context.rd.added
                            : change.kind == DiffKind.removed
                            ? context.rd.removed
                            : null,
                        decoration: change.kind == DiffKind.removed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                ],
              ),
              key: const ValueKey('refinement-proposal'),
              textDirection: rdDirection(n.proposal!),
            ),
          const SizedBox(height: 12),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: RdButton(
                  l.rdApply,
                  key: const ValueKey('accept-proposal'),
                  loading: r.workspace.busy,
                  onPressed: r.undo.loading || r.workspace.busy ? null : () => _apply(r, n),
                ),
              ),
              RdButton(
                l.rdDismiss,
                primary: false,
                full: false,
                onPressed: r.workspace.busy
                    ? null
                    : () => r.workspace.refine(
                        RefinementAction.reject,
                        reviewedNoteId: n.id,
                        expectedGeneration: n.generation,
                      ),
              ),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: context.rd.blue,
                textStyle: RdTokens.style(context),
                minimumSize: const Size(44, 44),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: r.workspace.busy
                  ? null
                  : () => r.workspace.refine(
                      RefinementAction.regenerate,
                      reviewedNoteId: n.id,
                      expectedGeneration: n.generation,
                    ),
              child: Text(l.rdAnother),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ProductView(
    listenTo: (r) => [r.workspace, r.tags, r.undo],
    builder: (context, r) {
      final w = r.workspace, l = context.l10n, n = w.detail;
      final note = n?.id == widget.id ? n : null;
      final title = note == null ? '' : rdNoteTitle(context, note.title, note.content);
      final pending = note == null ? null : r.undo.forNote(note.id);
      final optimistic = pending?.kind == UndoNoteKind.apply ? pending!.proposal : null;
      return RdPage(
        title: '',
        controller: _scroll,
        header: Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 10),
          child: Row(
            children: [
              RdIconButton(
                'back',
                label: l.rdHome,
                flip: true,
                onPressed: () => context.canPop() ? context.pop() : context.go('/notes'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AnimatedOpacity(
                  opacity: _scrolled ? 1 : 0,
                  duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 200),
                  child: RdText(title, weight: FontWeight.w600, lines: 1),
                ),
              ),
              RdIconButton(
                'more',
                key: const ValueKey('note-menu'),
                label: l.rdNoteActions,
                onPressed: note == null ? null : () => _menu(r, note),
              ),
            ],
          ),
        ),
        children: [
          if (w.detailLoading) const Center(child: CircularProgressIndicator()),
          if (w.detailFailure != null) ProductFailureView(w.detailFailure!, onRetry: () => w.openNote(widget.id)),
          NoteUndoFeedback(runtime: r),
          if (w.proposalConflict) RdText(l.productTheCurrentProposalWasReloadedReviewItBefore, color: context.rd.red),
          if (note == null && !w.detailLoading && w.detailFailure == null)
            RdText(l.productThisNoteIsUnavailableInTheSelectedProject, color: context.rd.muted),
          if (note != null) ...[
            RdText(title, size: 24, height: 1.4, weight: FontWeight.w600),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 14),
              child: Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  RdText(rdNoteTimestamp(context, note.createdAt), size: 13, color: context.rd.muted),
                  if (note.processing.pending) ...[
                    ProcessingDot(label: l.rdProc),
                    RdText(l.rdProc, size: 13, color: context.rd.muted),
                  ],
                  if (note.processing == ProcessingState.failed)
                    RdText(processingText(context, note.processing), size: 13, color: context.rd.red),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: RdText(optimistic ?? note.content, size: 17, selectable: true),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in r.tags.forNote(note.id)) RdChip(tag.label),
                  Semantics(
                    label: l.rdTag,
                    button: true,
                    child: RdChip(
                      '',
                      key: const ValueKey('note-add-tag'),
                      icon: 'plus',
                      onPressed: () => _tags(r, note),
                    ),
                  ),
                ],
              ),
            ),
            if (r.tags.failure != null) ProductFailureView(r.tags.failure!),
            if (note.proposal != null && note.processing == ProcessingState.completed && optimistic == null)
              _proposal(context, r, note),
            if (pending?.state == UndoNoteState.committing)
              RdText(l.rdPendingChange, size: 13, color: context.rd.muted),
            if (w.related.where((n) => !r.undo.hiddenIds.contains(n.noteId)).isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 2, 2, 8),
                child: RdText(l.rdRel, size: 13, color: context.rd.muted),
              ),
              for (final related in w.related.where((n) => !r.undo.hiddenIds.contains(n.noteId)))
                _RelatedCard(runtime: r, note: note, related: related),
            ],
          ],
        ],
      );
    },
  );
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.value,
    this.danger = false,
    this.enabled = true,
  });
  final String icon, label;
  final _NoteAction value;
  final bool danger, enabled;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: enabled ? () => Navigator.pop(context, value) : null,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          spacing: 12,
          children: [
            RdIcon(
              icon,
              color: !enabled
                  ? context.rd.muted
                  : danger
                  ? context.rd.red
                  : context.rd.text,
            ),
            Expanded(
              child: RdText(
                label,
                color: !enabled
                    ? context.rd.muted
                    : danger
                    ? context.rd.red
                    : context.rd.text,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RelatedCard extends StatelessWidget {
  const _RelatedCard({required this.runtime, required this.note, required this.related});
  final ProductRuntime runtime;
  final KnowledgeNote note;
  final NoteSourceReference related;
  @override
  Widget build(BuildContext context) {
    final ids = runtime.tags.forNote(note.id).map((t) => t.id).toSet();
    final shared = runtime.tags.forNote(related.noteId).where((t) => ids.contains(t.id)).firstOrNull;
    final known = runtime.workspace.notes.where((n) => n.id == related.noteId).firstOrNull;
    return RdCard(
      onTap: () => context.push('/note/${related.noteId}'),
      child: Row(
        spacing: 8,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RdText(rdNoteTitle(context, related.title, known?.content ?? ''), weight: FontWeight.w600),
                if (shared != null)
                  RdText('${context.l10n.rdShared}${rdIsolate(shared.label)}', size: 13, color: context.rd.muted),
              ],
            ),
          ),
          const RdIcon('chev', flip: true),
        ],
      ),
    );
  }
}

class _NoteEditForm extends StatefulWidget {
  const _NoteEditForm({required this.runtime, required this.note});
  final ProductRuntime runtime;
  final KnowledgeNote note;
  @override
  State<_NoteEditForm> createState() => _NoteEditFormState();
}

class _NoteEditFormState extends State<_NoteEditForm> {
  late String _title = widget.note.title ?? '', _content = widget.note.content;
  late final _body = TextEditingController(text: _content);
  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.runtime.workspace,
    builder: (context, _) {
      final l = context.l10n;
      final available =
          MediaQuery.sizeOf(context).height -
          MediaQuery.viewInsetsOf(context).bottom -
          MediaQuery.paddingOf(context).vertical;
      final compact = available < 260;
      return SizedBox(
        height: math.max(100, math.min(560, available - 38)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!compact)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RdText(l.productEditNote, size: 18, weight: FontWeight.w600),
              ),
            Expanded(
              key: const ValueKey('note-edit-viewport'),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  RedesignAuthField(
                    key: const ValueKey('edit-title'),
                    value: _title,
                    label: l.rdTph,
                    enabled: !widget.runtime.workspace.busy,
                    onChanged: (v) => setState(() => _title = v),
                  ),
                  const SizedBox(height: 12),
                  KeyedSubtree(
                    key: const ValueKey('edit-content'),
                    child: TextField(
                      controller: _body,
                      enabled: !widget.runtime.workspace.busy,
                      onChanged: (v) => setState(() => _content = v),
                      minLines: 5,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textDirection: rdDirection(_content, Directionality.of(context)),
                      textAlign: rdDirection(_content, Directionality.of(context)) == TextDirection.rtl
                          ? TextAlign.right
                          : TextAlign.left,
                      style: RdTokens.style(context, size: 17),
                      decoration: InputDecoration(
                        hintText: l.rdCph,
                        hintStyle: RdTokens.style(context, size: 17, color: context.rd.muted),
                        filled: true,
                        fillColor: context.rd.bg,
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: context.rd.line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: context.rd.line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: context.rd.blue),
                        ),
                      ),
                    ),
                  ),
                  if (widget.runtime.workspace.detailFailure != null)
                    ProductFailureView(widget.runtime.workspace.detailFailure!),
                ],
              ),
            ),
            const SizedBox(height: 12),
            RdButton(
              l.productSaveEdit,
              key: const ValueKey('save-note-edit'),
              loading: widget.runtime.workspace.busy,
              onPressed: _content.trim().isEmpty
                  ? null
                  : () async {
                      if (widget.runtime.workspace.detail?.id != widget.note.id) return;
                      final ok = await widget.runtime.workspace.edit(
                        NotePatch(
                          content: _content.trim(),
                          title: _title.trim().isEmpty ? null : _title.trim(),
                          includesTitle: true,
                        ),
                      );
                      if (ok && context.mounted) Navigator.pop(context);
                    },
            ),
          ],
        ),
      );
    },
  );
}
