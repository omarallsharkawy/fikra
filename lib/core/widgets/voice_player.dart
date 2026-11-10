import 'package:fikra/l10n/localizations.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../format.dart';
import '../motion/pressable.dart';
import '../theme/tokens.dart';
import 'fikra_widgets.dart';

/// Plays a local audio file: play / pause, progress, optional delete.
/// Used for the recording preview (Add) and voice notes (Details).
class VoicePlayer extends StatefulWidget {
  const VoicePlayer({
    super.key,
    required this.path,
    required this.durationMs,
    this.onDelete,
    this.title,
    this.embedded = false,
  });
  final String path;
  final int durationMs;
  final VoidCallback? onDelete;
  final String? title;

  /// Flat fill instead of a glass card, for use inside another surface.
  final bool embedded;

  @override
  State<VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState extends State<VoicePlayer> {
  final _player = AudioPlayer();
  StreamSubscription<PlayerState>? _sub;
  bool _playing = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _player.setFilePath(widget.path).catchError((_) {
      if (mounted) setState(() => _error = true);
      return null;
    });
    _sub = _player.playerStateStream.listen((s) {
      if (s.processingState == ProcessingState.completed) {
        _player.pause();
        _player.seek(Duration.zero);
      }
      if (mounted) setState(() => _playing = s.playing && s.processingState != ProcessingState.completed);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: widget.embedded ? FikraRadius.md : FikraRadius.lg,
      color: widget.embedded ? context.colors.pressed : null,
      borderColor: widget.embedded ? Colors.transparent : null,
      padding: widget.embedded
          ? const EdgeInsetsDirectional.fromSTEB(4, 8, 8, 8)
          : const EdgeInsetsDirectional.fromSTEB(8, 12, 12, 12),
      child: Row(
        children: [
          Pressable(
            onTap: _error ? null : () => _playing ? _player.pause() : _player.play(),
            minTarget: true,
            semanticLabel: _error
                ? context.l10n.voiceUnavailableA11y
                : (_playing ? context.l10n.voicePauseA11y : context.l10n.voicePlayA11y),
            child: Opacity(
              opacity: _error ? 0.4 : 1,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(gradient: context.colors.selectedGradient, shape: BoxShape.circle),
                child: Icon(
                  _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: context.colors.textOnSelected,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title ?? context.l10n.voiceRecording, style: context.text.body),
                const SizedBox(height: 6),
                StreamBuilder<Duration>(
                  stream: _player.positionStream,
                  builder: (context, snap) {
                    final pos = snap.data ?? Duration.zero;
                    final total = widget.durationMs <= 0 ? 1 : widget.durationMs;
                    return Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: (pos.inMilliseconds / total).clamp(0.0, 1.0),
                              minHeight: 4,
                              backgroundColor: context.colors.pressed,
                              color: context.colors.accentLight,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _error ? context.l10n.fileUnavailable : Fmt.duration(widget.durationMs),
                          style: context.text.meta.copyWith(color: context.colors.textSecondary),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          if (widget.onDelete != null)
            Pressable(
              onTap: widget.onDelete,
              minTarget: true,
              semanticLabel: context.l10n.deleteRecording,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.delete_outline_rounded, color: context.colors.danger),
              ),
            ),
        ],
      ),
    );
  }
}
