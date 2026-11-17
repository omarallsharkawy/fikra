import 'package:flutter/widgets.dart';

/// Clearance for floating shell controls, including their upper lens overhang.
/// Zero outside the shell and while the keyboard covers the controls.
class NavigationInset extends InheritedWidget {
  const NavigationInset({super.key, required this.bottom, required super.child});
  final double bottom;

  static double of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<NavigationInset>()?.bottom ?? 0;

  @override
  bool updateShouldNotify(NavigationInset oldWidget) => bottom != oldWidget.bottom;
}

/// Pads [child] by [NavigationInset]. Only this widget depends on the inset,
/// so the keyboard opening or closing does not rebuild the screen around it.
class NavigationInsetPadding extends StatelessWidget {
  const NavigationInsetPadding({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: NavigationInset.of(context)),
    child: child,
  );
}

/// Empty box of [extra] plus the [NavigationInset] height, for the end of a
/// scroll view. Only this box depends on the inset, so keyboard frames do not
/// rebuild the list that owns it.
class NavigationInsetSpacer extends StatelessWidget {
  const NavigationInsetSpacer({super.key, this.extra = 0});
  final double extra;

  @override
  Widget build(BuildContext context) => SizedBox(height: extra + NavigationInset.of(context));
}
