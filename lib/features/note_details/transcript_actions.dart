import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/local/database.dart';
import '../../data/processing/transcript_corrections.dart';
import '../../l10n/localizations.dart';

class TranscriptActions extends ConsumerStatefulWidget {
  const TranscriptActions({super.key, required this.attachment});
  final NoteAttachment attachment;
  @override
  ConsumerState<TranscriptActions> createState() => _TranscriptActionsState();
}

class _TranscriptActionsState extends ConsumerState<TranscriptActions> {
  bool _busy = false;
  int? _appendRevision;
  Future<void> _use({bool append = false}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(transcriptCorrectionsProvider)
          .save(
            widget.attachment.id,
            revision: append ? _appendRevision! : widget.attachment.transcriptRevision,
            append: append,
          );
      if (mounted) setState(() => _appendRevision = result.noteChanged ? null : result.revision);
    } catch (error) {
      if (mounted) {
        showToast(
          context,
          error is TranscriptConflict ? context.l10n.v2TranscriptConflict : context.l10n.v2TranscriptFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.attachment, l = context.l10n;
    final newer = a.hasNewTranscript;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FikraButton.secondary(
          key: ValueKey('transcript-edit-${a.id}'),
          label: l.v2EditTranscript,
          growForText: true,
          onPressed: _busy ? null : () => context.push('/note/${a.noteId}/transcript/${a.id}'),
        ),
        if (newer) ...[
          const SizedBox(height: FikraSpace.s8),
          StatusBanner(key: ValueKey('transcript-new-${a.id}'), kind: BannerKind.info, message: l.v2NewTranscript),
          FikraButton.secondary(
            key: ValueKey('transcript-use-${a.id}'),
            label: l.v2UseTranscript,
            loading: _busy,
            onPressed: _busy ? null : _use,
          ),
        ],
        if (_appendRevision != null) ...[
          StatusBanner(kind: BannerKind.info, message: l.v2CopyUnchanged),
          FikraButton.secondary(
            key: ValueKey('transcript-append-${a.id}'),
            label: l.v2AppendTranscript,
            growForText: true,
            onPressed: _busy ? null : () => _use(append: true),
          ),
        ],
      ],
    );
  }
}
