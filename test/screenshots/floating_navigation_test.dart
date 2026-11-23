// flutter test test/screenshots/floating_navigation_test.dart --run-skipped -t screenshots
@Tags(['screenshots'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:fikra/core/widgets/glass_quality.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:fikra/features/add/add_screen.dart';
import 'package:fikra/features/notes/notes_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/selection_fixture.dart';

void main() {
  setUpAll(loadAppFonts);
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      fikraTest(
        'floating navigation ${locale.languageCode} ${brightness.name}',
        locale: locale,
        brightness: brightness,
        glassTier: GlassTier.frosted,
        tags: 'screenshots',
        (tester, db) async {
          phone(tester);
          tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
          tester.view.viewPadding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
          final l10n = lookupAppLocalizations(locale);
          final (_, _, notes) = await seedNotes(
            tester,
            db,
            List.generate(35, (i) => locale.languageCode == 'ar' ? 'فكرة رقم ${i + 1}' : 'Idea ${i + 1}'),
            l10n: l10n,
          );
          Future<void> capture(String name) =>
              saveScreenshot(tester, '${locale.languageCode}/${brightness.name}/floating_$name');
          await capture('home');
          final pointer = await tester.startGesture(tester.getCenter(Tabs.finder(Tabs.notes)));
          addTearDown(pointer.removePointer);
          await pointer.moveTo(tester.getCenter(Tabs.finder(Tabs.links)));
          await tester.pump();
          // No release: the lens remains frozen over Links during capture's pump.
          await capture('mid_slide_links');
          await pointer.up();
          await tester.pumpAndSettle();
          await tester.tap(Tabs.addButton);
          await tester.pumpAndSettle();
          await capture('add_selected');
          final title = find.descendant(of: find.byType(AddScreen), matching: find.byType(TextField)).at(0);
          await tester.tap(title);
          tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
          await tester.pumpAndSettle();
          await saveWithKeyboard(
            tester,
            '${locale.languageCode}/${brightness.name}/floating_keyboard',
            inset: 300,
            dark: brightness == Brightness.dark,
          );
          tester.view.viewInsets = const FakeViewPadding();
          tester.testTextInput.hide();
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('add-close')));
          await tester.pumpAndSettle();
          await tester.tap(Tabs.finder(Tabs.me));
          await tester.pumpAndSettle();
          await capture('me');
          await tester.tap(Tabs.finder(Tabs.notes));
          await tester.pumpAndSettle();
          final scrollable = find.descendant(
            of: find.byType(NotesScreen),
            matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down),
          );
          await tester.scrollUntilVisible(find.byKey(ValueKey(notes[0].id)), 500, scrollable: scrollable);
          final position = tester.state<ScrollableState>(scrollable).position;
          position.jumpTo(position.maxScrollExtent);
          await tester.pumpAndSettle();
          await capture('notes_bottom');
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
