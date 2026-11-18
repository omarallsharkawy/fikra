import 'dart:math' as math;

import 'package:fikra/core/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Spec: composite in sRGB, ROUND TO 8-BIT, then WCAG 2 luminance.
Color composite(Color fg, Color bg, double alpha) => Color.fromARGB(
  255,
  ((fg.r * alpha + bg.r * (1 - alpha)) * 255).round(),
  ((fg.g * alpha + bg.g * (1 - alpha)) * 255).round(),
  ((fg.b * alpha + bg.b * (1 - alpha)) * 255).round(),
);

double luminance(Color c) {
  double linear(double channel) =>
      channel <= .04045 ? channel / 12.92 : math.pow((channel + .055) / 1.055, 2.4).toDouble();
  return .2126 * linear(c.r) + .7152 * linear(c.g) + .0722 * linear(c.b);
}

double contrast(Color a, Color b) {
  final x = luminance(a), y = luminance(b);
  return (math.max(x, y) + .05) / (math.min(x, y) + .05);
}

void main() {
  test('Pearl gradients retain their CSS angle on a wide capsule', () {
    const rect = Rect.fromLTWH(0, 0, 320, 76);
    for (final angle in [125.0, 135.0, 145.0]) {
      final matrix = PearlGradientAngle(angle).transform(rect);
      final start = MatrixUtils.transformPoint(matrix, rect.centerLeft);
      final end = MatrixUtils.transformPoint(matrix, rect.centerRight);
      final delta = end - start;
      expect(math.atan2(delta.dx, -delta.dy) * 180 / math.pi, closeTo(angle, 1e-8));
      expect((((start + end) / 2) - rect.center).distance, closeTo(0, 1e-8));
    }
  });
  test('WCAG reference and 90% composite rounding match the spec', () {
    expect(contrast(Colors.black, Colors.white), 21);
    expect(composite(FikraPalette.light.surface, Colors.black, .90), const Color(0xffe5e5e3));
    expect(composite(FikraPalette.dark.surface, Colors.white, .90), const Color(0xff42494e));
  });
  for (final (name, c) in [('light', FikraPalette.light), ('dark', FikraPalette.dark)]) {
    test('Pearl $name: every text-bearing surface passes normal text AA', () {
      void check(String pair, Color text, Color bg) =>
          expect(contrast(text, bg), greaterThanOrEqualTo(4.5), reason: '$name $pair');
      for (final (surface, bg) in [
        ('surface', c.surface),
        ('chip', c.chip),
        ('selected', c.selected),
        ('canvas', c.canvas),
        ('dangerBg', c.dangerBg),
        ('successBg', c.successBg),
        ('warningBg', c.warningBg),
      ]) {
        check('body/$surface', c.textPrimary, bg);
        check('secondary/$surface', c.textSecondary, bg);
      }
      for (final bg in [c.surface, c.chip, c.selected, c.canvas]) {
        check('accent/solid', c.accent, bg);
      }
      check('on-accent/accent', c.onAccent, c.accent);
      check('on-accent/add-top', c.onAccent, c.addTop);
      for (var i = 0; i <= 1000; i++) {
        final color = Color.lerp(c.addTop, c.accent, i / 1000)!;
        // Color.lerp returns float channels; round as the contrast method requires.
        check('Add gradient sample $i', c.onAccent, composite(color, Colors.black, 1));
      }
      for (final backdrop in [Colors.black, Colors.white]) {
        final bg = composite(c.surface, backdrop, FikraPalette.glassBackingAlpha);
        check('body/glass', c.textPrimary, bg);
        check('secondary/glass', c.textSecondary, bg);
        check('accent/glass', c.accent, bg);
      }
      for (final (status, bg) in [(c.danger, c.dangerBg), (c.success, c.successBg), (c.warning, c.warningBg)]) {
        check('status/surface', status, c.surface);
        check('status/canvas', status, c.canvas);
        check('status/own background', status, bg);
      }
      // Conservative bound for simultaneous maximum blooms, regardless of geometry.
      final bloom = composite(c.bloomCool, composite(c.bloomWarm, c.canvas, c.bloomWarmAlpha), c.bloomCoolAlpha);
      check('body/blooms', c.textPrimary, bloom);
      check('secondary/blooms', c.textSecondary, bloom);
    });
    test('Pearl $name: group markers pass 3:1 non-text contrast on surface and canvas', () {
      for (final (group, marker) in [
        ('blue', c.groupBlue),
        ('sage', c.groupSage),
        ('sand', c.groupSand),
        ('gray', c.groupGray),
      ]) {
        for (final (fill, bg) in [('surface', c.surface), ('canvas', c.canvas)]) {
          expect(contrast(marker, bg), greaterThanOrEqualTo(3), reason: '$name $group/$fill');
        }
      }
    });
    test('Pearl $name: glass sheet and toast text and icons pass WCAG AA across every tier and backdrop', () {
      final bloom = composite(c.bloomCool, composite(c.bloomWarm, c.canvas, c.bloomWarmAlpha), c.bloomCoolAlpha);
      final toastBackdrops = [
        ('solid', c.surface),
        for (final (label, under) in [
          ('black', Colors.black),
          ('white', Colors.white),
          ('canvas', c.canvas),
          ('bloom', bloom),
        ])
          ('frosted/$label', composite(c.surface, under, FikraPalette.glassBackingAlpha)),
      ];
      for (final (tierBg, bg) in toastBackdrops) {
        for (final (role, fg) in [
          ('toast/sheet body', c.textPrimary),
          ('sheet secondary', c.textSecondary),
          ('toast undo action', c.accent),
        ]) {
          expect(contrast(fg, bg), greaterThanOrEqualTo(4.5), reason: '$name $role on $tierBg');
        }
        for (final (iconRole, fg) in [
          ('primary icon', c.textPrimary),
          ('secondary icon', c.textSecondary),
          ('accent icon', c.accent),
          ('danger icon', c.danger),
        ]) {
          expect(contrast(fg, bg), greaterThanOrEqualTo(3.0), reason: '$name $iconRole on $tierBg');
        }
      }
      // Modal sheets sit above the barrier scrim, and SheetOption danger rows sit on opaque surface.
      for (final under in [Colors.black, Colors.white, c.canvas, bloom]) {
        final scrimmed = composite(const Color(0xFF000000), under, c.scrim.a);
        final sheetBg = composite(c.surface, scrimmed, FikraPalette.glassBackingAlpha);
        expect(contrast(c.textPrimary, sheetBg), greaterThanOrEqualTo(4.5), reason: '$name sheet title on scrimmed');
        expect(contrast(c.textSecondary, sheetBg), greaterThanOrEqualTo(4.5), reason: '$name sheet meta on scrimmed');
      }
      expect(contrast(c.danger, c.surface), greaterThanOrEqualTo(4.5), reason: '$name danger option on SolidSurface');
    });
  }
}
