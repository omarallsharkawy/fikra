import 'package:flutter/material.dart';

import 'pearl_canvas.dart';
import 'navigation_inset.dart';

/// Full-screen page outside the tab shell: Pearl canvas + transparent
/// Scaffold + SafeArea. Tab screens get the same chrome from AppShell.
class FikraScaffold extends StatelessWidget {
  const FikraScaffold({super.key, required this.child, this.safeBottom = true});
  final Widget child;
  final bool safeBottom;

  @override
  Widget build(BuildContext context) {
    return PearlCanvas(
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
        padding: EdgeInsets.only(bottom: NavigationInset.of(context)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (box.maxHeight - NavigationInset.of(context)).clamp(0, double.infinity),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
