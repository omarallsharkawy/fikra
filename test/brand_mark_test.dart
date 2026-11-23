import 'dart:ui' as ui;

import 'package:fikra/core/theme/fikra_theme.dart';
import 'package:fikra/core/widgets/brand_mark.dart';
import 'package:fikra/features/workspace/product_widgets.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('brand artwork loads and follows a live app-theme change without RTL mirroring', (tester) async {
    for (final mode in ['light', 'dark']) {
      await tester.runAsync(() async {
        final data = await rootBundle.load('assets/icons/fikrah-icon-$mode-mode.png');
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        expect(frame.image.width, 1024);
        expect(frame.image.height, 1024);
        frame.image.dispose();
        codec.dispose();
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFikraTheme(mode == 'dark' ? Brightness.dark : Brightness.light),
          home: const Directionality(textDirection: TextDirection.rtl, child: FikraBrandMark()),
        ),
      );
      await tester.pumpAndSettle();
      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as AssetImage).assetName, 'assets/icons/fikrah-icon-$mode-mode.png');
      expect(image.matchTextDirection, isFalse);
      expect(image.excludeFromSemantics, isTrue);
      expect(tester.takeException(), isNull);
    }
  });

  for (final locale in [const Locale('ar'), const Locale('en')]) {
    for (final brightness in Brightness.values) {
      testWidgets('branded product header fits 360dp at 2x text (${locale.languageCode}, $brightness)', (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: buildFikraTheme(brightness),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Builder(
              builder: (context) => ProductScaffold(
                title: context.l10n.productMyAccount,
                trailing: IconButton(onPressed: () {}, icon: const Icon(Icons.refresh)),
                children: const [],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(FikraBrandMark), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
