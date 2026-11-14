@Tags(['screenshots'])
library;

import 'package:fikra/core/motion/pressable.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/features/settings/settings_screen.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/app_harness.dart';
import '../voice_text/fake_voice_text_backend.dart';
import '../voice_text/voice_text_fixture.dart';

void main() {
  setUpAll(loadAppFonts);
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    for (final brightness in [Brightness.dark, Brightness.light]) {
      for (final egyptian in [false, true]) {
        final fake = FakeVoiceTextBackend()
          ..arabic = locale.languageCode == 'ar'
          ..egyptianFilePresent = egyptian;
        fikraTest(
          'voice to text phase 1 (${locale.languageCode}, ${brightness.name}, Egyptian $egyptian)',
          tags: 'screenshots',
          locale: locale,
          brightness: brightness,
          voiceTextBackend: fake,
          (tester, db) async {
            tester.view.devicePixelRatio = 3;
            tester.view.physicalSize = const Size(390 * 3, 844 * 3);
            tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
            tester.view.viewPadding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
            addTearDown(tester.view.reset);
            final l = lookupAppLocalizations(locale);
            Future<void> frames() async {
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 600));
              await tester.pump();
            }

            Future<void> capture(String name) async {
              await frames();
              expect(tester.takeException(), isNull);
              await saveScreenshot(
                tester,
                '${locale.languageCode}/${brightness.name}/voice_text_${egyptian ? 'egyptian' : 'default'}_$name',
              );
            }

            await pumpUntil(tester, find.text(l.startNewProject));
            await pumpFuture(tester, () => LocalProjectsRepository(db).create('Whisper'));
            await pumpUntil(tester, find.text('Whisper'));
            tester.element(find.text('Whisper').first).push('/settings');
            await pumpUntil(tester, find.byKey(const ValueKey('settings-voice-text')));
            await revealVoiceText(
              tester,
              'settings-voice-text',
              scrollable: find.descendant(of: find.byType(SettingsScreen), matching: find.byType(Scrollable)),
            );
            await capture('settings');
            await tester.tap(find.byKey(const ValueKey('settings-voice-text')));
            // Inventory plus stored preferences must finish before the capture.
            await pumpUntil(
              tester,
              find.byWidgetPredicate(
                (w) => w is Pressable && w.key == const ValueKey('vt-model-tiny-q5_1') && w.onTap != null,
              ),
            );
            tester.state<ScrollableState>(voiceTextScrollable()).position.jumpTo(0);
            await capture('models');
            await revealVoiceText(tester, 'vt-model-base-q5_1');
            await capture('model_list_lower');
            if (!egyptian) {
              await tapVoiceText(tester, 'vt-download-tiny-q5_1');
              await capture('download_confirmation');
              await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text(l.vtDownloadConfirm)));
              await pumpUntil(tester, find.byKey(const ValueKey('vt-delete-tiny-q5_1')));
            }
            await tapVoiceText(tester, 'vt-record');
            fake.amplitudes.add(-16);
            await tester.pump(const Duration(seconds: 2));
            await capture('recording');
            await tapVoiceText(tester, 'vt-stop');
            await tapVoiceText(tester, 'vt-try-transcribe');
            await revealVoiceText(tester, 'vt-last-result');
            await capture('try_result');
            await expandVoiceTextTesting(tester);
            await revealVoiceText(tester, 'vt-testing-toggle');
            await capture('testing_expanded');
            await revealVoiceText(tester, 'vt-run-0');
            await capture('numbers');
          },
        );
      }
    }
  }
}
