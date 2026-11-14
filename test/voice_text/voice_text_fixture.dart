import 'dart:async';

import 'package:fikra/app/providers.dart';
import 'package:fikra/core/theme/fikra_theme.dart';
import 'package:fikra/features/voice_text/voice_text_providers.dart';
import 'package:fikra/features/voice_text/voice_text_screen.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import 'fake_voice_text_backend.dart';

Future<void> pumpVoiceText(
  WidgetTester tester,
  FakeVoiceTextBackend backend, {
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.dark,
  double width = 390,
  double scale = 1,
  FakeVoiceTextSettings? settings,
}) async {
  addTearDown(() {
    unawaited(backend.dispose());
  });
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 844);
  await tester.pumpWidget(
    RepaintBoundary(
      key: appBoundaryKey,
      child: ProviderScope(
        key: ObjectKey(backend),
        overrides: [
          voiceTextBackendProvider.overrideWithValue(backend),
          voiceTextSettingsProvider.overrideWithValue(settings ?? FakeVoiceTextSettings()),
          appThemeProvider.overrideWith((_) => Stream.value(AppTheme.dark)),
          appLanguageProvider.overrideWith((_) => Stream.value(AppLanguage.en)),
        ],
        child: MaterialApp(
          locale: locale,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildFikraTheme(brightness),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
            child: child!,
          ),
          home: const VoiceTextScreen(),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

/// Select the outer list only, excluding SelectableText's nested Scrollables.
Finder voiceTextScrollable({bool sheet = false}) => find.byElementPredicate((element) {
  if (element.widget is! Scrollable) return false;
  var found = false;
  element.visitAncestorElements((ancestor) {
    if (ancestor.widget is Scrollable) return false;
    if (sheet ? ancestor.widget is BottomSheet : ancestor.widget.key == const ValueKey('vt-scroll')) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
});

/// A keyed target can evaluate to nothing while a lazy list builds its rows.
/// Never wrap it in first/last/at before dragUntilVisible evaluates it.
Future<void> revealVoiceText(
  WidgetTester tester,
  String key, {
  bool sheet = false,
  Finder? scrollable,
  double alignment = 0,
}) async {
  final target = find.byKey(ValueKey(key));
  final list = scrollable ?? voiceTextScrollable(sheet: sheet);
  tester.state<ScrollableState>(list).position.jumpTo(0);
  await tester.pump();
  await tester.scrollUntilVisible(target, 150, scrollable: list);
  await Scrollable.ensureVisible(tester.element(target), alignment: alignment);
  await tester.pump();
}

Future<void> tapVoiceText(WidgetTester tester, String key, {bool sheet = false}) async {
  await revealVoiceText(tester, key, sheet: sheet);
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> confirmVoiceTextDownload(WidgetTester tester, AppLocalizations l, {String model = 'tiny-q5_1'}) async {
  await tapVoiceText(tester, 'vt-download-$model');
  final confirm = find.descendant(of: find.byType(Dialog), matching: find.text(l.vtDownloadConfirm));
  await tester.tap(confirm);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> expandVoiceTextTesting(WidgetTester tester) async {
  await tapVoiceText(tester, 'vt-testing-toggle');
  await tester.pumpAndSettle();
}
