import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:go_router/go_router.dart';

import '../core/motion/motion.dart';
import '../core/motion/pressable.dart';
import '../core/theme/tokens.dart';
import '../core/widgets/pearl_canvas.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  /// The box that paints the Pearl canvas behind every tab. The tab veil
  /// aligns the same static paint to it.
  final _background = GlobalKey(debugLabel: 'shell background');

  List<(String, IconData)> _tabs(BuildContext context) => [
    (context.l10n.navAdd, Icons.add_circle_outline_rounded),
    (context.l10n.navNotes, Icons.sticky_note_2_outlined),
    (context.l10n.navLinks, Icons.hub_outlined),
    (context.l10n.navAsk, Icons.chat_bubble_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final shell = widget.shell;
    return ShellBackground(
      anchor: _background,
      child: PearlCanvas(
        key: _background,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: true,
          body: SafeArea(bottom: false, child: shell),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: FikraNavBar(
                items: _tabs(context),
                index: shell.currentIndex,
                onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
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

/// Glass pill nav. The selected pill slides with the smooth spring.
class FikraNavBar extends StatefulWidget {
  const FikraNavBar({super.key, required this.items, required this.index, required this.onTap});
  final List<(String, IconData)> items;
  final int index;
  final ValueChanged<int> onTap;

  @override
  State<FikraNavBar> createState() => _FikraNavBarState();
}

class _FikraNavBarState extends State<FikraNavBar> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(vsync: this, value: widget.index.toDouble());

  @override
  void didUpdateWidget(covariant FikraNavBar old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
        _c.value = widget.index.toDouble();
      } else {
        _c.animateWith(SpringSimulation(FikraSprings.smooth, _c.value, widget.index.toDouble(), _c.velocity));
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Container(
      height: FikraSpace.nav,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(FikraRadius.full),
        border: Border.all(color: context.colors.line, width: FikraSpace.hairline),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth / widget.items.length;
          // Label colors follow the sliding pill, never light-on-light mid-slide.
          Color fg(int i) => Color.lerp(
            context.colors.textSecondary,
            context.colors.accent,
            (1 - (_c.value - i).abs()).clamp(0.0, 1.0),
          )!;
          return Stack(
            children: [
              AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  final x = _c.value * w;
                  return Positioned(
                    top: 0,
                    bottom: 0,
                    width: w,
                    left: rtl ? null : x,
                    right: rtl ? x : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.colors.selected,
                        borderRadius: BorderRadius.circular(FikraRadius.full),
                      ),
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: _c,
                builder: (context, _) => Row(
                  children: [
                    for (var i = 0; i < widget.items.length; i++)
                      Expanded(
                        child: Pressable(
                          key: ValueKey('nav-$i'),
                          selected: i == widget.index,
                          onTap: () => widget.onTap(i),
                          semanticLabel: widget.items[i].$1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(widget.items[i].$2, size: 22, color: fg(i)),
                              const SizedBox(height: 2),
                              Text(
                                widget.items[i].$1,
                                style: context.text.nav.copyWith(
                                  height: 1.2,
                                  color: fg(i),
                                  fontWeight: i == widget.index ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
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
