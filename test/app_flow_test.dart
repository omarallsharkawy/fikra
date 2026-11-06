import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:fikra/app/app.dart';
import 'package:fikra/app/providers.dart';
import 'package:fikra/data/local/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('welcome -> demo project -> notes list', (tester) async {
    await initializeDateFormatting('ar');
    final db = FikraDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(overrides: [databaseProvider.overrideWithValue(db)], child: const FikraApp()),
    );
    Future<void> settle() async {
      for (var i = 0; i < 20; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    await settle();
    expect(find.text('جرّب مشروع تجريبي'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('فِكرة'))), TextDirection.rtl);

    await tester.tap(find.text('جرّب مشروع تجريبي'));
    await settle();
    await settle();
    expect(find.text('مشروع التخرج'), findsOneWidget);
    expect(find.text('محاضرة الشبكات'), findsOneWidget);

    // Switch to the links tab.
    await tester.tap(find.text('الروابط').last);
    await settle();
    expect(find.text('الذكاء الاصطناعي'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await settle();
  });
}
