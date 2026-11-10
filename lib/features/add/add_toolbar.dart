part of 'add_screen.dart';

/// Bottom row of the composer. Idle: mic, PDF and photos on the start side, save on the
/// end. Recording: cancel + stop.
class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.recording,
    required this.micEnabled,
    required this.pdfEnabled,
    required this.imagesEnabled,
    required this.canSave,
    required this.saving,
    required this.onMic,
    required this.onPdf,
    required this.onImages,
    required this.onStop,
    required this.onCancel,
    required this.onSave,
  });
  final bool recording;
  final bool micEnabled;
  final bool pdfEnabled;
  final bool imagesEnabled;
  final bool canSave;
  final bool saving;
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
                    foreground: c.textOnSelected,
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
                  _RoundAction(
                    key: const ValueKey('add-save'),
                    icon: Icons.check_rounded,
                    label: context.l10n.save,
                    gradient: c.sendGradient,
                    foreground: c.textOnSend,
                    loading: saving,
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
            color: context.colors.pressed,
            shape: BoxShape.circle,
            border: Border.all(color: context.colors.border, width: FikraSpace.hairline),
          ),
          child: Icon(icon, size: 21, color: context.colors.textPrimary),
        ),
      ),
    );
  }
}

/// The composer's main action (save, stop): filled circle at the end side.
class _RoundAction extends StatelessWidget {
  const _RoundAction({
    super.key,
    required this.icon,
    required this.label,
    required this.foreground,
    required this.onTap,
    this.gradient,
    this.color,
    this.loading = false,
  });
  final IconData icon;
  final String label;
  final Color foreground;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? color;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: loading ? null : onTap,
      semanticLabel: label,
      minTarget: true,
      child: AnimatedOpacity(
        opacity: onTap == null && !loading ? 0.35 : 1,
        duration: FikraMotion.reduced(context) ? Duration.zero : FikraMotion.exit,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(gradient: gradient, color: color, shape: BoxShape.circle),
          child: loading
              ? Padding(
                  padding: const EdgeInsets.all(13),
                  child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
                )
              : Icon(icon, size: 24, color: foreground),
        ),
      ),
    );
  }
}
