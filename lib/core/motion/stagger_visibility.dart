import 'package:flutter/widgets.dart';

import 'motion.dart';
import 'stagger.dart';

/// Keeps branch visibility dependencies away from the expensive screen build.
class StaggerVisibility extends StatefulWidget {
  const StaggerVisibility({super.key, required this.controllers, this.onHidden});

  final List<StaggerController> controllers;
  final VoidCallback? onHidden;

  @override
  State<StaggerVisibility> createState() => _StaggerVisibilityState();
}

class _StaggerVisibilityState extends State<StaggerVisibility> {
  bool _enabled = true;
  bool _reduced = false;
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _enabled = TickerMode.valuesOf(context).enabled;
    _reduced = FikraMotion.reduced(context);
    if (_scheduled) return;
    _scheduled = true;
    // Stopping a stagger notifies its rows; clearing selection can rebuild the
    // parent. Neither may run while this leaf's siblings are being built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted) return;
      for (final controller in widget.controllers) {
        controller.syncVisibility(tickerEnabled: _enabled, reduced: _reduced);
      }
      if (!_enabled) widget.onHidden?.call();
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
