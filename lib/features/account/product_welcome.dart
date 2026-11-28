import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
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
  final bool busy;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final compact = size.height < 680 || textScale >= 1.5;
    final titleSize = (size.width * 0.076).clamp(24.0, 32.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ExcludeSemantics(child: _WelcomeShapes()),
        SizedBox(height: compact ? 14 : 22),
        Semantics(
          header: true,
          child: Text(
            context.l10n.welcomeTagline,
            textAlign: TextAlign.center,
            style: context.text.title.copyWith(fontSize: titleSize, height: 1.2),
          ),
        ),
        SizedBox(height: compact ? 6 : 10),
        Text(
          context.l10n.uiWelcomeSubtitle,
          textAlign: TextAlign.center,
          style: context.text.body.copyWith(color: context.colors.textSecondary),
        ),
        SizedBox(height: compact ? 18 : 28),
        FikraButton(label: context.l10n.uiSignUpEmail, onPressed: onSignup, growForText: true),
        const SizedBox(height: 12),
        FikraButton.secondary(
          label: context.l10n.uiContinueGoogle,
          onPressed: null,
          icon: Icons.account_circle_outlined,
          growForText: true,
        ),
        const SizedBox(height: 8),
        Text(
          preview ? context.l10n.uiGoogleUnavailable : context.l10n.apiGoogleUnavailable,
          textAlign: TextAlign.center,
          style: context.text.meta,
        ),
        const SizedBox(height: 4),
        TextButton(onPressed: onLogin, child: Text(context.l10n.uiLogIn)),
        if (preview) ...[
          const Divider(height: 28),
          FikraButton.secondary(
            key: const ValueKey('fixture-reader'),
            label: context.l10n.productPreviewSampleWorkspace,
            onPressed: onSample,
            loading: busy,
            growForText: true,
          ),
          const SizedBox(height: 12),
          TextButton(
            key: const ValueKey('fixture-other'),
            onPressed: onEmpty,
            child: Text(context.l10n.productPreviewSeparateEmptyAccount, textAlign: TextAlign.center),
          ),
        ],
      ],
    );
  }
}

class _WelcomeShapes extends StatelessWidget {
  const _WelcomeShapes();

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final artHeight = textScale >= 1.6
        ? (screenHeight * 0.14).clamp(104.0, 140.0)
        : (screenHeight * 0.22).clamp(132.0, 200.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.isFinite ? constraints.maxWidth : 320.0;
        final purpleSize = (w * 0.54).clamp(140.0, 220.0);
        final limeSize = (w * 0.34).clamp(92.0, 144.0);
        final blueSize = (w * 0.25).clamp(68.0, 108.0);
        return Container(
          height: artHeight,
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: context.colors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              PositionedDirectional(
                end: -purpleSize * 0.14,
                top: -purpleSize * 0.32,
                child: Container(
                  width: purpleSize,
                  height: purpleSize,
                  decoration: BoxDecoration(color: context.colors.brandPurple, shape: BoxShape.circle),
                ),
              ),
              PositionedDirectional(
                start: -limeSize * 0.24,
                bottom: -limeSize * 0.12,
                child: Container(
                  width: limeSize,
                  height: limeSize,
                  decoration: BoxDecoration(color: context.colors.brandLime, shape: BoxShape.circle),
                ),
              ),
              PositionedDirectional(
                end: w * 0.14,
                bottom: artHeight * 0.08,
                child: Transform.rotate(
                  angle: .28,
                  child: Container(
                    width: blueSize,
                    height: blueSize,
                    decoration: BoxDecoration(
                      color: context.colors.brandBlue,
                      borderRadius: BorderRadius.circular(blueSize * 0.3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
