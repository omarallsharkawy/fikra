import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/local/database.dart';
import '../../data/processing/transcription_engine.dart';
import '../../l10n/localizations.dart';
import '../shared/transcription_notifications.dart';
import '../voice_text/voice_text_copy.dart';
import '../voice_text/whisper_metrics.dart';
import '../voice_text/whisper_models.dart';

/// A saved recording's durable state. No native engine calls from presentation.
class VoiceTranscript extends ConsumerStatefulWidget {
  const VoiceTranscript({super.key, required this.attachment});
  final NoteAttachment attachment;
  @override
  ConsumerState<VoiceTranscript> createState() => _VoiceTranscriptState();
}

class _VoiceTranscriptState extends ConsumerState<VoiceTranscript> {
  bool _expanded = false;
  bool _queuing = false;

  Future<void> _enqueue() async {
    if (_queuing) return;
    setState(() => _queuing = true);
    try {
      await ref
          .read(transcriptionQueueProvider)
          .enqueue(widget.attachment.id, redo: widget.attachment.transcript != null, manual: true);
      if (mounted) unawaited(askTranscriptionNotificationsOnce(context, ref));
    } catch (_) {
      if (mounted) showToast(context, context.l10n.trQueueFailed);
    } finally {
      if (mounted) setState(() => _queuing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.attachment;
    final l = context.l10n;
    final waiting =
        a.transcriptionStatus == TranscriptionStatus.queued || a.transcriptionStatus == TranscriptionStatus.running;
    final failure = a.transcriptionFailure;
    // A smaller model is one way out of repeated closing, so offer settings too.
    final settings =
        failure == TranscriptionFailureReason.modelMissing.name ||
        failure == TranscriptionFailureReason.interruptedTwice.name;
    final transcript = a.transcript;
    final engine = a.transcriptionEngine;
    final localModel = allSpikeModels.where((m) => 'local:${m.filename}' == engine).firstOrNull;
    return Glass(
      key: ValueKey('transcript-${a.id}'),
      radius: FikraRadius.lg,
      padding: const EdgeInsets.all(FikraSpace.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: FikraSpace.s8,
        children: [
          if (waiting)
            Semantics(
              liveRegion: true,
              child: FikraBadge(
                kind: BadgeKind.processing,
                label: a.transcriptionStatus == TranscriptionStatus.queued ? l.trQueued : l.trWorking,
              ),
            ),
          if (transcript != null && transcript.isNotEmpty) ...[
            Semantics(
              key: ValueKey('transcript-text-${a.id}'),
              expanded: _expanded,
              child: _expanded
                  ? SelectableText(
                      transcript,
                      style: context.text.body,
                      textDirection: containsArabic(transcript) ? TextDirection.rtl : TextDirection.ltr,
                    )
                  : Text(
                      transcript,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.body,
                      textDirection: containsArabic(transcript) ? TextDirection.rtl : TextDirection.ltr,
                    ),
            ),
            FikraButton.secondary(
              key: ValueKey('transcript-expand-${a.id}'),
              label: _expanded ? l.trCollapse : l.trExpand,
              growForText: true,
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
          ],
          if (engine != null) ...[
            Text(
              localModel != null ? l.trLocalEngine(modelName(l, localModel)) : Fmt.isolate(engine),
              key: ValueKey('transcript-engine-${a.id}'),
              style: context.text.meta,
            ),
          ],
          if (a.transcriptionStatus == TranscriptionStatus.failed) ...[
            StatusBanner(
              kind: BannerKind.error,
              message: switch (a.transcriptionFailure) {
                'modelMissing' => l.trModelMissing,
                'busy' => l.trBusy,
                'audioUnreadable' => l.trAudioUnreadable,
                'interruptedTwice' => l.trInterruptedTwice,
                _ => l.trFailed,
              },
            ),
            if (settings)
              FikraButton.secondary(
                key: ValueKey('transcript-settings-${a.id}'),
                label: l.trOpenSettings,
                growForText: true,
                onPressed: () => context.push('/settings/voice-text'),
              ),
          ],
          if (!waiting)
            FikraButton.secondary(
              key: ValueKey('transcribe-${a.id}'),
              label: a.transcriptionStatus == TranscriptionStatus.failed
                  ? l.retry
                  : transcript == null
                  ? l.trTranscribe
                  : l.trRedo,
              icon: Icons.record_voice_over_outlined,
              growForText: true,
              loading: _queuing,
              onPressed: _queuing ? null : _enqueue,
            ),
        ],
      ),
    );
  }
}
