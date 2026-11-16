import 'dart:ui' show Tristate;

import 'package:fikra/app/tab_bar/floating_navigation.dart';
import 'package:fikra/app/shell.dart' show FikraBranchContainer;
import 'package:fikra/core/theme/fikra_theme.dart';
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

Future<ValueNotifier<int>> hostNavigation(
  WidgetTester tester, {
  bool reduced = false,
  GlassTier tier = GlassTier.solid,
  TextDirection direction = TextDirection.rtl,
  List<int>? changes,
  List<bool>? reselections,
  double keyboard = 0,
  double textScale = 1,
  List<Widget>? branches,
}) async {
  final branch = ValueNotifier(1);
  addTearDown(branch.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        glassTierProvider(false).overrideWith((ref) => tier),
        glassTierProvider(true).overrideWith((ref) => GlassTier.frosted),
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
                    builder: (context, index, _) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (branches != null)
                          SizedBox(
                            height: 100,
                            child: FikraBranchContainer(index: index, children: branches),
                          ),
                        FloatingNavigation(
                          branch: index,
                          keyboardOpen: keyboard > 0,
                          onSelect: (index, reselect) {
                            changes?.add(index);
                            reselections?.add(reselect);
                            branch.value = index;
                          },
                        ),
                      ],
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
  testWidgets('down shows lens on the next frame without waiting for drag slop', (tester) async {
    await hostNavigation(tester);
    final pointer = await tester.startGesture(tester.getCenter(Tabs.finder(Tabs.links)));
    addTearDown(pointer.removePointer);
    await tester.pump(); // exactly one frame after down
    expect(find.byKey(_lens), findsOneWidget);
    expect(tester.widget<GlassLens>(find.byType(GlassLens)).opacity, 1);
    expect(tester.getSize(find.byKey(_lens)).height, 88);
    await pointer.up();
    await tester.pumpAndSettle();
  });

  testWidgets('bar and Add share one stable backdrop key and overlapping lens uses a separate key', (tester) async {
    final branch = await hostNavigation(tester, tier: GlassTier.frosted);
    BackdropKey? keyOf(Element e) => (e.renderObject! as RenderBackdropFilter).backdropKey;
    final filters = find.byType(BackdropFilter).evaluate().map(keyOf).toList();
    expect(filters, hasLength(2));
    expect(filters[0], isNotNull);
    expect(filters[1], same(filters[0]));
    final pointer = await tester.startGesture(tester.getCenter(Tabs.finder(Tabs.links)));
    addTearDown(pointer.removePointer);
    await tester.pump();
    expect(branch.value, 2); // the down switched tabs and rebuilt the navigation
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

  testWidgets('release springs onto final selected tab and fades to its pill', (tester) async {
    await hostNavigation(tester);
    final pointer = await tester.startGesture(tester.getCenter(Tabs.finder(Tabs.notes)));
    addTearDown(pointer.removePointer);
    await pointer.moveTo(tester.getCenter(Tabs.finder(Tabs.links)) + const Offset(15, 0));
    await tester.pump();
    await pointer.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.getCenter(find.byKey(_lens)).dx, closeTo(tester.getCenter(Tabs.finder(Tabs.links)).dx, 3));
    await tester.pumpAndSettle();
    expect(find.byKey(_lens), findsNothing);
    expect(
      tester.getCenter(find.byKey(const ValueKey('nav-selected-pill'))).dx,
      tester.getCenter(Tabs.finder(Tabs.links)).dx,
    );
  });

  testWidgets('settle ends at pixel tolerance, so the lens is gone soon after release', (tester) async {
    await hostNavigation(tester);
    final pointer = await tester.startGesture(tester.getCenter(Tabs.finder(Tabs.notes)));
    addTearDown(pointer.removePointer);
    await pointer.moveTo(tester.getCenter(Tabs.finder(Tabs.links)) + const Offset(30, 0));
    await tester.pump();
    await pointer.up();
    // ~0.4 s spring + 140 ms fade. The default 0.001 px tolerance kept the
    // lens (and its backdrop pass) on screen for over a second.
    for (var frame = 0; frame < 45; frame++) {
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
    final lensX = tester.getCenter(find.byKey(_lens)).dx;
    final second = await tester.startGesture(tester.getCenter(Tabs.finder(Tabs.ask)));
    addTearDown(second.removePointer);
    for (var step = 0; step < 3; step++) {
      await second.moveBy(const Offset(2, 0));
      await tester.pump();
    }
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
    await pointer.moveTo(tester.getCenter(Tabs.finder(Tabs.links)) + const Offset(15, 0));
    await tester.pump();
    await pointer.up();
    await tester.pump(const Duration(milliseconds: 16));
    branch.value = 3;
    for (var frame = 0; frame < 22; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(tester.getCenter(find.byKey(_lens)).dx, closeTo(tester.getCenter(Tabs.finder(Tabs.ask)).dx, 3));
    await tester.pumpAndSettle();
    expect(find.byKey(_lens), findsNothing);
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

  testWidgets('quick tap pulses, switches once and reselect returns to initial location', (tester) async {
    final changes = <int>[];
    final reselections = <bool>[];
    await hostNavigation(tester, changes: changes, reselections: reselections);
    await tester.tap(Tabs.finder(Tabs.links));
    await tester.pump();
    expect(find.byKey(_lens), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byKey(_lens), findsNothing);
    await tester.tap(Tabs.finder(Tabs.links));
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
    expect(tester.getSemantics(Tabs.addButton).label, l10n.navAdd);
    tester.semantics.tap(find.semantics.byLabel(l10n.navAdd));
    await tester.pumpAndSettle();
    expect(branch.value, 0);
    expect(find.byKey(const ValueKey('nav-selected-pill')), findsNothing);
    expect(tester.getSemantics(Tabs.addButton).flagsCollection.isSelected, Tristate.isTrue);
    semantics.dispose();
  });

  testWidgets('keyboard hides and disables both controls', (tester) async {
    final semantics = tester.ensureSemantics();
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
    semantics.dispose();
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
