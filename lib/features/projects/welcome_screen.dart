import 'dart:math' as math;

import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/motion/motion.dart';
import '../../core/motion/pressable.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/demo/demo_seed.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> with SingleTickerProviderStateMixin {
  bool _creating = false;
  bool _seeding = false;
  bool _startedEnter = false;
  late final AnimationController _enter = AnimationController.unbounded(vsync: this, value: 0);

  static const _springTolerance = Tolerance(distance: 0.005, velocity: 0.05);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = FikraMotion.reduced(context);
    if (reduced) {
      _startedEnter = true;
      if (_enter.isAnimating) _enter.stop();
      _enter.value = 1;
      return;
    }
    if (!_startedEnter) {
      _startedEnter = true;
      _enter.animateWith(SpringSimulation(FikraSprings.smooth, 0, 1, 0, tolerance: _springTolerance));
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  Future<void> _startWriting() async {
    if (_creating || _seeding) return;
    setState(() => _creating = true);
    try {
      await runAction(
        context,
        () => ref.read(projectsRepoProvider).create(context.l10n.defaultProjectName),
        failure: context.l10n.createProjectFailed,
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _seed() async {
    if (_seeding || _creating) return;
    setState(() => _seeding = true);
    try {
      await runAction(
        context,
        () => seedDemoProject(
          ref.read(projectsRepoProvider),
          ref.read(notesRepoProvider),
          locale: ref.read(appLocaleProvider),
          clock: ref.read(appClockProvider),
        ),
        failure: context.l10n.sampleProjectFailed,
      );
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  Widget _stagger(double begin, double end, Widget child) {
    final reduced = FikraMotion.reduced(context);
    if (reduced) return child;
    return AnimatedBuilder(
      animation: _enter,
      child: child,
      builder: (context, child) {
        final raw = _enter.value.clamp(0.0, 1.0);
        final t = ((raw - begin) / (end - begin)).clamp(0.0, 1.0);
        final scale = 0.95 + 0.05 * t;
        return Opacity(
          opacity: t,
          child: Transform.scale(scale: scale, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final direction = Directionality.of(context);
    final busy = _creating || _seeding;

    return FikraScaffold(
      child: LayoutBuilder(
        builder: (context, box) {
          final heroHeight = (box.maxHeight * 0.36).clamp(180.0, 320.0);
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _stagger(
                      0.0,
                      0.75,
                      SizedBox(
                        height: heroHeight,
                        width: double.infinity,
                        child: ExcludeSemantics(
                          child: ClipRect(
                            child: CustomPaint(
                              key: const ValueKey('welcome-hero'),
                              painter: WelcomeHeroPainter(colors: c, textDirection: direction),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: FikraSpace.screen),
                      child: _stagger(
                        0.15,
                        0.9,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.welcomeEyebrow,
                              style: context.text.section.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: c.brandLimeFg,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Semantics(
                              header: true,
                              child: Text(
                                l10n.welcomeBrandTitle,
                                style: context.text.title.copyWith(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  height: 1.12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.welcomeTagline,
                              style: context.text.title.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(l10n.welcomeSubtitle, style: context.text.body.copyWith(color: c.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(FikraSpace.screen, 28, FikraSpace.screen, 16),
                      child: _stagger(
                        0.3,
                        1.0,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FikraButton(
                              key: const ValueKey('welcome-start'),
                              label: l10n.welcomeStartWriting,
                              growForText: true,
                              loading: _creating,
                              onPressed: busy ? null : _startWriting,
                            ),
                            const SizedBox(height: 12),
                            FikraButton.secondary(
                              key: const ValueKey('welcome-sample'),
                              label: l10n.welcomeTrySample,
                              growForText: true,
                              loading: _seeding,
                              onPressed: busy ? null : _seed,
                            ),
                            const SizedBox(height: 16),
                            Text(l10n.welcomeFooter, textAlign: TextAlign.center, style: context.text.meta),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Bold geometric hero painted on the welcome canvas. Mirrors horizontally for RTL
/// so the lime circle always bleeds off the reading-start edge and the purple/blue
/// composition anchors at the top-end corner.
@visibleForTesting
class WelcomeHeroPainter extends CustomPainter {
  const WelcomeHeroPainter({required this.colors, required this.textDirection});

  final FikraPalette colors;
  final TextDirection textDirection;

  bool get isMirrored => textDirection == TextDirection.rtl;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    if (isMirrored) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }

    final w = size.width;
    final h = size.height;

    // 1. Purple circle bleeding off the top-end corner.
    final purpleRadius = math.min(w * 0.40, h * 0.58);
    final purpleCenter = Offset(w * 0.86, h * 0.14);
    canvas.drawCircle(purpleCenter, purpleRadius, Paint()..color = colors.brandPurple);

    // 2. Blue rounded square overlapping the lower-start edge of the purple circle.
    final squareSize = math.min(w * 0.40, h * 0.56);
    final squareCenter = Offset(w * 0.72, h * 0.56);
    canvas.save();
    canvas.translate(squareCenter.dx, squareCenter.dy);
    canvas.rotate(16 * math.pi / 180);
    final rect = Rect.fromCenter(center: Offset.zero, width: squareSize, height: squareSize);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(squareSize * 0.24)),
      Paint()..color = colors.brandBlue,
    );
    canvas.restore();

    // 3. Big lime circle bleeding off the start edge above the brand mark.
    final limeRadius = math.min(w * 0.27, h * 0.42);
    final limeCenter = Offset(w * 0.04, h * 0.64);
    canvas.drawCircle(limeCenter, limeRadius, Paint()..color = colors.brandLime);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WelcomeHeroPainter old) => old.colors != colors || old.textDirection != textDirection;
}
