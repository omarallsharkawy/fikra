@Tags(['screenshots'])
library;

import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../project_header_test.dart' show pumpProjectHeaders, tabHeaders, expectHeaderLayout;
import '../support/app_harness.dart';

void main() {
  setUpAll(loadAppFonts);

  for (final language in ['ar', 'en']) {
    testWidgets('tab header layouts ($language)', (tester) async {
      addTearDown(tester.view.reset);
      final locale = Locale(language);
      final l10n = lookupAppLocalizations(locale);
      final headers = tabHeaders(l10n);
      for (final width in [320.0, 390.0]) {
        for (final scale in [1.0, 1.3]) {
          await pumpProjectHeaders(tester, locale: locale, headers: headers, width: width, scale: scale);
          for (final header in headers) {
            expectHeaderLayout(tester, header, l10n, width, scale);
          }
          await saveScreenshot(tester, 'headers/$language/${width.toInt()}_scale_$scale');
        }
      }
    });

    testWidgets('notes header light ($language)', (tester) async {
      addTearDown(tester.view.reset);
      final locale = Locale(language);
      final l10n = lookupAppLocalizations(locale);
      final header = (title: l10n.notesTitle, action: false);
      await pumpProjectHeaders(
        tester,
        locale: locale,
        brightness: Brightness.light,
        headers: [header],
        width: 390,
        height: 180,
        scale: 1.0,
      );
      expectHeaderLayout(tester, header, l10n, 390, 1.0);
      await saveScreenshot(tester, 'headers/$language/notes_light');
    });
  }
}
