import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/ids.dart';
import '../../data/transcription/service_config.dart';
import '../../data/transcription/remote_engine.dart';
import '../../l10n/localizations.dart';
import 'service_consent.dart';
import 'service_copy.dart';
import 'service_form_fields.dart';
import 'whisper_metrics.dart';

class ServiceFormScreen extends ConsumerStatefulWidget {
  const ServiceFormScreen({super.key, this.serviceId});
  final String? serviceId;
  @override
  ConsumerState<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends ConsumerState<ServiceFormScreen> {
  final _name = TextEditingController(), _url = TextEditingController(), _model = TextEditingController();
  final _key = TextEditingController(), _language = TextEditingController();
  late final _id = widget.serviceId ?? newId();
  TranscriptionServiceType _type = TranscriptionServiceType.openAi;
  TranscriptionService? _existing;
  String? _authorized, _error, _testText;
  bool _initialized = false, _busy = false, _obscured = true, _probing = false, _allowPop = false;

  @override
  void dispose() {
    for (final c in [_name, _url, _model, _key, _language]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _needsKey =>
      _existing == null || _existing!.type != _type || serviceOrigin(_existing!.baseUrl) != serviceOrigin(_url.text);
  TranscriptionService _value() => TranscriptionService(
    id: _id,
    type: _type,
    name: _name.text.trim(),
    baseUrl: _url.text.trim().replaceAll(RegExp(r'/+$'), ''),
    model: _model.text.trim(),
    language: _language.text.trim().isEmpty ? null : _language.text.trim(),
    consentedFor: _authorized,
  );
  void _changed() => setState(() {
    _testText = null;
    _error = null;
  });

  Future<void> _act(Future<void> Function() action, {bool probe = false}) async {
    if (_busy || _allowPop) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _probing = probe;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) {
        final message = serviceErrorMessage(context.l10n, error);
        setState(() => _error = message);
        showToast(context, message);
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _probing = false;
        });
      }
    }
  }

  void _validate(TranscriptionService value) {
    value.validate();
    if (_needsKey && _key.text.trim().isEmpty) {
      throw const ServiceConfigException(ServiceConfigIssue.keyRequired);
    }
  }

  Future<void> _test() => _act(() async {
    var service = _value();
    _validate(service);
    if (!await confirmServiceConsent(context, service) || !mounted) return;
    _authorized = service.consentIdentity;
    service = service.authorize();
    // This explicit probe uses a bundled silence clip, never a note recording.
    final typed = _key.text.trim();
    final engine = RemoteTranscriptionEngine(
      service,
      (id) => typed.isEmpty
          ? ref.read(transcriptionServicesProvider).readKey(id, forService: service)
          : Future.value(typed),
      ref.read(transcriptionTransportProvider),
    );
    final text = await engine.upload(connectionTestClip(), language: 'auto', connectionTest: true);
    if (mounted) setState(() => _testText = text);
  }, probe: true);
  Future<void> _save() => _act(() async {
    final value = _value();
    _validate(value);
    await ref.read(transcriptionServicesProvider).save(value, key: _key.text.trim().isEmpty ? null : _key.text.trim());
    if (mounted) _leave();
  });
  Future<void> _delete() => _act(() async {
    if (!await confirmDestructive(context, title: context.l10n.vsDeleteTitle, message: context.l10n.vsDeleteBody) ||
        !mounted) {
      return;
    }
    await ref.read(transcriptionServicesProvider).delete(_id);
    if (mounted) _leave();
  });

  void _leave() {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transcriptionServicesStateProvider);
    final l = context.l10n;
    if (!_initialized && state.hasValue) {
      _existing = state.requireValue.services.where((s) => s.id == widget.serviceId).firstOrNull;
      _type = _existing?.type ?? TranscriptionServiceType.openAi;
      _name.text = _existing?.name ?? serviceTypeName(l, _type);
      _url.text = _existing?.baseUrl ?? defaultServiceUrl(_type);
      _model.text = _existing?.model ?? defaultServiceModel(_type);
      _language.text = _existing?.language ?? '';
      _authorized = _existing?.consentedFor;
      _initialized = true;
    }
    final missing = widget.serviceId != null && _initialized && _existing == null;
    return PopScope(
      canPop: !_busy || _allowPop,
      child: FikraScaffold(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(FikraSpace.s8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: FikraIconButton(
                  icon: Icons.arrow_back_rounded,
                  label: l.back,
                  onTap: () {
                    if (!_busy) context.pop();
                  },
                ),
              ),
            ),
            Expanded(
              child: !_initialized || missing
                  ? Center(child: Text(state.hasError || missing ? l.vsLoadError : l.vtWait))
                  : ListView(
                      key: const ValueKey('vs-form-scroll'),
                      padding: const EdgeInsets.all(FikraSpace.screen),
                      children: [
                        Text(
                          widget.serviceId == null ? l.vsAdd : l.vsEdit,
                          style: context.text.title.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: FikraSpace.s16),
                        IgnorePointer(
                          ignoring: _busy,
                          child: ServiceFormFields(
                            type: _type,
                            name: _name,
                            url: _url,
                            model: _model,
                            keyText: _key,
                            language: _language,
                            obscured: _obscured,
                            keepKey: !_needsKey,
                            onShowKey: () => setState(() => _obscured = !_obscured),
                            onChanged: _changed,
                            onType: (type) => setState(() {
                              if (_type == type) return;
                              _type = type;
                              _name.text = serviceTypeName(l, type);
                              _url.text = defaultServiceUrl(type);
                              _model.text = defaultServiceModel(type);
                              _key.clear();
                              _testText = null;
                              _error = null;
                            }),
                          ),
                        ),
                        const SizedBox(height: FikraSpace.s24),
                        if (_error != null)
                          StatusBanner(key: const ValueKey('vs-form-error'), kind: BannerKind.error, message: _error!),
                        if (_testText != null) ...[
                          StatusBanner(
                            key: const ValueKey('vs-connected'),
                            kind: BannerKind.info,
                            message: l.vsConnected,
                          ),
                          if (_testText!.isNotEmpty)
                            SelectableText(
                              _testText!,
                              style: context.text.body,
                              textDirection: containsArabic(_testText!) ? TextDirection.rtl : TextDirection.ltr,
                            ),
                          const SizedBox(height: FikraSpace.s12),
                        ],
                        FikraButton.secondary(
                          key: const ValueKey('vs-test'),
                          label: _probing ? l.vsTesting : l.vsTest,
                          loading: _probing,
                          growForText: true,
                          onPressed: _busy ? null : _test,
                        ),
                        const SizedBox(height: FikraSpace.s12),
                        FikraButton(
                          key: const ValueKey('vs-save'),
                          label: l.save,
                          growForText: true,
                          loading: _busy && !_probing,
                          onPressed: _busy ? null : _save,
                        ),
                        if (_existing != null) ...[
                          const SizedBox(height: FikraSpace.s12),
                          FikraButton.danger(
                            key: const ValueKey('vs-delete'),
                            label: l.delete,
                            onPressed: _busy ? null : _delete,
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
