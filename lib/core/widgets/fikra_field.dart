import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';

import '../motion/pressable.dart';
import '../theme/tokens.dart';

import 'solid_surface.dart';

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
    this.clearable = false,
    this.clearButtonKey,
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

  /// Shows a 48 dp clear (X) control when non-empty that clears the query and keeps focus.
  final bool clearable;
  final Key? clearButtonKey;

  @override
  State<FikraField> createState() => _FikraFieldState();
}

class _FikraFieldState extends State<FikraField> {
  final _focus = FocusNode();
  TextEditingController? _ownedController;

  TextEditingController? get _controller =>
      widget.controller ?? (widget.clearable ? (_ownedController ??= TextEditingController()) : null);

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant FikraField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null && _ownedController != null) {
      _ownedController!.dispose();
      _ownedController = null;
    }
  }

  @override
  void dispose() {
    _ownedController?.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _clear() {
    final controller = _controller;
    if (controller == null) return;
    // Keep the keyboard only if it was up: a field the user scrolled away from
    // (keyboard dismissed) stays unfocused after clearing.
    final hadFocus = _focus.hasFocus;
    controller.clear();
    widget.onChanged?.call('');
    if (hadFocus) _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final clearable = widget.clearable && controller != null;
    final light = Theme.of(context).brightness == Brightness.light;
    final border = widget.error
        ? context.colors.danger
        : _focus.hasFocus
        ? context.colors.accent
        : light
        ? context.colors.borderGraph
        : context.colors.line;
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: FikraSpace.field),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(20, 0, clearable ? 0 : 20, 0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: _focus,
                autofocus: widget.autofocus,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                keyboardType: widget.keyboardType,
                obscureText: widget.obscure,
                textInputAction: widget.textInputAction,
                maxLength: widget.maxLength,
                textAlignVertical: TextAlignVertical.center,
                style: context.text.field,
                decoration: InputDecoration(
                  isDense: true,
                  constraints: const BoxConstraints(minHeight: FikraSpace.field),
                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
                  border: InputBorder.none,
                  counterText: '',
                  hintText: widget.hint,
                  hintStyle: context.text.field.copyWith(color: context.colors.textSecondary),
                ),
              ),
            ),
            if (clearable)
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) => value.text.isNotEmpty
                    ? const SizedBox(width: Pressable.minTargetSize)
                    : Padding(
                        padding: const EdgeInsetsDirectional.only(end: 20),
                        child: widget.icon == null
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsetsDirectional.only(start: 12),
                                child: Icon(widget.icon, color: context.colors.textSecondary, size: 20),
                              ),
                      ),
              )
            else if (widget.icon != null) ...[
              const SizedBox(width: 12),
              Icon(widget.icon, color: context.colors.textSecondary, size: 20),
            ],
          ],
        ),
      ),
    );
    // SolidSurface fills behind the row so focus border width changes never shift field height,
    // and the clear control overlays outside the border to keep a full 48×48 dp target.
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: SolidSurface(
            radius: FikraRadius.full,
            padding: EdgeInsets.zero,
            borderColor: border,
            // A hairline vanishes on light surfaces; inputs need a visible edge.
            borderWidth: widget.error || _focus.hasFocus || light ? 1 : FikraSpace.hairline,
            child: const SizedBox.expand(),
          ),
        ),
        row,
        if (clearable)
          PositionedDirectional(
            end: 0,
            top: 0,
            bottom: 0,
            width: Pressable.minTargetSize,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) => IgnorePointer(
                ignoring: value.text.isEmpty,
                child: value.text.isEmpty
                    ? const SizedBox.shrink()
                    : TextFieldTapRegion(
                        child: Pressable(
                          key: widget.clearButtonKey,
                          onTap: _clear,
                          minTarget: true,
                          semanticLabel: context.l10n.clearSearch,
                          child: Icon(Icons.close_rounded, color: context.colors.textSecondary, size: 20),
                        ),
                      ),
              ),
            ),
          ),
      ],
    );
  }
}
