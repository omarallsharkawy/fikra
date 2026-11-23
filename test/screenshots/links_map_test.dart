@Tags(['screenshots'])
library;

import 'package:fikra/core/widgets/glass_quality.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/links_library_fixture.dart';
import '../support/selection_fixture.dart';

void main() {
  setUpAll(loadAppFonts);
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      fikraTest(
        'Map overview, cluster, ego (${locale.languageCode}, ${brightness.name})',
        locale: locale,
        brightness: brightness,
        glassTier: GlassTier.frosted,
        tags: 'screenshots',
        (tester, db) async {
          phone(tester);
          final notes = await seedLibrary(
            tester,
            db,
            l10n: lookupAppLocalizations(locale),
            localizedContent: true,
            browse: false,
          );
          await pumpUntil(tester, find.byKey(const ValueKey('map-paint')));
          final prefix = '${locale.languageCode}/${brightness.name}';
          await saveScreenshot(tester, '$prefix/76_map_overview');
          await tapMapNode(tester, 'group:parent');
          await saveScreenshot(tester, '$prefix/77_map_cluster');
          await tapMapNode(tester, notes[0].id);
          await saveScreenshot(tester, '$prefix/78_map_ego');
          for (var i = 0; i < 17; i++) {
            final n = notes[0].copyWith(
              id: 'dense-$i',
              title: locale.languageCode == 'ar' ? 'ملاحظة مرتبطة ${i + 1}' : 'Connected note ${i + 1}',
            );
            await pumpFuture(tester, () => db.into(db.notes).insert(n));
            await insertLink(tester, db, notes[0], n, origin: i < 12 ? LinkOrigin.user : LinkOrigin.ai);
          }
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          await saveScreenshot(tester, '$prefix/79_map_dense_ego');
          tester.view.physicalSize = const Size(1080, 2400);
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await tester.pump();
          await saveScreenshot(tester, '$prefix/80_map_dense_ego_scale2');
        },
      );
    }
  }
}
