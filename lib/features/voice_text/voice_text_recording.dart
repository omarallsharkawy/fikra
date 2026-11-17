import 'package:flutter/material.dart';

import '../../core/motion/recording_pulse.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../core/widgets/voice_player.dart';
import '../../l10n/localizations.dart';
import '../shared/inline_recorder.dart';
import 'voice_text_backend.dart';
import 'voice_text_controller.dart';
import 'voice_text_models.dart';

class VoiceTextRecording extends StatelessWidget {
  const VoiceTextRecording({super.key, required this.controller, required this.act});
  final VoiceTextController controller;
  final VoiceTextAction act;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final l = context.l10n;
    final recording = c.phase == VoiceTextPhase.recording;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (recording) ...[
          InlineRecorder(levels: List.of(c.levels), elapsed: c.elapsed, max: VoiceTextController.maxRecording),
          Row(
            children: [
              FikraIconButton(
                icon: Icons.close_rounded,
                label: l.discardRecording,
                onTap: () => act(() => c.stop(discard: true)),
              ),
              const Spacer(),
              RecordingPulse(
                key: const ValueKey('vt-stop-pulse'),
                active: true,
                color: context.colors.danger,
                child: FikraIconButton(
                  key: const ValueKey('vt-stop'),
                  icon: Icons.stop_rounded,
                  label: l.stopRecording,
                  onTap: () => act(c.stop),
                ),
              ),
            ],
          ),
        ] else ...[
          FikraButton.secondary(
            key: const ValueKey('vt-record'),
            label: l.recordVoice,
            icon: Icons.mic_none_rounded,
            growForText: true,
            onPressed: c.idle ? () => act(c.start) : null,
          ),
        ],
      ],
    );
  }
}

class VoiceTextRecordings extends StatelessWidget {
  const VoiceTextRecordings({super.key, required this.controller, required this.act});
  final VoiceTextController controller;
  final VoiceTextAction act;

  Future<void> _delete(BuildContext context, SpikeRecording clip) async {
    final ok = await confirmDestructive(
      context,
      title: context.l10n.deleteRecording,
      message: context.l10n.vtDeleteRecordingBody,
    );
    if (ok && context.mounted) await act(() => controller.deleteClip(clip));
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: FikraSpace.s16),
        Text(l.vtClips, style: context.text.section),
        const SizedBox(height: FikraSpace.s8),
        if (c.clips.isEmpty) Text(l.vtNoRecordings, style: context.text.caption),
        for (var i = 0; i < c.clips.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: FikraSpace.s8),
            child: SolidSurface(
              radius: FikraRadius.md,
              padding: const EdgeInsets.all(FikraSpace.s8),
              child: Column(
                children: [
                  Semantics(
                    selected: c.selected?.path == c.clips[i].path,
                    child: IgnorePointer(
                      ignoring: !c.idle,
                      child: ExcludeSemantics(
                        excluding: !c.idle,
                        child: SheetOption(
                          key: ValueKey('vt-clip-$i'),
                          label: l.vtClip('${i + 1}', c.clips[i].format.startsWith('wav') ? 'WAV' : 'AAC'),
                          icon: c.selected?.path == c.clips[i].path
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          onTap: () => c.chooseClip(c.clips[i]),
                        ),
                      ),
                    ),
                  ),
                  IgnorePointer(
                    ignoring: !c.idle,
                    child: ExcludeSemantics(
                      excluding: !c.idle,
                      child: VoicePlayer(
                        key: ValueKey(c.clips[i].path),
                        path: c.clips[i].path,
                        durationMs: (c.clips[i].seconds * 1000).round(),
                        embedded: true,
                        onDelete: () => _delete(context, c.clips[i]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
