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

/// Shared arbitration for all local previews and note recordings.
class VoicePlaybackCoordinator {
  Future<void>? _pending;
  Future<void> Function()? _stop;
  Object? _owner;

  Future<void> _stopCurrent() async {
    final stop = _stop;
    _owner = null;
    _stop = null;
    await stop?.call();
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final previous = _pending;
    final next = previous == null ? action() : previous.then((_) => action());
    final settled = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    _pending = settled;
    unawaited(
      settled.then((_) {
        if (identical(_pending, settled)) _pending = null;
      }),
    );
    return next;
  }

  Future<void> stop() => _enqueue(_stopCurrent);

  Future<void> start(
    Object owner,
    Future<void> Function() stop,
    void Function() play, {
    bool Function()? isActive,
    Future<void> Function()? prepare,
  }) {
    return _enqueue(() async {
      if (isActive?.call() == false) return;
      await _stopCurrent();
      if (isActive?.call() == false) return;
      _owner = owner;
      _stop = stop;
      await prepare?.call();
      if (!identical(_owner, owner) || isActive?.call() == false) return;
      play();
    });
  }

  void release(Object owner) {
    if (identical(_owner, owner)) {
      _owner = null;
      _stop = null;
    }
  }
}

final voicePlaybackCoordinator = VoicePlaybackCoordinator();

class _VoicePlayerState extends State<VoicePlayer> {
  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _sub;
  bool _playing = false;
  bool _starting = false;
  bool _error = false;

  Future<void> _prepare() async {
    if (!mounted || _player != null) return;
    final player = _player = AudioPlayer();
    _sub = player.playerStateStream.listen((s) {
      if (s.processingState == ProcessingState.completed) {
        unawaited(player.pause());
        unawaited(player.seek(Duration.zero));
      }
      if (mounted) setState(() => _playing = s.playing && s.processingState != ProcessingState.completed);
    });
    await player.setFilePath(widget.path);
    if (mounted) setState(() {});
  }

  Future<void> _toggle() async {
    if (_error || _starting) return;
    if (_playing) {
      await _player?.pause();
      return;
    }
    setState(() => _starting = true);
    try {
      await voicePlaybackCoordinator.start(
        this,
        () async {
          await _player?.pause();
        },
        () {
          unawaited(
            _player!.play().catchError((Object _) {
              if (mounted) setState(() => _error = true);
            }),
          );
        },
        prepare: _prepare,
        isActive: () => mounted,
      );
    } catch (_) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  void dispose() {
    voicePlaybackCoordinator.release(this);
    _sub?.cancel();
    // No player exists for previews that were never played.
    unawaited(_player?.dispose().catchError((Object _) {}) ?? Future<void>.value());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SolidSurface(
      radius: widget.embedded ? FikraRadius.md : FikraRadius.lg,
      color: widget.embedded ? context.colors.chip : null,

      padding: widget.embedded
          ? const EdgeInsetsDirectional.fromSTEB(4, 8, 8, 8)
          : const EdgeInsetsDirectional.fromSTEB(8, 12, 12, 12),
      child: Row(
        children: [
          Pressable(
            onTap: _error || _starting ? null : _toggle,
            minTarget: true,
            semanticLabel: _error
                ? context.l10n.voiceUnavailableA11y
                : (_playing ? context.l10n.voicePauseA11y : context.l10n.voicePlayA11y),
            child: Opacity(
              opacity: _error ? 0.4 : 1,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: context.colors.chip, shape: BoxShape.circle),
                child: Icon(
                  _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: context.colors.textSecondary,
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
                  stream: _player?.positionStream,
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
                              backgroundColor: context.colors.chip,
                              color: context.colors.textSecondary,
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
