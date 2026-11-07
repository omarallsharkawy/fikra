// Renders every main screen to build/screenshots/{dark,light}/*.png with the real Arabic
// font and icons, at phone size. For design review, not a regression test:
//   flutter test test/screenshots --tags screenshots
@Tags(['screenshots'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/app_harness.dart';

void main() {
  setUpAll(loadAppFonts);

  void phone(WidgetTester tester) {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    tester.view.viewPadding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    addTearDown(tester.view.reset);
  }

  for (final brightness in [Brightness.dark, Brightness.light]) {
    fikraTest('all screens (${brightness.name})', brightness: brightness, tags: 'screenshots', (tester, db) async {
      Future<void> capture(String name) => saveScreenshot(tester, '${brightness.name}/$name');
      phone(tester);
      BuildContext ctx() => tester.element(find.byType(Scaffold).last);

      await pumpUntil(tester, find.text('جرّب مشروع تجريبي'));
      await capture('01_welcome');

      await tester.tap(find.text('جرّب مشروع تجريبي'));
      await pumpUntil(tester, find.text('محاضرة الشبكات'));
      await capture('02_notes');

      // Details of a note with a pending rewrite, concepts and links.
      final rag = await pumpFuture(
        tester,
        () => (db.select(db.notes)..where((n) => n.title.equals('إزاي RAG بيشتغل'))).getSingle(),
      );
      ctx().push('/note/${rag.id}');
      await pumpUntil(tester, find.text('اقتراح إعادة صياغة'));
      await capture('03_details_top');
      await tester.drag(find.byType(ListView).last, const Offset(0, -600));
      await pumpUntil(tester, find.text('نوتس مرتبطة'));
      await capture('04_details_bottom');

      await tester.tap(find.bySemanticsLabel('خيارات'));
      await pumpUntil(tester, find.text('خيارات النوت'));
      await capture('05_note_options_sheet');
      await tester.tap(find.text('حذف النوت'));
      await pumpUntil(tester, find.text('تحذف النوت دي؟'));
      await capture('06_delete_confirm');
      await tester.tap(find.text('إلغاء').last);
      await pumpUntil(tester, find.text('خيارات النوت'));
      await tester.tap(find.text('تعديل'));
      await pumpUntil(tester, find.text('تعديل النوت'));
      await capture('07_edit');
      ctx().go('/notes');
      await pumpUntil(tester, find.text('محاضرة الشبكات'));

      await tester.tap(Tabs.finder(Tabs.add));
      await pumpUntil(tester, find.byKey(const ValueKey('add-mic')));
      await capture('08_add_empty');
      await tester.enterText(
        find.byType(TextField).last,
        'فكرة: نعمل وضع مذاكرة يجمع نوتس المحاضرات ويطلّع أسئلة مراجعة.',
      );
      await tester.pump();
      await capture('09_add_typed');

      await tester.tap(Tabs.finder(Tabs.links));
      await pumpUntil(tester, find.text('الذكاء الاصطناعي'));
      await capture('10_links');
      await tester.tap(find.text('إزاي RAG بيشتغل'));
      await pumpUntil(tester, find.text('فتح النوت'));
      await capture('11_links_selected');

      await tester.tap(Tabs.finder(Tabs.ask));
      await pumpUntil(tester, find.text('اسأل نوتسك'));
      await capture('12_ask_empty');
      await tester.tap(find.textContaining('إيه اللي كتبته عن').first);
      await pumpUntil(tester, find.text('المصادر'));
      await capture('13_ask_answer');
      await tester.enterText(find.byType(TextField).last, 'إيه رأيي في الطبخ؟');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await pumpUntil(tester, find.text('ملقيناش إجابة في نوتسك'));
      await capture('14_ask_not_found');

      await tester.tap(find.text('مشروع التخرج').first);
      await pumpUntil(tester, find.text('المشاريع'));
      await capture('15_projects_sheet');
      await tester.tap(find.text('مشروع جديد'));
      await pumpUntil(tester, find.text('اسم المشروع'));
      await tester.enterText(find.byType(TextField).last, 'مذاكرة الشبكات');
      await tester.pump();
      await capture('16_new_project');
      await tester.tap(find.text('إنشاء'));
      await pumpUntil(tester, find.text('مذاكرة الشبكات'));

      await tester.tap(Tabs.finder(Tabs.notes));
      await pumpUntil(tester, find.text('لسه مفيش نوتس'));
      await capture('17_notes_empty');
      await tester.tap(Tabs.finder(Tabs.links));
      await pumpUntil(tester, find.text('الروابط بتظهر هنا'));
      await capture('18_links_empty');

      await tester.tap(find.byIcon(Icons.settings_outlined).hitTestable().first);
      await pumpUntil(tester, find.text('المظهر'));
      await capture('19_settings');
    });
  }
}
