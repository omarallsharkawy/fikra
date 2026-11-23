part of 'attachment_editor.dart';

/// Bottom row of the composer. Idle: mic, PDF and photos on the start side, save on the
/// end. Recording: cancel + stop.
class _Toolbar extends StatelessWidget {
  const _Toolbar({
    this.showSave = true,
    required this.recording,
    required this.micEnabled,
    required this.pdfEnabled,
    required this.imagesEnabled,
    required this.canSave,
    required this.saving,
    this.saveTick,
    this.saveTickActive = false,
    required this.onMic,
    required this.onPdf,
    required this.onImages,
    required this.onStop,
    required this.onCancel,
    required this.onSave,
  });
  final bool showSave;
  final bool recording;
  final bool micEnabled;
  final bool pdfEnabled;
  final bool imagesEnabled;
  final bool canSave;
  final bool saving;
  final Animation<double>? saveTick;
  final bool saveTickActive;
  final VoidCallback onMic;
  final VoidCallback onPdf;
  final VoidCallback onImages;
  final VoidCallback? onStop;
  final VoidCallback? onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 48,
      child: FikraSwitcher(
        alignment: Alignment.center,
        child: recording
            ? Row(
                key: const ValueKey('rec-tools'),
                children: [
                  _ToolButton(
                    key: const ValueKey('add-cancel-rec'),
                    icon: Icons.close_rounded,
                    label: context.l10n.discardRecording,
                    onTap: onCancel,
                  ),
                  const Spacer(),
                  _RoundAction(
                    key: const ValueKey('add-stop'),
                    icon: Icons.stop_rounded,
                    label: context.l10n.stopRecording,
                    color: c.danger,
                    foreground: c.dangerBg,
                    pulse: onStop != null,
                    pulseColor: c.danger,
                    onTap: onStop,
                  ),
                ],
              )
            : Row(
                key: const ValueKey('idle-tools'),
                children: [
                  _ToolButton(
                    key: const ValueKey('add-mic'),
                    icon: Icons.mic_none_rounded,
                    label: context.l10n.recordVoice,
                    onTap: micEnabled ? onMic : null,
                  ),
                  const SizedBox(width: 6),
                  _ToolButton(
                    key: const ValueKey('add-pdf'),
                    icon: Icons.attach_file_rounded,
                    label: context.l10n.addPdf,
                    onTap: pdfEnabled ? onPdf : null,
                  ),
                  const SizedBox(width: 6),
                  _ToolButton(
                    key: const ValueKey('add-image'),
                    icon: Icons.image_outlined,
                    label: context.l10n.addPhotos,
                    onTap: imagesEnabled ? onImages : null,
                  ),
                  const Spacer(),
                  if (showSave)
                    SaveTickButton(
                      key: const ValueKey('add-save'),
                      label: context.l10n.save,
                      loading: saving,
                      tick: saveTick,
                      tickActive: saveTickActive,
                      onTap: canSave ? onSave : null,
                    ),
                ],
              ),
      ),
    );
  }
}

/// Small round tool (mic, attach, cancel): subtle fill, 48 dp hit area.
class _ToolButton extends StatelessWidget {
  const _ToolButton({super.key, required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      minTarget: true,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.35 : 1,
        duration: FikraMotion.reduced(context) ? Duration.zero : FikraMotion.exit,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.colors.chip,
            shape: BoxShape.circle,
            border: Border.all(color: context.colors.line, width: FikraSpace.hairline),
          ),
          child: Icon(icon, size: 21, color: context.colors.textPrimary),
        ),
      ),
    );
  }
}

/// Filled round action (stop recording) at the end side.
class _RoundAction extends StatelessWidget {
  const _RoundAction({
    super.key,
    required this.icon,
    required this.label,
    required this.foreground,
    required this.onTap,
    this.color,
    this.pulse = false,
    this.pulseColor,
  });
  final IconData icon;
  final String label;
  final Color foreground;
  final VoidCallback? onTap;
  final Color? color;
  final bool pulse;
  final Color? pulseColor;

  @override
  Widget build(BuildContext context) {
    Widget circle = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, size: 24, color: foreground),
    );
    if (pulse) {
      circle = RecordingPulse(
        key: const ValueKey('add-stop-pulse'),
        active: true,
        color: pulseColor ?? foreground,
        child: circle,
      );
    }
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      minTarget: true,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.35 : 1,
        duration: FikraMotion.reduced(context) ? Duration.zero : FikraMotion.exit,
        child: circle,
      ),
    );
  }
}
