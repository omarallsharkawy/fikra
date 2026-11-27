import 'package:fikra/app/tab_bar/product_navigation.dart';
import 'package:fikra/core/theme/product_theme.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart' show loadAppFonts;

void main() {
  setUpAll(loadAppFonts);
  for (final language in ['ar', 'en']) {
    for (final reduced in [false, true]) {
      testWidgets('glass navigation mirrors and preserves actions ($language, reduced=$reduced)', (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        int branch = 1;
        final selected = <int>[];
        await tester.pumpWidget(
          MaterialApp(
            theme: buildProductTheme(Brightness.dark),
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (c) => MediaQuery(
                data: MediaQuery.of(c).copyWith(disableAnimations: reduced, textScaler: TextScaler.linear(2)),
                child: Scaffold(
                  body: StatefulBuilder(
                    builder: (c, set) => Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: ProductNavigation(
                          branch: branch,
                          onSelect: (id, reselect) {
                            selected.add(id);
                            set(() => branch = id);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final home = find.byKey(const ValueKey('nav-0')), map = find.byKey(const ValueKey('nav-1'));
        expect(tester.getSize(home).height, greaterThanOrEqualTo(44));
        expect(tester.getSize(map).width, greaterThanOrEqualTo(44));
        expect(
          tester.getCenter(home).dx,
          language == 'ar' ? greaterThan(tester.getCenter(map).dx) : lessThan(tester.getCenter(map).dx),
        );
        final before = tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned)).left!;
        await tester.tap(map);
        await tester.pumpAndSettle();
        final after = tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned));
        expect(after.left, language == 'ar' ? lessThan(before) : greaterThan(before));
        expect(after.duration, reduced ? Duration.zero : const Duration(milliseconds: 320));
        await tester.tap(find.byKey(const ValueKey('nav-add')));
        await tester.pumpAndSettle();
        expect(selected, [2, 0]);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
