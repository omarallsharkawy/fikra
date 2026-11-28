import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/processing/transcript_corrections.dart';
import '../../l10n/localizations.dart';

class TranscriptEditorScreen extends ConsumerStatefulWidget {
  const TranscriptEditorScreen({super.key, required this.noteId, required this.attachmentId});
  final String noteId, attachmentId;
  @override
  ConsumerState<TranscriptEditorScreen> createState() => _TranscriptEditorScreenState();
}

class _TranscriptEditorScreenState extends ConsumerState<TranscriptEditorScreen> {
  TextEditingController? _text;
  String _initial = '';
  int _revision = 0;
  bool _busy = false, _allowPop = false, _append = false;
  String? _error, _savedCorrection;
  bool get _dirty => _text != null && _text!.text != _initial;
  @override
  void dispose() {
    _text?.dispose();
    super.dispose();
  }

  void _exit() {
    // A second back tap before the pop lands must not close the note too.
    if (_allowPop) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.pop();
    });
  }

  Future<void> _leave() async {
    if (_busy) return;
    if (!_dirty) return _exit();
    final choice = await showFikraSheet<String>(
      context,
      title: context.l10n.unsavedTitle,
      builder: (sheet) => Column(
        children: [
          SheetOption(
            label: context.l10n.saveChanges,
            icon: Icons.check_rounded,
            onTap: () => Navigator.pop(sheet, 'save'),
          ),
          SheetOption(
            label: context.l10n.discardChanges,
            icon: Icons.close_rounded,
            danger: true,
            onTap: () => Navigator.pop(sheet, 'discard'),
          ),
          SheetOption(label: context.l10n.keepEditing, icon: Icons.edit_outlined, onTap: () => Navigator.pop(sheet)),
        ],
      ),
    );
    if (!mounted) return;
    if (choice == 'save') await _save();
    if (choice == 'discard') _exit();
  }

  Future<void> _save({bool restore = false, bool append = false}) async {
    if (_busy || _text == null) return;
    final correction = append
        ? _savedCorrection
        : restore
        ? null
        : _text!.text.trim();
    if (correction != null && correction.isEmpty) {
      showToast(context, context.l10n.v2TranscriptEmpty);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(transcriptCorrectionsProvider)
          .save(widget.attachmentId, revision: _revision, correction: correction, append: append);
      if (!mounted) return;
      if (result.noteChanged) {
        showToast(context, context.l10n.v2TranscriptSaved);
        _exit();
      } else {
        final files = ref.read(noteAttachmentsProvider(widget.noteId)).value ?? [];
        final a = files.where((a) => a.id == widget.attachmentId).firstOrNull;
        setState(() {
          _revision = result.revision;
          _savedCorrection = correction;
          _append = true;
          if (restore && a?.transcript != null) _text!.text = a!.transcript!;
          _initial = _text!.text;
        });
      }
    } on TranscriptConflict {
      if (mounted) setState(() => _error = context.l10n.v2TranscriptConflict);
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.v2TranscriptFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final files = ref.watch(noteAttachmentsProvider(widget.noteId));
    final a = files.value?.where((a) => a.id == widget.attachmentId).firstOrNull;
    final l = context.l10n;
    if (_text == null && a?.transcript != null) {
      _initial = a!.transcriptCorrection ?? a.transcript!;
      _text = TextEditingController(text: _initial);
      _revision = a.transcriptRevision;
    }
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (popped, _) {
        if (!popped) _leave();
      },
      child: FikraScaffold(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FikraIconButton(icon: Icons.arrow_back_rounded, label: l.back, onTap: _leave),
            ),
            Expanded(
              child: _text == null || a == null
                  ? Center(child: SmartText(files.hasError || files.hasValue ? l.v2TranscriptFailed : l.vtWait))
                  : ListView(
                      key: const ValueKey('v2-editor-scroll'),
                      padding: const EdgeInsets.all(FikraSpace.screen),
                      children: [
                        SmartText(l.v2EditTranscript, content: ReadOnlyContent.chrome, style: context.text.title),
                        const SizedBox(height: FikraSpace.s16),
                        SolidSurface(
                          radius: FikraRadius.lg,
                          padding: const EdgeInsets.all(FikraSpace.s16),
                          child: SmartInput(
                            key: const ValueKey('v2-transcript-field'),
                            controller: _text,
                            readOnly: _busy,
                            onChanged: (_) => setState(() => _append = false),
                            minLines: 8,
                            maxLines: 20,
                            style: context.text.bodyLarge,
                            decoration: InputDecoration(border: InputBorder.none, hintText: l.v2EditTranscript),
                          ),
                        ),
                        const SizedBox(height: FikraSpace.s16),
                        if (_error != null) StatusBanner(kind: BannerKind.error, message: _error!),
                        if (_append) ...[
                          StatusBanner(
                            key: const ValueKey('v2-copy-unchanged'),
                            kind: BannerKind.info,
                            message: l.v2CopyUnchanged,
                          ),
                          FikraButton.secondary(
                            key: const ValueKey('v2-append'),
                            label: l.v2AppendTranscript,
                            growForText: true,
                            onPressed: _busy ? null : () => _save(append: true),
                          ),
                        ],
                        FikraButton(
                          key: const ValueKey('v2-transcript-save'),
                          label: l.save,
                          loading: _busy,
                          onPressed: _busy ? null : _save,
                        ),
                        const SizedBox(height: FikraSpace.s12),
                        if (a.transcriptCorrection != null)
                          FikraButton.secondary(
                            key: const ValueKey('v2-transcript-restore'),
                            label: l.v2RestoreTranscript,
                            growForText: true,
                            onPressed: _busy ? null : () => _save(restore: true),
                          ),
                        FikraButton.secondary(
                          key: const ValueKey('v2-transcript-cancel'),
                          label: l.cancel,
                          onPressed: _busy ? null : _leave,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
