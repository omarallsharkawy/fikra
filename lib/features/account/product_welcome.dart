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
  });
  final VoidCallback? onSignup, onLogin, onSample, onEmpty;
  final bool busy;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const ExcludeSemantics(child: _WelcomeShapes()),
      const SizedBox(height: 16),
      Text(context.l10n.welcomeTagline, style: context.text.title.copyWith(fontSize: 24)),
      const SizedBox(height: 8),
      Text(context.l10n.welcomeSubtitle, style: context.text.body.copyWith(color: context.colors.textSecondary)),
      const SizedBox(height: 24),
      FikraButton(label: context.l10n.uiSignUpEmail, onPressed: onSignup, growForText: true),
      const SizedBox(height: 12),
      FikraButton.secondary(
        label: context.l10n.uiContinueGoogle,
        onPressed: null,
        icon: Icons.account_circle_outlined,
        growForText: true,
      ),
      const SizedBox(height: 8),
      Text(context.l10n.productGoogleSignInWaitingForApprovedPlatformConfiguration, style: context.text.meta),
      TextButton(onPressed: onLogin, child: Text(context.l10n.uiLogIn)),
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
  );
}

class _WelcomeShapes extends StatelessWidget {
  const _WelcomeShapes();
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 150,
    child: ClipRect(
      child: Stack(
        children: [
          PositionedDirectional(
            end: -30,
            top: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(color: context.colors.brandPurple, shape: BoxShape.circle),
            ),
          ),
          PositionedDirectional(
            start: -44,
            bottom: 0,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(color: context.colors.brandLime, shape: BoxShape.circle),
            ),
          ),
          PositionedDirectional(
            end: 46,
            bottom: 0,
            child: Transform.rotate(
              angle: .3,
              child: Container(
                width: 94,
                height: 94,
                decoration: BoxDecoration(color: context.colors.brandBlue, borderRadius: BorderRadius.circular(28)),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
