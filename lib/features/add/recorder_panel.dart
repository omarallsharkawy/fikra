import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';

/// How many level samples the waveform shows. The Add screen keeps at most
/// this many; the painter pads with silence when it has fewer.
const kWaveformSamples = 48;

/// Amplitude from the recorder is dBFS (−160..0). Anything quieter than this
/// floor draws as a flat bar; 0 dB draws full height.
const kWaveformFloorDb = -50.0;

/// Maps a dBFS reading to a 0..1 bar height.
double levelFromDb(double db) => ((db - kWaveformFloorDb) / -kWaveformFloorDb).clamp(0.06, 1.0);

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

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = FikraColors.accentLight
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;
    const bars = kWaveformSamples;
    final step = size.width / bars;
    final recent = levels.length > bars ? levels.sublist(levels.length - bars) : levels;
    final padded = List<double>.filled(bars - recent.length, 0.06) + recent;
    for (var i = 0; i < bars; i++) {
      final h = (padded[i] * size.height).clamp(3.0, size.height);
      final x = size.width - (i + 0.5) * step; // newest on the left (RTL time flow)
      canvas.drawLine(Offset(x, (size.height - h) / 2), Offset(x, (size.height + h) / 2), paint);
    }
  }

  @override
  bool shouldRepaint(_LevelsPainter old) => true;
}
