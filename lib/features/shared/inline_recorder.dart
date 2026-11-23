import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/motion/motion.dart';
import '../../core/motion/recording_pulse.dart';
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
class InlineRecorder extends StatefulWidget {
  const InlineRecorder({super.key, required this.levels, required this.elapsed, required this.max, this.levelUpdates});
  final List<double> levels;
  final Duration elapsed;
  final Duration max;
  final Listenable? levelUpdates;

  @override
  State<InlineRecorder> createState() => _InlineRecorderState();
}

class _InlineRecorderState extends State<InlineRecorder> with SingleTickerProviderStateMixin {
  late final AnimationController _smooth = AnimationController(
    vsync: this,
    duration: FikraMotion.waveformStep,
    value: 1,
  );
  final _repaint = ValueNotifier<int>(0);
  late final Listenable _painterRepaint = Listenable.merge([_smooth, _repaint]);
  List<double> _from = List<double>.filled(kWaveformSamples, 0.06);
  List<double> _to = List<double>.filled(kWaveformSamples, 0.06);
  bool _tickerEnabled = true;

  static List<double> _padded(List<double> raw) {
    final recent = raw.length > kWaveformSamples ? raw.sublist(raw.length - kWaveformSamples) : raw;
    return List<double>.filled(kWaveformSamples - recent.length, 0.06) + recent;
  }

  List<double> _currentBars() {
    final t = _smooth.value;
    if (t >= 1) return _to;
    return [for (var i = 0; i < kWaveformSamples; i++) _from[i] + (_to[i] - _from[i]) * t];
  }

  void _onLevels() {
    if (!mounted) return;
    final next = _padded(widget.levels);
    if (!TickerMode.valuesOf(context).enabled) {
      _smooth.stop();
      _smooth.value = 1;
      _from = next;
      _to = next;
      return;
    }
    if (FikraMotion.reduced(context)) {
      _smooth.stop();
      _smooth.value = 1;
      _from = next;
      _to = next;
      _repaint.value++;
      return;
    }
    _from = _currentBars();
    _to = next;
    _smooth.forward(from: 0);
  }

  @override
  void initState() {
    super.initState();
    _to = _padded(widget.levels);
    _from = _to;
    widget.levelUpdates?.addListener(_onLevels);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final enabled = TickerMode.valuesOf(context).enabled;
    final reduced = FikraMotion.reduced(context);
    if (_smooth.isAnimating && (reduced || !enabled)) {
      _smooth.stop();
      _smooth.value = 1;
      _from = _to;
    } else if (enabled && !_tickerEnabled) {
      _repaint.value++;
    }
    _tickerEnabled = enabled;
  }

  @override
  void didUpdateWidget(covariant InlineRecorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.levelUpdates != widget.levelUpdates) {
      oldWidget.levelUpdates?.removeListener(_onLevels);
      widget.levelUpdates?.addListener(_onLevels);
    }
    if (widget.levelUpdates == null) {
      _onLevels();
    } else if (_to.every((v) => v == 0.06) && widget.levels.isNotEmpty) {
      _onLevels();
    }
  }

  @override
  void dispose() {
    widget.levelUpdates?.removeListener(_onLevels);
    _repaint.dispose();
    _smooth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 14, 2, 6),
      child: Column(
        children: [
          Row(
            children: [
              RecordingPulse(
                active: true,
                color: context.colors.danger,
                maxExpand: 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: context.colors.danger, shape: BoxShape.circle),
                ),
              ),
              const SizedBox(width: 8),
              Text(context.l10n.recordingNow, style: context.text.chip),
              const Spacer(),
              Text(
                '${Fmt.duration(widget.elapsed.inMilliseconds)} / ${Fmt.duration(widget.max.inMilliseconds)}',
                style: context.text.meta.copyWith(color: context.colors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 18),
          RepaintBoundary(
            child: SizedBox(
              key: const ValueKey('recording-waveform'),
              height: 72,
              child: CustomPaint(
                painter: _LevelsPainter(
                  repaint: _painterRepaint,
                  bars: _currentBars,
                  quietColor: context.colors.textSecondary,
                  activeColor: context.colors.accent,
                  direction: Directionality.of(context),
                ),
                size: Size.infinite,
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _LevelsPainter extends CustomPainter {
  _LevelsPainter({
    required Listenable repaint,
    required this.bars,
    required this.quietColor,
    required this.activeColor,
    required this.direction,
  }) : super(repaint: repaint);

  final TextDirection direction;
  final Color quietColor;
  final Color activeColor;
  final List<double> Function() bars;

  @override
  void paint(Canvas canvas, Size size) {
    final values = bars();
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;
    final step = size.width / kWaveformSamples;
    for (var i = 0; i < kWaveformSamples; i++) {
      final level = values[i].clamp(0.06, 1.0);
      paint.color = Color.lerp(quietColor, activeColor, ((level - 0.06) / 0.94).clamp(0.0, 1.0))!;
      final h = (level * size.height).clamp(3.0, size.height);
      final offset = (i + 0.5) * step;
      final x = direction == TextDirection.rtl ? size.width - offset : offset;
      canvas.drawLine(Offset(x, (size.height - h) / 2), Offset(x, (size.height + h) / 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LevelsPainter old) =>
      old.quietColor != quietColor || old.activeColor != activeColor || old.direction != direction;
}
