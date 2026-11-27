import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/redesign_tokens.dart';
import '../../core/widgets/redesign_widgets.dart';
import '../../l10n/localizations.dart';

class RedesignAuthField extends StatefulWidget {
  const RedesignAuthField({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
    this.password = false,
    this.enabled = true,
    this.keyboardType,
    this.autofillHints,
    this.textDirection,
    this.inputFormatters,
    this.action = TextInputAction.next,
    this.onSubmitted,
  });
  final String value, label;
  final ValueChanged<String> onChanged;
  final bool password, enabled;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextDirection? textDirection;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction action;
  final ValueChanged<String>? onSubmitted;
  @override
  State<RedesignAuthField> createState() => _RedesignAuthFieldState();
}

class _RedesignAuthFieldState extends State<RedesignAuthField> {
  late final _controller = TextEditingController(text: widget.value);
  bool _revealed = false;
  @override
  void didUpdateWidget(RedesignAuthField old) {
    super.didUpdateWidget(old);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    enabled: widget.enabled,
    onChanged: (v) {
      widget.onChanged(v);
      if (widget.textDirection == null) setState(() {});
    },
    onSubmitted: widget.onSubmitted,
    textInputAction: widget.action,
    keyboardType: widget.keyboardType,
    autofillHints: widget.autofillHints,
    inputFormatters: widget.inputFormatters,
    textDirection: widget.textDirection ?? rdDirection(_controller.text),
    textAlign: (widget.textDirection ?? rdDirection(_controller.text)) == TextDirection.rtl
        ? TextAlign.right
        : TextAlign.left,
    style: RdTokens.style(context),
    obscureText: widget.password && !_revealed,
    enableSuggestions: !widget.password,
    autocorrect: !widget.password,
    decoration: InputDecoration(
      hintText: widget.label,
      hintStyle: RdTokens.style(context, color: context.rd.muted),
      filled: true,
      fillColor: context.rd.surface,
      contentPadding: const EdgeInsetsDirectional.fromSTEB(14, 13, 6, 13),
      isDense: true,
      constraints: const BoxConstraints(minHeight: 52),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: context.rd.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: context.rd.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: context.rd.blue),
      ),
      suffixIconConstraints: const BoxConstraints(minHeight: 44, minWidth: 44),
      suffixIcon: widget.password
          ? TextButton(
              onPressed: widget.enabled ? () => setState(() => _revealed = !_revealed) : null,
              style: TextButton.styleFrom(
                foregroundColor: context.rd.blue,
                textStyle: RdTokens.style(context),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(_revealed ? context.l10n.rdHide : context.l10n.rdShow),
            )
          : null,
    ),
  );
}
