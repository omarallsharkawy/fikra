@Tags(['screenshots'])
library;

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
      final fake = FakeVoiceTextBackend()..arabic = locale.languageCode == 'ar';
      fikraTest(
        'voice to text (${locale.languageCode}, ${brightness.name})',
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
            await saveScreenshot(tester, '${locale.languageCode}/${brightness.name}/voice_text_$name');
          }

          await pumpUntil(tester, find.text(l.startNewProject));
          await pumpFuture(tester, () => LocalProjectsRepository(db).create('Whisper'));
          await pumpUntil(tester, find.text('Whisper'));
          tester.element(find.text('Whisper').first).push('/settings');
          await pumpUntil(tester, find.byKey(const ValueKey('settings-voice-text')));
          await capture('settings');
          await revealVoiceText(
            tester,
            'settings-voice-text',
            scrollable: find.descendant(of: find.byType(SettingsScreen), matching: find.byType(Scrollable)),
          );

          await tester.tap(find.byKey(const ValueKey('settings-voice-text')));
          await pumpUntil(tester, find.byKey(const ValueKey('vt-model-picker')));
          await capture('empty');
          await tapVoiceText(tester, 'vt-model-picker');
          await capture('model_picker');
          Navigator.of(tester.element(find.byType(BottomSheet))).pop();
          await frames();
          await tapVoiceText(tester, 'vt-download');
          await capture('download_confirmation');
          await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text(l.vtDownloadConfirm)));
          await frames();
          await tapVoiceText(tester, 'vt-record');
          fake.amplitudes.add(-16);
          await tester.pump(const Duration(seconds: 2));
          await capture('recording');
          await tapVoiceText(tester, 'vt-stop');
          await tapVoiceText(tester, 'vt-transcribe');
          await revealVoiceText(tester, 'vt-result-card');
          await capture('result');
        },
      );
    }
  }
}
