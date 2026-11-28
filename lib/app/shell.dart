import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/motion/motion.dart';
import '../core/widgets/glass_quality.dart';
import '../core/widgets/pearl_canvas.dart';
import '../core/widgets/navigation_inset.dart';
import '../features/capture/capture_controller.dart';
import 'composer_navigation.dart';
import 'product_runtime.dart';
import 'tab_bar/activity_capsule.dart';
import 'tab_bar/floating_navigation.dart';
import 'tab_bar/product_navigation.dart';

export 'tab_bar/sliding_tab_bar.dart';
export 'branch_container.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.shell, this.showLegacyActivity = true});
  final StatefulNavigationShell shell;
  final bool showLegacyActivity;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final _scrollShrink = ValueNotifier<double>(0);
  int? _lastBranch;
  int _composerReturn = 1;

  void _stopLiveRecordingIfLeavingComposer() {
    if (widget.showLegacyActivity) return;
    final capture = ref.read(productRuntimeProvider).capture;
    if (capture.state == CaptureState.starting) {
      unawaited(capture.cancel());
    } else if (capture.state == CaptureState.recording) {
      unawaited(capture.stop());
    }
  }

  void _closeComposer() {
    _stopLiveRecordingIfLeavingComposer();
    widget.shell.goBranch(_composerReturn);
  }
  bool _shrinkEnabled = false;
  bool _reduced = false;

  /// viewInsets changes on every frame of the keyboard animation, but this
  /// tree only depends on whether it is open. Returning the identical widget
  /// stops those frames from rebuilding the navigation and copying ThemeData.
  Widget? _built;
  (StatefulNavigationShell, bool, double, ThemeData, bool, bool, bool)? _builtFor;

  @override
  void dispose() {
    _scrollShrink.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    _builtFor = null;
  }

  bool _onScroll(ScrollNotification notification) {
    if (!_shrinkEnabled || _reduced) return false;
    // Only standard top-to-bottom vertical lists drive bar shrink; ignore
    // horizontal scrollables and reversed vertical lists (AxisDirection.up).
    if (notification.metrics.axisDirection != AxisDirection.down) return false;
    if (notification is ScrollUpdateNotification) {
      final pixels = notification.metrics.pixels;
      if (pixels <= 0) {
        if (_scrollShrink.value != 0) _scrollShrink.value = 0;
        return false;
      }
      final delta = notification.scrollDelta ?? 0;
      if (delta == 0) return false;
      if (pixels > notification.metrics.maxScrollExtent && delta > 0) return false;
      final next = (_scrollShrink.value + delta / FikraMotion.barShrinkDistance).clamp(0.0, 1.0);
      if (next != _scrollShrink.value) _scrollShrink.value = next;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final shell = widget.shell;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    final theme = Theme.of(context);
    final shrinkEnabled = !kReleaseMode && ref.watch(navBarShrinkEnabledProvider);
    _shrinkEnabled = shrinkEnabled;
    _reduced = FikraMotion.reduced(context);
    if ((_lastBranch != null && _lastBranch != shell.currentIndex) || !shrinkEnabled || _reduced) {
      if (_scrollShrink.value != 0) _scrollShrink.value = 0;
    }
    if (shell.currentIndex == 0 && _lastBranch != null && _lastBranch != 0) _composerReturn = _lastBranch!;
    if (_lastBranch == 0 && shell.currentIndex != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.shell.currentIndex != 0) _stopLiveRecordingIfLeavingComposer();
      });
    }
    _lastBranch = shell.currentIndex;
    final inputs = _builtFor;
    if (inputs != null &&
        identical(inputs.$1, shell) &&
        inputs.$2 == keyboard &&
        inputs.$3 == safeBottom &&
        inputs.$5 == shrinkEnabled &&
        inputs.$6 == widget.showLegacyActivity &&
        inputs.$7 == _reduced &&
        // Theme.of's localized copy is cached FIFO, so equal can mean a new instance.
        (identical(inputs.$4, theme) || inputs.$4 == theme)) {
      return _built!;
    }
    _builtFor = (shell, keyboard, safeBottom, theme, shrinkEnabled, widget.showLegacyActivity, _reduced);
    final hidden = keyboard || shell.currentIndex == 0;
    final bottomInset = hidden ? 0.0 : FloatingNavigation.clearance + safeBottom;
    return _built = PearlCanvas(
      child: Theme(
        // Keep existing toasts/Undo reachable above the same floating controls.
        data: theme.copyWith(
          snackBarTheme: theme.snackBarTheme.copyWith(insetPadding: EdgeInsets.fromLTRB(16, 5, 16, bottomInset + 10)),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: true,
          // The snackbar inset follows the keyboard. Re-provide the unchanged
          // theme so that change cannot rebuild every themed widget in all
          // five branches, offstage ones included; only snackbars see it.
          body: Theme(
            data: theme,
            child: Stack(
              children: [
                Positioned.fill(
                  child: NavigationInset(
                    bottom: bottomInset,
                    child: SafeArea(
                      bottom: false,
                      child: ComposerNavigation(
                        close: _closeComposer,
                        child: PopScope(
                          canPop: shell.currentIndex != 0,
                          onPopInvokedWithResult: (didPop, _) {
                            if (!didPop && shell.currentIndex == 0) _closeComposer();
                          },
                          child: NotificationListener<ScrollNotification>(onNotification: _onScroll, child: shell),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: FloatingNavigation.gap + safeBottom,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    heightFactor: 1,
                    child: !widget.showLegacyActivity
                        ? ProductNavigation(
                            branch: shell.currentIndex,
                            hidden: hidden,
                            onSelect: (branch, reselect) => shell.goBranch(branch, initialLocation: reselect),
                          )
                        : FloatingNavigation(
                            branch: shell.currentIndex,
                            keyboardOpen: hidden,
                            shrink: shrinkEnabled ? _scrollShrink : null,
                            aboveBar: widget.showLegacyActivity
                                ? ActivityCapsule(
                                    branch: shell.currentIndex,
                                    onOpenAdd: () => shell.goBranch(0, initialLocation: false),
                                    onOpenNote: (id) => context.push('/note/$id'),
                                  )
                                : null,
                            onSelect: (branch, reselect) => shell.goBranch(branch, initialLocation: reselect),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
