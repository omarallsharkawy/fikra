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

  fikraTest('notes search filters after a short pause and clears instantly', (tester, db) async {
    await pumpUntil(tester, find.text('جرّب مشروع تجريبي'));
    await tester.tap(find.text('جرّب مشروع تجريبي'));
    await pumpUntil(tester, find.text('محاضرة الشبكات'));
    expect(find.text('البحث الدلالي'), findsWidgets);

    await tester.enterText(find.byType(TextField).first, 'TCP');
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('البحث الدلالي'), findsWidgets); // debounced: not filtered yet
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('محاضرة الشبكات'), findsOneWidget);
    expect(find.text('البحث الدلالي'), findsNothing);

    await tester.enterText(find.byType(TextField).first, '');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('البحث الدلالي'), findsWidgets);
  });

  fikraTest('settings: theme choice applies and wipe returns to welcome', (tester, db) async {
    await pumpUntil(tester, find.text('جرّب مشروع تجريبي'));
    await tester.tap(find.text('جرّب مشروع تجريبي'));
    await pumpUntil(tester, find.text('محاضرة الشبكات'));

    await tester.tap(find.byIcon(Icons.settings_outlined).hitTestable().first);
    await pumpUntil(tester, find.text('المظهر'));
    expect(Theme.of(tester.element(find.text('المظهر'))).brightness, Brightness.dark);

    await tester.tap(find.text('فاتح'));
    await pumpUntil(tester, find.text('المظهر'));
    for (var i = 0; i < 20 && Theme.of(tester.element(find.text('المظهر'))).brightness != Brightness.light; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(Theme.of(tester.element(find.text('المظهر'))).brightness, Brightness.light);

    await tester.tap(find.text('مسح كل البيانات'));
    await pumpUntil(tester, find.text('امسح كله'));
    await tester.tap(find.text('امسح كله'));
    await pumpUntil(tester, find.text('ابدأ مشروع جديد'));
    await pumpUntil(tester, find.text('كل حاجة اتمسحت'));
    expect(await pumpFuture(tester, () => db.select(db.notes).get()), isEmpty);
    // The theme choice survives the wipe.
    expect(Theme.of(tester.element(find.text('ابدأ مشروع جديد'))).brightness, Brightness.light);
  });

  fikraTest('add: one composer box holds title, text, tools and save', (tester, db) async {
    await pumpUntil(tester, find.text('جرّب مشروع تجريبي'));
    await tester.tap(find.text('جرّب مشروع تجريبي'));
    await pumpUntil(tester, find.text('محاضرة الشبكات'));

    await tester.tap(Tabs.finder(Tabs.add));
    final save = find.byKey(const ValueKey('add-save'));
    await pumpUntil(tester, save);
    expect(find.byKey(const ValueKey('add-mic')), findsOneWidget);
    expect(find.byKey(const ValueKey('add-pdf')), findsOneWidget);

    // Empty draft: save does nothing.
    await tester.tap(save);
    await tester.pump(const Duration(milliseconds: 300));
    expect(save, findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'فكرة الكومبوزر');
    await tester.enterText(find.byType(TextField).last, 'البوكس فيه كل حاجة زي الشات.');
    await tester.pump();
    await tester.tap(save);
    await pumpUntil(tester, find.text('فكرة الكومبوزر'));
    await tester.pump(const Duration(seconds: 5)); // let the demo analysis finish
    final notes = await pumpFuture(tester, () => db.select(db.notes).get());
    expect(notes.where((n) => n.title == 'فكرة الكومبوزر'), hasLength(1));
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

  fikraTest('an opened note shows its content on the first frame, before the query returns', (tester, db) async {
    await pumpUntil(tester, find.text('ابدأ مشروع جديد'));
    late Note note;
    await pumpFuture(tester, () async {
      final p = await LocalProjectsRepository(db).create('مشروع');
      note = await LocalNotesRepository(db)
          .create(projectId: p.id, title: 'نوت سريعة', text: 'محتوى', source: NoteSource.text);
    });
    await pumpUntil(tester, find.text('مشروع'));

    // Deep link (no note handed over): nothing until the query answers.
    tester.element(find.text('مشروع')).push('/note/${note.id}');
    await tester.pump(); // the route's first frame
    expect(find.text('محتوى'), findsNothing);
    await pumpUntil(tester, find.text('محتوى'));
    tester.element(find.text('محتوى')).pop();
    await tester.pumpAndSettle();

    // From the app (note handed over): drawn with the page itself.
    tester.element(find.text('مشروع')).push('/note/${note.id}', extra: note);
    await tester.pump();
    expect(find.text('محتوى'), findsOneWidget);
  });
}
