import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/motion/motion.dart';
import '../core/theme/tokens.dart';
import '../core/widgets/glass_quality.dart';
import '../core/widgets/pearl_canvas.dart';
import '../core/widgets/navigation_inset.dart';
import 'tab_bar/activity_capsule.dart';
import 'tab_bar/floating_navigation.dart';

export 'tab_bar/sliding_tab_bar.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  /// The box that paints the Pearl canvas behind every tab. The tab veil
  /// aligns the same static paint to it.
  final _background = GlobalKey(debugLabel: 'shell background');
  final _scrollShrink = ValueNotifier<double>(0);
  int? _lastBranch;
  bool _shrinkEnabled = false;
  bool _reduced = false;

  /// viewInsets changes on every frame of the keyboard animation, but this
  /// tree only depends on whether it is open. Returning the identical widget
  /// stops those frames from rebuilding the navigation and copying ThemeData.
  Widget? _built;
  (StatefulNavigationShell, bool, double, ThemeData, bool)? _builtFor;

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
    _lastBranch = shell.currentIndex;
    final inputs = _builtFor;
    if (inputs != null &&
        identical(inputs.$1, shell) &&
        inputs.$2 == keyboard &&
        inputs.$3 == safeBottom &&
        inputs.$5 == shrinkEnabled &&
        // Theme.of's localized copy is cached FIFO, so equal can mean a new instance.
        (identical(inputs.$4, theme) || inputs.$4 == theme)) {
      return _built!;
    }
    _builtFor = (shell, keyboard, safeBottom, theme, shrinkEnabled);
    final bottomInset = keyboard ? 0.0 : FloatingNavigation.clearance + safeBottom;
    return _built = ShellBackground(
      anchor: _background,
      child: PearlCanvas(
        key: _background,
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
            // four branches, offstage ones included; only snackbars see it.
            body: Theme(
              data: theme,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: NavigationInset(
                      bottom: bottomInset,
                      child: SafeArea(
                        bottom: false,
                        child: NotificationListener<ScrollNotification>(onNotification: _onScroll, child: shell),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: FloatingNavigation.gap + safeBottom,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      heightFactor: 1,
                      child: FloatingNavigation(
                        branch: shell.currentIndex,
                        keyboardOpen: keyboard,
                        shrink: shrinkEnabled ? _scrollShrink : null,
                        aboveBar: ActivityCapsule(
                          branch: shell.currentIndex,
                          onOpenAdd: () => shell.goBranch(0, initialLocation: false),
                          onOpenNote: (id) => context.push('/note/$id'),
                        ),
                        onSelect: (branch, reselect) => shell.goBranch(branch, initialLocation: reselect),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Points descendants at the render box that paints the screen background.
class ShellBackground extends InheritedWidget {
  const ShellBackground({super.key, required this.anchor, required super.child});
  final GlobalKey anchor;

  static GlobalKey? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellBackground>()?.anchor;

  @override
  bool updateShouldNotify(ShellBackground old) => old.anchor != anchor;
}

/// All navigator elements stay in their original slots. Only the selected
/// branch paints, receives input/focus/semantics, or runs descendant tickers.
class FikraBranchContainer extends StatefulWidget {
  const FikraBranchContainer({super.key, required this.index, required this.children});
  final int index;
  final List<Widget> children;

  @override
  State<FikraBranchContainer> createState() => _FikraBranchContainerState();
}

class _FikraBranchContainerState extends State<FikraBranchContainer> with SingleTickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(vsync: this, value: 1);

  @override
  void didUpdateWidget(covariant FikraBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _enter.duration = FikraMotion.reduced(context) ? FikraMotion.reducedFade : FikraMotion.enter;
      _enter.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = FikraMotion.reduced(context);
    final progress = _enter.drive(CurveTween(curve: reduced ? Curves.linear : FikraMotion.enterCurve));
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          Offstage(
            offstage: i != widget.index,
            child: TickerMode(
              enabled: i == widget.index,
              child: ExcludeFocus(
                excluding: i != widget.index,
                // Each tab paints into its own layer, so the veil above never
                // repaints the tab underneath it.
                child: RepaintBoundary(child: widget.children[i]),
              ),
            ),
          ),
        // The fade-in is a background-coloured veil that clears over the new
        // tab. On screen it is the same as fading the tab in, but it costs one
        // background paint per frame instead of an offscreen copy of the screen.
        // No scale: on GLES (e.g. Adreno 650) rescaling the tab re-rasterised
        // its text every frame and missed the 144 Hz budget on ~20% of frames.
        IgnorePointer(child: _Veil(progress: progress)),
      ],
    );
  }
}

class _Veil extends AnimatedWidget {
  const _Veil({required Animation<double> progress}) : super(listenable: progress);

  @override
  Widget build(BuildContext context) {
    final t = (listenable as Animation<double>).value;
    if (t >= 1) return const SizedBox.shrink();
    return TabVeil(
      opacity: 1 - t,
      palette: context.colors,
      // The tabs are transparent over AppShell's background, so the veil
      // paints the canvas in that box's rectangle, not its own.
      anchor: ShellBackground.maybeOf(context),
      screen: MediaQuery.sizeOf(context),
    );
  }
}

/// Paints the Pearl canvas at [opacity] in the rectangle of [anchor]'s render box
/// (mapped through any transform between the two), clipped to this box, so
/// it lines up exactly with the background [anchor] paints. Without an
/// anchor it assumes a [screen]-sized background at the view origin.
@visibleForTesting
class TabVeil extends LeafRenderObjectWidget {
  const TabVeil({super.key, required this.opacity, required this.palette, this.anchor, required this.screen});
  final double opacity;
  final FikraPalette palette;
  final GlobalKey? anchor;
  final Size screen;

  @override
  RenderTabVeil createRenderObject(BuildContext context) => RenderTabVeil(opacity, palette, anchor, screen);

  @override
  void updateRenderObject(BuildContext context, RenderTabVeil renderObject) => renderObject
    ..opacity = opacity
    ..palette = palette
    ..anchor = anchor
    ..screen = screen;
}

class RenderTabVeil extends RenderBox {
  RenderTabVeil(this._opacity, this._palette, this._anchor, this._screen);

  double _opacity;
  set opacity(double v) {
    if (v == _opacity) return;
    _opacity = v;
    markNeedsPaint();
  }

  FikraPalette _palette;
  set palette(FikraPalette v) {
    if (v == _palette) return;
    _palette = v;
    markNeedsPaint();
  }

  GlobalKey? _anchor;
  set anchor(GlobalKey? v) {
    if (v == _anchor) return;
    _anchor = v;
    markNeedsPaint();
  }

  Size _screen;
  set screen(Size v) {
    if (v == _screen) return;
    _screen = v;
    markNeedsPaint();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  bool hitTestSelf(Offset position) => false;

  /// The background's rectangle in this box's local coordinates.
  Rect _backgroundRect() {
    final anchor = _anchor?.currentContext?.findRenderObject();
    if (anchor is RenderBox && anchor.attached && anchor.hasSize) {
      final toLocal = Matrix4.tryInvert(getTransformTo(anchor));
      if (toLocal != null) return MatrixUtils.transformRect(toLocal, Offset.zero & anchor.size);
    }
    return globalToLocal(Offset.zero) & _screen;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_opacity <= 0) return;
    context.canvas.save();
    context.canvas.clipRect(offset & size);
    PearlCanvasPainter(_palette)
        .paintRect(context.canvas, _backgroundRect().shift(offset), opacity: _opacity.clamp(0, 1));
    context.canvas.restore();
  }
}
