import 'package:flutter/material.dart';

import '../../core/theme/redesign_tokens.dart';
import '../../core/widgets/redesign_widgets.dart';
import '../../l10n/localizations.dart';
import '../workspace/product_widgets.dart';

/// The reference's sticky header and 14px column rhythm, with a scrollable
/// content area so keyboards and accessibility text never hide form actions.
class ProductAuthLayout extends StatelessWidget {
  const ProductAuthLayout({
    super.key,
    required this.title,
    required this.children,
    this.previewDetails = const [],
    this.subtitle,
    this.icon = 'me',
    this.onBack,
    this.welcome = false,
  });
  final String title, icon;
  final String? subtitle;
  final List<Widget> children;
  final List<String> previewDetails;
  final VoidCallback? onBack;
  final bool welcome;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.rd.bg,
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  children: [
                    Visibility(
                      visible: !welcome,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: RdIconButton(
                        'back',
                        key: const ValueKey('auth-back'),
                        label: context.l10n.rdBack,
                        onPressed: onBack,
                        flip: true,
                      ),
                    ),
                    const Spacer(),
                    const RdLogo(),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  key: const ValueKey('auth-scroll'),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 14,
                      children: [
                        if (!welcome) ...[
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: context.rd.purpleSoft,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              alignment: Alignment.center,
                              child: RdIcon(icon, color: context.rd.purple),
                            ),
                          ),
                          Semantics(header: true, child: RdText(title, size: 26, weight: FontWeight.w700)),
                          if (subtitle != null) RdText(subtitle!, color: context.rd.muted),
                        ],
                        ...children,
                        if (ProductEnvironment.previewOf(context)) DevelopmentBanner(details: previewDetails),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
