import 'dart:async';
import 'dart:math' as math;

import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';

import '../motion/pressable.dart';
import '../theme/tokens.dart';
import 'glass_edge.dart';

/// How long a toast with an action (Undo) stays: long enough to reach it.
const toastActionDuration = Duration(seconds: 6);

/// Shows [message], replacing any toast on screen. With [actionLabel] and
/// [onAction] it carries one button (Undo) and stays [toastActionDuration];
/// while a screen reader is on it stays until the next toast, so the button
/// can be reached. That follows the screen reader while the toast is shown:
/// turned on, the toast stays; turned off, it leaves [toastActionDuration]
/// later. The text is a live region, so screen readers announce it.
void showToast(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
  showMessengerToast(
    ScaffoldMessenger.of(context),
    message,
    actionLabel: actionLabel,
    onAction: onAction,
    measureContext: context,
  );
}

/// Shows a solid floating toast pill on a captured [messenger] (for example
/// after an async write whose originating page may have closed).
void showMessengerToast(
  ScaffoldMessengerState? messenger,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  BuildContext? measureContext,
}) {
  if (messenger == null || !messenger.mounted) return;
  final ctx = measureContext != null && measureContext.mounted ? measureContext : messenger.context;
  final action = actionLabel != null && onAction != null;

  final screenWidth = MediaQuery.widthOf(ctx);
  final maxWidth = math.max(120.0, screenWidth - 32.0);
  final textScaler = MediaQuery.textScalerOf(ctx);
  final direction = Directionality.maybeOf(ctx) ?? TextDirection.rtl;
  final locale = Localizations.maybeLocaleOf(ctx);
  final defaultStyle = DefaultTextStyle.of(ctx).style;

  final msgPainter = TextPainter(
    text: TextSpan(text: message, style: defaultStyle.merge(ctx.text.body)),
    textDirection: direction,
    textScaler: textScaler,
    locale: locale,
  )..layout();
  final msgWidth = msgPainter.width;
  msgPainter.dispose();

  var stacked = false;
  final double capsuleWidth;
  if (!action) {
    capsuleWidth = (msgWidth + 42).ceilToDouble().clamp(0.0, maxWidth);
  } else {
    final actStyle = defaultStyle.merge(ctx.text.chip.copyWith(fontWeight: FontWeight.w700));
    final actPainter = TextPainter(
      text: TextSpan(text: actionLabel, style: actStyle),
      textDirection: direction,
      textScaler: textScaler,
      locale: locale,
      maxLines: 1,
    )..layout();
    final actWidth = math.max(Pressable.minTargetSize, actPainter.width + 28);
    actPainter.dispose();
    stacked = actWidth > maxWidth * 0.45;
    final natural = stacked ? math.max(msgWidth + 36, actWidth + 28) : 18 + msgWidth + 8 + actWidth + 10;
    capsuleWidth = natural.ceilToDouble().clamp(0.0, maxWidth);
  }

  // Once pressed or replaced, the toast is leaving: its timer must not
  // hide it again (or the toast after it).
  final shown = ++_toasts;
  var pressed = false;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        width: capsuleWidth < screenWidth ? capsuleWidth : null,
        clipBehavior: Clip.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(stacked ? FikraRadius.xl : FikraRadius.full)),
        content: _ToastCapsule(
          message: message,
          actionLabel: action ? actionLabel : null,
          stacked: stacked,
          onAction: action
              ? () {
                  pressed = true;
                  onAction();
                }
              : null,
          leaving: action ? () => pressed || _toasts != shown : null,
        ),
        duration: action ? toastActionDuration : const Duration(seconds: 3),
        // A toast with an action times itself out (_ToastCapsule), since the
        // messenger decides `persist` once, when the toast is shown.
        persist: action,
      ),
    );
}

/// Toasts shown by [showMessengerToast] so far.
var _toasts = 0;

/// Solid high-contrast floating pill content of a toast. When [leaving] is set,
/// closes the toast [toastActionDuration] after it was shown, or after the
/// screen reader was turned off, and never while a screen reader is on.
class _ToastCapsule extends StatefulWidget {
  const _ToastCapsule({required this.message, this.actionLabel, this.stacked = false, this.onAction, this.leaving});
  final String message;
  final String? actionLabel;
  final bool stacked;
  final VoidCallback? onAction;

  /// True once the toast was closed by its button or replaced.
  final bool Function()? leaving;

  @override
  State<_ToastCapsule> createState() => _ToastCapsuleState();
}

class _ToastCapsuleState extends State<_ToastCapsule> {
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final leaving = widget.leaving;
    if (leaving == null) return;
    if (MediaQuery.accessibleNavigationOf(context)) {
      _timer?.cancel();
      _timer = null;
    } else {
      // While this toast is shown it is the current one (a newer toast waits
      // until it has left), so hiding the current toast hides this one.
      _timer ??= Timer(toastActionDuration, () {
        if (mounted && !leaving()) {
          ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar(reason: SnackBarClosedReason.timeout);
        }
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
    final c = context.colors;
    final light = Theme.of(context).brightness == Brightness.light;
    final actionLabel = widget.actionLabel;
    final onAction = widget.onAction;

    Widget pill({required double radius, required EdgeInsetsGeometry padding, required Widget child}) => DecoratedBox(
      key: const ValueKey('toast-capsule'),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: light ? c.borderGraph : c.line, width: 1),
        boxShadow: glassShadows(c),
      ),
      child: Padding(padding: padding, child: child),
    );

    if (actionLabel == null || onAction == null) {
      return pill(
        radius: FikraRadius.full,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Text(widget.message, style: context.text.body),
      );
    }

    final actionStyle = context.text.chip.copyWith(fontWeight: FontWeight.w700);
    final actionButton = TextButtonTheme(
      data: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(Pressable.minTargetSize, Pressable.minTargetSize),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          textStyle: actionStyle,
        ),
      ),
      child: SnackBarAction(
        label: actionLabel,
        // The default action colour (inversePrimary) vanishes on the light toast.
        textColor: c.accent,
        onPressed: onAction,
      ),
    );

    return pill(
      radius: widget.stacked ? FikraRadius.xl : FikraRadius.full,
      padding: widget.stacked
          ? const EdgeInsets.fromLTRB(18, 10, 10, 4)
          : const EdgeInsetsDirectional.fromSTEB(18, 4, 8, 4),
      child: widget.stacked
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: Text(widget.message, style: context.text.body),
                ),
                Align(alignment: AlignmentDirectional.centerEnd, child: actionButton),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(widget.message, style: context.text.body),
                  ),
                ),
                const SizedBox(width: 8),
                actionButton,
              ],
            ),
    );
  }
}

/// Runs a user action, showing [success] only after it completes and a toast
/// on failure. Returns whether it succeeded.
Future<bool> runAction(BuildContext context, Future<void> Function() action, {String? success, String? failure}) async {
  final failureMessage = failure ?? context.l10n.genericError;
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    await action();
    if (success != null) {
      showMessengerToast(messenger, success, measureContext: context.mounted ? context : null);
    }
    return true;
  } catch (_) {
    showMessengerToast(messenger, failureMessage, measureContext: context.mounted ? context : null);
    return false;
  }
}
