import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/format.dart';
import '../../core/motion/pressable.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';

/// Live recording: level bars, timer, stop / cancel.
class RecorderPanel extends StatelessWidget {
  const RecorderPanel({
    super.key,
    required this.levels,
    required this.elapsed,
    required this.max,
    required this.onStop,
    required this.onCancel,
  });
  final List<double> levels;
  final Duration elapsed;
  final Duration max;
  final VoidCallback onStop;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: FikraRadius.lg,
      borderColor: FikraColors.danger.withValues(alpha: 0.5),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(color: FikraColors.danger, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text('بيسجّل', style: FikraText.chip),
              const Spacer(),
              Text(
                '${Fmt.duration(elapsed.inMilliseconds)} / ${Fmt.duration(max.inMilliseconds)}',
                style: FikraText.meta.copyWith(color: FikraColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 56,
            child: CustomPaint(painter: _LevelsPainter(levels), size: Size.infinite),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FikraButton(label: 'إيقاف', icon: Icons.stop_rounded, onPressed: onStop),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FikraButton.secondary(label: 'إلغاء', onPressed: onCancel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelsPainter extends CustomPainter {
  _LevelsPainter(this.levels);
  final List<double> levels;
  static const bars = 48;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = FikraColors.accentLight
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;
    final step = size.width / bars;
    final padded = List<double>.filled(bars - levels.length, 0.06) + levels;
    for (var i = 0; i < bars; i++) {
      final h = (padded[i] * size.height).clamp(3.0, size.height);
      final x = size.width - (i + 0.5) * step; // newest on the left (RTL time flow)
      canvas.drawLine(Offset(x, (size.height - h) / 2), Offset(x, (size.height + h) / 2), paint);
    }
  }

  @override
  bool shouldRepaint(_LevelsPainter old) => true;
}

/// Recorded clip: play / pause, progress, delete.
class VoiceReview extends StatefulWidget {
  const VoiceReview({super.key, required this.path, required this.durationMs, this.onDelete, this.title});
  final String path;
  final int durationMs;
  final VoidCallback? onDelete;
  final String? title;

  @override
  State<VoiceReview> createState() => _VoiceReviewState();
}

class _VoiceReviewState extends State<VoiceReview> {
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
            semanticLabel: _playing ? 'إيقاف مؤقت' : 'تشغيل',
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(gradient: FikraColors.selectedGradient, shape: BoxShape.circle),
              child: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
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
              semanticLabel: 'احذف التسجيل',
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.delete_outline_rounded, color: FikraColors.danger),
              ),
            ),
        ],
      ),
    );
  }
}
