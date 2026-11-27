import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show Bidi;

import '../theme/redesign_tokens.dart';
import '../../l10n/localizations.dart';
import 'navigation_inset.dart';

TextDirection rdDirection(String text, [TextDirection fallback = TextDirection.ltr]) {
  if (text.trim().isEmpty) return fallback;
  return Bidi.startsWithRtl(text) ? TextDirection.rtl : TextDirection.ltr;
}

String rdIsolate(String value) => '\u2068$value\u2069';

class RdText extends StatelessWidget {
  const RdText(
    this.text, {
    super.key,
    this.size = 15,
    this.weight = FontWeight.w400,
    this.color,
    this.height = 1.6,
    this.lines,
    this.align,
    this.direction,
    this.selectable = false,
    this.decoration,
  });
  final String text;
  final double size, height;
  final FontWeight weight;
  final Color? color;
  final int? lines;
  final TextAlign? align;
  final TextDirection? direction;
  final bool selectable;
  final TextDecoration? decoration;
  @override
  Widget build(BuildContext context) {
    final style = RdTokens.style(
      context,
      size: size,
      weight: weight,
      color: color,
      height: height,
    ).copyWith(decoration: decoration);
    final dir = direction ?? rdDirection(text, Directionality.of(context));
    return selectable
        ? SelectableText(text, style: style, textDirection: dir, textAlign: align, maxLines: lines)
        : Text(
            text,
            style: style,
            textDirection: dir,
            textAlign: align,
            maxLines: lines,
            overflow: lines == null ? null : TextOverflow.ellipsis,
          );
  }
}

class RdLogo extends StatelessWidget {
  const RdLogo({super.key});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: context.rd.lime, borderRadius: BorderRadius.circular(10)),
      child: Text(
        'f.',
        textDirection: TextDirection.ltr,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w700,
          height: 1.6,
          color: context.rd.onLime,
        ),
      ),
    ),
  );
}

class RdIcon extends StatelessWidget {
  const RdIcon(this.name, {super.key, this.size = 22, this.color, this.flip = false});
  final String name;
  final double size;
  final Color? color;
  final bool flip;
  @override
  Widget build(BuildContext context) => Transform.flip(
    flipX: flip && Directionality.of(context) == TextDirection.rtl,
    child: CustomPaint(size: Size.square(size), painter: _IconPainter(name, color ?? context.rd.text)),
  );
}

