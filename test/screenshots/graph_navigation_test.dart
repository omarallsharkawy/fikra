@Tags(['screenshots'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:fikra/data/local/database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../graph_fixture.dart';
import '../graph_navigation_fixture.dart';
import '../support/app_harness.dart';

void main() {
  setUpAll(loadAppFonts);
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    for (final brightness in [Brightness.dark, Brightness.light]) {
      fikraTest(
        'graph navigation (${locale.languageCode}, ${brightness.name})',
        locale: locale,
        brightness: brightness,
        tags: 'screenshots',
        (t, db) async {
          navPhone(t);
          final ar = locale.languageCode == 'ar';
          final f = await seedNavigation(t, db, arabic: ar);
          final prefix = '${locale.languageCode}/${brightness.name}';
          await saveScreenshot(t, '$prefix/61_graph_chips');
          // A query that fills the list, so the capture shows it ending at the keyboard.
          await graphQuery(t, ar ? 'ا' : 'e');
          t.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
          await navPump(t);
          final list = t.getRect(navKey('graph-search-results'));
          expect(list.bottom, lessThanOrEqualTo(844 - 300 + 0.01));
          expect(t.getRect(find.byType(ListTile).last).bottom, greaterThan(list.bottom - 72));
          await saveWithKeyboard(
            t,
            '$prefix/62_graph_search_results_keyboard',
            inset: 300,
            dark: brightness == Brightness.dark,
          );
          await t.enterText(
            find.descendant(of: navKey('graph-search-field'), matching: find.byType(TextField)),
            'xyzxyz',
          );
          await t.pump();
          await saveScreenshot(t, '$prefix/63_graph_search_empty');
          t.view.viewInsets = const FakeViewPadding();
          await t.tap(navKey('graph-search-close'));
          await navPump(t);
          await t.tap(navKey('graph-group-collapse-${f.parent.id}'));
          await navPump(t);
          final layout = graphPaths(t).layout;
          navController(t).value = Matrix4.translationValues(ar ? 390 - layout.width * 0.65 : 0, 0, 0)
            ..scaleByDouble(0.65, 0.65, 1, 1);
          await t.pump();
          await saveScreenshot(t, '$prefix/64_graph_collapsed');
          await pumpFuture(t, () async {
            for (var i = 0; i < 100; i++) {
              await db
                  .into(db.notes)
                  .insert(
                    f.notes.first.copyWith(
                      id: 'map-$i',
                      title: ar ? 'ملاحظة $i' : 'Note $i',
                      status: ProcessingStatus.ready,
                      groupId: const Value(null),
                      cluster: Value(ar ? 'موضوع ${i ~/ 8}' : 'Topic ${i ~/ 8}'),
                    ),
                  );
            }
          });
          await navPump(t);
          expect(navKey('graph-minimap'), findsOneWidget);
          await saveScreenshot(t, '$prefix/65_graph_minimap');
        },
      );
    }
  }
}

/// [saveScreenshot] plus a keyboard drawn over the bottom inset: the test
/// view has no system keyboard, so the capture would otherwise show whatever
/// the app paints there (the tab bar), not what the user sees.
Future<void> saveWithKeyboard(WidgetTester t, String name, {required double inset, required bool dark}) async {
  await t.pump(const Duration(milliseconds: 400));
  final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(appBoundaryKey));
  final ratio = t.view.devicePixelRatio;
  await t.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: ratio);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..drawImage(image, Offset.zero, Paint());
    final top = image.height - inset * ratio, width = image.width.toDouble();
    canvas.drawRect(
      Rect.fromLTWH(0, top, width, inset * ratio),
      Paint()..color = dark ? const Color(0xFF2B2B2E) : const Color(0xFFD3D5DB),
    );
    final key = Paint()..color = dark ? const Color(0xFF47474C) : const Color(0xFFFFFFFF);
    final pitch = width / 10, rowHeight = inset * ratio / 5;
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 10; col++) {
        final r = Rect.fromLTWH(
          col * pitch + 3 * ratio,
          top + 8 * ratio + row * rowHeight,
          pitch - 6 * ratio,
          rowHeight - 10 * ratio,
        );
        canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(5 * ratio)), key);
      }
    }
    final composed = await recorder.endRecording().toImage(image.width, image.height);
    final png = await composed.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/screenshots/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(png!.buffer.asUint8List());
  });
}
