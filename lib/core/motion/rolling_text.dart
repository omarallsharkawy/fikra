import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'motion.dart';

/// Renders [text] as a single [Text] at rest and on first build, and vertically
/// rolls only the changed digits when a visible count changes.
///
/// Honors Reduce Motion and [TickerMode], preserves Western (`0-9`) and
/// Arabic-Indic (`٠-٩`) numerals, and exposes the final value to TalkBack.
class RollingText extends StatefulWidget {
  const RollingText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textScaler,
    this.semanticLabel,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final String? semanticLabel;

  @override
  State<RollingText> createState() => _RollingTextState();
}

class _RollingTextState extends State<RollingText> with SingleTickerProviderStateMixin {
  static final _digits = RegExp(r'[0-9\u0660-\u0669\u06f0-\u06f9]+');
  late final AnimationController _controller = AnimationController(vsync: this, duration: FikraMotion.roll)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted && _roll != null) {
        setState(() => _roll = null);
      }
    });

  late String _displayed;
  _RollSpec? _roll;

  @override
  void initState() {
    super.initState();
    _displayed = widget.text;
  }

  static ({String prefix, String digits, int value, String suffix})? _parseLastNumber(String input) {
    final matches = _digits.allMatches(input);
    if (matches.isEmpty) return null;
    final m = matches.last;
    final raw = m.group(0)!;
    var value = 0;
    for (var i = 0; i < raw.length; i++) {
      final code = raw.codeUnitAt(i);
      final digit = code >= 0x06f0
          ? code - 0x06f0
          : code >= 0x0660
          ? code - 0x0660
          : code - 0x30;
      value = value * 10 + digit;
    }
    return (prefix: input.substring(0, m.start), digits: raw, value: value, suffix: input.substring(m.end));
  }

  void _stopRoll() {
    _controller.stop();
    _roll = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_roll != null && (FikraMotion.reduced(context) || !TickerMode.valuesOf(context).enabled)) {
      _stopRoll();
    }
  }

  @override
  void didUpdateWidget(covariant RollingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text == widget.text) return;
    final previous = _displayed;
    _displayed = widget.text;
    if (FikraMotion.reduced(context) || !TickerMode.valuesOf(context).enabled) {
      _stopRoll();
      return;
    }
    final from = _parseLastNumber(previous);
    final to = _parseLastNumber(widget.text);
    if (from == null ||
        to == null ||
        from.prefix != to.prefix ||
        from.suffix != to.suffix ||
        from.digits == to.digits) {
      _stopRoll();
      return;
    }
    final width = math.max(from.digits.length, to.digits.length);
    _roll = _RollSpec(
      prefix: to.prefix,
      suffix: to.suffix,
      oldDigits: from.digits.padLeft(width),
      newDigits: to.digits.padLeft(width),
      direction: to.value >= from.value ? 1.0 : -1.0,
    );
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roll = _roll;
    if (roll == null || FikraMotion.reduced(context)) {
      final text = Text(
        widget.text,
        style: widget.style,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
        textScaler: widget.textScaler,
      );
      if (widget.semanticLabel == null) return text;
      return Semantics(label: widget.semanticLabel, excludeSemantics: true, child: text);
    }
    return Semantics(
      label: widget.semanticLabel ?? widget.text,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (roll.prefix.isNotEmpty)
            Flexible(
              child: Text(
                roll.prefix,
                style: widget.style,
                maxLines: widget.maxLines,
                overflow: widget.overflow ?? (widget.maxLines != null ? TextOverflow.ellipsis : null),
                textScaler: widget.textScaler,
              ),
            ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < roll.newDigits.length; i++)
                  roll.oldDigits[i] == roll.newDigits[i]
                      ? Text(roll.newDigits[i], style: widget.style, textScaler: widget.textScaler)
                      : RollingDigit(
                          oldChar: roll.oldDigits[i],
                          newChar: roll.newDigits[i],
                          direction: roll.direction,
                          animation: _controller,
                          style: widget.style,
                          textScaler: widget.textScaler,
                        ),
              ],
            ),
          ),
          if (roll.suffix.isNotEmpty)
            Flexible(
              child: Text(
                roll.suffix,
                style: widget.style,
                maxLines: widget.maxLines,
                overflow: widget.overflow ?? (widget.maxLines != null ? TextOverflow.ellipsis : null),
                textScaler: widget.textScaler,
              ),
            ),
        ],
      ),
    );
  }
}

class _RollSpec {
  const _RollSpec({
    required this.prefix,
    required this.suffix,
    required this.oldDigits,
    required this.newDigits,
    required this.direction,
  });
  final String prefix;
  final String suffix;
  final String oldDigits;
  final String newDigits;
  final double direction;
}

@visibleForTesting
class RollingDigit extends StatelessWidget {
  const RollingDigit({
    super.key,
    required this.oldChar,
    required this.newChar,
    required this.direction,
    required this.animation,
    this.style,
    this.textScaler,
  });

  final String oldChar;
  final String newChar;
  final double direction;
  final Animation<double> animation;
  final TextStyle? style;
  final TextScaler? textScaler;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = FikraMotion.rollCurve.transform(animation.value);
          return Stack(
            alignment: Alignment.center,
            children: [
              if (oldChar != ' ')
                FractionalTranslation(
                  translation: Offset(0, -direction * t),
                  child: Opacity(
                    opacity: (1 - t).clamp(0.0, 1.0),
                    child: Text(oldChar, style: style, textScaler: textScaler),
                  ),
                ),
              FractionalTranslation(
                translation: Offset(0, direction * (1 - t)),
                child: Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Text(newChar == ' ' ? '' : newChar, style: style, textScaler: textScaler),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
