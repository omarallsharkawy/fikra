import 'package:flutter/material.dart';

import '../../core/theme/redesign_tokens.dart';
import '../../core/widgets/redesign_widgets.dart';
import '../../l10n/localizations.dart';
import '../account/redesign_auth_field.dart';
import 'local_tags_controller.dart';
import 'product_widgets.dart';

Future<Set<String>?> pickNoteTags(BuildContext context, LocalTagsController tags, Set<String> current) =>
    rdSheet<Set<String>>(
      context,
      child: _TagPicker(tags: tags, current: current),
    );

class _TagPicker extends StatefulWidget {
  const _TagPicker({required this.tags, required this.current});
  final LocalTagsController tags;
  final Set<String> current;
  @override
  State<_TagPicker> createState() => _TagPickerState();
}

class _TagPickerState extends State<_TagPicker> {
  late final _selected = Set<String>.of(widget.current);
  Future<void> _edit([LocalTag? tag]) async {
    final id = await rdSheet<String>(
      context,
      child: _TagForm(tags: widget.tags, tag: tag),
    );
    if (id != null && mounted) setState(() => _selected.add(id));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.tags,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        RdText(context.l10n.rdTag, size: 18, weight: FontWeight.w600),
        if (widget.tags.loading) const Center(child: CircularProgressIndicator()),
        if (widget.tags.failure != null) ProductFailureView(widget.tags.failure!),
        for (final tag in widget.tags.tags)
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  value: _selected.contains(tag.id),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: RdText(tag.label),
                  onChanged: widget.tags.busy
                      ? null
                      : (v) => setState(() {
                          if (v == true) {
                            _selected.add(tag.id);
                          } else {
                            _selected.remove(tag.id);
                          }
                        }),
                ),
              ),
              IconButton(
                tooltip: context.l10n.rdEditTag,
                onPressed: widget.tags.busy ? null : () => _edit(tag),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
        RdButton(context.l10n.rdNewTag, primary: false, onPressed: widget.tags.busy ? null : () => _edit()),
        RdText(context.l10n.rdNameDevice, size: 13, color: context.rd.muted),
        RdButton(context.l10n.rdSave, onPressed: widget.tags.busy ? null : () => Navigator.pop(context, _selected)),
      ],
    ),
  );
}

class _TagForm extends StatefulWidget {
  const _TagForm({required this.tags, this.tag});
  final LocalTagsController tags;
  final LocalTag? tag;
  @override
  State<_TagForm> createState() => _TagFormState();
}

class _TagFormState extends State<_TagForm> {
  late String _label = widget.tag?.label ?? '';
  bool _invalid = false;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.tags,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 14,
      children: [
        RdText(widget.tag == null ? context.l10n.rdNewTag : context.l10n.rdEditTag, size: 18, weight: FontWeight.w600),
        RedesignAuthField(
          value: _label,
          label: context.l10n.rdTagName,
          onChanged: (v) => setState(() {
            _label = v;
            _invalid = false;
          }),
          action: TextInputAction.done,
          enabled: !widget.tags.busy,
        ),
        if (_invalid) RdText(context.l10n.rdTagExists, size: 13, color: context.rd.red),
        if (widget.tags.failure != null) ProductFailureView(widget.tags.failure!),
        RdButton(
          context.l10n.rdSave,
          loading: widget.tags.busy,
          onPressed: _label.trim().isEmpty
              ? null
              : () async {
                  final tag = widget.tag;
                  if (tag == null) {
                    final created = await widget.tags.create(_label, color: widget.tags.tags.length % 4);
                    if (created != null && context.mounted) Navigator.pop(context, created.id);
                  } else {
                    final ok = await widget.tags.rename(tag.id, _label);
                    if (context.mounted) {
                      if (ok) {
                        Navigator.pop(context, tag.id);
                      } else {
                        setState(() => _invalid = true);
                      }
                    }
                  }
                },
        ),
      ],
    ),
  );
}
