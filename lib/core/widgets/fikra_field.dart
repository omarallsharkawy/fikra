import 'package:flutter/material.dart';

import '../theme/tokens.dart';

import 'glass.dart';

/// 48px pill input on glass. Icon sits at the end (left in RTL), like the design.
class FikraField extends StatefulWidget {
  const FikraField({
    super.key,
    this.controller,
    this.hint,
    this.icon,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.error = false,
    this.keyboardType,
    this.obscure = false,
    this.textInputAction,
    this.maxLength,
  });

  final TextEditingController? controller;
  final String? hint;
  final IconData? icon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool error;
  final TextInputType? keyboardType;
  final bool obscure;
  final TextInputAction? textInputAction;
  final int? maxLength;

  @override
  State<FikraField> createState() => _FikraFieldState();
}

class _FikraFieldState extends State<FikraField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    final border = widget.error
        ? context.colors.danger
        : _focus.hasFocus
        ? context.colors.borderFocus
        : light
        ? context.colors.borderGraph
        : context.colors.border;
    return Glass(
      radius: FikraRadius.full,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      borderColor: border,
      // A hairline vanishes on light surfaces; inputs need a visible edge.
      borderWidth: widget.error || _focus.hasFocus || light ? 1 : FikraSpace.hairline,
      height: FikraSpace.field,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              autofocus: widget.autofocus,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              keyboardType: widget.keyboardType,
              obscureText: widget.obscure,
              textInputAction: widget.textInputAction,
              maxLength: widget.maxLength,
              style: context.text.field,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                counterText: '',
                hintText: widget.hint,
                hintStyle: context.text.field.copyWith(color: context.colors.textPlaceholder),
              ),
            ),
          ),
          if (widget.icon != null) ...[
            const SizedBox(width: 12),
            Icon(widget.icon, color: context.colors.textSecondary, size: 20),
          ],
        ],
      ),
    );
  }
}
