import 'package:fikra/core/motion/pressable.dart';
import 'package:fikra/core/widgets/fikra_widgets.dart';
import 'package:fikra/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/a11y_fixture.dart';
import 'support/app_harness.dart';
import 'support/fake_external_transcription.dart';
import 'voice_text/fake_voice_text_backend.dart';

bool _isInsideHorizontalScrollable(Element element) {
  var inside = false;
  element.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    if (widget is Scrollable &&
        (widget.axisDirection == AxisDirection.left || widget.axisDirection == AxisDirection.right)) {
      inside = true;
      return false;
    }
    return true;
  });
  return inside;
}

void _expectNoClippedInteractiveControls(WidgetTester tester, String contextLabel) {
  const screenWidth = 360.0;
  const screenHeight = 800.0;

  bool isInteractiveWidget(Widget w) =>
      w is Pressable ||
      w is FikraButton ||
      w is FikraIconButton ||
      w is IconButton ||
      w is TextButton ||
      w is Switch ||
      w is SnackBarAction ||
      w is TextField;

  final candidates = find.byWidgetPredicate(isInteractiveWidget).hitTestable();
  for (final element in candidates.evaluate()) {
    final box = element.renderObject;
    if (box is! RenderBox || !box.hasSize) continue;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    // Ignore controls scrolled completely out of the vertical viewport.
    if (rect.bottom <= 0 || rect.top >= screenHeight) continue;

    if (!_isInsideHorizontalScrollable(element)) {
      expect(
        rect.left,
        greaterThanOrEqualTo(-0.5),
        reason: '$contextLabel: ${element.widget.runtimeType} clipped on left ($rect)',
      );
      expect(
        rect.right,
        lessThanOrEqualTo(screenWidth + 0.5),
        reason: '$contextLabel: ${element.widget.runtimeType} clipped on right ($rect)',
      );
    }

    // Check every descendant RenderParagraph inside this control isn't vertically clipped
    // or horizontally clipped without ellipsis.
    void checkParagraphs(Element child) {
      final ro = child.renderObject;
      if (ro is RenderParagraph && ro.hasSize) {
        final pRect = ro.localToGlobal(Offset.zero) & ro.size;
        expect(
          pRect.height,
          lessThanOrEqualTo(rect.height + 1.0),
          reason: '$contextLabel: text "${ro.text.toPlainText()}" taller than control ($pRect vs $rect)',
        );
        if (ro.overflow != TextOverflow.ellipsis) {
          expect(
            pRect.width,
            lessThanOrEqualTo(rect.width + 1.0),
            reason:
                '$contextLabel: text "${ro.text.toPlainText()}" wider than control without ellipsis ($pRect vs $rect)',
          );
        }
      }
      child.visitChildren(checkParagraphs);
    }

    element.visitChildren(checkParagraphs);
  }
}

void main() {
  setUpAll(loadAppFonts);

  for (final scale in [1.3, 2.0]) {
    for (final code in ['ar', 'en']) {
      for (final brightness in [Brightness.light, Brightness.dark]) {
        final locale = Locale(code);
        final serviceKeys = MemoryServiceKeys();
        final voiceBackend = FakeVoiceTextBackend()
          ..arabic = (code == 'ar')
          ..seed();

        fikraTest(
          'large text ${scale}x at 360dp has no overflow or clipped controls ($code, ${brightness.name})',
          locale: locale,
          brightness: brightness,
          glassTier: GlassTier.frosted,
          textScale: scale,
          serviceKeys: serviceKeys,
          voiceTextBackend: voiceBackend,
          (tester, db) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = const Size(360, 800);
            addTearDown(tester.view.reset);

            final semantics = tester.ensureSemantics();
            try {
              final data = await seedA11yApp(tester, db, locale: locale, serviceKeys: serviceKeys);
              await visitAllMainScreensAndSheets(
                tester,
                data,
                locale: locale,
                onScreen: (screenName) async {
                  final label = '$screenName ($code ${brightness.name} ${scale}x)';
                  expect(tester.takeException(), isNull, reason: '$label threw layout/overflow exception');
                  _expectNoClippedInteractiveControls(tester, label);
                  if (screenName == 'settings') {
                    final pillParagraphs = tester.renderObjectList<RenderParagraph>(
                      find.descendant(
                        of: find.descendant(of: find.byType(SettingsScreen), matching: find.byType(SegmentedPill)),
                        matching: find.byType(RichText),
                      ),
                    );
                    expect(pillParagraphs, isNotEmpty);
                    for (final p in pillParagraphs) {
                      expect(
                        p.didExceedMaxLines,
                        isFalse,
                        reason: '$label segmented label "${p.text.toPlainText()}" truncated',
                      );
                    }
                  }
                  await expectLater(tester, meetsGuideline(androidTapTargetGuideline), reason: '$label tap targets');
                  await expectLater(
                    tester,
                    meetsGuideline(labeledTapTargetGuideline),
                    reason: '$label labeled tap targets',
                  );
                },
              );

              // Also check glass toast with action at large text scale on 360dp width.
              final ctx = tester.element(find.byType(Scaffold).first);
              showMessengerToast(
                ScaffoldMessenger.of(ctx),
                code == 'ar' ? 'تم ربط الملاحظتين ببعض بنجاح' : 'Linked two notes together',
                actionLabel: code == 'ar' ? 'تراجع' : 'Undo',
                onAction: () {},
              );
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 350));
              expect(tester.takeException(), isNull, reason: 'toast ($code ${brightness.name} ${scale}x) overflow');
              _expectNoClippedInteractiveControls(tester, 'toast ($code ${brightness.name} ${scale}x)');
            } finally {
              semantics.dispose();
            }
          },
        );
      }
    }
  }
}
