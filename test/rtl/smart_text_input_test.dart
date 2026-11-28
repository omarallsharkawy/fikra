import 'dart:io';
import 'dart:ui' as ui;

import 'package:fikra/core/text_direction.dart';
import 'package:fikra/core/theme/product_theme.dart';
import 'package:fikra/core/theme/redesign_tokens.dart';
import 'package:fikra/core/widgets/redesign_widgets.dart';
import 'package:fikra/core/widgets/smart_input.dart';
import 'package:fikra/core/widgets/smart_text.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart' show loadAppFonts;

void main() {
  setUpAll(loadAppFonts);
  for (final brightness in Brightness.values) {
    test('material dialog actions, labels and cursors retain contrast: $brightness', () {
      final theme = buildProductTheme(brightness), colors = RdColors(brightness == Brightness.dark);
      final action = theme.textButtonTheme.style!.foregroundColor!.resolve({})!;
      for (final background in [colors.bg, colors.surface]) {
        final a = action.computeLuminance(), b = background.computeLuminance();
        final ratio = a > b ? (a + .05) / (b + .05) : (b + .05) / (a + .05);
        expect(ratio, greaterThanOrEqualTo(4.5));
      }
      expect(theme.inputDecorationTheme.floatingLabelStyle!.color, action);
      expect(theme.textSelectionTheme.cursorColor, action);
      expect(theme.textSelectionTheme.selectionHandleColor, action);
    });
  }
  testWidgets('OTP normalizes committed Arabic digits without changing active composition', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmartInput(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
          ),
        ),
      ),
    );
    await tester.showKeyboard(find.byType(TextField));
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '١٢',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 0, end: 2),
      ),
    );
    await tester.pump();
    expect(controller.text, '١٢');
    expect(controller.value.composing, const TextRange(start: 0, end: 2));
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(text: '١٢٣۴۵۶7', selection: TextSelection.collapsed(offset: 7)),
    );
    await tester.pump();
    expect(controller.text, '123456');
    expect(controller.selection.extentOffset, 6);
  });
  test('first-strong ignores punctuation, numerals, emoji and isolated fragments', () {
    for (final s in ['… (12) محمد!', '🌟 ال Deep Learning يعني إيه؟', '؟محمد @ Microsoft']) {
      expect(contentDirection(s), TextDirection.rtl);
    }
    for (final s in ['… (12) Alice!', '🌟 Deep Learning بالعربي', 'Microsoft @ محمد']) {
      expect(contentDirection(s), TextDirection.ltr);
    }
    expect(contentDirection('…123🌟', TextDirection.rtl), TextDirection.rtl);
    final mixed = isolateMixedText('ال Deep Learning يعني إيه؟ https://example.com!', TextDirection.rtl);
    expect(mixed, contains('\u2068Deep Learning\u2069'));
    expect(mixed, contains('\u2068https://example.com\u2069!'));
    expect(isolateMixedText(mixed, TextDirection.rtl), mixed);
  });
  for (final uiDir in TextDirection.values) {
    testWidgets('shared input preserves UI chrome and IME state: $uiDir', (tester) async {
      final text = TextEditingController(), id = TextEditingController();
      addTearDown(text.dispose);
      addTearDown(id.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: uiDir,
            child: Scaffold(
              body: Column(
                children: [
                  SmartInput(
                    key: const ValueKey('text'),
                    controller: text,
                    decoration: const InputDecoration(hintText: 'الاسم'),
                  ),
                  SmartInput(
                    key: const ValueKey('id'),
                    controller: id,
                    content: InputContent.identifier,
                    decoration: const InputDecoration(hintText: 'البريد الإلكتروني', suffixIcon: Icon(Icons.person)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      TextField field(String key) =>
          tester.widget<TextField>(find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(TextField)));
      expect(field('text').textDirection, uiDir);
      expect(field('id').textDirection, uiDir);
      expect(field('id').textAlign, TextAlign.start);
      expect(field('id').decoration!.hintTextDirection, uiDir);
      for (final value in ['محمد @ Microsoft', 'Alice في الجامعة', '…123🌟']) {
        text.value = TextEditingValue(
          text: value,
          selection: const TextSelection.collapsed(offset: 2),
          composing: const TextRange(start: 0, end: 2),
        );
        await tester.pump();
        expect(field('text').textDirection, contentDirection(value, uiDir));
        expect(text.selection.baseOffset, 2);
        expect(text.value.composing, const TextRange(start: 0, end: 2));
      }
      id.text = 'owner@example.com';
      await tester.pump();
      expect(field('id').textDirection, TextDirection.ltr);
      expect(field('id').textAlign, uiDir == TextDirection.rtl ? TextAlign.end : TextAlign.start);
      id.clear();
      text.clear();
      await tester.pump();
      expect(field('id').textDirection, uiDir);
      expect(field('text').textDirection, uiDir);
      expect(field('id').textAlign, TextAlign.start);
      expect(field('id').style!.fontFamilyFallback, contains('IBMPlexSansArabic'));
      expect(tester.takeException(), isNull);
    });
    for (final dark in [false, true]) {
      for (final value in [
        '',
        'مُحَمَّدٌ والفِكْرَةُ العَرَبِيَّةُ',
        'Deep Learning idea',
        'ال Deep Learning يعني إيه؟ 🌟 (12 kg) https://example.com',
      ]) {
        testWidgets('shared RTL snapshot $uiDir $dark $value', (tester) async {
          tester.view.physicalSize = const Size(398, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              locale: Locale(uiDir == TextDirection.rtl ? 'ar' : 'en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: buildProductTheme(dark ? Brightness.dark : Brightness.light),
              home: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.3)),
                  child: RepaintBoundary(
                    key: const ValueKey('snapshot'),
                    child: Scaffold(
                      body: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              RdText(context.l10n.rdMk, size: 22),
                              SmartInput(
                                initialValue: value,
                                decoration: InputDecoration(hintText: context.l10n.rdNm),
                              ),
                              const SizedBox(height: 16),
                              SmartInput(
                                initialValue: value.isEmpty ? '' : 'owner@example.com',
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(hintText: context.l10n.rdEm),
                              ),
                              const SizedBox(height: 16),
                              SmartInput(
                                initialValue: value.isEmpty ? '' : 'test-password',
                                obscureText: true,
                                decoration: InputDecoration(hintText: context.l10n.rdPw),
                              ),
                              const SizedBox(height: 16),
                              SmartInput(
                                initialValue: value,
                                minLines: 2,
                                maxLines: 3,
                                decoration: InputDecoration(hintText: context.l10n.rdCph),
                              ),
                              const SizedBox(height: 16),
                              SmartText(value, maxLines: 2, overflow: TextOverflow.ellipsis),
                              Wrap(
                                spacing: 8,
                                children: [
                                  RdChip(value.isEmpty ? context.l10n.rdNm : value),
                                  RdChip(context.l10n.rdTag),
                                ],
                              ),
                              RdButton(context.l10n.rdSave, onPressed: () {}),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final phase = const String.fromEnvironment('RTL_SHARED_CAPTURE', defaultValue: 'rtl-shared');
          final suffix = value.isEmpty
              ? 'empty'
              : value.startsWith('مُ')
              ? 'ar'
              : value.startsWith('Deep')
              ? 'en'
              : 'mixed';
          final name = '${uiDir.name}-${dark ? 'dark' : 'light'}-$suffix';
          final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('snapshot')));
          await tester.runAsync(() async {
            final im = await boundary.toImage();
            final bytes = await im.toByteData(format: ui.ImageByteFormat.png);
            final dir = Directory('build/validation/redesign/$phase')..createSync(recursive: true);
            File('${dir.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
            im.dispose();
          });
          await expectLater(find.byKey(const ValueKey('snapshot')), matchesGoldenFile('goldens/$name.png'));
        });
      }
    }
  }
}
