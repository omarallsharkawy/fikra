import 'package:flutter/material.dart';

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 3)));
}

/// Runs a user action, showing [success] only after it completes and a toast
/// on failure. Returns whether it succeeded.
Future<bool> runAction(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
  String failure = 'حصلت مشكلة، جرّب تاني',
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  void toast(String m) => messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m), duration: const Duration(seconds: 3)));
  try {
    await action();
    if (success != null) toast(success);
    return true;
  } catch (_) {
    toast(failure);
    return false;
  }
}
