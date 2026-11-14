import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../l10n/localizations.dart';
import 'voice_text_backend.dart';
import 'voice_text_copy.dart';
import 'whisper_metrics.dart';

class VoiceTextResult extends StatelessWidget {
  const VoiceTextResult({super.key, required this.run});
  final Map<String, Object?> run;
  String _number(String key, [int decimals = 1]) => Fmt.isolate((run[key] as num).toStringAsFixed(decimals));

  // Number and Latin unit are isolated together so Arabic does not show "MB 84.0".
  String _mb(AppLocalizations l, String key) => Fmt.isolate(l.sizeMb((run[key] as num).toStringAsFixed(1)));
  String _ms(AppLocalizations l, String key) => Fmt.isolate(l.vtMs((run[key] as num).toStringAsFixed(0)));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = run['text'] as String? ?? '';
    final live = run['mode'] == 'live';
    final factor = (run['rtf'] as num?)?.toDouble();
    final model = allSpikeModels.where((m) => m.filename == run['model']).firstOrNull;
    final issue =
        VoiceTextIssue.values.where((i) => i.name == run['error_kind']).firstOrNull ?? VoiceTextIssue.transcription;
    Widget number(String label) => Padding(
      padding: const EdgeInsets.only(top: FikraSpace.s4),
      child: Text(label, style: context.text.caption),
    );
    return Glass(
      key: const ValueKey('vt-result-card'),
      radius: FikraRadius.md,
      padding: const EdgeInsets.all(FikraSpace.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (model != null)
            Text(modelLabel(l, model, bytes: (run['model_bytes'] as num?)?.toInt()), style: context.text.section),
          const SizedBox(height: FikraSpace.s8),
          if (run['error'] != null) StatusBanner(kind: BannerKind.error, message: issueMessage(l, issue)),
          if (text.isNotEmpty || run['error'] == null)
            SelectableText(
              text.isEmpty ? l.vtNoSpeech : text,
              textDirection: containsArabic(text) ? TextDirection.rtl : TextDirection.ltr,
              style: context.text.bodyLarge,
            ),
          const SizedBox(height: FikraSpace.s16),
          Text(l.vtNumbers, style: context.text.section),
          number(l.vtAudioLength(_number('audio_seconds'))),
          number(l.vtWall(Fmt.isolate(((run['wall_ms'] as num) / 1000).toStringAsFixed(2)))),
          if (!live && factor != null && factor > 0)
            number(
              factor <= 1
                  ? l.vtFaster(Fmt.isolate((1 / factor).toStringAsFixed(1)))
                  : l.vtSlower(Fmt.isolate(factor.toStringAsFixed(1))),
            ),
          if (factor != null) number(l.vtFactor(_number('rtf', 3))),
          if (run['rss_before_mb'] != null && run['rss_after_mb'] != null)
            number(l.vtMemory(_mb(l, 'rss_before_mb'), _mb(l, 'rss_after_mb'))),
          if (run['rss_max_mb'] != null) number(l.vtPeak(_mb(l, 'rss_max_mb'))),
          if (run['conversion_ms'] != null) number(l.vtConversion(_ms(l, 'conversion_ms'))),
          if (run['transcription_wall_ms_estimate'] != null)
            number(l.vtEstimate(_ms(l, 'transcription_wall_ms_estimate'))),
          if (run['model_load_ms'] != null) number(l.vtModelLoad(_ms(l, 'model_load_ms'))),
          const SizedBox(height: FikraSpace.s8),
          Text(live ? l.vtLiveTiming : l.vtTimingHint, style: context.text.caption),
        ],
      ),
    );
  }
}

/// Everyday result: the transcript and elapsed seconds. Raw measurements remain
/// in the collapsed testing area, using the same run data.
class VoiceTextTranscript extends StatelessWidget {
  const VoiceTextTranscript({super.key, required this.run});
  final Map<String, Object?> run;
  @override
  Widget build(BuildContext context) {
    final text = run['text'] as String? ?? '';
    final seconds = ((run['wall_ms'] as num) / 1000).toStringAsFixed(2);
    return Glass(
      key: const ValueKey('vt-last-result'),
      radius: FikraRadius.md,
      padding: const EdgeInsets.all(FikraSpace.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (text.isNotEmpty || run['error'] == null)
            SelectableText(
              text.isEmpty ? context.l10n.vtNoSpeech : text,
              style: context.text.bodyLarge,
              textDirection: containsArabic(text) ? TextDirection.rtl : TextDirection.ltr,
            ),
          const SizedBox(height: FikraSpace.s8),
          Text(context.l10n.vtWall(Fmt.isolate(seconds)), style: context.text.caption),
          if (run['mode'] == 'live') Text(context.l10n.vtLiveTiming, style: context.text.caption),
        ],
      ),
    );
  }
}
