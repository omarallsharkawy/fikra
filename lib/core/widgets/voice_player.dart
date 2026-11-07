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
  const VoicePlayer({super.key, required this.path, required this.durationMs, this.onDelete, this.title});
  final String path;
  final int durationMs;
  final VoidCallback? onDelete;
  final String? title;

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
      radius: FikraRadius.lg,
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      child: Row(
        children: [
          Pressable(
            onTap: _error ? null : () => _playing ? _player.pause() : _player.play(),
            minTarget: true,
            semanticLabel: _error ? 'التسجيل مش متاح' : (_playing ? 'إيقاف مؤقت' : 'تشغيل'),
            child: Opacity(
              opacity: _error ? 0.4 : 1,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(gradient: FikraColors.selectedGradient, shape: BoxShape.circle),
                child: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title ?? 'تسجيل صوتي', style: FikraText.body),
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
                              backgroundColor: FikraColors.pressed,
                              color: FikraColors.accentLight,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _error ? 'الملف مش متاح' : Fmt.duration(widget.durationMs),
                          style: FikraText.meta.copyWith(color: FikraColors.textSecondary),
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
              semanticLabel: 'احذف التسجيل',
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.delete_outline_rounded, color: FikraColors.danger),
              ),
            ),
        ],
      ),
    );
  }
}
