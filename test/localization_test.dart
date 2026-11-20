import 'package:fikra/app/providers.dart';
import 'package:fikra/core/format.dart';
import 'package:fikra/data/ai/demo_ai_service.dart';
import 'package:fikra/data/demo/demo_seed.dart';
import 'package:fikra/data/files/attachment_store.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/data/settings_repository.dart';
import 'package:fikra/features/settings/settings_screen.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'support/app_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final ar = lookupAppLocalizations(const Locale('ar'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('Arabic ICU note forms use the final two digits for few and many', () {
    // Expected forms intentionally literal: these verify the translation itself.
    expect([0, 1, 2, 3, 11, 103].map(ar.notesCount), [
      'مفيش ملاحظات',
      'ملاحظة واحدة',
      'ملاحظتين',
      '3 ملاحظات',
      '11 ملاحظة',
      '103 ملاحظات',
    ]);
    expect([0, 1, 2].map(en.notesCount), ['No notes', '1 note', '2 notes']);
  });

  test('dates, relative times and sizes use the requested language and Western digits', () async {
    await initializeDateFormatting();
    final now = DateTime(2026, 11, 10, 15, 4);
    expect(Fmt.time(en, now), '3:04 PM');
    expect(Fmt.time(ar, now), '3:04 م');
    expect(Fmt.dayHeader(en, now, now: now), en.today);
    expect(Fmt.dayHeader(ar, now.subtract(const Duration(days: 1)), now: now), ar.yesterday);
    expect(Fmt.relative(ar, now.subtract(const Duration(minutes: 3)), now: now), ar.minutesAgo(3));
    expect(Fmt.relative(en, now.subtract(const Duration(hours: 2)), now: now), en.hoursAgo(2));
    expect(Fmt.bytes(ar, 1536), ar.sizeKb('2'));
    expect(Fmt.bytes(en, 1572864), en.sizeMb('1.5'));
    expect(Fmt.dayHeader(ar, now.subtract(const Duration(days: 3)), now: now), isNot(matches(RegExp(r'[٠-٩]'))));
    expect(Fmt.date(en, DateTime(2027, 2, 26)), 'Feb 26, 2027');
    expect(Fmt.date(ar, DateTime(2027, 2, 26)), allOf(contains('26'), contains('2027'), contains('فبراير')));
    expect(Fmt.date(ar, DateTime(2027, 2, 26)), isNot(contains('-')));
  });

  fikraTest('language choice switches the entire app at runtime and persists', (tester, db) async {
    await pumpUntil(tester, find.text(ar.trySampleProject));
    await tester.tap(find.text(ar.trySampleProject));
    await pumpUntil(tester, find.text(ar.sample7Title));
    await tester.tap(Tabs.finder(Tabs.me));
    await pumpUntil(tester, find.byType(SettingsScreen));
    await tester.pump(const Duration(milliseconds: 500));
    await Scrollable.ensureVisible(tester.element(find.text(ar.languageEnglish)), alignment: .4);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text(ar.languageEnglish));
    await pumpUntil(tester, find.text(en.appearance));
    expect(testL10n(tester).localeName, 'en');
    expect(Directionality.of(tester.element(find.text(en.appearance))), TextDirection.ltr);

    final context = tester.element(find.byType(SettingsScreen));
    final container = ProviderScope.containerOf(context);
    final settings = container.read(settingsRepoProvider);
    expect(await pumpFuture(tester, () => settings.watchLanguage().first), AppLanguage.en);
    // A fresh repository reads the persisted row, independent of provider state.
    final reopened = LocalSettingsRepository(db, AttachmentStore());
    expect(await pumpFuture(tester, () => reopened.watchLanguage().first), AppLanguage.en);
    await tester.tap(Tabs.finder(Tabs.notes));
    await pumpUntil(tester, find.text(en.notesTitle));
    expect(Directionality.of(tester.element(Tabs.finder(Tabs.notes))), TextDirection.ltr);
    // Stored sample text and its topics remain in their creation language.
    expect(find.text(ar.sample7Title), findsOneWidget);

    await tester.tap(Tabs.finder(Tabs.me));
    await pumpUntil(tester, find.text(en.appearance));
    await tester.pump(const Duration(milliseconds: 500));
    await Scrollable.ensureVisible(tester.element(find.text(en.languageArabic)), alignment: .4);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text(en.languageArabic));
    await pumpUntil(tester, find.text(ar.appearance));
    expect(Directionality.of(tester.element(find.text(ar.appearance))), TextDirection.rtl);
    expect(await pumpFuture(tester, () => settings.watchLanguage().first), AppLanguage.ar);
    // Device fallback responds while the app is running.
    await tester.tap(find.text(ar.languageSystem).last);
    await pumpFuture(tester, () => settings.watchLanguage().firstWhere((l) => l == AppLanguage.system));
    tester.platformDispatcher.localesTestValue = [const Locale('en', 'US')];
    await pumpUntil(tester, find.text(en.appearance));
    tester.platformDispatcher.localesTestValue = [const Locale('fr')];
    await pumpUntil(tester, find.text(ar.appearance));
  });

  fikraTest('English device starts LTR, creates English samples and answers in English', locale: const Locale('en'), (
    tester,
    db,
  ) async {
    await pumpUntil(tester, find.text(en.trySampleProject));
    expect(Directionality.of(tester.element(find.text(en.trySampleProject))), TextDirection.ltr);
    final container = ProviderScope.containerOf(tester.element(find.text(en.trySampleProject)));
    final project = await pumpFuture(
      tester,
      () => seedDemoProject(
        container.read(projectsRepoProvider),
        container.read(notesRepoProvider),
        locale: container.read(appLocaleProvider),
      ),
    );
    await pumpUntil(tester, find.text(en.sample7Title));
    final notes = await pumpFuture(tester, () => LocalNotesRepository(db).notesOf(project.id));
    expect(project.name, en.sampleProjectName);
    expect(notes.expand((n) => n.conceptList), contains('Embeddings'));
    expect(notes.singleWhere((n) => n.title == en.sample7Title).conceptList, contains('Networking'));
    final ai = container.read(aiServiceProvider);
    final answer = await pumpFuture(tester, () => ai.ask(en.askSuggestion(en.sample2Title), notes));
    expect(answer.found, isTrue);
    expect(answer.text, startsWith(en.demoAnswerIntro));
    expect(answer.text, isNot(matches(RegExp(r'[\u0600-\u06ff]'))));
    expect(answer.sourceIds, isNotEmpty);
    final notFound = await pumpFuture(tester, () => ai.ask('cooking?', notes));
    expect(notFound.text, en.demoAnswerNotFound);
  });

  test('English dictionary supports all glossary search keywords', () async {
    final concepts = await DemoAiService.detectConcepts(
      'lecture exam study network video design interface ai embeddings',
      locale: const Locale('en'),
    );
    // Each independently, since an analysis intentionally caps topics at five.
    expect(concepts, isNotEmpty);
    for (final keyword in ['lecture', 'exam', 'study', 'network', 'video', 'design', 'interface', 'ai', 'embeddings']) {
      expect(await DemoAiService.detectConcepts(keyword, locale: const Locale('en')), isNotEmpty, reason: keyword);
    }
  });
}
