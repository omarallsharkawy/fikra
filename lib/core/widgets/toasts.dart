import 'dart:async';

import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// How long a toast with an action (Undo) stays: long enough to reach it.
const toastActionDuration = Duration(seconds: 6);

/// Shows [message], replacing any toast on screen. With [actionLabel] and
/// [onAction] it carries one button (Undo) and stays [toastActionDuration];
/// while a screen reader is on it stays until the next toast, so the button
/// can be reached. That follows the screen reader while the toast is shown:
/// turned on, the toast stays; turned off, it leaves [toastActionDuration]
/// later. The text is a live region, so screen readers announce it.
void showToast(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
  final action = actionLabel != null && onAction != null;
  // Once pressed or replaced, the toast is leaving: its timer must not
  // hide it again (or the toast after it).
  final shown = ++_toasts;
  var pressed = false;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: action ? _TimedToast(message: message, leaving: () => pressed || _toasts != shown) : Text(message),
        duration: action ? toastActionDuration : const Duration(seconds: 3),
        // A toast with an action times itself out (_TimedToast), since the
        // messenger decides `persist` once, when the toast is shown.
        persist: action,
        // The default action colour (inversePrimary) vanishes on the light toast.
        action: action
            ? SnackBarAction(
                label: actionLabel,
                textColor: context.colors.accent,
                onPressed: () {
                  pressed = true;
                  onAction();
                },
              )
            : null,
      ),
    );
}

/// Toasts shown by [showToast] so far.
var _toasts = 0;

/// The text of a toast with an action. It closes the toast
/// [toastActionDuration] after it was shown, or after the screen reader was
/// turned off, and never while a screen reader is on.
class _TimedToast extends StatefulWidget {
  const _TimedToast({required this.message, required this.leaving});
  final String message;

  /// True once the toast was closed by its button or replaced.
  final bool Function() leaving;

  @override
  State<_TimedToast> createState() => _TimedToastState();
}

class _TimedToastState extends State<_TimedToast> {
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.accessibleNavigationOf(context)) {
      _timer?.cancel();
      _timer = null;
    } else {
      // While this toast is shown it is the current one (a newer toast waits
      // until it has left), so hiding the current toast hides this one.
      _timer ??= Timer(toastActionDuration, () {
        if (mounted && !widget.leaving()) {
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
  Widget build(BuildContext context) => Text(widget.message);
}

/// Runs a user action, showing [success] only after it completes and a toast
/// on failure. Returns whether it succeeded.
Future<bool> runAction(BuildContext context, Future<void> Function() action, {String? success, String? failure}) async {
  final failureMessage = failure ?? context.l10n.genericError;
  final messenger = ScaffoldMessenger.maybeOf(context);
  void toast(String m) => messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m), duration: const Duration(seconds: 3)));
  try {
    await action();
    if (success != null) toast(success);
    return true;
  } catch (_) {
    toast(failureMessage);
    return false;
  }
}
