import 'package:flutter/material.dart';

import '../text_direction.dart';

enum ReadOnlyContent { text, chrome, identifier }

/// Read-only content uses first-strong direction without changing its parent UI.
class SmartText extends StatelessWidget {
  const SmartText(
    this.data, {
    super.key,
    this.content = ReadOnlyContent.text,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.selectable = false,
    this.direction,
    this.textDirection,
    this.softWrap,
    this.textScaler,
    this.semanticsLabel,
  }) : span = null;
  const SmartText.rich(
    this.span, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.selectable = true,
    this.direction,
    this.textDirection,
    this.softWrap,
    this.textScaler,
    this.semanticsLabel,
    this.content = ReadOnlyContent.text,
  }) : data = '';
  final TextSpan? span;
  final ReadOnlyContent content;
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool selectable;
  final TextDirection? direction, textDirection;
  final bool? softWrap;
  final TextScaler? textScaler;
  final String? semanticsLabel;
  @override
  Widget build(BuildContext context) {
    final raw = span?.toPlainText() ?? data;
    final ui = Directionality.of(context);
    final dir =
        direction ??
        textDirection ??
        switch (content) {
          ReadOnlyContent.chrome => ui,
          ReadOnlyContent.identifier => TextDirection.ltr,
          ReadOnlyContent.text => contentDirection(raw, ui),
        };
    final align = textAlign ?? (content == ReadOnlyContent.identifier && ui != dir ? TextAlign.end : TextAlign.start);
    final value = isolateMixedText(raw, dir);
    final resolved = (style ?? DefaultTextStyle.of(context).style).copyWith(
      fontFamily: 'Inter',
      fontFamilyFallback: const ['IBMPlexSansArabic', 'Noto Color Emoji'],
      height: 1.6,
      letterSpacing: 0,
    );
    if (span != null) {
      TextSpan isolate(TextSpan node) {
        final text = node.text;
        final value = text == null
            ? null
            : contentDirection(text, dir) != dir
            ? bidiIsolate(text)
            : isolateMixedText(text, dir);
        return TextSpan(
          text: value,
          style: node.style,
          children: [
            for (final child in node.children ?? const <InlineSpan>[]) child is TextSpan ? isolate(child) : child,
          ],
        );
      }

      final rich = isolate(span!);
      return selectable
          ? SelectableText.rich(
              rich,
              style: resolved,
              textDirection: dir,
              textAlign: align,
              maxLines: maxLines,
              textScaler: textScaler,
              semanticsLabel: semanticsLabel ?? raw,
            )
          : Text.rich(
              rich,
              style: resolved,
              textDirection: dir,
              textAlign: align,
              maxLines: maxLines,
              overflow: overflow,
              textScaler: textScaler,
              semanticsLabel: semanticsLabel ?? raw,
            );
    }
    return selectable
        ? SelectableText(
            value,
            textDirection: dir,
            textAlign: align,
            style: resolved,
            maxLines: maxLines,
            textScaler: textScaler,
            semanticsLabel: semanticsLabel ?? (value == raw ? null : raw),
          )
        : Text(
            value,
            textDirection: dir,
            textAlign: align,
            softWrap: softWrap,
            style: resolved,
            maxLines: maxLines,
            overflow: overflow,
            textScaler: textScaler,
            semanticsLabel: semanticsLabel ?? (value == raw ? null : raw),
          );
  }
}
