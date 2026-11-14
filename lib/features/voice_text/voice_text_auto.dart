import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../l10n/localizations.dart';
import 'voice_text_controller.dart';

class VoiceTextAuto extends StatelessWidget {
  const VoiceTextAuto({super.key, required this.controller, required this.act, required this.onChanged});
  final VoiceTextController controller;
  final Future<void> Function(Future<void> Function()) act;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) {
    final c = controller;
    final enabled = c.idle && (c.usedBytes > 0 || c.autoTranscribe);
    Future<void> toggle() async {
      await act(() => c.setAutoTranscribe(!c.autoTranscribe));
      onChanged();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          key: const ValueKey('vt-auto-transcribe'),
          label: context.l10n.trAutomatic,
          excludeSemantics: true,
          onTap: enabled ? toggle : null,
          toggled: c.autoTranscribe,
          enabled: enabled,
          child: IgnorePointer(
            ignoring: !enabled,
            child: SheetOption(
              label: context.l10n.trAutomatic,
              icon: c.autoTranscribe ? Icons.toggle_on_rounded : Icons.toggle_off_outlined,
              onTap: toggle,
            ),
          ),
        ),
        Text(
          c.usedBytes > 0 ? context.l10n.trAutomaticHint : context.l10n.trDownloadFirst,
          style: context.text.caption,
        ),
      ],
    );
  }
}
