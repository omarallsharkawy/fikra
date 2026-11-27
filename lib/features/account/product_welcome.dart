import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/redesign_tokens.dart';
import '../../core/widgets/redesign_widgets.dart';
import '../../l10n/localizations.dart';

class ProductWelcome extends StatelessWidget {
  const ProductWelcome({
    super.key,
    required this.onSignup,
    required this.onLogin,
    required this.onSample,
    required this.onEmpty,
    required this.busy,
    this.preview = true,
  });
  final VoidCallback? onSignup, onLogin, onSample, onEmpty;
  final bool busy, preview;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _WelcomeSteps(),
      const SizedBox(height: 22),
      Semantics(header: true, child: RdText(context.l10n.rdTagl, size: 28, height: 1.3, weight: FontWeight.w700)),
      const SizedBox(height: 14),
      RdText(context.l10n.rdTag1, color: context.rd.muted),
      const SizedBox(height: 34),
      RdButton(context.l10n.rdGs, key: const ValueKey('auth-start-signup'), onPressed: onSignup),
      const SizedBox(height: 10),
      RdButton(context.l10n.rdHave, key: const ValueKey('auth-start-login'), primary: false, onPressed: onLogin),
      if (preview) ...[
        const SizedBox(height: 24),
        RdButton(
          context.l10n.productPreviewSampleWorkspace,
          key: const ValueKey('fixture-reader'),
          primary: false,
          onPressed: onSample,
          loading: busy,
        ),
        TextButton(
          key: const ValueKey('fixture-other'),
          onPressed: onEmpty,
          child: Text(context.l10n.productPreviewSeparateEmptyAccount),
        ),
      ],
    ],
  );
}

class _WelcomeSteps extends StatefulWidget {
  const _WelcomeSteps();
  @override
  State<_WelcomeSteps> createState() => _WelcomeStepsState();
}

class _WelcomeStepsState extends State<_WelcomeSteps> {
  Timer? _timer;
  int _tick = 0, _active = 0;
  bool? _reduce;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (_reduce == reduce) return;
    _reduce = reduce;
    _timer?.cancel();
    _active = reduce ? -1 : 0;
    _tick = 0;
    if (!reduce) {
      _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        _tick = (_tick + 1) % 30;
        final active = _tick % 10 >= 9 ? -1 : _tick ~/ 10;
        if (active != _active && mounted) setState(() => _active = active);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = [context.l10n.rdWr, context.l10n.rdLk, context.l10n.rdAs];
    return Row(
      spacing: 8,
      children: [
        for (var i = 0; i < 3; i++)
          Expanded(
            child: AnimatedContainer(
              duration: _reduce == true ? Duration.zero : const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
              decoration: BoxDecoration(
                color: _active == i ? context.rd.lime : context.rd.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.rd.line),
              ),
              child: Column(
                children: [
                  RdIcon(['file', 'map', 'ask'][i], color: _active == i ? context.rd.onLime : context.rd.text),
                  const SizedBox(height: 11.87),
                  RdText(
                    labels[i],
                    weight: FontWeight.w600,
                    align: TextAlign.center,
                    color: _active == i ? context.rd.onLime : context.rd.text,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
