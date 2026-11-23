import 'package:fikra/core/widgets/fikra_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';
import 'support/selection_fixture.dart' show host;

// The Undo toast (links phase 5a): its timing, its colour, and how it follows
// the screen reader while it is shown.
void main() {
  setUpAll(loadAppFonts);

  group('toasts', () {
    Future<void> show(
      WidgetTester tester,
      void Function(BuildContext context) action, {
      Brightness brightness = Brightness.dark,
    }) async {
      await host(
        tester,
        brightness: brightness,
        Builder(
          builder: (context) => TextButton(onPressed: () => action(context), child: const Text('go')),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('a plain toast is unchanged: no button, 3 seconds', (tester) async {
      await show(tester, (c) => showToast(c, 'saved'));
      final bar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(bar.action, isNull);
      expect(bar.duration, const Duration(seconds: 3));
      expect(bar.persist, isFalse);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('saved'), findsNothing);
    });

    testWidgets('an Undo toast stays about 6 seconds, is announced and runs its action once', (tester) async {
      var undone = 0;
      await show(tester, (c) => showToast(c, 'linked', actionLabel: 'Undo', onAction: () => undone++));
      final node = tester.getSemantics(find.text('linked'));
      expect(node.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
      // Frame by frame, so a shorter timeout would have closed it by now.
      for (var i = 0; i < 55; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('Undo'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pump();
      expect(undone, 1);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('linked'), findsNothing);

      // Untouched, it times out after 6 seconds.
      await tester.tap(find.text('go'));
      await tester.pump();
      for (var i = 0; i < 59; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('linked'), findsOneWidget);
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('linked'), findsNothing);
    });

    for (final brightness in Brightness.values) {
      for (final tier in [GlassTier.solid, GlassTier.frosted]) {
        testWidgets('the Undo button is readable on the solid ${brightness.name} toast (tier=${tier.name})', (
          tester,
        ) async {
          await host(
            tester,
            brightness: brightness,
            overrides: [glassTierProvider(false).overrideWith((ref) => tier)],
            Builder(
              builder: (context) => TextButton(
                onPressed: () => showToast(context, 'linked', actionLabel: 'Undo', onAction: () {}),
                child: const Text('go'),
              ),
            ),
          );
          await tester.tap(find.text('go'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          final capsule = find.byKey(const ValueKey('toast-capsule'));
          expect(find.descendant(of: capsule, matching: find.byType(BackdropFilter)), findsNothing);
          final label = find.descendant(of: find.byType(SnackBarAction), matching: find.byType(RichText));
          final color = (tester.renderObject(label) as RenderParagraph).text.style!.color!;
          final backing = (tester.widget<DecoratedBox>(capsule).decoration as BoxDecoration).color!;
          expect(backing.a, 1.0);
          final (a, b) = (color.computeLuminance(), backing.computeLuminance());
          final contrast = (a > b ? a + 0.05 : b + 0.05) / (a > b ? b + 0.05 : a + 0.05);
          expect(contrast, greaterThanOrEqualTo(4.5));
        });
      }
    }

    testWidgets('with a screen reader the Undo toast waits for the next one', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const _Features();
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await show(tester, (c) => showToast(c, 'linked', actionLabel: 'Undo', onAction: () {}));
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('Undo'), findsOneWidget);
    });

    testWidgets('a screen reader turned off mid-toast lets the Undo toast leave 6 seconds later', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const _Features();
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await show(tester, (c) => showToast(c, 'linked', actionLabel: 'Undo', onAction: () {}));
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('linked'), findsOneWidget);
      tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      await tester.pump();
      for (var i = 0; i < 55; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('linked'), findsOneWidget);
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('linked'), findsNothing);
    });

    testWidgets('a screen reader turned on mid-toast keeps the Undo toast', (tester) async {
      await show(tester, (c) => showToast(c, 'linked', actionLabel: 'Undo', onAction: () {}));
      await tester.pump(const Duration(seconds: 3));
      tester.platformDispatcher.accessibilityFeaturesTestValue = const _Features();
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await tester.pump();
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('Undo'), findsOneWidget);
    });

    testWidgets('a second toast replaces the first, Undo included', (tester) async {
      var undone = 0;
      var second = false;
      await show(tester, (c) {
        if (second) {
          showToast(c, 'two');
        } else {
          showToast(c, 'one', actionLabel: 'Undo', onAction: () => undone++);
        }
        second = true;
      });
      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('one'), findsNothing);
      expect(find.text('Undo'), findsNothing);
      expect(find.text('two'), findsOneWidget);
      expect(undone, 0);
    });
  });
}

class _Features implements AccessibilityFeatures {
  const _Features();
  @override
  bool get accessibleNavigation => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => false;
}
