import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/composer_navigation.dart';
import '../../app/product_runtime.dart';
import '../../core/format.dart';
import '../../core/theme/redesign_tokens.dart';
import '../../core/widgets/redesign_widgets.dart';
import '../../l10n/localizations.dart';
import '../workspace/product_widgets.dart';
import '../workspace/tag_picker.dart';
import 'capture_controller.dart';

class ProductComposerScreen extends StatefulWidget {
  const ProductComposerScreen({super.key});
  @override
  State<ProductComposerScreen> createState() => _ComposerState();
}

class _ComposerState extends State<ProductComposerScreen> {
  ProductRuntime? _runtime;
  Object? _usedClip;
  bool _transcribing = false;
  void _consume(ProductRuntime r) {
    final c = r.capture, w = r.workspace;
    if (c.state != CaptureState.review ||
        c.clip == null ||
        identical(_usedClip, c.clip) ||
        w.pendingAttempt != null ||
        !w.draftsReady ||
        w.busy) {
      return;
    }
    _usedClip = c.clip;
    final text = c.transcript.trim(), previous = w.draft.content;
    if (text.isNotEmpty) w.updateDraft(content: previous.trim().isEmpty ? text : '$previous\n\n$text');
  }

  Future<void> _transcribe(ProductRuntime r) async {
    if (_transcribing) return;
    setState(() => _transcribing = true);
    final account = r.workspace.accountId, project = r.workspace.selectedProjectId;
    try {
      if (r.capture.state == CaptureState.recording) await r.capture.stop();
      if (!mounted || account != r.workspace.accountId || project != r.workspace.selectedProjectId) return;
      await r.capture.transcribe();
      if (mounted && account == r.workspace.accountId && project == r.workspace.selectedProjectId) _consume(r);
    } finally {
      if (mounted) setState(() => _transcribing = false);
    }
  }

  Future<void> _close(ProductRuntime r) async {
    unawaited(r.workspace.flushDraft());
    await r.capture.close();
    if (mounted) ComposerNavigation.closeOf(context);
  }

