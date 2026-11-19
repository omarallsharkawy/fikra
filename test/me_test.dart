import 'package:drift/drift.dart' show Value;
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/data/links_repository.dart';
import 'package:fikra/features/me/me_stats.dart';
import 'package:fikra/features/me/me_screen.dart';
import 'package:fikra/features/settings/settings_screen.dart';
import 'package:fikra/core/widgets/fikra_widgets.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';
import 'support/selection_fixture.dart';

void main() {
  final now = DateTime(2026, 11, 20, 12);
  fikraTest('Me aggregates current-project notes, confirmed pairs and seven calendar days', clock: () => now, (
    tester,
    db,
  ) async {
    phone(tester);
    final (project, work, notes) = await seedNotes(tester, db, ['a', 'b', 'c', 'd', 'e', 'f']);
    await pumpFuture(tester, () async {
      // Today counted once, six days ago included, seven days ago excluded.
      final dates = [
        DateTime(2026, 11, 20),
        DateTime(2026, 11, 20, 10),
        DateTime(2026, 11, 14),
        DateTime(2026, 11, 13, 23, 59),
        DateTime(2026, 11, 21),
        DateTime(2026, 11, 18),
      ];
      for (var i = 0; i < notes.length; i++) {
        await (db.update(
          db.notes,
        )..where((n) => n.id.equals(notes[i].id))).write(NotesCompanion(createdAt: Value(dates[i])));
      }
      final links = LocalLinksRepository(db);
      await links.linkNotes(notes[0].id, [notes[1].id, notes[2].id]);
      // A reverse legacy row must not count twice. Suggestions/tombstones do not count.
      for (final (id, origin, dismissed, a, b) in [
        ('reverse', LinkOrigin.user, false, notes[1].id, notes[0].id),
        ('suggestion', LinkOrigin.ai, false, notes[2].id, notes[3].id),
        ('dismissed', LinkOrigin.user, true, notes[3].id, notes[4].id),
      ]) {
        await db
            .into(db.noteLinks)
            .insert(
              NoteLink(
                id: id,
                projectId: project.id,
                sourceId: a,
                targetId: b,
                label: '',
                strength: 1,
                origin: origin,
                dismissed: dismissed,
              ),
            );
      }
    });
    await tester.tap(Tabs.finder(Tabs.me));
    await pumpUntil(tester, find.byType(MeScreen));
    final container = ProviderScope.containerOf(tester.element(find.byType(MeScreen)));
    final sub = container.listen(meStatsProvider, (_, _) {});
    addTearDown(sub.close);
    for (var i = 0; i < 20 && container.read(meStatsProvider).value?.links != 2; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(container.read(meStatsProvider).requireValue, (notes: 6, links: 2, activeDays: 3));
    await pumpFuture(tester, () => LocalProjectsRepository(db).setCurrent(work.id));
    for (var i = 0; i < 20 && container.read(meStatsProvider).value?.notes != 1; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(container.read(meStatsProvider).requireValue, (notes: 1, links: 0, activeDays: 1));
  });

  for (final code in ['ar', 'en']) {
    final l = lookupAppLocalizations(Locale(code));
    fikraTest('Me sections, project actions and guarded wipe $code', locale: Locale(code), (tester, db) async {
      phone(tester, height: 1000);
      await seedNotes(tester, db, ['Kept'], l10n: l);
      await tester.tap(Tabs.finder(Tabs.me));
      await tester.pumpAndSettle();
      expect(find.text(l.navMe), findsWidgets);
      for (final key in ['ideas', 'links', 'days']) {
        expect(find.byKey(ValueKey('me-stat-$key')), findsOneWidget);
      }
      await tester.tap(find.byKey(const ValueKey('me-projects')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('new-project')), findsOneWidget);
      expect(find.text('Study'), findsWidgets);
      Navigator.of(tester.element(find.byType(BottomSheet))).pop();
      await tester.pumpAndSettle();
      final scrollable = find.descendant(of: find.byType(SettingsScreen), matching: find.byType(Scrollable)).first;
      for (final label in [l.projectsTitle, l.meAppearanceLanguage, l.meVoiceServices, l.privacySection]) {
        await tester.scrollUntilVisible(find.text(label), 180, scrollable: scrollable);
        expect(find.text(label), findsOneWidget);
      }
      final erase = find.byKey(const ValueKey('settings-erase-all'));
      await tester.scrollUntilVisible(erase, 200, scrollable: scrollable);
      expect(tester.widget<SheetOption>(erase).danger, isTrue);
      await tester.tap(erase);
      await tester.pumpAndSettle();
      expect(find.text(l.eraseAllTitle), findsOneWidget);
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text(l.cancel)));
      await tester.pumpAndSettle();
      expect(await pumpFuture(tester, () => db.select(db.notes).get()), hasLength(2));
    });
  }
}
