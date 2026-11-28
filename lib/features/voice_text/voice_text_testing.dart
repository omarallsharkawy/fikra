import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../l10n/localizations.dart';
import 'voice_text_controller.dart';
import 'voice_text_models.dart';
import 'voice_text_recording.dart';
import 'voice_text_result.dart';

/// Measurement controls stay available without crowding the everyday choices.
class VoiceTextTesting extends StatelessWidget {
  const VoiceTextTesting({super.key, required this.controller, required this.act});
  final VoiceTextController controller;
  final VoiceTextAction act;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final l = context.l10n;
    Widget section(String title) => Padding(
      padding: const EdgeInsets.symmetric(vertical: FikraSpace.s12),
      child: SmartText(title, style: context.text.section),
    );
    final fullModels = c.models.where((m) => !m.quantized && m != c.model).toList();
    return Column(
      key: const ValueKey('vt-testing-content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IgnorePointer(
          ignoring: !c.idle,
          child: ExcludeSemantics(
            excluding: !c.idle,
            child: SheetOption(
              key: const ValueKey('vt-format'),
              label: '${l.vtFormat}\n${c.aac ? l.vtAac : l.vtWav}',
              icon: Icons.audio_file_outlined,
              onTap: () => showFikraSheet<void>(
                context,
                title: l.vtFormat,
                builder: (sheet) => Column(
                  children: [
                    for (final aac in [false, true])
                      VoiceTextChoice(
                        label: aac ? l.vtAac : l.vtWav,
                        selected: aac == c.aac,
                        onTap: () {
                          c.chooseFormat(aac);
                          Navigator.pop(sheet);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (!c.isRemote)
          IgnorePointer(
            ignoring: !c.idle,
            child: ExcludeSemantics(
              excluding: !c.idle,
              child: SheetOption(
                key: const ValueKey('vt-advanced'),
                label: l.vtThreads('${c.threads}'),
                icon: Icons.tune_rounded,
                onTap: () => showFikraSheet<void>(
                  context,
                  title: l.vtAdvanced,
                  builder: (sheet) => Column(
                    children: [
                      for (final threads in [2, 4, 6])
                        VoiceTextChoice(
                          label: l.vtThreads('$threads'),
                          selected: c.threads == threads,
                          onTap: () {
                            c.chooseThreads(threads);
                            Navigator.pop(sheet);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        FikraButton.secondary(
          key: const ValueKey('vt-refresh-models'),
          label: l.vtRefreshModels,
          growForText: true,
          icon: Icons.refresh_rounded,
          onPressed: c.idle ? () => act(c.initialize) : null,
        ),
        if (!c.isRemote && fullModels.isNotEmpty) ...[
          section(l.vtFullModels),
          VoiceTextModels(controller: c, act: act, models: fullModels, showStorage: false),
        ],
        VoiceTextRecordings(controller: c, act: act),
        const SizedBox(height: FikraSpace.s16),
        FikraButton(
          key: const ValueKey('vt-transcribe'),
          growForText: true,
          label: c.phase == VoiceTextPhase.transcribing ? l.vtWorking : l.vtTranscribe,
          icon: Icons.text_fields_rounded,
          onPressed: c.idle && c.selected != null && c.canTranscribe ? () => act(c.transcribe) : null,
        ),
        const SizedBox(height: FikraSpace.s8),
        SmartText(l.vtCannotCancel, content: ReadOnlyContent.chrome, style: context.text.caption),
        if (c.phase == VoiceTextPhase.transcribing) ...[
          const SizedBox(height: FikraSpace.s12),
          VoiceTextProgress(key: const ValueKey('vt-working'), label: l.vtWorking),
        ],
        if (c.history.isNotEmpty) ...[
          section(l.vtHistory),
          for (var i = 0; i < c.history.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: FikraSpace.s12),
              child: VoiceTextResult(key: ValueKey('vt-run-$i'), run: c.history[i]),
            ),
        ],
      ],
    );
  }
}