  @override
  void dispose() {
    final r = _runtime;
    if (r != null) {
      unawaited(r.workspace.flushDraft());
      unawaited(r.capture.close());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ProductView(
    listenTo: (r) => [r.workspace, r.capture, r.tags],
    builder: (context, r) {
      _runtime = r;
      final w = r.workspace, c = r.capture, l = context.l10n;
      final locked = w.busy || w.pendingAttempt != null || !w.draftsReady;
      if (c.state == CaptureState.review && !identical(_usedClip, c.clip)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _consume(r);
        });
      }
      final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
      final available =
          MediaQuery.sizeOf(context).height -
          MediaQuery.viewInsetsOf(context).bottom -
          MediaQuery.paddingOf(context).vertical;
      final compact = keyboard && available < 260;
      final save = RdButton(
        w.pendingAttempt == null
            ? l.rdSave
            : keyboard
            ? l.actionStripRetry
            : l.productReconcileTheSameSaveAttempt,
        key: const ValueKey('save-product-note'),
        loading: w.busy,
        onPressed:
            c.active ||
                w.selected == null ||
                !w.draftsReady ||
                w.coolingDown ||
                (w.pendingAttempt == null && w.draft.content.trim().isEmpty)
            ? null
            : () async {
                final account = w.accountId, project = w.selectedProjectId;
                final saved = await w.save();
                if (saved == null || account != w.accountId || project != w.selectedProjectId) return;
                c.clearAfterSave();
                unawaited(r.tags.bind(account));
                if (context.mounted) {
                  context.go('/notes');
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(l.rdSaved), behavior: SnackBarBehavior.floating));
                }
              },
      );
      return PopScope(
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) {
            unawaited(w.flushDraft());
            unawaited(c.close());
          }
        },
        child: Scaffold(
          backgroundColor: context.rd.bg,
          body: SafeArea(
            child: Column(
              children: [
                if (!compact)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Row(
                      children: [
                        RdIconButton('x', label: l.rdCancel, onPressed: () => _close(r)),
                        const Spacer(),
                        if (!w.draft.titleVisible)
                          Semantics(
                            button: true,
                            child: InkWell(
                              onTap: locked ? null : () => w.updateDraft(titleVisible: true),
                              borderRadius: BorderRadius.circular(99),
                              child: SizedBox(height: 44, child: Center(child: RdChip(l.rdAddt))),
                            ),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  key: const ValueKey('capture-editor-viewport'),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [
                      if (w.loading && w.selected == null) const Center(child: CircularProgressIndicator()),
                      if (w.failure != null) ProductFailureView(w.failure!, onRetry: w.retryWorkspace),
                      if (w.draftFailure) ...[
                        RdText(l.rdDraftFailed, size: 13, color: context.rd.red),
                        RdButton(
                          l.actionStripRetry,
                          primary: false,
                          onPressed: w.draftsReady ? w.flushDraft : w.restoreDrafts,
                        ),
                      ],
                      if (w.pendingAttempt != null) ...[
                        RdText(l.productASaveAttemptIsUnresolvedRetryItsOriginal, size: 13, color: context.rd.muted),
                        if (w.pendingAttempt!.projectId != w.selectedProjectId)
                          TextButton(
                            onPressed: () => w.selectProject(w.pendingAttempt!.projectId),
                            child: Text(l.productReturnToThePendingAttemptSProject),
                          ),
                      ],
                      if (w.canReviewFailedAttempt)
                        TextButton(
                          onPressed: () async {
                            final yes = await rdConfirm(
                              context,
                              title: l.productReviewFailedSave,
                              message: l.productNewIntentionalSaveExplanation,
                              confirm: l.productReviewFailedSave,
                            );
                            if (yes && context.mounted) await w.reviewFailedAttempt();
                          },
                          child: Text(l.productReviewFailedSave),
                        ),
                      if (w.draft.titleVisible)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _DraftField(
                            key: ValueKey('capture-title-${w.selectedProjectId}'),
                            value: w.draft.title,
                            hint: l.rdTph,
                            title: true,
                            enabled: !locked,
                            onChanged: (v) => w.updateDraft(title: v),
                          ),
                        ),
                      _DraftField(
                        key: ValueKey('capture-content-${w.selectedProjectId}'),
                        value: w.draft.content,
                        hint: l.rdCph,
                        enabled: !locked,
                        onChanged: (v) => w.updateDraft(content: v),
                      ),
                      if (c.failure != null) ProductFailureView(c.failure!),
                      if (c.state == CaptureState.recording) ...[
                        RdCard(
                          ai: true,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final status = Row(
                                children: [
                                  const _VoiceWave(),
                                  const SizedBox(width: 8),
                                  Expanded(child: RdText(l.rdLis, color: context.rd.purple)),
                                ],
                              );
                              final stop = RdButton(l.rdStop, full: false, onPressed: () => _transcribe(r));
                              return constraints.maxWidth < 420
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      spacing: 8,
                                      children: [status, stop],
                                    )
                                  : Row(
                                      spacing: 8,
                                      children: [
                                        Expanded(child: status),
                                        stop,
                                      ],
                                    );
                            },
                          ),
                        ),
                        RdText(
                          '${Fmt.duration(c.elapsed.inMilliseconds)} / 1:00',
                          key: const ValueKey('recording-time'),
                          size: 12,
                          color: context.rd.muted,
                        ),
                      ],
                      if (c.active && c.state != CaptureState.recording)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      if (c.state == CaptureState.recorded)
                        RdButton(
                          l.apiTranscribe,
                          key: const ValueKey('transcribe-product-voice'),
                          primary: false,
                          onPressed: c.coolingDown || locked ? null : () => _transcribe(r),
                        ),
                      if (c.clip != null && !c.active)
                        TextButton(onPressed: c.close, child: Text(l.productDiscardRecording)),
                      for (final tag in r.tags.tags.where((tag) => w.draft.tagIds.contains(tag.id)))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: RdChip(tag.label, small: true),
                          ),
                        ),
                      for (final pdf in c.localPdfs)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: RdText(pdf.name, size: 13),
                          subtitle: RdText(l.rdOnDevice, size: 12, color: context.rd.muted),
                          trailing: const RdIcon('file'),
                          onTap: () => c.openPdf(pdf),
                        ),
                    ],
                  ),
                ),
                if (!keyboard)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: context.rd.line)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 9, 16, 8),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final tools = <Widget>[
                            _CaptureTool(
                              l.rdVoice,
                              icon: 'mic',
                              key: const ValueKey('record-product-voice'),
                              onPressed: locked || c.active || c.pickingPdf ? null : c.start,
                            ),
                            _CaptureTool(l.rdPdf, icon: 'file', onPressed: c.pickingPdf || c.active ? null : c.pickPdf),
                            _CaptureTool(
                              l.rdTag,
                              icon: 'tag',
                              onPressed: locked || r.tags.loading
                                  ? null
                                  : () async {
                                      final account = w.accountId, project = w.selectedProjectId;
                                      final selected = await pickNoteTags(context, r.tags, w.draft.tagIds);
                                      if (mounted &&
                                          selected != null &&
                                          account == w.accountId &&
                                          project == w.selectedProjectId) {
                                        w.updateDraft(tagIds: selected);
                                      }
                                    },
                            ),
                          ];
                          final count = RdText('${w.draft.content.length}', size: 12, color: context.rd.muted);
                          return MediaQuery.textScalerOf(context).scale(13) > 18 || constraints.maxWidth < 288
                              ? Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [...tools, count],
                                )
                              : Row(spacing: 8, children: [...tools, const Spacer(), count]);
                        },
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!keyboard && w.draft.content.trim().isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: RdText(l.rdSh, size: 13, color: context.rd.muted),
                        ),
                      if (keyboard)
                        Row(
                          spacing: 4,
                          children: [
                            if (compact) RdIconButton('x', label: l.rdCancel, onPressed: () => _close(r)),
                            RdIconButton(
                              'mic',
                              label: l.rdVoice,
                              onPressed: locked || c.active || c.pickingPdf ? null : c.start,
                            ),
                            RdIconButton(
                              'file',
                              label: l.rdPdf,
                              onPressed: c.pickingPdf || c.active ? null : c.pickPdf,
                            ),
                            RdIconButton(
                              'tag',
                              label: l.rdTag,
                              onPressed: locked || r.tags.loading
                                  ? null
                                  : () async {
                                      final account = w.accountId, project = w.selectedProjectId;
                                      final selected = await pickNoteTags(context, r.tags, w.draft.tagIds);
                                      if (mounted &&
                                          selected != null &&
                                          account == w.accountId &&
                                          project == w.selectedProjectId) {
                                        w.updateDraft(tagIds: selected);
                                      }
                                    },
                            ),
                            Expanded(child: save),
                          ],
                        )
                      else
                        save,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _CaptureTool extends StatelessWidget {
  const _CaptureTool(this.label, {super.key, required this.icon, this.onPressed});
  final String label, icon;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: context.rd.text,
      disabledForegroundColor: context.rd.muted,
      backgroundColor: context.rd.surface2,
      minimumSize: const Size(44, 44),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(99),
        side: BorderSide(color: context.rd.line),
      ),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, spacing: 6, children: [RdIcon(icon), RdText(label, size: 13, lines: 1)]),
  );
}

