import 'package:fikra/app/router.dart';
import 'package:fikra/core/widgets/navigation_inset.dart';
import 'package:fikra/features/add/add_screen.dart';
import 'package:fikra/features/me/me_screen.dart';
import 'package:fikra/features/voice_text/voice_text_screen.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'floating_navigation_test.dart' show hostNavigation;
import 'support/app_harness.dart';
import 'support/selection_fixture.dart';

void main() {
  setUpAll(loadAppFonts);
  for (final code in ['ar', 'en']) {
    final locale = Locale(code);
    final l = lookupAppLocalizations(locale);
    for (final scale in [1.0, 1.3, 1.4, 2.0]) {
      testWidgets('four tabs and separate FAB fit 360 dp $code $scale', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(360, 800);
        addTearDown(tester.view.reset);
        final semantics = tester.ensureSemantics();
        try {
          await hostNavigation(
            tester,
            locale: locale,
            width: 336,
            textScale: scale,
            direction: code == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          );
          final labels = [l.navHome, l.navMap, l.navAsk, l.navMe];
          for (var i = 0; i < 4; i++) {
            final tab = Tabs.finder(i);
            expect(tab, findsOneWidget);
            expect(tester.getSize(tab).width, greaterThanOrEqualTo(48));
            expect(tester.getSemantics(tab).label, labels[i]);
            final text = find.descendant(of: tab, matching: find.text(labels[i]));
            if (scale >= 1.4) {
              expect(text, findsNothing);
            } else {
              final paragraph = tester.renderObject<RenderParagraph>(text);
              expect(paragraph.didExceedMaxLines, isFalse, reason: '$code ${labels[i]} at $scale');
              final natural = TextPainter(
                text: paragraph.text,
                textDirection: paragraph.textDirection,
                textScaler: paragraph.textScaler,
                locale: paragraph.locale,
              )..layout();
              try {
                expect(natural.width, lessThanOrEqualTo(paragraph.size.width + .01));
              } finally {
                natural.dispose();
              }
            }
          }
          final bar = tester.getRect(find.byKey(const ValueKey('floating-tab-bar')));
          final fab = tester.getRect(Tabs.addButton);
          expect(fab.size, const Size(56, 56));
          expect(code == 'ar' ? bar.left - fab.right : fab.left - bar.right, closeTo(8, .01));
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      });
    }
  }

  for (final reduced in [false, true]) {
    testWidgets('plain tap spring moves over frames, retargets, and respects Reduce Motion $reduced', (tester) async {
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'HapticFeedback.vibrate') calls.add(call.arguments as String);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      final branch = await hostNavigation(tester, reduced: reduced);
      final pill = find.byKey(const ValueKey('nav-selected-pill'));
      final start = tester.getCenter(pill).dx;
      final target = tester.getCenter(Tabs.finder(Tabs.links)).dx;
      await tester.tap(Tabs.finder(Tabs.links));
      await tester.pump();
      expect(branch.value, 2);
      expect(find.byKey(const ValueKey('nav-lens')), findsNothing);
      if (reduced) {
        expect(tester.getCenter(pill).dx, closeTo(target, .01));
      } else {
        expect(tester.getCenter(pill).dx, closeTo(start, .01));
        await tester.pump(const Duration(milliseconds: 40));
        final a = tester.getCenter(pill).dx;
        await tester.pump(const Duration(milliseconds: 40));
        final b = tester.getCenter(pill).dx;
        expect(a, isNot(closeTo(start, .1)));
        expect(b, isNot(closeTo(a, .1)));
      }
      for (final i in [Tabs.ask, Tabs.notes, Tabs.me]) {
        await tester.tap(Tabs.finder(i));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pump(const Duration(milliseconds: 380));
      expect(branch.value, 4);
      expect(tester.getCenter(pill).dx, closeTo(tester.getCenter(Tabs.finder(Tabs.me)).dx, .1));
      expect(calls, hasLength(4));
      await tester.tap(Tabs.finder(Tabs.me));
      await tester.pump();
      expect(calls, hasLength(4));
      expect(tester.takeException(), isNull);
    });
  }

  fikraTest('Me/settings routes and full-screen Add return history including back', (tester, db) async {
    phone(tester);
    await seedNotes(tester, db, ['A']);
    final container = ProviderScope.containerOf(tester.element(Tabs.finder(Tabs.notes)));
    final router = container.read(routerProvider);
    for (final (tab, path) in [(Tabs.links, '/links'), (Tabs.ask, '/ask'), (Tabs.me, '/me'), (Tabs.notes, '/notes')]) {
      await tester.tap(Tabs.finder(tab));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, path);
      await tester.tap(Tabs.addButton);
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/add');
      expect(Tabs.addButton.hitTestable(), findsNothing);
      expect(Tabs.finder(Tabs.notes).hitTestable(), findsNothing);
      expect(NavigationInset.of(tester.element(find.byType(AddScreen))), 0);
      expect(find.text(arL10n.newIdea), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('add-close')));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, path);
      await tester.tap(Tabs.addButton);
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(router.state.uri.path, path);
    }
    router.go('/settings');
    await pumpUntil(tester, find.byType(MeScreen));
    expect(router.state.uri.path, '/me');
    router.go('/settings/voice-text');
    await pumpUntil(tester, find.byType(VoiceTextScreen));
    expect(router.state.uri.path, '/settings/voice-text');
  });
}
