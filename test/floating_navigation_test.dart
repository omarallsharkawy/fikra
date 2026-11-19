import 'dart:ui' show ImageFilter, Tristate;

import 'package:fikra/app/tab_bar/floating_navigation.dart';
import 'package:fikra/app/tab_bar/sliding_tab_bar.dart' show kLensHoldDelay;
import 'package:fikra/app/shell.dart' show FikraBranchContainer;
import 'package:fikra/core/theme/fikra_theme.dart';
import 'package:fikra/core/widgets/glass.dart';
import 'package:fikra/core/widgets/glass_quality.dart';
import 'package:fikra/core/widgets/glass_lens.dart';
import 'package:fikra/core/widgets/glass_watchdog.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsAction, RenderBackdropFilter;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'glass_test_fakes.dart';
import 'support/app_harness.dart';

const _lens = ValueKey('nav-lens');

double _lensOpacity(WidgetTester tester) {
  final lenses = find.byType(GlassLens).evaluate();
  return lenses.isEmpty ? 0 : (lenses.single.widget as GlassLens).opacity;
}

double _pillOpacity(WidgetTester tester) => tester
    .widget<FadeTransition>(
      find.ancestor(of: find.byKey(const ValueKey('nav-selected-pill')), matching: find.byType(FadeTransition)).first,
    )
    .opacity
    .value;

