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
        child: LayoutBuilder(
          builder: (context, viewport) {
            final hPad = viewport.maxWidth < 360
                ? 16.0
                : viewport.maxWidth < 440
                ? 20.0
                : 24.0;
            final compact = viewport.maxHeight < 680;
            final maxWidth = viewport.maxWidth >= 720 ? 520.0 : 480.0;
            final minContentHeight = (viewport.maxHeight - 36).clamp(0.0, double.infinity);
            final header = Row(
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
            );
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SingleChildScrollView(
                  key: const ValueKey('auth-scroll'),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minContentHeight),
                    child: AutofillGroup(
                      child: Column(
                        mainAxisAlignment: welcome ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (welcome) ...[
                            header,
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: compact ? 16 : 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: children,
                              ),
                            ),
                            DevelopmentBanner(details: previewDetails),
                          ] else ...[
                            header,
                            SizedBox(height: compact ? 16 : 24),
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: context.colors.brandPurple.withValues(alpha: .15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ExcludeSemantics(
                                  child: Icon(icon, color: context.colors.brandPurpleFg, size: 28),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Semantics(
                              header: true,
                              child: Text(title, style: context.text.title.copyWith(fontSize: 28, height: 1.2)),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 10),
                              Text(subtitle!, style: context.text.body.copyWith(color: context.colors.textSecondary)),
                            ],
                            SizedBox(height: compact ? 18 : 24),
                            ...children,
                            const SizedBox(height: 24),
                            DevelopmentBanner(details: previewDetails),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}
