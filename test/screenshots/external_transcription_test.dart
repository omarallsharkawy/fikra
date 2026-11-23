@Tags(['screenshots'])
library;

import 'dart:async';

import 'package:fikra/data/transcription/service_config.dart';
import 'package:fikra/data/transcription/services_repository.dart';
import 'package:fikra/features/settings/settings_screen.dart';
import 'package:fikra/features/voice_text/service_form_screen.dart';
import 'package:fikra/features/voice_text/voice_text_screen.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/app_harness.dart';
import '../support/external_service_fixture.dart';
import '../support/fake_external_transcription.dart';
import '../support/transcription_scroll.dart';
import '../voice_text/fake_voice_text_backend.dart';

void main() {
  setUpAll(loadAppFonts);
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    for (final brightness in [Brightness.dark, Brightness.light]) {
      final backend = FakeVoiceTextBackend();
      final keys = MemoryServiceKeys();
      fikraTest(
        'external transcription (${locale.languageCode}, ${brightness.name})',
        tags: 'screenshots',
        locale: locale,
        brightness: brightness,
        voiceTextBackend: backend,
        serviceKeys: keys,
        (tester, db) async {
          addTearDown(() => unawaited(backend.dispose()));
          await seedExternalProject(tester, db, locale);
          tester.view.devicePixelRatio = 3;
          tester.view.physicalSize = const Size(390 * 3, 844 * 3);
          tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
          tester.view.viewPadding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
          final l = lookupAppLocalizations(locale);
          Future<void> capture(String name) async {
            await tester.pump(const Duration(milliseconds: 600));
            expect(tester.takeException(), isNull);
            await saveScreenshot(tester, '${locale.languageCode}/${brightness.name}/external_$name');
          }

          final repo = LocalTranscriptionServices(db, keys);
          final services = [
            for (final type in TranscriptionServiceType.values)
              sampleService(
                id: type.name,
                type: type,
                name: switch (type) {
                  TranscriptionServiceType.openAi => 'OpenAI',
                  TranscriptionServiceType.gemini => l.vsGemini,
                  TranscriptionServiceType.elevenLabs => l.vsElevenLabs,
                  TranscriptionServiceType.qwen => l.vsQwen,
                },
              ),
          ];
          await pumpFuture(tester, () async {
            for (final s in services) {
              await repo.save(s, key: 'screenshot-key');
            }
          });
          await openExternalSettings(tester);
          await capture('engines');
          for (final s in services) {
            final edit = ValueKey('vs-edit-${s.id}');
            await revealTranscription(tester, VoiceTextScreen, edit);
            await tester.tap(find.byKey(edit));
            await pumpUntil(tester, find.byType(ServiceFormScreen));
            await capture('form_${s.type.name}_top');
            await serviceField(tester, 'vs-key', 'screenshot-key');
            await revealTranscription(tester, ServiceFormScreen, const ValueKey('vs-key'));
            await capture('form_${s.type.name}_key');
            tester.element(find.byType(ServiceFormScreen)).pop();
            await tester.pump(const Duration(milliseconds: 600));
          }
          await tapEngine(tester, services[0].id);
          await capture('consent');
          await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text(l.vsConsentConfirm)));
          await pumpFuture(tester, () async {
            while ((await repo.read()).selected != services[0].engineId) {
              await Future<void>.delayed(const Duration(milliseconds: 10));
            }
          });
          tester.element(find.byType(VoiceTextScreen)).pop();
          await tester.pump(const Duration(milliseconds: 600));
          tester.element(find.text(externalProject)).push('/settings');
          await pumpUntil(tester, find.byType(SettingsScreen));
          await revealTranscription(tester, SettingsScreen, const ValueKey('settings-data-location'));
          await capture('settings_data');
        },
      );
    }
  }
}
