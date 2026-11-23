import 'dart:ui' as ui;

import 'package:fikra/core/theme/tokens.dart';
import 'package:fikra/features/notes/notes_screen.dart';
import 'package:fikra/features/projects/welcome_screen.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';

void main() {
  setUpAll(loadAppFonts);

  for (final locale in [const Locale('ar'), const Locale('en')]) {
    final l = lookupAppLocalizations(locale);
    fikraTest(
      'welcome primary CTA creates default project directly with no dialog and lands on Notes (${locale.languageCode})',
      locale: locale,
      (tester, db) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.reset);

        await pumpUntil(tester, find.byKey(const ValueKey('welcome-start')));
        expect(find.text(l.welcomeBrandTitle), findsWidgets);
        expect(find.text(l.welcomeTagline), findsOneWidget);
        expect(find.text(l.welcomeSubtitle), findsOneWidget);
        expect(find.text(l.welcomeFooter), findsOneWidget);

        // No auth buttons (Google, Apple, email, Log in).
        for (final forbidden in ['Google', 'Apple', 'email', 'Log in', 'جوجل', 'أبل', 'إيميل']) {
          expect(find.textContaining(forbidden), findsNothing);
        }

        await tester.tap(find.byKey(const ValueKey('welcome-start')));
        await pumpUntil(tester, find.byType(NotesScreen));
        expect(find.byType(BottomSheet), findsNothing);
        expect(find.byType(Dialog), findsNothing);
        expect(find.text(l.defaultProjectName), findsOneWidget);
        final projects = await pumpFuture(tester, () => db.select(db.projects).get());
        expect(projects.map((p) => p.name), [l.defaultProjectName]);
      },
    );
  }

  fikraTest('welcome secondary CTA seeds the sample project and opens Notes', (tester, db) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    final l = lookupAppLocalizations(const Locale('ar'));
    await pumpUntil(tester, find.byKey(const ValueKey('welcome-sample')));
    await tester.tap(find.byKey(const ValueKey('welcome-sample')));
    await pumpUntil(tester, find.text(l.sample7Title));
    expect(find.byType(NotesScreen), findsOneWidget);
    expect(find.text(l.sampleProjectName), findsOneWidget);
  });

  testWidgets('welcome hero painter mirrors horizontally between LTR and RTL', (tester) async {
    Future<List<int>> renderPixels(TextDirection direction) async {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(200, 120);
      canvas.drawRect(Offset.zero & size, Paint()..color = FikraPalette.dark.canvas);
      WelcomeHeroPainter(colors: FikraPalette.dark, textDirection: direction).paint(canvas, size);
      final picture = recorder.endRecording();
      final image = await picture.toImage(size.width.toInt(), size.height.toInt());
      final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      image.dispose();
      picture.dispose();
      return data.buffer.asUint8List();
    }

    final ltr = await tester.runAsync(() => renderPixels(TextDirection.ltr));
    final rtl = await tester.runAsync(() => renderPixels(TextDirection.rtl));
    const width = 200;
    Color pixelAt(List<int> bytes, int x, int y) {
      final i = (y * width + x) * 4;
      return Color.fromARGB(bytes[i + 3], bytes[i], bytes[i + 1], bytes[i + 2]);
    }

    // Check interior centers of all three hero shapes mirror horizontally across LTR <-> RTL.
    // LTR: lime on left (x≈8, y≈77), purple top-right (x≈172, y≈17), blue lower-right (x≈144, y≈67).
    for (final (x, y, expected) in [
      (8, 77, FikraPalette.dark.brandLime),
      (172, 17, FikraPalette.dark.brandPurple),
      (144, 67, FikraPalette.dark.brandBlue),
    ]) {
      expect(pixelAt(ltr!, x, y), expected);
      expect(pixelAt(rtl!, width - 1 - x, y), expected);
    }
  });

  for (final locale in [const Locale('ar'), const Locale('en')]) {
    fikraTest(
      'welcome handles 2.0x large text on 360 dp width without overflow and scrolls cleanly (${locale.languageCode})',
      locale: locale,
      textScale: 2.0,
      (tester, db) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(360, 640);
        addTearDown(tester.view.reset);

        await pumpUntil(tester, find.byKey(const ValueKey('welcome-start')));
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);

        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('welcome-sample')),
          120,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('welcome-sample')), findsOneWidget);
      },
    );
  }

  fikraTest('welcome skips entrance animation under Reduce Motion', (tester, db) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await pumpUntil(tester, find.byKey(const ValueKey('welcome-start')));
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
  });
}
