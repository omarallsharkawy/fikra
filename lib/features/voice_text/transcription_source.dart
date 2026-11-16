import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/localizations.dart';
import 'voice_text_copy.dart';
import 'whisper_models.dart';

class TranscriptionSource extends ConsumerWidget {
  const TranscriptionSource({super.key, required this.engineId, this.serviceName});
  final String engineId;
  final String? serviceName;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final local = allSpikeModels.where((m) => 'local:${m.filename}' == engineId).firstOrNull;
    final String label;
    if (engineId.startsWith('remote:')) {
      final id = engineId.substring('remote:'.length);
      final names = ref.watch(transcriptionServicesStateProvider).value?.names;
      label = l.vsVia(Fmt.isolate(serviceName ?? names?[id] ?? l.vsRemovedService));
    } else {
      label = local != null ? l.trLocalEngine(modelName(l, local)) : Fmt.isolate(engineId);
    }
    return Text(label, style: context.text.meta);
  }
}
