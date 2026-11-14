import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/motion/pressable.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../l10n/localizations.dart';
import 'voice_text_backend.dart';
import 'voice_text_controller.dart';
import 'voice_text_copy.dart';

typedef VoiceTextAction = Future<void> Function(Future<void> Function());

/// Always-visible choices, with actions scoped to each file rather than to a
/// hidden picker selection. The same rows serve the measurement-only variants.
class VoiceTextModels extends StatelessWidget {
  const VoiceTextModels({
    super.key,
    required this.controller,
    required this.act,
    required this.models,
    this.showStorage = true,
  });
  final VoiceTextController controller;
  final VoiceTextAction act;
  final List<SpikeModel> models;
  final bool showStorage;

  Future<void> _download(BuildContext context, SpikeModel model) async {
    final l = context.l10n;
    final ok = await confirmDestructive(
      context,
      title: l.vtDownloadTitle,
      message: l.vtDownloadBody(Fmt.isolate(l.sizeMb(model.downloadMb))),
      confirmLabel: l.vtDownloadConfirm,
      danger: false,
    );
    if (ok && context.mounted) await act(() => controller.download(model));
  }

  Future<void> _delete(BuildContext context, SpikeModel model) async {
    final ok = await confirmDestructive(
      context,
      title: context.l10n.vtDeleteModelTitle,
      message: context.l10n.vtDeleteModelBody,
    );
    if (ok && context.mounted) await act(() => controller.deleteModel(model));
  }

  Widget _row(BuildContext context, SpikeModel model) {
    final c = controller;
    final l = context.l10n;
    final present = (c.sizes[model.modelName] ?? 0) > 0;
    final downloading = c.phase == VoiceTextPhase.downloading && c.downloadingModel == model;
    final selected = c.choices.loaded && c.model == model;
    return Padding(
      padding: const EdgeInsets.only(bottom: FikraSpace.s8),
      child: Glass(
        radius: FikraRadius.md,
        padding: const EdgeInsets.all(FikraSpace.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Pressable(
              key: ValueKey('vt-model-${model.modelName}'),
              minTarget: true,
              selected: selected,
              onTap: c.idle ? () => act(() => c.chooseModel(model)) : null,
              child: Row(
                children: [
                  Icon(
                    selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: context.colors.accentLight,
                  ),
                  const SizedBox(width: FikraSpace.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(modelLabel(l, model, bytes: c.sizes[model.modelName]), style: context.text.section),
                        const SizedBox(height: FikraSpace.s4),
                        Text(modelHint(l, model), style: context.text.caption),
                        const SizedBox(height: FikraSpace.s4),
                        Text(
                          downloading
                              ? l.vtProgress(
                                  Fmt.isolate(Fmt.bytes(l, c.received)),
                                  Fmt.isolate(c.total > 0 ? Fmt.bytes(l, c.total) : l.sizeMb(model.downloadMb)),
                                )
                              : present
                              ? l.vtOnPhone
                              : l.vtNotDownloaded,
                          style: context.text.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!model.localOnly) ...[
              const SizedBox(height: FikraSpace.s8),
              if (downloading) ...[
                VoiceTextProgress(value: c.progress, label: l.vtDownload(l.sizeMb(model.downloadMb))),
                FikraButton.secondary(
                  key: ValueKey('vt-cancel-${model.modelName}'),
                  label: l.cancel,
                  growForText: true,
                  onPressed: c.cancelDownload,
                ),
              ] else if (present)
                FikraButton.secondary(
                  key: ValueKey('vt-delete-${model.modelName}'),
                  label: l.vtDeleteModel,
                  growForText: true,
                  icon: Icons.delete_outline_rounded,
                  onPressed: c.idle ? () => _delete(context, model) : null,
                )
              else
                FikraButton(
                  key: ValueKey('vt-download-${model.modelName}'),
                  label: l.vtDownload(Fmt.isolate(l.sizeMb(model.downloadMb))),
                  growForText: true,
                  icon: Icons.download_rounded,
                  onPressed: c.idle ? () => _download(context, model) : null,
                ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final model in models) _row(context, model),
      if (showStorage)
        Text(
          context.l10n.vtUsed(Fmt.isolate(Fmt.bytes(context.l10n, controller.usedBytes))),
          style: context.text.caption,
        ),
    ],
  );
}

class VoiceTextProgress extends StatelessWidget {
  const VoiceTextProgress({super.key, this.value, required this.label});
  final double? value;
  final String label;
  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    value: value == null ? null : '${(value! * 100).round()}%',
    liveRegion: true,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(FikraRadius.full),
      child: LinearProgressIndicator(
        value: value ?? (MediaQuery.disableAnimationsOf(context) ? 0 : null),
        color: context.colors.accentLight,
        backgroundColor: context.colors.border,
      ),
    ),
  );
}

/// Speech language, format and CPU choices still use the app's sheet rows.
class VoiceTextChoice extends StatelessWidget {
  const VoiceTextChoice({super.key, required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: SheetOption(
      label: label,
      icon: selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
      onTap: onTap,
    ),
  );
}
