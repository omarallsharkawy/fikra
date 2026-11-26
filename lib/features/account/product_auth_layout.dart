import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../core/widgets/pearl_canvas.dart';
import '../../l10n/localizations.dart';
import '../workspace/product_widgets.dart';

/// One scrollable column keeps every auth stage usable with the keyboard,
/// large text and small screens, without nesting scroll views or fixed heights.
class ProductAuthLayout extends StatelessWidget {
  const ProductAuthLayout({
    super.key,
    required this.title,
    required this.children,
    required this.previewDetails,
    this.subtitle,
    this.icon = Icons.login_rounded,
    this.onBack,
    this.welcome = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final List<String> previewDetails;
  final IconData icon;
  final VoidCallback? onBack;
  final bool welcome;

  @override
  Widget build(BuildContext context) => PearlCanvas(
    child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              key: const ValueKey('auth-scroll'),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        if (!welcome) ...[
                          IconButton(
                            key: const ValueKey('auth-back'),
                            tooltip: context.l10n.productBack,
                            onPressed: onBack,
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const Spacer(),
                        ],
                        const FikraBrandMark(size: 32),
                        const SizedBox(width: 8),
                        Text('FIKRAH', style: context.text.section),
                      ],
                    ),
                    if (!welcome) ...[
                      const SizedBox(height: 32),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: context.colors.brandPurple.withValues(alpha: .15),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: ExcludeSemantics(child: Icon(icon, color: context.colors.brandPurpleFg, size: 28)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Semantics(
                        header: true,
                        child: Text(title, style: context.text.title.copyWith(fontSize: 30, height: 1.2)),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 10),
                        Text(subtitle!, style: context.text.body.copyWith(color: context.colors.textSecondary)),
                      ],
                      const SizedBox(height: 32),
                    ] else
                      const SizedBox(height: 24),
                    ...children,
                    const SizedBox(height: 24),
                    DevelopmentBanner(details: previewDetails),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