class _DraftField extends StatefulWidget {
  const _DraftField({
    super.key,
    required this.value,
    required this.hint,
    required this.enabled,
    required this.onChanged,
    this.title = false,
  });
  final String value, hint;
  final bool enabled, title;
  final ValueChanged<String> onChanged;
  @override
  State<_DraftField> createState() => _DraftFieldState();
}

class _DraftFieldState extends State<_DraftField> {
  late final _controller = TextEditingController(text: widget.value);
  @override
  void didUpdateWidget(_DraftField old) {
    super.didUpdateWidget(old);
    if (_controller.text != widget.value) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(minHeight: widget.title ? 44 : 200),
    child: TextField(
      controller: _controller,
      enabled: widget.enabled,
      minLines: widget.title ? 1 : 6,
      maxLines: null,
      onChanged: (v) {
        widget.onChanged(v);
        setState(() {});
      },
      textDirection: rdDirection(_controller.text, Directionality.of(context)),
      textAlign: rdDirection(_controller.text, Directionality.of(context)) == TextDirection.rtl
          ? TextAlign.right
          : TextAlign.left,
      style: RdTokens.style(
        context,
        size: widget.title ? 22 : 17,
        weight: widget.title ? FontWeight.w600 : FontWeight.w400,
      ),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: RdTokens.style(
          context,
          size: widget.title ? 22 : 17,
          weight: widget.title ? FontWeight.w600 : FontWeight.w400,
          color: context.rd.muted,
        ),
        filled: false,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
      ),
    ),
  );
}

class _VoiceWave extends StatefulWidget {
  const _VoiceWave();
  @override
  State<_VoiceWave> createState() => _VoiceWaveState();
}

class _VoiceWaveState extends State<_VoiceWave> with SingleTickerProviderStateMixin {
  late final _animation = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _animation.stop();
    } else {
      _animation.repeat();
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: 32,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 3,
          children: List.generate(14, (i) {
            final elapsed = (_animation.lastElapsedDuration?.inMilliseconds ?? 0) - i * 70;
            final phase = (elapsed % 900) / 900;
            final triangular = phase <= .5 ? phase * 2 : (1 - phase) * 2;
            final scale = MediaQuery.disableAnimationsOf(context) || elapsed < 0
                ? 1.0
                : .2 + .8 * Curves.easeInOut.transform(triangular);
            return Transform.scale(
              scaleY: scale,
              child: Container(
                width: 4,
                height: 32,
                decoration: BoxDecoration(color: context.rd.purple, borderRadius: BorderRadius.circular(3)),
              ),
            );
          }),
        ),
      ),
    ),
  );
}
