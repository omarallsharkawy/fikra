import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/motion/motion.dart';
import '../../core/motion/pressable.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/glass.dart';
import '../../l10n/localizations.dart';
import '../activity_providers.dart';

/// Floating glass pill above the tab bar showing background recording (while
/// on another tab) or background transcription, tapping through to its owner.
class ActivityCapsule extends ConsumerWidget {
  const ActivityCapsule({super.key, required this.branch, required this.onOpenAdd, required this.onOpenNote});

  final int branch;
  final VoidCallback onOpenAdd;
  final ValueChanged<String> onOpenNote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingInAdd = ref.watch(addRecordingLiveProvider);
    final transcribingNoteId = ref.watch(activeTranscriptionNoteIdProvider).value;
    final showRecording = recordingInAdd && branch != 0;
    final showTranscribing = !showRecording && transcribingNoteId != null;

    return FikraSwitcher(
      alignment: AlignmentDirectional.bottomStart,
      child: showRecording
          ? Padding(
              key: const ValueKey('capsule-recording'),
              padding: const EdgeInsets.only(bottom: 10),
              child: _RecordingCapsuleButton(
                elapsed: ref.read(recordingActiveProvider.notifier).elapsed,
                onTap: onOpenAdd,
              ),
            )
          : showTranscribing
          ? Padding(
              key: ValueKey('capsule-transcribing-$transcribingNoteId'),
              padding: const EdgeInsets.only(bottom: 10),
              child: _TranscribingCapsuleButton(onTap: () => onOpenNote(transcribingNoteId)),
            )
          : const SizedBox.shrink(key: ValueKey('capsule-idle')),
    );
  }
}

class _RecordingCapsuleButton extends StatelessWidget {
  const _RecordingCapsuleButton({required this.elapsed, required this.onTap});

  final ValueListenable<Duration> elapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final timeStyle = context.text.meta.copyWith(
      color: colors.textSecondary,
      fontSize: 12,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Pressable(
      key: const ValueKey('activity-capsule'),
      minTarget: true,
      semanticLabel: l10n.capsuleRecordingA11y,
      onTap: onTap,
      child: Glass(
        radius: FikraRadius.full,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: colors.danger, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                l10n.capsuleRecording,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.chip,
              ),
            ),
            const SizedBox(width: 8),
            RepaintBoundary(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: ValueListenableBuilder<Duration>(
                  valueListenable: elapsed,
                  builder: (context, duration, _) => Text(Fmt.duration(duration.inMilliseconds), style: timeStyle),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TranscribingCapsuleButton extends StatelessWidget {
  const _TranscribingCapsuleButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return Pressable(
      key: const ValueKey('activity-capsule'),
      minTarget: true,
      semanticLabel: l10n.capsuleTranscribingA11y,
      onTap: onTap,
      child: Glass(
        radius: FikraRadius.full,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.graphic_eq_rounded, size: 16, color: colors.accent),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                l10n.capsuleTranscribing,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.chip,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