Future<ValueNotifier<int>> hostNavigation(
  WidgetTester tester, {
  bool reduced = false,
  bool highContrast = false,
  GlassTier tier = GlassTier.solid,
  TextDirection direction = TextDirection.rtl,
  List<int>? changes,
  List<bool>? reselections,
  double keyboard = 0,
  ValueNotifier<bool>? keyboardOpen,
  double textScale = 1,
  List<Widget>? branches,
  Widget? aboveBar,
}) async {
  final branch = ValueNotifier(1);
  addTearDown(branch.dispose);
  Widget buildColumn(int index, bool isKeyboardOpen) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (branches != null)
        SizedBox(
          height: 100,
          child: FikraBranchContainer(index: index, children: branches),
        ),
      FloatingNavigation(
        branch: index,
        keyboardOpen: isKeyboardOpen,
        aboveBar: aboveBar,
        onSelect: (index, reselect) {
          changes?.add(index);
          reselections?.add(reselect);
          branch.value = index;
        },
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        glassTierProvider(false).overrideWith((ref) => tier),
        glassTierProvider(true).overrideWith((ref) => GlassTier.solid),
        glassTimingsSourceProvider.overrideWithValue(FakeGlassTimings()),
      ],
      child: MaterialApp(
        theme: buildFikraTheme(Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ar'),
        home: MediaQuery(
          data: MediaQueryData(
            disableAnimations: reduced,
            highContrast: highContrast,
            viewInsets: EdgeInsets.only(bottom: keyboard),
            textScaler: TextScaler.linear(textScale),
          ),
          child: Directionality(
            textDirection: direction,
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 358,
                  child: ValueListenableBuilder<int>(
                    valueListenable: branch,
                    builder: (context, index, _) => keyboardOpen == null
                        ? buildColumn(index, keyboard > 0)
                        : ValueListenableBuilder<bool>(
                            valueListenable: keyboardOpen,
                            builder: (context, isKeyboardOpen, _) => buildColumn(index, isKeyboardOpen),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));
  return branch;
}

void main() {
  testWidgets('quick tap switches immediately with normal pill and zero lens opacity throughout and after', (
    tester,
  ) async {
    final changes = <int>[];
    final branch = await hostNavigation(tester, changes: changes);
    final pointer = await tester.startGesture(tester.getCenter(Tabs.finder(Tabs.links)));
    addTearDown(pointer.removePointer);
    await tester.pump();
    expect(branch.value, 2);
    expect(changes, [2]);
    expect(find.byKey(_lens), findsNothing);
    expect(_lensOpacity(tester), 0);
    expect(_pillOpacity(tester), 1);

    await tester.pump(const Duration(milliseconds: 80));
    expect(find.byKey(_lens), findsNothing);
    expect(_lensOpacity(tester), 0);

    await pointer.up();
    await tester.pump();
    expect(find.byKey(_lens), findsNothing);
    expect(_lensOpacity(tester), 0);
    expect(_pillOpacity(tester), 1);
    expect(tester.hasRunningAnimations, isFalse);

    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byKey(_lens), findsNothing);
    expect(_lensOpacity(tester), 0);
    expect(_pillOpacity(tester), 1);
    expect(changes, [2]);
  });

  testWidgets('hold of 200 ms or more engages the lens', (tester) async {
    await hostNavigation(tester);
    final pointer = await tester.startGesture(tester.getCenter(Tabs.finder(Tabs.links)));
    addTearDown(pointer.removePointer);
    await tester.pump();
    await tester.pump(kLensHoldDelay - const Duration(milliseconds: 1));
    expect(find.byKey(_lens), findsNothing);
    expect(_lensOpacity(tester), 0);

    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(_lens), findsOneWidget);
    expect(_lensOpacity(tester), 1);
    expect(tester.getSize(find.byKey(_lens)).height, 88);
    expect(tester.getCenter(find.byKey(_lens)).dx, closeTo(tester.getCenter(Tabs.finder(Tabs.links)).dx, 0.5));
    await pointer.up();
    await tester.pumpAndSettle();
  });

  testWidgets('horizontal slide before 200 ms engages the lens and follows the finger', (tester) async {
    final branch = await hostNavigation(tester);
    final pointer = await tester.startGesture(tester.getCenter(Tabs.finder(Tabs.notes)));
    addTearDown(pointer.removePointer);
    await tester.pump();
    expect(_lensOpacity(tester), 0);

    await pointer.moveBy(const Offset(-6, 0));
    await tester.pump();
    expect(_lensOpacity(tester), 0);

    final links = tester.getCenter(Tabs.finder(Tabs.links));
    await pointer.moveTo(links);
    await tester.pump();
    expect(find.byKey(_lens), findsOneWidget);
    expect(_lensOpacity(tester), 1);
    expect(tester.getCenter(find.byKey(_lens)).dx, closeTo(links.dx, 0.5));
    expect(branch.value, 2);
    await pointer.up();
    await tester.pumpAndSettle();
  });

  testWidgets('Add button has no BackdropFilter; bar and aboveBar share one stable sigma-16 key; lens uses another', (
    tester,
  ) async {
    final branch = await hostNavigation(
      tester,
      tier: GlassTier.frosted,
      aboveBar: const Glass(child: Text('capsule')),
    );
    expect(find.descendant(of: Tabs.addButton, matching: find.byType(BackdropFilter)), findsNothing);
    final barFilter = find.descendant(
      of: find.byKey(const ValueKey('floating-tab-bar')),
      matching: find.byType(BackdropFilter),
    );
    expect(barFilter, findsOneWidget);
    expect(tester.widget<BackdropFilter>(barFilter).filter, ImageFilter.blur(sigmaX: 16, sigmaY: 16));

    BackdropKey? keyOf(Element e) => (e.renderObject! as RenderBackdropFilter).backdropKey;
    final filters = find.byType(BackdropFilter).evaluate().map(keyOf).toList();
    expect(filters, hasLength(2));
    expect(filters[0], isNotNull);
    expect(filters[1], same(filters[0]));
    final pointer = await tester.startGesture(tester.getCenter(Tabs.finder(Tabs.links)));
    addTearDown(pointer.removePointer);
    await tester.pump();
    expect(branch.value, 2); // the down switched tabs and rebuilt the navigation
    await tester.pump(kLensHoldDelay);
    final inLens = find.descendant(of: find.byKey(_lens), matching: find.byType(BackdropFilter));
    final lensKey = keyOf(inLens.evaluate().single);
    final shared = find.byType(BackdropFilter).evaluate().where((e) => !inLens.evaluate().contains(e)).map(keyOf);
    expect(shared, hasLength(2));
    // A new key per rebuild would repaint both glass layers on every switch.
    expect(shared.first, same(filters[0]));
    expect(shared.last, same(shared.first));
    expect(lensKey, isNot(same(shared.first)));
    await pointer.up();
    await tester.pumpAndSettle();
  });

  testWidgets('tab bar drops BackdropFilter under solid tier, reduce motion and high contrast', (tester) async {
    for (final (tier, reduced, highContrast) in [
      (GlassTier.solid, false, false),
      (GlassTier.frosted, true, false),
      (GlassTier.frosted, false, true),
    ]) {
      await hostNavigation(tester, tier: tier, reduced: reduced, highContrast: highContrast);
      expect(find.byType(BackdropFilter), findsNothing);
    }
  });

  testWidgets('lens stays clamped at both bar ends while the finger is outside horizontally', (tester) async {
    await hostNavigation(tester);
    final bar = tester.getRect(find.byKey(const ValueKey('floating-tab-bar')));
    final pointer = await tester.startGesture(bar.center);
    addTearDown(pointer.removePointer);
    for (final x in [bar.right + 100, bar.left - 100]) {
      await pointer.moveTo(Offset(x, bar.center.dy));
      await tester.pump();
      final lens = tester.getRect(find.byKey(_lens));
      expect(lens.left, greaterThanOrEqualTo(bar.left - 5.01));
      expect(lens.right, lessThanOrEqualTo(bar.right + 5.01));
    }
    await pointer.up();
    await tester.pumpAndSettle();
  });

  testWidgets('slide switches live in order and haptics fire once per tab change', (tester) async {
    final calls = <MethodCall>[];
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(SystemChannels.platform, null));
    final changes = <int>[];
    final branch = await hostNavigation(tester, changes: changes);
    final pointer = await tester.startGesture(tester.getCenter(Tabs.finder(Tabs.notes)));
    addTearDown(pointer.removePointer);
    for (final tab in [Tabs.links, Tabs.ask, Tabs.links, Tabs.notes]) {
      await pointer.moveTo(tester.getCenter(Tabs.finder(tab)));
      await tester.pump();
      expect(branch.value, tab + 1); // still down
      await pointer.moveBy(const Offset(1, 0));
      await tester.pump(); // another move within the same tab causes no navigation
    }
    expect(changes, [2, 3, 2, 1]);
    expect(
      calls.where((c) => c.method == 'HapticFeedback.vibrate').map((c) => c.arguments),
      List.filled(4, 'HapticFeedbackType.selectionClick'),
    );
    await pointer.up();
    await tester.pumpAndSettle();
    expect(changes, [2, 3, 2, 1]);
  });

  testWidgets('pointer motion and live switching do not rebuild other branch children', (tester) async {
    final builds = List.filled(4, 0);
    await hostNavigation(tester, branches: [for (var i = 0; i < 4; i++) _BuildProbe(() => builds[i]++)]);
    final initial = List.of(builds);
    final pointer = await tester.startGesture(tester.getCenter(Tabs.finder(Tabs.notes)));
    addTearDown(pointer.removePointer);
    for (final tab in [Tabs.links, Tabs.ask, Tabs.links, Tabs.notes]) {
      final to = tester.getCenter(Tabs.finder(tab));
      await pointer.moveTo(to);
      await tester.pump();
      for (var step = 0; step < 10; step++) {
        await pointer.moveBy(const Offset(.5, 0));
        await tester.pump();
      }
      expect(builds, initial);
    }
    await pointer.up();
    await tester.pumpAndSettle();
    expect(builds, initial);
  });

  testWidgets('release springs onto final selected tab and fades immediately to its pill', (tester) async {
    await hostNavigation(tester);
    final pointer = await tester.startGesture(tester.getCenter(Tabs.finder(Tabs.notes)));
    addTearDown(pointer.removePointer);
    final linksCenter = tester.getCenter(Tabs.finder(Tabs.links));
    await pointer.moveTo(linksCenter + const Offset(15, 0));
    await tester.pump();
    await pointer.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    expect(find.byKey(_lens), findsOneWidget);
    expect(_lensOpacity(tester), inExclusiveRange(0.0, 1.0));
    expect((tester.getCenter(find.byKey(_lens)).dx - linksCenter.dx).abs(), lessThan(15));
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.byKey(_lens), findsNothing);
    expect(_lensOpacity(tester), 0);
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.getCenter(find.byKey(const ValueKey('nav-selected-pill'))).dx, linksCenter.dx);
  });

  testWidgets('release after hold fades the lens to zero within 150 ms plus a pump', (tester) async {
    await hostNavigation(tester);
    final pointer = await tester.startGesture(tester.getCenter(Tabs.finder(Tabs.links)));
    addTearDown(pointer.removePointer);
    await tester.pump();
    await tester.pump(kLensHoldDelay);
    expect(_lensOpacity(tester), 1);

    await pointer.up();
    await tester.pump();
    expect(_lensOpacity(tester), 1);
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byKey(_lens), findsNothing);
    expect(_lensOpacity(tester), 0);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('releasing before 200 ms cancels the hold timer so no late lens appears', (tester) async {
    await hostNavigation(tester);
    final pointer = await tester.startGesture(tester.getCenter(Tabs.finder(Tabs.links)));
    addTearDown(pointer.removePointer);
    await tester.pump(const Duration(milliseconds: 80));
    expect(_lensOpacity(tester), 0);

    await pointer.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byKey(_lens), findsNothing);
    expect(_lensOpacity(tester), 0);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('settle stops hidden animations once the lens finishes fading out', (tester) async {
    await hostNavigation(tester);
    final pointer = await tester.startGesture(tester.getCenter(Tabs.finder(Tabs.notes)));
    addTearDown(pointer.removePointer);
    await pointer.moveTo(tester.getCenter(Tabs.finder(Tabs.links)) + const Offset(30, 0));
    await tester.pump();
    await pointer.up();
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.byKey(_lens), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('a second finger neither steers navigation nor moves the lens', (tester) async {
    final changes = <int>[];
    final branch = await hostNavigation(tester, changes: changes);
    final first = await tester.startGesture(tester.getCenter(Tabs.finder(Tabs.notes)));
    addTearDown(first.removePointer);
    await tester.pump();
    final second = await tester.startGesture(tester.getCenter(Tabs.finder(Tabs.ask)));
    addTearDown(second.removePointer);
    for (var step = 0; step < 3; step++) {
      await second.moveBy(const Offset(10, 0));
      await tester.pump();
    }
    expect(changes, isEmpty);
    expect(_lensOpacity(tester), 0);
    await tester.pump(kLensHoldDelay);
    final lensX = tester.getCenter(find.byKey(_lens)).dx;
    await second.moveBy(const Offset(10, 0));
    await tester.pump();
    expect(changes, isEmpty);
    expect(tester.getCenter(find.byKey(_lens)).dx, lensX);
    await first.moveTo(tester.getCenter(Tabs.finder(Tabs.links)));
    await tester.pump();
    expect(changes, [2]);
    await second.up();
    await first.up();
    await tester.pumpAndSettle();
    expect(branch.value, 2);
    expect(changes, [2]);
  });

  testWidgets('external index change while a hold is pending cancels the lens', (tester) async {
    final changes = <int>[];
    final branch = await hostNavigation(tester, changes: changes);
    final pointer = await tester.startGesture(tester.getCenter(Tabs.finder(Tabs.links)));
    addTearDown(pointer.removePointer);
    await tester.pump(const Duration(milliseconds: 50));
    expect(changes, [2]);
    expect(branch.value, 2);
    expect(_lensOpacity(tester), 0);

    branch.value = 3; // e.g. deep link or TalkBack switch while hold timer is pending
    await tester.pump();
    await tester.pump(kLensHoldDelay + const Duration(milliseconds: 50));
    expect(find.byKey(_lens), findsNothing);
    expect(_lensOpacity(tester), 0);

    await pointer.up();
    await tester.pumpAndSettle();
    expect(branch.value, 3);
    expect(changes, [2]);
  });

  testWidgets('a tab change from elsewhere during a press is not reselected on release', (tester) async {
    final changes = <int>[];
    final branch = await hostNavigation(tester, changes: changes);
    final pointer = await tester.startGesture(tester.getCenter(Tabs.finder(Tabs.notes)));
    addTearDown(pointer.removePointer);
    await tester.pump();
    branch.value = 3; // e.g. a deep link to Ask
    await tester.pump();
    await pointer.moveBy(const Offset(2, 0));
    await pointer.up();
    await tester.pumpAndSettle();
    // A reselect here would reset the deep-linked branch to its root.
    expect(changes, isEmpty);
    expect(branch.value, 3);
    expect(find.byKey(_lens), findsNothing);
  });

  testWidgets('a tab change from elsewhere while settling moves the lens to it', (tester) async {
    final branch = await hostNavigation(tester);
    final pointer = await tester.startGesture(tester.getCenter(Tabs.finder(Tabs.notes)));
    addTearDown(pointer.removePointer);
    final linksCenter = tester.getCenter(Tabs.finder(Tabs.links));
    final askCenter = tester.getCenter(Tabs.finder(Tabs.ask));
    await pointer.moveTo(linksCenter + const Offset(15, 0));
    await tester.pump();
    await pointer.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    branch.value = 3;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 64));
    expect(find.byKey(_lens), findsOneWidget);
    expect(_lensOpacity(tester), inExclusiveRange(0.0, 1.0));
    expect(
      (tester.getCenter(find.byKey(_lens)).dx - askCenter.dx).abs(),
      lessThan((linksCenter.dx - askCenter.dx).abs()),
    );
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.byKey(_lens), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  for (final cancel in [true, false]) {
    testWidgets(cancel ? 'pointer cancel settles current tab' : 'vertical leave cancels and ignores reentry', (
      tester,
    ) async {
      final changes = <int>[];
      final branch = await hostNavigation(tester, changes: changes);
      final pointer = await tester.startGesture(tester.getCenter(Tabs.finder(Tabs.notes)));
      addTearDown(pointer.removePointer);
      await pointer.moveTo(tester.getCenter(Tabs.finder(Tabs.links)));
      await tester.pump();
      if (cancel) {
        await pointer.cancel();
      } else {
        await pointer.moveBy(const Offset(0, -110));
        await pointer.moveTo(tester.getCenter(Tabs.finder(Tabs.ask)));
        await pointer.up();
      }
      await tester.pumpAndSettle();
      expect(branch.value, 2);
      expect(changes, [2]);
      expect(find.byKey(_lens), findsNothing);
    });
  }

  testWidgets('pending hold timer cancels on pointer cancel, vertical escape, keyboard open, and dispose', (
    tester,
  ) async {
    final keyboardOpen = ValueNotifier(false);
    addTearDown(keyboardOpen.dispose);
    await hostNavigation(tester, keyboardOpen: keyboardOpen);

    // Pointer cancel before 200 ms.
    final cancelPointer = await tester.startGesture(tester.getCenter(Tabs.finder(Tabs.links)));
    addTearDown(cancelPointer.removePointer);
    await tester.pump(const Duration(milliseconds: 60));
    await cancelPointer.cancel();
    await tester.pump(kLensHoldDelay);
    expect(_lensOpacity(tester), 0);

    // Vertical escape before 200 ms.
    final escapePointer = await tester.startGesture(tester.getCenter(Tabs.finder(Tabs.ask)));
    addTearDown(escapePointer.removePointer);
    await tester.pump(const Duration(milliseconds: 60));
    await escapePointer.moveBy(const Offset(0, -110));
    await tester.pump(kLensHoldDelay);
    expect(_lensOpacity(tester), 0);
    await escapePointer.up();
    await tester.pump();

    // Keyboard opening before 200 ms.
    final kbPointer = await tester.startGesture(tester.getCenter(Tabs.finder(Tabs.notes)));
    addTearDown(kbPointer.removePointer);
    await tester.pump(const Duration(milliseconds: 60));
    keyboardOpen.value = true;
    await tester.pump();
    await tester.pump(kLensHoldDelay);
    expect(_lensOpacity(tester), 0);
    await kbPointer.up();
    keyboardOpen.value = false;
    await tester.pumpAndSettle();

    // Dispose while a hold timer is pending cancels the timer cleanly.
    final disposePointer = await tester.startGesture(tester.getCenter(Tabs.finder(Tabs.links)));
    addTearDown(disposePointer.removePointer);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(kLensHoldDelay);
  });

  for (final reason in ['vertical escape', 'external index change']) {
    testWidgets(
      'after drag cancellation by $reason, a second press with small vertical move shows no lens before 200 ms',
      (tester) async {
        final branch = await hostNavigation(tester);
        final first = await tester.startGesture(tester.getCenter(Tabs.finder(Tabs.notes)));
        addTearDown(first.removePointer);
        await first.moveTo(tester.getCenter(Tabs.finder(Tabs.links)));
        await tester.pump();
        expect(_lensOpacity(tester), 1);

        if (reason == 'vertical escape') {
          await first.moveBy(const Offset(0, -110));
        } else {
          branch.value = 3;
        }
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 160));
        expect(_lensOpacity(tester), 0);

        // Keep original finger down and start a fresh second press with a small vertical move.
        final second = await tester.startGesture(tester.getCenter(Tabs.finder(Tabs.notes)));
        addTearDown(second.removePointer);
        await tester.pump();
        await second.moveBy(const Offset(0, 6));
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.byKey(_lens), findsNothing);
        expect(_lensOpacity(tester), 0);

        await second.up();
        await first.up();
        await tester.pumpAndSettle();
        expect(_lensOpacity(tester), 0);
      },
    );
  }

  testWidgets('quick tap shows no lens, switches once and reselect returns to initial location', (tester) async {
    final changes = <int>[];
    final reselections = <bool>[];
    await hostNavigation(tester, changes: changes, reselections: reselections);
    await tester.tap(Tabs.finder(Tabs.links));
    await tester.pump();
    expect(find.byKey(_lens), findsNothing);
    expect(_lensOpacity(tester), 0);
    expect(_pillOpacity(tester), 1);
    await tester.pumpAndSettle();
    expect(find.byKey(_lens), findsNothing);
    await tester.tap(Tabs.finder(Tabs.links));
    await tester.pump();
    expect(find.byKey(_lens), findsNothing);
    await tester.pumpAndSettle();
    expect(changes, [2, 2]);
    expect(reselections, [false, true]);
  });

  testWidgets('reduce motion keeps tracking, with no icon scale or settle spring', (tester) async {
    final branch = await hostNavigation(tester, reduced: true);
    final pointer = await tester.startGesture(tester.getCenter(Tabs.finder(Tabs.notes)));
    addTearDown(pointer.removePointer);
    final target = tester.getCenter(Tabs.finder(Tabs.links));
    await pointer.moveTo(target + const Offset(10, 0));
    await tester.pump();
    expect(branch.value, 2);
    final scale = tester.widget<Transform>(
      find.descendant(of: Tabs.finder(Tabs.links), matching: find.byType(Transform)),
    );
    expect(scale.transform.getMaxScaleOnAxis(), 1);
    await pointer.up();
    await tester.pump();
    expect(tester.getCenter(find.byKey(_lens)).dx, target.dx);
    await tester.pumpAndSettle();
    expect(find.byKey(_lens), findsNothing);
  });

  testWidgets('TalkBack buttons expose selection and activate tabs and Add', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final branch = await hostNavigation(tester);
      for (var i = 0; i < 3; i++) {
        final data = tester.getSemantics(Tabs.finder(i)).getSemanticsData();
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.flagsCollection.isSelected, i == 0 ? Tristate.isTrue : Tristate.isFalse);
        expect(data.hasAction(SemanticsAction.tap), isTrue);
      }
      final l10n = lookupAppLocalizations(const Locale('ar'));
      tester.semantics.tap(find.semantics.byLabel(l10n.navAsk));
      await tester.pump();
      expect(branch.value, 3);
      expect(_lensOpacity(tester), 0);
      expect(tester.getSemantics(Tabs.addButton).label, l10n.navAdd);
      tester.semantics.tap(find.semantics.byLabel(l10n.navAdd));
      await tester.pumpAndSettle();
      expect(branch.value, 0);
      expect(find.byKey(const ValueKey('nav-selected-pill')), findsNothing);
      expect(tester.getSemantics(Tabs.addButton).flagsCollection.isSelected, Tristate.isTrue);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('keyboard hides and disables both controls', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final changes = <int>[];
      await hostNavigation(tester, keyboard: 300, changes: changes);
      expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity, 0);
      for (final control in [Tabs.finder(Tabs.links), Tabs.addButton]) {
        expect(control.hitTestable(), findsNothing);
        await tester.tap(control, warnIfMissed: false);
        await tester.pump();
      }
      expect(changes, isEmpty);
      expect(find.bySemanticsLabel(lookupAppLocalizations(const Locale('ar')).navAdd), findsNothing);
    } finally {
      semantics.dispose();
    }
  });

  for (final direction in TextDirection.values) {
    testWidgets('$direction orders Notes first and Add at the trailing edge at large text', (tester) async {
      await hostNavigation(tester, direction: direction, textScale: 3);
      final xs = [for (var i = 0; i < 3; i++) tester.getCenter(Tabs.finder(i)).dx];
      final addX = tester.getCenter(Tabs.addButton).dx;
      if (direction == TextDirection.rtl) {
        expect(xs[0], greaterThan(xs[1]));
        expect(xs[1], greaterThan(xs[2]));
        expect(addX, lessThan(xs[2]));
      } else {
        expect(xs[0], lessThan(xs[1]));
        expect(xs[1], lessThan(xs[2]));
        expect(addX, greaterThan(xs[2]));
      }
      for (var i = 0; i < 3; i++) {
        expect(tester.getSize(Tabs.finder(i)).width, greaterThanOrEqualTo(48));
      }
      expect(tester.takeException(), isNull);
    });
  }
}

class _BuildProbe extends StatelessWidget {
  const _BuildProbe(this.onBuild);
  final VoidCallback onBuild;
  @override
  Widget build(BuildContext context) {
    onBuild();
    return const SizedBox.expand();
  }
}
