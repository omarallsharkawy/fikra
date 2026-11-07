import 'package:fikra/data/ai/ai_service.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/app_harness.dart';

void main() {
  fikraTest('welcome -> demo project -> notes list -> links tab', (tester, db) async {
    final tryDemo = find.text('جرّب مشروع تجريبي');
    await pumpUntil(tester, tryDemo);
    expect(Directionality.of(tester.element(tryDemo)), TextDirection.rtl);

    await tester.tap(tryDemo);
    // Newest seeded note: top of the list once seeding finished.
    await pumpUntil(tester, find.text('محاضرة الشبكات'));
    expect(find.text('مشروع التخرج'), findsOneWidget);

    await tester.tap(Tabs.finder(Tabs.links));
    await pumpUntil(tester, find.text('الذكاء الاصطناعي'));
  });

  fikraTest('deleting the last project returns to welcome', (tester, db) async {
    await pumpUntil(tester, find.text('ابدأ مشروع جديد'));

    final projects = LocalProjectsRepository(db);
    final p = await pumpFuture(tester, () => projects.create('مؤقت'));
    await pumpUntil(tester, find.text('مؤقت'));

    await pumpFuture(tester, () => projects.delete(p.id));
    await pumpUntil(tester, find.text('ابدأ مشروع جديد'));
    expect(await pumpFuture(tester, () => db.select(db.projects).get()), isEmpty);
  });

  fikraTest('a note from another project still shows its related notes', (tester, db) async {
    await pumpUntil(tester, find.text('ابدأ مشروع جديد'));
    final projects = LocalProjectsRepository(db);
    final notes = LocalNotesRepository(db);

    late Note a;
    await pumpFuture(tester, () async {
      final p1 = await projects.create('الأول');
      a = await notes.create(projectId: p1.id, title: 'نوت أ', text: 'x', source: NoteSource.text);
      final b = await notes.create(projectId: p1.id, title: 'نوت ب', text: 'y', source: NoteSource.text);
      await notes.applyInsights(
        a.id,
        NoteInsights(
          title: 'نوت أ',
          concepts: const [],
          cluster: 'k',
          links: [ProposedLink(targetId: b.id, label: 'مرتبطة', strength: 1)],
        ),
      );
      await projects.create('التاني'); // becomes the selected project
    });
    await pumpUntil(tester, find.text('التاني'));

    tester.element(find.text('التاني')).push('/note/${a.id}');
    await pumpUntil(tester, find.text('نوت ب'));
  });
}
