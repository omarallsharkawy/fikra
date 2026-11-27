import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/transcription/service_config.dart';
import '../../l10n/localizations.dart';
import 'service_consent.dart';
import 'service_copy.dart';
import 'voice_text_models.dart';

class VoiceTextEngines extends ConsumerStatefulWidget {
  const VoiceTextEngines({super.key, required this.enabled});
  final bool enabled;
  @override
  ConsumerState<VoiceTextEngines> createState() => _VoiceTextEnginesState();
}

class _VoiceTextEnginesState extends ConsumerState<VoiceTextEngines> {
  bool _busy = false;
  Future<void> _select(TranscriptionService? service) async {
    if (_busy || !widget.enabled) return;
    setState(() => _busy = true);
    try {
      if (service != null && !service.consented) {
        if (!await confirmServiceConsent(context, service) || !mounted) return;
        await ref.read(transcriptionServicesProvider).authorize(service);
      }
      await ref.read(transcriptionServicesProvider).select(service?.engineId ?? 'local');
    } catch (error) {
      if (mounted) showToast(context, serviceErrorMessage(context.l10n, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(transcriptionServicesStateProvider);
    final state = value.value;
    final l = context.l10n;
    if (state == null) return SmartText(value.hasError ? l.vsLoadError : l.vtWait, style: context.text.caption);
    final enabled = widget.enabled && !_busy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IgnorePointer(
          ignoring: !enabled,
          child: Column(
            children: [
              VoiceTextChoice(
                key: const ValueKey('vs-engine-local'),
                label: l.vsLocal,
                selected: state.selected == 'local',
                onTap: () => _select(null),
              ),
              for (final service in state.services)
                Row(
                  children: [
                    Expanded(
                      child: VoiceTextChoice(
                        key: ValueKey('vs-engine-${service.id}'),
                        label: service.name,
                        selected: state.selected == service.engineId,
                        onTap: () => _select(service),
                      ),
                    ),
                    FikraIconButton(
                      key: ValueKey('vs-edit-${service.id}'),
                      icon: Icons.edit_outlined,
                      label: l.vsEdit,
                      onTap: () => context.push('/settings/voice-text/service/${service.id}'),
                    ),
                  ],
                ),
            ],
          ),
        ),
        FikraButton.secondary(
          key: const ValueKey('vs-add'),
          label: l.vsAdd,
          icon: Icons.add_rounded,
          growForText: true,
          onPressed: enabled ? () => context.push('/settings/voice-text/service/new') : null,
        ),
      ],
    );
  }
}
