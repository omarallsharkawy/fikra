@Tags(['screenshots'])
library;

import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import 'package:fikra/data/local/database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../graph_fixture.dart';
import '../support/app_harness.dart';

void main() {
  setUpAll(loadAppFonts);
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    for (final brightness in [Brightness.dark, Brightness.light]) {
      fikraTest(
        'connector focus (${locale.languageCode}, ${brightness.name})',
        locale: locale,
        brightness: brightness,
        tags: 'screenshots',
        (tester, db) async {
          tester.view.devicePixelRatio = 3;
          tester.view.physicalSize = const Size(390 * 3, 844 * 3);
          addTearDown(tester.view.reset);
          final notes = await seedGraph(tester, db, arabic: locale.languageCode == 'ar');
          final prefix = '${locale.languageCode}/${brightness.name}';
          await saveScreenshot(tester, '$prefix/42_graph_connectors');
          await tester.tap(find.byKey(ValueKey(notes.first.id)));
          await tester.pump(const Duration(milliseconds: 500));
          await saveScreenshot(tester, '$prefix/43_graph_focus');
          // Wide graph capture: nested top arcs and a long heading make the
          // span-height and capsule collision rules visible in each variant.
          final cluster = locale.languageCode == 'ar'
              ? 'أفكار وملاحظات للمشروع محتاجة ترتيب ومراجعة عشان نحدد الخطوة الجاية'
              : 'Project ideas and research notes needing review before the next step';
          await pumpFuture(tester, () async {
            await (db.update(
              db.notes,
            )..where((n) => n.id.isIn([notes[0].id, notes[1].id]))).write(NotesCompanion(cluster: Value(cluster)));
            for (var i = 1; i <= 2; i++) {
              await db
                  .into(db.notes)
                  .insert(
                    notes[0].copyWith(
                      id: 'nested-$i',
                      title: locale.languageCode == 'ar' ? 'فكرة $i' : 'Idea $i',
                      status: ProcessingStatus.ready,
                      cluster: Value(cluster),
                      createdAt: DateTime(2026, 11, 1, i),
                    ),
                  );
            }
            await db
                .into(db.noteLinks)
                .insert(
                  NoteLink(
                    id: 'nested-inner',
                    projectId: notes[0].projectId,
                    sourceId: 'nested-1',
                    targetId: 'nested-2',
                    label: '',
                    strength: 0.5,
                    origin: LinkOrigin.user,
                    dismissed: false,
                  ),
                );
          });
          await pumpUntil(tester, find.text(locale.languageCode == 'ar' ? 'فكرة 1' : 'Idea 1'));
          tester.view.physicalSize = const Size(780 * 3, 844 * 3);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          await saveScreenshot(tester, '$prefix/44_graph_nested');
        },
      );
    }
  }
}
