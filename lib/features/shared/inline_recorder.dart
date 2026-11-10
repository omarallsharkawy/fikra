import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme/tokens.dart';

/// How many level samples the waveform shows. The Add screen keeps at most
/// this many; the painter pads with silence when it has fewer.
const kWaveformSamples = 48;

/// Amplitude from the recorder is dBFS (−160..0). Anything quieter than this
/// floor draws as a flat bar; 0 dB draws full height.
const kWaveformFloorDb = -50.0;

/// Maps a dBFS reading to a 0..1 bar height.
double levelFromDb(double db) => ((db - kWaveformFloorDb) / -kWaveformFloorDb).clamp(0.06, 1.0);

/// Live recording inside the composer: status, timer and level bars.
/// Stop / cancel live in the composer's toolbar.
class InlineRecorder extends StatelessWidget {
  const InlineRecorder({super.key, required this.levels, required this.elapsed, required this.max});
  final List<double> levels;
  final Duration elapsed;
  final Duration max;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 14, 2, 6),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: context.colors.danger, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(context.l10n.recordingNow, style: context.text.chip),
              const Spacer(),
              Text(
                '${Fmt.duration(elapsed.inMilliseconds)} / ${Fmt.duration(max.inMilliseconds)}',
                style: context.text.meta.copyWith(color: context.colors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 72,
            child: CustomPaint(
              painter: _LevelsPainter(levels, context.colors.accentLight, Directionality.of(context)),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _LevelsPainter extends CustomPainter {
  _LevelsPainter(this.levels, this.color, this.direction);
  final TextDirection direction;
  final Color color;
  final List<double> levels;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;
    const bars = kWaveformSamples;
    final step = size.width / bars;
    final recent = levels.length > bars ? levels.sublist(levels.length - bars) : levels;
    final padded = List<double>.filled(bars - recent.length, 0.06) + recent;
    for (var i = 0; i < bars; i++) {
      final h = (padded[i] * size.height).clamp(3.0, size.height);
      final offset = (i + 0.5) * step;
      final x = direction == TextDirection.rtl ? size.width - offset : offset;
      canvas.drawLine(Offset(x, (size.height - h) / 2), Offset(x, (size.height + h) / 2), paint);
    }
  }

  @override
  bool shouldRepaint(_LevelsPainter old) => true;
}
