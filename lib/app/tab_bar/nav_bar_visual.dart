part of 'sliding_tab_bar.dart';

extension _NavBarVisual on _FikraNavBarState {
  Widget _buildBar(BuildContext context, double maxWidth, double w, Widget glassBacking) {
    final s = _effectiveShrink(context);
    // Quantize height to whole dp so Glass only relays out across 20 discrete
    // steps instead of every sub-pixel scroll frame, and reuse glassBacking.
    final barHeight = ui.lerpDouble(72, FikraMotion.barShrunkHeight, s)!.roundToDouble();
    final pillHeight = barHeight - 8;
    final lensHeight = barHeight + 16;
    return SizedBox(
      key: const ValueKey('floating-tab-bar'),
      // Fill the offered width. The Stack's only unpositioned child is
      // the hidden lens, so it would otherwise shrink to 0 dp and drop taps.
      width: maxWidth,
      height: barHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          glassBacking,
          if (widget.index >= 0)
            NavSelection(position: _selection, pulse: _pulse, width: w, height: pillHeight, count: widget.items.length),
          AnimatedBuilder(
            animation: Listenable.merge([_x, _pulse]),
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) => GlassLens(opacity: _pulse.value, child: const SizedBox.expand()),
            ),
            builder: (context, lens) => _pulse.value == 0
                ? const SizedBox.shrink()
                : Positioned(
                    left: 0,
                    top: -8,
                    width: w + 20,
                    height: lensHeight,
                    child: Transform.translate(
                      offset: Offset(_clampX(_x.value) - (w + 20) / 2, 0),
                      child: IgnorePointer(
                        child: ExcludeSemantics(
                          child: SizedBox(key: const ValueKey('nav-lens'), child: lens),
                        ),
                      ),
                    ),
                  ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: RepaintBoundary(
                child: Row(
                  children: [
                    for (var i = 0; i < widget.items.length; i++)
                      Expanded(
                        child: TabLabel(
                          key: ValueKey('nav-$i'),
                          label: widget.items[i].$1,
                          icon: widget.items[i].$2,
                          selected: widget.index == i,
                          position: _selection,
                          iconOnly: MediaQuery.textScalerOf(context).scale(1) >= 1.4 && w < 72,
                          enabled: widget.enabled,
                          index: i,
                          hover: _hover,
                          shrink: s,
                          onActivate: () {
                            if (!widget.enabled) return;
                            if (widget.index == i) {
                              widget.onSelect(i, true);
                            } else {
                              _choose(i);
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
