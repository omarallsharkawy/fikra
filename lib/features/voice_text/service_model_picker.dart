import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/transcription/model_catalog.dart';
import '../../data/transcription/model_discovery.dart';
import '../../data/transcription/service_config.dart';
import '../../l10n/localizations.dart';
import 'service_consent.dart';
import 'service_copy.dart';
import 'voice_text_models.dart';

class ServiceModelPicker extends ConsumerStatefulWidget {
  const ServiceModelPicker({
    super.key,
    required this.service,
    required this.onChanged,
    required this.readKey,
    required this.onAgreed,
    required this.enabled,
    required this.onBusy,
  });
  final TranscriptionService service;
  final ValueChanged<String> onChanged, onAgreed;
  final Future<String?> Function(TranscriptionService service) readKey;
  final bool enabled;
  final ValueChanged<bool> onBusy;
  @override
  ConsumerState<ServiceModelPicker> createState() => _ServiceModelPickerState();
}

class _ServiceModelPickerState extends ConsumerState<ServiceModelPicker> {
  DiscoveredModels? _cache;
  bool _busy = false;
  String? _error;
  String get _identity => '${widget.service.id}:${widget.service.consentIdentity}';
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ServiceModelPicker old) {
    super.didUpdateWidget(old);
    if (old.service.id != widget.service.id || old.service.consentIdentity != widget.service.consentIdentity) {
      _cache = null;
      _error = null;
      _load();
    }
  }

  Future<void> _load() async {
    final identity = _identity;
    try {
      final cache = await ref.read(modelDiscoveryProvider).cached(widget.service);
      if (mounted && identity == _identity) setState(() => _cache = cache);
    } catch (_) {
      if (mounted && identity == _identity) setState(() => _error = context.l10n.vsLoadError);
    }
  }

  Future<void> _refresh() async {
    if (_busy) return;
    final identity = _identity;
    FocusScope.of(context).unfocus();
    widget.onBusy(true);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      var service = widget.service;
      service.validate();
      if (!await confirmServiceConsent(context, service) || !mounted) return;
      widget.onAgreed(service.consentIdentity);
      service = service.authorize();
      final result = await ref.read(modelDiscoveryProvider).refresh(service, () => widget.readKey(service));
      if (mounted && identity == _identity) setState(() => _cache = result);
    } catch (error) {
      if (mounted) {
        final message = serviceErrorMessage(context.l10n, error);
        setState(() => _error = message);
        showToast(context, message);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        widget.onBusy(false);
      }
    }
  }

  Future<void> _pick() async {
    final selected = await showFikraSheet<String>(
      context,
      title: context.l10n.vsModel,
      builder: (_) => _CatalogSheet(service: widget.service, available: _cache?.ids ?? const {}),
    );
    if (selected != null && mounted) widget.onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final qwen = widget.service.type == TranscriptionServiceType.qwen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IgnorePointer(
          ignoring: !widget.enabled || _busy,
          child: SheetOption(
            key: const ValueKey('vs-model'),
            label: widget.service.batchModel,
            icon: Icons.expand_more_rounded,
            onTap: _pick,
          ),
        ),
        if (qwen)
          Text(l.v2DiscoveryQwen, style: context.text.caption)
        else ...[
          FikraButton.secondary(
            key: const ValueKey('v2-refresh'),
            label: _busy ? l.v2Refreshing : l.v2Refresh,
            loading: _busy,
            growForText: true,
            onPressed: widget.enabled && !_busy ? _refresh : null,
          ),
          const SizedBox(height: FikraSpace.s8),
          Text(l.v2DiscoveryHint, style: context.text.caption),
          if (_cache != null)
            Text(l.v2Checked(Fmt.isolate(Fmt.relative(l, _cache!.checkedAt.toLocal()))), style: context.text.meta),
        ],
        if (_error != null) StatusBanner(kind: BannerKind.error, message: _error!),
      ],
    );
  }
}

class _CatalogSheet extends StatefulWidget {
  const _CatalogSheet({required this.service, required this.available});
  final TranscriptionService service;
  final Set<String> available;
  @override
  State<_CatalogSheet> createState() => _CatalogSheetState();
}

class _CatalogSheetState extends State<_CatalogSheet> {
  late final _custom = TextEditingController(text: widget.service.batchModel);
  bool _expanded = false;
  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final models = catalogFor(widget.service.type, widget.service.baseUrl);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final status in ModelStatus.values)
          if (models.any((m) => m.status == status && m.supported)) ...[
            Semantics(
              header: true,
              child: Text(switch (status) {
                ModelStatus.recommended => l.v2Recommended,
                ModelStatus.other => l.v2Other,
                ModelStatus.legacy => l.v2Legacy,
              }, style: context.text.section),
            ),
            const SizedBox(height: FikraSpace.s8),
            for (final model in models.where((m) => m.status == status && m.supported)) ...[
              VoiceTextChoice(
                key: ValueKey('v2-model-${model.id}'),
                label: '${model.label}\n${model.id}',
                selected: model.id == widget.service.batchModel,
                onTap: () => Navigator.pop(context, model.id),
              ),
              Text(
                model.arabic == ArabicSuitability.generative ? l.v2Generative : l.v2Arabic,
                style: context.text.caption,
              ),
              if (widget.available.contains(model.id)) Text(l.v2Available, style: context.text.meta),
              if (status == ModelStatus.legacy)
                Text(
                  model.shutdown == null
                      ? l.v2LegacyUnknown
                      : l.v2Shutdown(Fmt.isolate(Fmt.date(l, DateTime.parse(model.shutdown!)))),
                  style: context.text.caption,
                ),
              const SizedBox(height: FikraSpace.s12),
            ],
          ],
        for (final model in models.where((m) => !m.supported))
          Text('${model.label} · ${l.v2Unsupported}', style: context.text.caption),
        Semantics(
          expanded: _expanded,
          child: SheetOption(
            key: const ValueKey('v2-custom-toggle'),
            label: l.v2Custom,
            icon: _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            onTap: () => setState(() => _expanded = !_expanded),
          ),
        ),
        if (_expanded) ...[
          Directionality(
            textDirection: TextDirection.ltr,
            child: FikraField(key: const ValueKey('v2-custom-id'), controller: _custom, hint: l.vsModel),
          ),
          const SizedBox(height: FikraSpace.s12),
          FikraButton(
            key: const ValueKey('v2-custom-save'),
            label: l.save,
            onPressed: () {
              if (RegExp(r'^[a-zA-Z0-9._:/-]{1,160}$').hasMatch(_custom.text.trim())) {
                Navigator.pop(context, _custom.text.trim());
              } else {
                showToast(context, l.vsInvalidFields);
              }
            },
          ),
        ],
      ],
    );
  }
}
