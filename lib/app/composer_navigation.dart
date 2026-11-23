import 'package:flutter/widgets.dart';

/// The shell owns composer return history, including direct /add entry.
class ComposerNavigation extends InheritedWidget {
  const ComposerNavigation({super.key, required this.close, required super.child});
  final VoidCallback close;

  static void closeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ComposerNavigation>()!.close();

  @override
  bool updateShouldNotify(ComposerNavigation oldWidget) => close != oldWidget.close;
}
