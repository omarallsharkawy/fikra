@Tags(['screenshots'])
library;

import 'package:fikra/core/theme/fikra_theme.dart';
import 'package:fikra/core/theme/tokens.dart';
import 'package:fikra/core/widgets/glass_power.dart';
import 'package:fikra/core/widgets/glass_preview.dart';
import 'package:fikra/core/widgets/glass_quality.dart';
import 'package:fikra/core/widgets/glass_watchdog.dart';
import 'package:fikra/core/widgets/pearl_canvas.dart';
import 'package:fikra/core/widgets/solid_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../glass_test_fakes.dart';
import '../support/app_harness.dart';

void main() {
  setUpAll(loadAppFonts);
  testWidgets('glass tiers side by side, Arabic light and dark', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          glassPowerSaveProvider.overrideWithValue(const AsyncData(false)),
          glassTimingsSourceProvider.overrideWithValue(FakeGlassTimings()),
        ],
        child: MaterialApp(
          theme: buildFikraTheme(Brightness.light),
          // A Material ancestor gives the gallery's text the app's default style.
          home: RepaintBoundary(
            key: appBoundaryKey,
            child: Material(
              type: MaterialType.transparency,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  children: [
                    for (final brightness in [Brightness.dark, Brightness.light])
                      Expanded(
                        child: Theme(
                          data: buildFikraTheme(brightness),
                          child: _GalleryFrame(
                            child: PearlCanvas(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: BackdropGroup(
                                  child: Row(
                                    children: [
                                      for (final tier in GlassTier.values)
                                        Expanded(
                                          child: ProviderScope(
                                            overrides: [glassTierProvider(false).overrideWith((ref) => tier)],
                                            child: _TierCell(tier, brightness),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
    });
    await saveScreenshot(tester, 'ar/glass_tiers');
  });
}

class _TierCell extends StatelessWidget {
  const _TierCell(this.tier, this.brightness);
  final GlassTier tier;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('فكرة · ${brightness.name}', style: context.text.title),
        const SizedBox(height: 20),
        SizedBox(
          height: 230,
          child: Stack(
            children: [
              Positioned.fill(
                child: SolidSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('تسعير الاشتراك', style: context.text.cardTitle),
                      const SizedBox(height: 8),
                      Text(
                        'أفكار تستاهل نرجع لها\nنبدأ بـ٩٩ جنيه في الشهر\nونجرب خصم للطلاب\nونراجع بعد أول شهر.',
                        style: context.text.body,
                      ),
                    ],
                  ),
                ),
              ),
              const Positioned(left: 0, right: 0, bottom: 20, child: GlassReviewPanel()),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(tier.name, style: context.text.body),
      ],
    ),
  );
}

/// The mockup frame shadow belongs to the review artifact, not app chrome.
class _GalleryFrame extends StatelessWidget {
  const _GalleryFrame({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: context.colors.shadow.withValues(alpha: context.colors.frameShadowAlpha),
          offset: const Offset(0, 16),
          blurRadius: 30,
        ),
      ],
    ),
    child: child,
  );
}
