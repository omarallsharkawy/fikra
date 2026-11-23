// flutter test test/screenshots/phase8_finishing_test.dart --run-skipped -t screenshots
@Tags(['screenshots'])
library;

import 'package:fikra/core/motion/pressable.dart';
import 'package:fikra/core/widgets/fikra_widgets.dart';
import 'package:fikra/features/notes/notes_screen.dart';
import 'package:fikra/features/projects/project_header.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y_fixture.dart';
import '../support/app_harness.dart';
import '../support/fake_external_transcription.dart';
import '../voice_text/fake_voice_text_backend.dart';

void main() {
  setUpAll(loadAppFonts);

  // 1. Main screens (and sheets) at text scale 2.0 in Arabic & English (light).
  for (final code in ['ar', 'en']) {
    final locale = Locale(code);
    final serviceKeys = MemoryServiceKeys();
    final voiceBackend = FakeVoiceTextBackend()
      ..arabic = (code == 'ar')
      ..seed();

    fikraTest(
      'phase 8 large-text 2.0x screenshots ($code, light)',
      locale: locale,
      brightness: Brightness.light,
      glassTier: GlassTier.frosted,
      textScale: 2.0,
      serviceKeys: serviceKeys,
      voiceTextBackend: voiceBackend,
      clock: () => DateTime(2026, 11, 10, 12),
      tags: 'screenshots',
      (tester, db) async {
        tester.view.devicePixelRatio = 3;
        tester.view.physicalSize = const Size(360 * 3, 800 * 3);
        tester.view.padding = const FakeViewPadding(top: 24 * 3, bottom: 16 * 3);
        tester.view.viewPadding = const FakeViewPadding(top: 24 * 3, bottom: 16 * 3);
        addTearDown(tester.view.reset);

        final data = await seedA11yApp(tester, db, locale: locale, serviceKeys: serviceKeys);
        await visitAllMainScreensAndSheets(
          tester,
          data,
          locale: locale,
          onScreen: (screenName) => saveScreenshot(tester, '$code/light/phase8_scale2_$screenName'),
        );
      },
    );
  }

  // 2. Frosted glass sheet and frosted glass toast in Arabic & English, light & dark.
  for (final code in ['ar', 'en']) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      final locale = Locale(code);
      final serviceKeys = MemoryServiceKeys();
      final voiceBackend = FakeVoiceTextBackend()
        ..arabic = (code == 'ar')
        ..seed();

      fikraTest(
        'phase 8 frosted glass sheet and toast screenshots ($code, ${brightness.name})',
        locale: locale,
        brightness: brightness,
        glassTier: GlassTier.frosted,
        serviceKeys: serviceKeys,
        voiceTextBackend: voiceBackend,
        clock: () => DateTime(2026, 11, 10, 12),
        tags: 'screenshots',
        (tester, db) async {
          tester.view.devicePixelRatio = 3;
          tester.view.physicalSize = const Size(390 * 3, 844 * 3);
          tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
          tester.view.viewPadding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
          addTearDown(tester.view.reset);

          final l = lookupAppLocalizations(locale);
          final data = await seedA11yApp(tester, db, locale: locale, serviceKeys: serviceKeys);
          final prefix = '$code/${brightness.name}';

          // Glass sheet (projects switcher over populated notes list).
          final projectPill = find.descendant(
            of: find.descendant(of: find.byType(NotesScreen), matching: find.byType(ProjectHeader)),
            matching: find.byWidgetPredicate(
              (w) => w is Pressable && w.semanticLabel == l.projectPillA11y(data.project.name),
            ),
          );
          await tester.tap(projectPill);
          await tester.pump();
          await saveScreenshot(tester, '$prefix/phase8_glass_sheet');
          Navigator.of(tester.element(find.byType(BottomSheet))).pop();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          // Glass toast capsule with Undo action floating above the frosted tab bar and Add button.
          final ctx = tester.element(find.byType(NotesScreen));
          showMessengerToast(ScaffoldMessenger.of(ctx), l.notesLinked(2), actionLabel: l.undo, onAction: () {});
          await tester.pump();
          await saveScreenshot(tester, '$prefix/phase8_glass_toast');
        },
      );
    }
  }
}
