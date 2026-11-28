import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../text_direction.dart';

/// A semantic input kind, rather than a screen-owned direction override.
enum InputContent { text, identifier }

/// The only editable-text direction policy in the app. Decorations/icons remain
/// in UI order; identifiers render LTR at the UI start. Empty/cleared fields use
/// UI direction. Listening never rewrites selection or an IME composing range.
class SmartInput extends StatefulWidget {
  const SmartInput({
    super.key,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.content = InputContent.text,
    this.decoration = const InputDecoration(),
    this.style,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.enabled,
    this.readOnly = false,
    this.autofocus = false,
    this.obscureText = false,
    this.autocorrect,
    this.enableSuggestions = true,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.textAlignVertical,
    this.expands = false,
    this.scrollPadding = const EdgeInsets.all(20),
    this.textCapitalization = TextCapitalization.none,
  });
  final TextEditingController? controller;
  final String? initialValue;
  final FocusNode? focusNode;
  final InputContent content;
  final InputDecoration? decoration;
  final TextStyle? style;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged, onSubmitted;
  final VoidCallback? onEditingComplete;
  final bool? enabled, autocorrect;
  final bool readOnly, autofocus, obscureText, enableSuggestions, expands;
  final int? minLines, maxLines, maxLength;
  final TextAlignVertical? textAlignVertical;
  final EdgeInsets scrollPadding;
  final TextCapitalization textCapitalization;
  @override
  State<SmartInput> createState() => _SmartInputState();
}

class _SmartInputState extends State<SmartInput> {
  TextEditingController? _owned;
  TextEditingController get _controller =>
      widget.controller ?? (_owned ??= TextEditingController(text: widget.initialValue));
  @override
  void didUpdateWidget(SmartInput old) {
    super.didUpdateWidget(old);
    if (widget.controller != null && _owned != null) {
      _owned!.dispose();
      _owned = null;
    }
  }

  @override
  void dispose() {
    _owned?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<TextEditingValue>(
    valueListenable: _controller,
    builder: (context, value, _) {
      final ui = Directionality.of(context);
      final technical =
          widget.content == InputContent.identifier ||
          widget.obscureText ||
          [
            TextInputType.emailAddress,
            TextInputType.url,
            TextInputType.number,
            TextInputType.phone,
          ].contains(widget.keyboardType);
      final direction = value.text.isEmpty
          ? ui
          : technical
          ? TextDirection.ltr
          : contentDirection(value.text, ui);
      final alignment = technical && value.text.isNotEmpty && direction != ui ? TextAlign.end : TextAlign.start;
      final style = (widget.style ?? DefaultTextStyle.of(context).style).copyWith(
        fontFamily: 'Inter',
        fontFamilyFallback: const ['IBMPlexSansArabic', 'Noto Color Emoji'],
        height: 1.6,
        letterSpacing: 0,
      );
      return TextField(
        controller: _controller,
        focusNode: widget.focusNode,
        textDirection: direction,
        textAlign: alignment,
        style: style,
        decoration: widget.decoration?.copyWith(
          hintTextDirection: ui,
          hintMaxLines: widget.decoration?.hintMaxLines ?? (widget.maxLines == 1 ? 2 : widget.maxLines),
          hintStyle: (widget.decoration?.hintStyle ?? style).copyWith(
            fontFamily: 'Inter',
            fontFamilyFallback: const ['IBMPlexSansArabic', 'Noto Color Emoji'],
            height: 1.6,
            letterSpacing: 0,
          ),
        ),
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        autofocus: widget.autofocus,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        autofillHints: widget.autofillHints,
        inputFormatters: [
          TextInputFormatter.withFunction((oldValue, newValue) {
            // Do not truncate, filter or rewrite an in-progress IME composition.
            if (newValue.composing.isValid && !newValue.composing.isCollapsed) return newValue;
            var next = newValue;
            if (widget.keyboardType == TextInputType.number) {
              final normalized = next.text.replaceAllMapped(RegExp(r'[\u0660-\u0669\u06f0-\u06f9]'), (m) {
                final code = m[0]!.codeUnitAt(0);
                return '${code - (code >= 0x6f0 ? 0x6f0 : 0x660)}';
              });
              next = next.copyWith(text: normalized);
            }
            for (final formatter in widget.inputFormatters ?? const <TextInputFormatter>[]) {
              next = formatter.formatEditUpdate(oldValue, next);
            }
            return next;
          }),
        ],
        obscureText: widget.obscureText,
        autocorrect: widget.autocorrect,
        enableSuggestions: widget.enableSuggestions,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        onEditingComplete: widget.onEditingComplete,
        minLines: widget.minLines,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        textAlignVertical: widget.textAlignVertical,
        expands: widget.expands,
        scrollPadding: widget.scrollPadding,
        textCapitalization: widget.textCapitalization,
      );
    },
  );
}
