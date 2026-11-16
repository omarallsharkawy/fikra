import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/data/transcription/service_config.dart';
import 'package:fikra/features/voice_text/service_form_screen.dart';
import 'package:fikra/features/voice_text/voice_text_screen.dart';
import 'package:fikra/features/voice_text/voice_text_engines.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'app_harness.dart';
import 'transcription_scroll.dart';

const externalProject = 'External project';
Future<void> seedExternalProject(WidgetTester tester, FikraDatabase db, Locale locale) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await pumpUntil(tester, find.text(lookupAppLocalizations(locale).startNewProject));
  await pumpFuture(tester, () => LocalProjectsRepository(db).create(externalProject));
  await pumpUntil(tester, find.text(externalProject));
}

Future<void> openExternalSettings(WidgetTester tester) async {
  tester.element(find.text(externalProject)).push('/settings/voice-text');
  await pumpUntil(tester, find.byWidgetPredicate((w) => w is VoiceTextEngines && w.enabled));
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> tapEngine(WidgetTester tester, String id) async {
  final key = ValueKey('vs-engine-$id');
  await revealTranscription(tester, VoiceTextScreen, key);
  await tester.tap(find.byKey(key));
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> serviceFormAction(WidgetTester tester, String key) async {
  await revealTranscription(tester, ServiceFormScreen, ValueKey(key));
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> serviceField(WidgetTester tester, String key, String value) async {
  await revealTranscription(tester, ServiceFormScreen, ValueKey(key));
  await tester.enterText(find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(TextField)), value);
  tester.testTextInput.hide();
  await tester.pump();
}

Future<void> serviceType(WidgetTester tester, TranscriptionServiceType type) async {
  await serviceFormAction(tester, 'vs-type');
  // The sheet's slide starts on the first frame after the tap; let it land.
  await tester.pump(const Duration(milliseconds: 600));
  await tester.tap(find.byKey(ValueKey('vs-type-${type.name}')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}
