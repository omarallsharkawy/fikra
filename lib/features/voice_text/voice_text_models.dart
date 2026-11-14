import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../l10n/localizations.dart';
import 'voice_text_controller.dart';
import 'voice_text_copy.dart';

typedef VoiceTextAction = Future<void> Function(Future<void> Function());

class VoiceTextModels extends StatelessWidget {
  const VoiceTextModels({super.key, required this.controller, required this.act});
  final VoiceTextController controller;
  final VoiceTextAction act;

  Future<void> _pick(BuildContext context) async {
    // Rescan so an adb push is discovered without leaving the screen.
    await act(controller.initialize);
    if (!context.mounted) return;
    await showFikraSheet<void>(
      context,
      title: context.l10n.vtModel,
      tall: true,
      builder: (sheet) => ListView(
        children: [
          for (final model in controller.models)
            VoiceTextChoice(
              key: ValueKey('vt-model-${model.modelName}'),
              label:
                  '${modelLabel(sheet.l10n, model, bytes: controller.sizes[model.modelName])}\n${modelHint(sheet.l10n, model)}\n'
                  '${(controller.sizes[model.modelName] ?? 0) > 0 ? sheet.l10n.vtOnPhone : sheet.l10n.vtNotDownloaded}',
              selected: identical(model, controller.model),
              onTap: () {
                controller.chooseModel(model);
                Navigator.pop(sheet);
              },
            ),
        ],
      ),
    );
  }

  Future<void> _download(BuildContext context) async {
    final l = context.l10n;
    final model = controller.model;
    final ok = await confirmDestructive(
      context,
      title: l.vtDownloadTitle,
      message: l.vtDownloadBody(Fmt.isolate(l.sizeMb(model.downloadMb))),
      confirmLabel: l.vtDownloadConfirm,
      danger: false,
    );
    if (ok && context.mounted && identical(controller.model, model)) await act(controller.download);
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await confirmDestructive(
      context,
      title: context.l10n.vtDeleteModelTitle,
      message: context.l10n.vtDeleteModelBody,
    );
    if (ok && context.mounted) await act(controller.deleteModel);
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final l = context.l10n;
    final downloading = c.phase == VoiceTextPhase.downloading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IgnorePointer(
          ignoring: !c.idle,
          child: ExcludeSemantics(
            excluding: !c.idle,
            child: SheetOption(
              key: const ValueKey('vt-model-picker'),
              label:
                  '${modelLabel(l, c.model, bytes: c.sizes[c.model.modelName])}\n${c.downloaded ? l.vtOnPhone : l.vtNotDownloaded}',
              icon: Icons.memory_rounded,
              onTap: () => _pick(context),
            ),
          ),
        ),
        Text(modelHint(l, c.model), style: context.text.caption),
        const SizedBox(height: FikraSpace.s12),
        if (c.model.localOnly)
          const SizedBox.shrink()
        else if (downloading) ...[
          VoiceTextProgress(value: c.progress, label: l.vtDownload(l.sizeMb(c.model.downloadMb))),
          const SizedBox(height: FikraSpace.s8),
          Text(
            l.vtProgress(
              Fmt.isolate(Fmt.bytes(l, c.received)),
              Fmt.isolate(c.total > 0 ? Fmt.bytes(l, c.total) : l.sizeMb(c.model.downloadMb)),
            ),
            style: context.text.caption,
          ),
          FikraButton.secondary(
            key: const ValueKey('vt-cancel-download'),
            label: l.cancel,
            growForText: true,
            onPressed: c.cancelDownload,
          ),
        ] else if (!c.downloaded)
          FikraButton(
            key: const ValueKey('vt-download'),
            label: l.vtDownload(Fmt.isolate(l.sizeMb(c.model.downloadMb))),
            growForText: true,
            icon: Icons.download_rounded,
            onPressed: c.idle ? () => _download(context) : null,
          )
        else
          FikraButton.secondary(
            key: const ValueKey('vt-delete-model'),
            label: l.vtDeleteModel,
            growForText: true,
            icon: Icons.delete_outline_rounded,
            onPressed: c.idle ? () => _delete(context) : null,
          ),
        const SizedBox(height: FikraSpace.s8),
        Text(l.vtUsed(Fmt.isolate(Fmt.bytes(l, c.usedBytes))), style: context.text.caption),
      ],
    );
  }
}

/// Same token-based progress treatment as VoicePlayer. Reduced motion has a
/// static track for unknown progress; no new looping animation is introduced.
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

/// Selected semantics around the existing sheet row; visual style is unchanged.
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
