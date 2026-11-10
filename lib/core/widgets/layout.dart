import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Full-screen page outside the tab shell: screen gradient + transparent
/// Scaffold + SafeArea. Tab screens get the same chrome from AppShell.
class FikraScaffold extends StatelessWidget {
  const FikraScaffold({super.key, required this.child, this.safeBottom = true});
  final Widget child;
  final bool safeBottom;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: context.colors.screenGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(bottom: safeBottom, child: child),
      ),
    );
  }
}

/// Fills the available height and centers [child], scrolling instead of
/// overflowing when the window is short (landscape, large text, keyboard).
class FillScroll extends StatelessWidget {
  const FillScroll({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }
}
