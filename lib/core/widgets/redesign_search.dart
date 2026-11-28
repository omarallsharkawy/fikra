import 'smart_input.dart';

import 'package:flutter/material.dart';

import '../theme/redesign_tokens.dart';
import 'redesign_widgets.dart';

class RdSearch extends StatefulWidget {
  const RdSearch({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
    required this.onSubmitted,
  });
  final String value, label;
  final ValueChanged<String> onChanged, onSubmitted;
  @override
  State<RdSearch> createState() => _RdSearchState();
}

class _RdSearchState extends State<RdSearch> {
  late final _controller = TextEditingController(text: widget.value);
  @override
  void didUpdateWidget(RdSearch old) {
    super.didUpdateWidget(old);
    if (_controller.text != widget.value) {
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
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: context.rd.surface,
      border: Border.all(color: context.rd.line),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      spacing: 8,
      children: [
        ExcludeSemantics(child: RdIcon('search', color: context.rd.muted)),
        Expanded(
          child: SmartInput(
            controller: _controller,
            style: RdTokens.style(context),
            textInputAction: TextInputAction.search,
            textAlignVertical: TextAlignVertical.center,
            onChanged: (v) {
              widget.onChanged(v);
              setState(() {});
            },
            onSubmitted: widget.onSubmitted,
            decoration: InputDecoration(
              hintText: widget.label,
              hintStyle: RdTokens.style(context, color: context.rd.muted),
              filled: false,
              isCollapsed: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              constraints: const BoxConstraints(minHeight: 44),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    ),
  );
}