// The reference's 24x24 line geometry, including its 1.9px rounded stroke.
class _IconPainter extends CustomPainter {
  _IconPainter(this.name, this.color);
  final String name;
  final Color color;
  @override
  void paint(Canvas c, Size size) {
    c.scale(size.width / 24, size.height / 24);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void path(List<Offset> points, {bool close = false}) {
      final a = Path()..addPolygon(points, close);
      c.drawPath(a, p);
    }

    void line(double x, double y, double a, double b) => c.drawLine(Offset(x, y), Offset(a, b), p);
    void circle(double x, double y, double r) => c.drawCircle(Offset(x, y), r, p);
    switch (name) {
      case 'home':
        path(const [Offset(3, 11), Offset(12, 3), Offset(21, 11), Offset(21, 21), Offset(3, 21)], close: true);
      case 'map':
        circle(6, 6, 2.2);
        circle(18, 9, 2.2);
        circle(11, 18, 2.2);
        line(7.7, 7.6, 9.9, 15.8);
        line(16.3, 10.6, 12.5, 16.2);
      case 'ask':
        path(const [Offset(4, 5), Offset(20, 5), Offset(20, 16), Offset(9, 16), Offset(4, 20)], close: true);
      case 'me':
        circle(12, 8, 4);
        c.drawPath(
          Path()
            ..moveTo(4, 21)
            ..cubicTo(5, 16, 19, 16, 20, 21),
          p,
        );
      case 'plus':
        line(12, 5, 12, 19);
        line(5, 12, 19, 12);
      case 'back':
        path(const [Offset(15, 5), Offset(8, 12), Offset(15, 19)]);
      case 'more':
        circle(5, 12, 1.4);
        circle(12, 12, 1.4);
        circle(19, 12, 1.4);
      case 'search':
        circle(11, 11, 6);
        line(20, 20, 15.5, 15.5);
      case 'mic':
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(9, 3, 6, 11), const Radius.circular(3)), p);
        c.drawArc(const Rect.fromLTWH(5, 4, 14, 14), 0, 3.14159265, false, p);
        line(12, 18, 12, 21);
      case 'file':
        path(const [Offset(6, 3), Offset(14, 3), Offset(18, 7), Offset(18, 21), Offset(6, 21)], close: true);
      case 'tag':
        path(const [Offset(3, 12), Offset(3, 3), Offset(12, 3), Offset(21, 12), Offset(12, 21)], close: true);
      case 'x':
        line(6, 6, 18, 18);
        line(18, 6, 6, 18);
      case 'send':
        line(12, 19, 12, 5);
        path(const [Offset(5, 12), Offset(12, 5), Offset(19, 12)]);
      case 'chev':
        path(const [Offset(9, 5), Offset(16, 12), Offset(9, 19)]);
      case 'spark':
        path(const [
          Offset(12, 3),
          Offset(14, 9),
          Offset(20, 11),
          Offset(14, 13),
          Offset(12, 19),
          Offset(10, 13),
          Offset(4, 11),
          Offset(10, 9),
        ], close: true);
      case 'hist':
        c.drawArc(const Rect.fromLTWH(4, 4, 16, 16), -1.5707963, 4.712389, false, p);
        path(const [Offset(4, 4), Offset(4, 9), Offset(9, 9)]);
        path(const [Offset(12, 8), Offset(12, 12), Offset(15, 14)]);
      case 'pin':
        path(const [
          Offset(9, 3),
          Offset(15, 3),
          Offset(14, 9),
          Offset(17, 12),
          Offset(7, 12),
          Offset(10, 9),
        ], close: true);
        line(12, 12, 12, 21);
      case 'share':
        line(12, 3, 12, 15);
        path(const [Offset(7, 8), Offset(12, 3), Offset(17, 8)]);
        path(const [Offset(5, 14), Offset(5, 21), Offset(19, 21), Offset(19, 14)]);
      case 're':
        c.drawArc(const Rect.fromLTWH(4, 4, 16, 16), 0, 5.497787, false, p);
        path(const [Offset(20, 4), Offset(20, 11), Offset(13, 11)]);
      case 'del':
        line(4, 7, 20, 7);
        path(const [Offset(9, 7), Offset(9, 4), Offset(15, 4), Offset(15, 7)]);
        path(const [Offset(6, 7), Offset(7, 21), Offset(17, 21), Offset(18, 7)]);
      default:
        circle(12, 12, 8);
        line(12, 7, 12, 13);
        circle(12, 17, .5);
    }
  }

  @override
  bool shouldRepaint(covariant _IconPainter old) => old.name != name || old.color != color;
}

class RdIconButton extends StatelessWidget {
  const RdIconButton(this.icon, {super.key, required this.label, this.onPressed, this.color, this.flip = false});
  final String icon, label;
  final VoidCallback? onPressed;
  final Color? color;
  final bool flip;
  @override
  Widget build(BuildContext context) => IconButton(
    style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap, minimumSize: const Size(44, 44)),
    tooltip: label,
    onPressed: onPressed,
    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    padding: EdgeInsets.zero,
    icon: RdIcon(icon, color: color, flip: flip),
  );
}

