import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../theme/tokens.dart';

import 'buttons.dart';
import 'glass.dart';

/// Destructive confirmation. Returns true when confirmed.
Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
}) async {
  final label = confirmLabel ?? context.l10n.delete;
  final navigator = Navigator.of(context, rootNavigator: true);
  final ok = await navigator.push<bool>(
    _FikraDialogRoute(
      context: context,
      reduced: FikraMotion.reduced(context),
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      barrierColor: context.colors.scrim,
      traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 35),
        child: Glass(
          radius: FikraRadius.xl,
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(namesRoute: true, header: true, child: Text(title, style: context.text.cardTitle)),
              const SizedBox(height: 8),
              Text(message, style: context.text.body.copyWith(color: context.colors.textSecondary)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FikraButton.danger(label: label, onPressed: () => Navigator.pop(context, true)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FikraButton.secondary(
                      label: context.l10n.cancel,
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return ok ?? false;
}

/// Retains Material's barrier, safe area, theme capture and dialog semantics.
class _FikraDialogRoute extends DialogRoute<bool> {
  _FikraDialogRoute({
    required super.context,
    required super.builder,
    required this.reduced,
    super.themes,
    super.barrierColor,
    super.traversalEdgeBehavior,
  });

  final bool reduced;

  @override
  Duration get transitionDuration => reduced ? FikraMotion.reducedFade : FikraMotion.enter;

  @override
  Duration get reverseTransitionDuration => reduced ? FikraMotion.reducedFade : FikraMotion.exit;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (FikraMotion.reduced(context)) return FadeTransition(opacity: animation, child: child);
    return DualTransitionBuilder(
      animation: animation,
      forwardBuilder: (context, animation, child) {
        final progress = animation.drive(CurveTween(curve: FikraMotion.enterCurve));
        return FadeTransition(
          opacity: progress,
          child: ScaleTransition(
            scale: progress.drive(Tween(begin: FikraMotion.enterScale, end: 1.0)),
            child: child,
          ),
        );
      },
      reverseBuilder: (context, animation, child) => FadeTransition(
        opacity: ReverseAnimation(animation.drive(CurveTween(curve: FikraMotion.exitCurve))),
        child: child,
      ),
      child: child,
    );
  }
}
