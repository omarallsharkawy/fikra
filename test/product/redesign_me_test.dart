import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fikra/data/settings_repository.dart';
import 'package:fikra/features/account/session_controller.dart';
import 'package:fikra/features/workspace/note_share.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart' show loadAppFonts;
import 'navigation_test.dart' show boot, cleanup, tapVisible;

class MutablePreferences implements SettingsRepository {
  AppLanguage language = AppLanguage.en;
  AppTheme theme = AppTheme.dark;
  final _languages = StreamController<AppLanguage>.broadcast(), _themes = StreamController<AppTheme>.broadcast();
  @override
  Stream<AppLanguage> watchLanguage() async* {
    yield language;
    yield* _languages.stream;
  }

  @override
  Stream<AppTheme> watchTheme() async* {
    yield theme;
    yield* _themes.stream;
  }

  @override
  Future<void> setLanguage(AppLanguage value) async {
    language = value;
    _languages.add(value);
  }

  @override
  Future<void> setTheme(AppTheme value) async {
    theme = value;
    _themes.add(value);
  }

  Future<void> dispose() async {
    await _languages.close();
    await _themes.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError('Unused test preference');
}

class ExportSpy implements NoteSharing {
  bool fail = false;
  Map<String, dynamic>? exported;
  @override
  bool get available => true;
  @override
  Future<void> share(Uint8List bytes, {required String filename, required String mime}) async {
    if (fail) throw StateError('must never reach the UI');
    expect(filename, endsWith('.json'));
    expect(mime, 'application/json');
    exported = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  }
}

void main() {
  setUpAll(loadAppFonts);
  for (final scale in [1.0, 2.0]) {
    testWidgets('Me edits names, switches language/theme live, exports actual notes and confirms logout $scale', (
      tester,
    ) async {
      final settings = MutablePreferences(), sharing = ExportSpy();
      final r = await boot(tester, settings: settings, sharing: sharing, scale: scale, size: const Size(360, 800));
      await r.session.login('reader@example.invalid', 'fixture-only');
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const ValueKey('nav-3')));
      var l = tester.element(find.byType(Scaffold).first).l10n;
      expect(find.byType(Switch), findsNothing);
      await tapVisible(tester, find.text(l.rdAddName));
      await tester.enterText(find.byType(TextField).last, '  علاء  ');
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text(l.rdSave));
      expect(r.profile.name, 'علاء');
      expect(find.text('علاء'), findsOneWidget);
      await tapVisible(tester, find.text('العربية'));
      l = tester.element(find.byType(Scaffold).first).l10n;
      expect(l.localeName, 'ar');
      expect(settings.language, AppLanguage.ar);
      await tapVisible(tester, find.text(l.rdLight));
      expect(settings.theme, AppTheme.light);
      expect(Theme.of(tester.element(find.text(l.rdTheme))).brightness, Brightness.light);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tapVisible(tester, find.text(l.rdSys));
      expect(settings.theme, AppTheme.system);
      expect(Theme.of(tester.element(find.text(l.rdTheme))).brightness, Brightness.dark);
      await tapVisible(tester, find.text('English'));
      l = tester.element(find.byType(Scaffold).first).l10n;
      expect(l.localeName, 'en');
      expect(r.profile.name, 'علاء');
      await tapVisible(tester, find.text(l.rdExp));
      expect(sharing.exported!['scope'], 'selected_project');
      expect(sharing.exported!['project']['id'], r.workspace.selectedProjectId);
      expect(
        (sharing.exported!['notes'] as List).map((n) => n['content']).toSet(),
        r.workspace.notes.map((n) => n.content).toSet(),
      );
      sharing.fail = true;
      await tapVisible(tester, find.text(l.rdExp));
      expect(find.textContaining('must never reach'), findsNothing);
      await tester.drag(find.byType(ListView).last, const Offset(0, -360));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text(l.rdOut));
      await tapVisible(tester, find.text(l.rdCancel));
      expect(r.session.stage, SessionStage.authenticated);
      await tapVisible(tester, find.text(l.rdOut));
      await tapVisible(tester, find.text(l.rdOut).last);
      expect(r.session.stage, SessionStage.unauthenticated);
      expect(tester.takeException(), isNull);
      await cleanup(tester);
      await settings.dispose();
      tester.platformDispatcher.clearPlatformBrightnessTestValue();
    });
  }
}