class RdButton extends StatelessWidget {
  const RdButton(
    this.label, {
    super.key,
    this.onPressed,
    this.primary = true,
    this.danger = false,
    this.loading = false,
    this.icon,
    this.full = true,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool primary, danger, loading, full;
  final String? icon;
  @override
  Widget build(BuildContext context) {
    final c = context.rd;
    final enabled = onPressed != null && !loading;
    final bg = !enabled
        ? c.surface2
        : danger
        ? c.redSoft
        : primary
        ? c.lime
        : Colors.transparent;
    final fg = !enabled
        ? c.muted
        : danger
        ? c.red
        : primary
        ? c.onLime
        : c.text;
    return SizedBox(
      width: full ? double.infinity : null,
      child: TextButton(
        onPressed: enabled ? onPressed : null,
        style: TextButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: c.surface2,
          disabledForegroundColor: c.muted,
          minimumSize: const Size(44, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: !primary && !danger && enabled ? BorderSide(color: c.line) : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: fg)),
              ),
            if (icon != null) ...[RdIcon(icon!, color: fg), const SizedBox(width: 8)],
            Flexible(
              child: RdText(label, weight: FontWeight.w600, color: fg, align: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}

class RdChip extends StatelessWidget {
  const RdChip(
    this.label, {
    super.key,
    this.selected = false,
    this.onPressed,
    this.small = false,
    this.icon,
    this.color,
  });
  final String label;
  final bool selected, small;
  final VoidCallback? onPressed;
  final String? icon;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final c = context.rd;
    final child = Container(
      constraints: BoxConstraints(minHeight: small ? 24 : 32),
      padding: EdgeInsets.symmetric(horizontal: small ? 10 : 12, vertical: small ? 0 : 3),
      decoration: BoxDecoration(
        color: selected ? c.lime : c.surface2,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: selected ? c.lime : c.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            RdIcon(icon!, color: selected ? c.onLime : color),
            if (label.isNotEmpty) const SizedBox(width: 6),
          ],
          if (label.isNotEmpty)
            LimitedBox(
              maxWidth: 240,
              child: RdText(label, size: small ? 12 : 13, color: selected ? c.onLime : color, lines: 1),
            ),
        ],
      ),
    );
    return onPressed == null
        ? child
        : Semantics(
            selected: selected,
            button: true,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(99),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                child: Align(alignment: Alignment.topCenter, widthFactor: 1, heightFactor: 1, child: child),
              ),
            ),
          );
  }
}

class RdCard extends StatelessWidget {
  const RdCard({super.key, required this.child, this.onTap, this.ai = false, this.padding = 14, this.margin = 10});
  final Widget child;
  final VoidCallback? onTap;
  final bool ai;
  final double padding, margin;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: margin),
    child: Material(
      color: ai ? context.rd.purpleSoft : context.rd.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: ai ? context.rd.purple : context.rd.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: EdgeInsets.all(padding + 1), child: child),
      ),
    ),
  );
}

class RdPage extends StatelessWidget {
  const RdPage({
    super.key,
    required this.title,
    this.children = const [],
    this.header,
    this.trailing,
    this.footer,
    this.body,
    this.back,
    this.controller,
  });
  final String title;
  final List<Widget> children;
  final Widget? header, trailing, footer, body;
  final VoidCallback? back;
  final ScrollController? controller;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.rd.bg,
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child:
                header ??
                Container(
                  constraints: const BoxConstraints(minHeight: 60),
                  padding: const EdgeInsets.only(top: 14, bottom: 10),
                  child: Row(
                    children: [
                      if (back != null)
                        RdIconButton('back', label: context.l10n.rdBack, onPressed: back, flip: true)
                      else
                        const RdLogo(),
                      const SizedBox(width: 8),
                      Expanded(child: RdText(title, size: 22, weight: FontWeight.w600)),
                      ?trailing,
                    ],
                  ),
                ),
          ),
          Expanded(
            child:
                body ??
                ListView(
                  controller: controller,
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + NavigationInset.of(context)),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  children: children,
                ),
          ),
          ?footer,
        ],
      ),
    ),
  );
}

Future<T?> rdSheet<T>(BuildContext context, {required Widget child}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useRootNavigator: true,
  useSafeArea: true,
  showDragHandle: false,
  sheetAnimationStyle: AnimationStyle(
    duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : RdTokens.sheetMotion,
  ),
  builder: (context) => Padding(
    padding: EdgeInsets.fromLTRB(16, 18, 16, 20 + MediaQuery.viewInsetsOf(context).bottom),
    child: SingleChildScrollView(child: child),
  ),
);

Future<bool> rdConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirm,
  bool danger = false,
}) async =>
    await rdSheet<bool>(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          RdText(title, size: 18, weight: FontWeight.w600),
          const SizedBox(height: 8),
          RdText(message, color: context.rd.muted),
          const SizedBox(height: 14),
          RdButton(confirm, danger: danger, onPressed: () => Navigator.pop(context, true)),
          const SizedBox(height: 8),
          RdButton(context.l10n.rdCancel, primary: false, onPressed: () => Navigator.pop(context, false)),
        ],
      ),
    ) ??
    false;
