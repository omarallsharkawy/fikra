import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/transcription/service_config.dart';
import '../../l10n/localizations.dart';
import 'service_copy.dart';
import 'voice_text_models.dart';
import '../shared/group_form.dart';

class ServiceFormFields extends StatelessWidget {
  const ServiceFormFields({
    super.key,
    required this.type,
    required this.name,
    required this.url,
    required this.modelPicker,
    required this.keyText,
    required this.language,
    required this.obscured,
    required this.onShowKey,
    required this.onType,
    required this.onChanged,
    required this.keepKey,
  });
  final TranscriptionServiceType type;
  final TextEditingController name, url, keyText, language;
  final Widget modelPicker;
  final bool obscured, keepKey;
  final VoidCallback onShowKey, onChanged;
  final ValueChanged<TranscriptionServiceType> onType;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(top: FikraSpace.s16, bottom: FikraSpace.s8),
      child: SmartText(text, style: context.text.section),
    );
    Widget field(String key, TextEditingController controller, String hint, {bool ltr = true}) => Semantics(
      label: hint,
      child: FikraField(
        content: ltr ? InputContent.identifier : InputContent.text,
        key: ValueKey(key),
        controller: controller,
        hint: hint,
        textInputAction: TextInputAction.next,
        onChanged: (_) => onChanged(),
      ),
    );
    final editableUrl = type == TranscriptionServiceType.openAi || type == TranscriptionServiceType.qwen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetOption(
          key: const ValueKey('vs-type'),
          label: '${l.vsType}\n${serviceTypeName(l, type)}',
          icon: Icons.tune_rounded,
          onTap: () => showFikraSheet<void>(
            context,
            title: l.vsType,
            builder: (sheet) => Column(
              children: [
                for (final choice in TranscriptionServiceType.values)
                  VoiceTextChoice(
                    key: ValueKey('vs-type-${choice.name}'),
                    label: serviceTypeName(l, choice),
                    selected: type == choice,
                    onTap: () {
                      Navigator.pop(sheet);
                      onType(choice);
                    },
                  ),
              ],
            ),
          ),
        ),
        SmartText(serviceKeyHint(l, type), style: context.text.caption),
        label(l.vsName),
        field('vs-name', name, l.vsName, ltr: false),
        label(l.vsBaseUrl),
        if (type == TranscriptionServiceType.qwen) ...[
          SmartText(l.vsRegion, content: ReadOnlyContent.chrome, style: context.text.caption),
          const SizedBox(height: FikraSpace.s8),
          Wrap(
            spacing: FikraSpace.s8,
            runSpacing: FikraSpace.s8,
            children: [
              for (final region in [(qwenInternationalUrl, l.vsSingapore), (qwenMainlandUrl, l.vsBeijing)])
                ChoiceTag(
                  key: ValueKey(region.$1 == qwenInternationalUrl ? 'vs-intl' : 'vs-mainland'),
                  label: region.$2,
                  selected: url.text == region.$1,
                  onTap: () {
                    url.text = region.$1;
                    onChanged();
                  },
                ),
            ],
          ),
          const SizedBox(height: FikraSpace.s8),
        ],
        if (editableUrl)
          field('vs-url', url, l.vsBaseUrl)
        else
          SmartText(url.text, selectable: true, content: ReadOnlyContent.identifier, style: context.text.caption),
        if (url.text.trim().toLowerCase().startsWith('http:')) ...[
          const SizedBox(height: FikraSpace.s8),
          StatusBanner(kind: BannerKind.info, message: l.vsHttpWarning),
        ],
        label(l.vsModel),
        modelPicker,
        label(l.vsKey),
        Row(
          children: [
            Expanded(
              child: Semantics(
                label: l.vsKey,
                child: FikraField(
                  content: InputContent.identifier,
                  key: const ValueKey('vs-key'),
                  controller: keyText,
                  hint: l.vsKey,
                  obscure: obscured,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => onChanged(),
                ),
              ),
            ),
            FikraIconButton(
              key: const ValueKey('vs-key-visibility'),
              icon: obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              label: obscured ? l.vsShowKey : l.vsHideKey,
              onTap: onShowKey,
            ),
          ],
        ),
        if (keepKey) SmartText(l.vsKeyKeep, content: ReadOnlyContent.chrome, style: context.text.caption),
        label(l.vsLanguageHint),
        field('vs-language-hint', language, l.vsLanguageHint),
        const SizedBox(height: FikraSpace.s8),
        SmartText(l.vsLanguageHelp, content: ReadOnlyContent.chrome, style: context.text.caption),
      ],
    );
  }
}
