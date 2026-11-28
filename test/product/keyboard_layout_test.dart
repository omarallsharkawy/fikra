import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:fikra/app/product_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../support/app_harness.dart' show loadAppFonts;
import 'navigation_test.dart' show boot, cleanup, tapVisible;

void main() {
  setUpAll(loadAppFonts);
  for (final lang in ['en', 'ar']) {
    for (final contentLang in ['en', 'ar']) {
      for (final scenario in [
        (const Size(360, 640), 340.0, 1.0),
        (const Size(360, 640), 340.0, 2.0),
        (const Size(640, 360), 180.0, 1.0),
      ]) {
        for (final screen in ['capture', 'ask', 'edit']) {
          testWidgets('keyboard preserves visible caret and action: $screen $lang $contentLang $scenario', (
            tester,
          ) async {
            addTearDown(() async {
              tester.view.resetViewInsets();
              if (tester.testTextInput.isRegistered) tester.testTextInput.hide();
              await cleanup(tester);
            });
            final r = await boot(tester, locale: Locale(lang), size: scenario.$1, scale: scenario.$3);
            await r.session.login('reader@example.invalid', 'fixture-only');
            await tester.pumpAndSettle();
            var l = tester.element(find.byType(Scaffold).first).l10n;
            late Finder field, action;
            if (screen == 'capture') {
              await tapVisible(tester, find.byKey(const ValueKey('nav-add')));
              field = find.descendant(
                of: find.byKey(ValueKey('capture-content-${r.workspace.selectedProjectId}')),
                matching: find.byType(TextField),
              );
              action = find.byKey(const ValueKey('save-product-note'));
            } else if (screen == 'ask') {
              await tapVisible(tester, find.byKey(const ValueKey('nav-2')));
              await tapVisible(tester, find.byKey(const ValueKey('new-conversation')));
              field = find.descendant(
                of: find.byKey(const ValueKey('chat-question')),
                matching: find.byType(TextField),
              );
              action = find.byKey(const ValueKey('send-chat'));
            } else {
              ProviderScope.containerOf(tester.element(find.byType(MaterialApp)))
                  .read(productRouterProvider)
                  .go('/note/${r.workspace.notes.first.id}');
              await tester.pumpAndSettle();
              await tapVisible(tester, find.byKey(const ValueKey('note-menu')));
              await tapVisible(tester, find.text(l.productEditNote));
              field = find.descendant(of: find.byKey(const ValueKey('edit-content')), matching: find.byType(TextField));
              action = find.text(l.productSaveEdit);
            }
            final text = List.generate(
              24,
              (i) =>
                  contentLang == 'ar' ? 'السطر $i: فكرة طويلة نقدر نراجعها.' : 'Line $i: a longer thought to review.',
            ).join('\n');
            await tester.enterText(field, text);
            tester.view.viewInsets = FakeViewPadding(bottom: scenario.$2);
            await tester.pumpAndSettle();
            await tester.runAsync(() async {
              final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(const ValueKey('product-capture')),
              );
              final im = await boundary.toImage();
              final bytes = await im.toByteData(format: ui.ImageByteFormat.png);
              final dir = Directory('build/validation/redesign/keyboard')..createSync(recursive: true);
              File('${dir.path}/$screen-$lang-$contentLang-${scenario.$1.width.toInt()}-${scenario.$3.toInt()}.png')
                  .writeAsBytesSync(bytes!.buffer.asUint8List());
              im.dispose();
            });
            expect(field, findsOneWidget, reason: 'editor disappeared when keyboard opened');
            final editable = tester.state<EditableTextState>(
              find.descendant(of: field, matching: find.byType(EditableText)),
            );
            final render = editable.renderEditable;
            final caret = render
                .getLocalRectForCaret(TextPosition(offset: text.length))
                .shift(render.localToGlobal(Offset.zero));
            final visibleBottom = scenario.$1.height - scenario.$2;
            expect(tester.takeException(), isNull);
            expect(caret.top, greaterThanOrEqualTo(0), reason: 'caret above the viewport');
            expect(caret.bottom, lessThanOrEqualTo(visibleBottom), reason: 'keyboard covers the caret');
            if (screen != 'edit') {
              final rect = tester.getRect(action);
              expect(rect.bottom, lessThanOrEqualTo(visibleBottom));
              expect(rect.top, greaterThanOrEqualTo(0));
              expect(
                action.hitTestable(),
                findsOneWidget,
                reason: 'selection handles and keyboard must not cover the action',
              );
              expect(caret.overlaps(rect), isFalse, reason: 'action covers the writing area');
              if (screen == 'capture') {
                final viewport = tester.getRect(find.ancestor(of: field, matching: find.byType(ListView)).first);
                expect(caret.top, greaterThanOrEqualTo(viewport.top - 1));
                expect(caret.bottom, lessThanOrEqualTo(viewport.bottom + 1), reason: 'caret clipped by Capture tools');
              }
            } else {
              expect(action.hitTestable(), findsOneWidget);
              expect(tester.getRect(action).bottom, lessThanOrEqualTo(visibleBottom));
              final viewport = tester.getRect(find.ancestor(of: field, matching: find.byType(ListView)).first);
              expect(caret.top, greaterThanOrEqualTo(viewport.top - 1));
              expect(caret.bottom, lessThanOrEqualTo(viewport.bottom + 1));
            }
            expect(editable.widget.focusNode.hasFocus, isTrue, reason: 'keyboard resize must preserve focus');
            tester.view.resetViewInsets();
            await tester.pumpAndSettle();
            expect(tester.widget<TextField>(field).controller!.text, text);
            tester.view.viewInsets = FakeViewPadding(bottom: scenario.$2);
            await tester.pumpAndSettle();
            expect(tester.widget<TextField>(field).controller!.text, text);
            await tester.tap(action);
            await tester.pumpAndSettle();
            if (screen == 'capture') {
              expect(r.workspace.notes.any((n) => n.content == text), isTrue);
            }
            if (screen == 'edit') {
              expect(r.workspace.detail!.content, text);
            }
            if (screen == 'ask') {
              expect(r.chat.draft, isEmpty);
            }
            tester.view.resetViewInsets();
            tester.testTextInput.hide();
            await cleanup(tester);
          });
        }
      }
    }
  }
}
