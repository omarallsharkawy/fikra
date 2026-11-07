// Renders every main screen to build/screenshots/*.png with the real Arabic
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

  fikraTest('all screens', tags: 'screenshots', (tester, db) async {
    phone(tester);
    BuildContext ctx() => tester.element(find.byType(Scaffold).last);

    await pumpUntil(tester, find.text('جرّب مشروع تجريبي'));
    await saveScreenshot(tester, '01_welcome');

    await tester.tap(find.text('جرّب مشروع تجريبي'));
    await pumpUntil(tester, find.text('محاضرة الشبكات'));
    await saveScreenshot(tester, '02_notes');

    // Details of a note with a pending rewrite, concepts and links.
    final rag = await pumpFuture(
      tester,
      () => (db.select(db.notes)..where((n) => n.title.equals('إزاي RAG بيشتغل'))).getSingle(),
    );
    ctx().push('/note/${rag.id}');
    await pumpUntil(tester, find.text('اقتراح إعادة صياغة'));
    await saveScreenshot(tester, '03_details_top');
    await tester.drag(find.byType(ListView).last, const Offset(0, -600));
    await pumpUntil(tester, find.text('نوتس مرتبطة'));
    await saveScreenshot(tester, '04_details_bottom');

    await tester.tap(find.bySemanticsLabel('خيارات'));
    await pumpUntil(tester, find.text('خيارات النوت'));
    await saveScreenshot(tester, '05_note_options_sheet');
    await tester.tap(find.text('حذف النوت'));
    await pumpUntil(tester, find.text('تحذف النوت دي؟'));
    await saveScreenshot(tester, '06_delete_confirm');
    await tester.tap(find.text('إلغاء').last);
    await pumpUntil(tester, find.text('خيارات النوت'));
    await tester.tap(find.text('تعديل'));
    await pumpUntil(tester, find.text('تعديل النوت'));
    await saveScreenshot(tester, '07_edit');
    ctx().go('/notes');
    await pumpUntil(tester, find.text('محاضرة الشبكات'));

    await tester.tap(Tabs.finder(Tabs.add));
    await pumpUntil(tester, find.text('تسجيل صوت'));
    await saveScreenshot(tester, '08_add_empty');
    await tester.enterText(
      find.byType(TextField).last,
      'فكرة: نعمل وضع مذاكرة يجمع نوتس المحاضرات ويطلّع أسئلة مراجعة.',
    );
    await tester.pump();
    await saveScreenshot(tester, '09_add_typed');

    await tester.tap(Tabs.finder(Tabs.links));
    await pumpUntil(tester, find.text('الذكاء الاصطناعي'));
    await saveScreenshot(tester, '10_links');
    await tester.tap(find.text('إزاي RAG بيشتغل'));
    await pumpUntil(tester, find.text('فتح النوت'));
    await saveScreenshot(tester, '11_links_selected');

    await tester.tap(Tabs.finder(Tabs.ask));
    await pumpUntil(tester, find.text('اسأل نوتسك'));
    await saveScreenshot(tester, '12_ask_empty');
    await tester.tap(find.textContaining('إيه اللي كتبته عن').first);
    await pumpUntil(tester, find.text('المصادر'));
    await saveScreenshot(tester, '13_ask_answer');
    await tester.enterText(find.byType(TextField).last, 'إيه رأيي في الطبخ؟');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await pumpUntil(tester, find.text('ملقيناش إجابة في نوتسك'));
    await saveScreenshot(tester, '14_ask_not_found');

    await tester.tap(find.text('مشروع التخرج').first);
    await pumpUntil(tester, find.text('المشاريع'));
    await saveScreenshot(tester, '15_projects_sheet');
    await tester.tap(find.text('مشروع جديد'));
    await pumpUntil(tester, find.text('اسم المشروع'));
    await tester.enterText(find.byType(TextField).last, 'مذاكرة الشبكات');
    await tester.pump();
    await saveScreenshot(tester, '16_new_project');
    await tester.tap(find.text('إنشاء'));
    await pumpUntil(tester, find.text('مذاكرة الشبكات'));

    await tester.tap(Tabs.finder(Tabs.notes));
    await pumpUntil(tester, find.text('لسه مفيش نوتس'));
    await saveScreenshot(tester, '17_notes_empty');
    await tester.tap(Tabs.finder(Tabs.links));
    await pumpUntil(tester, find.text('الروابط بتظهر هنا'));
    await saveScreenshot(tester, '18_links_empty');
  });
}
