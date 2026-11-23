import 'package:fikra/l10n/localizations.dart';
import 'package:fikra/app/shell.dart';
import 'package:fikra/core/motion/motion.dart';
import 'package:fikra/core/motion/page_transitions.dart';
import 'package:fikra/core/motion/pressable.dart';
import 'package:fikra/core/theme/fikra_theme.dart';
import 'package:fikra/core/widgets/fikra_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsAction;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a labelled Pressable exposes a tap action to TalkBack', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: Pressable(
              onTap: () => taps++,
              semanticLabel: lookupAppLocalizations(const Locale('ar')).save,
              child: const SizedBox(width: 48, height: 48),
            ),
          ),
        ),
      );
      final node = tester.getSemantics(find.bySemanticsLabel(lookupAppLocalizations(const Locale('ar')).save));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      tester.semantics.tap(find.semantics.byLabel(lookupAppLocalizations(const Locale('ar')).save));
      expect(taps, 1);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('switcher: the outgoing child takes no taps during its exit', (tester) async {
    var taps = 0;
    final showButton = ValueNotifier(true);
    addTearDown(showButton.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder(
          valueListenable: showButton,
          builder: (context, show, _) => FikraSwitcher(
            child: show
                ? TextButton(key: const ValueKey('old'), onPressed: () => taps++, child: const Text('old'))
                : const SizedBox(key: ValueKey('new'), width: 10, height: 10),
          ),
        ),
      ),
    );
    showButton.value = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30)); // still visible, exiting
    expect(find.text('old'), findsOneWidget);
    await tester.tap(find.text('old'), warnIfMissed: false);
    expect(taps, 0);
    await tester.pumpAndSettle();
  });

  testWidgets('switcher: animateSize swaps states under Reduce Motion without a layout assertion', (tester) async {
    final tall = ValueNotifier(false);
    addTearDown(tall.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: ValueListenableBuilder(
            valueListenable: tall,
            builder: (context, isTall, _) => Align(
              alignment: Alignment.topCenter,
              child: FikraSwitcher(
                animateSize: true,
                child: isTall
                    ? const SizedBox(key: ValueKey('tall'), width: 10, height: 200)
                    : const SizedBox(key: ValueKey('short'), width: 10, height: 20),
              ),
            ),
          ),
        ),
      ),
    );
    tall.value = true;
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(FikraSwitcher)).height, 200);
    tall.value = false;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(FikraSwitcher)).height, 20);
  });

  testWidgets('switcher: toggling Reduce Motion keeps animateSize content and focus', (tester) async {
    final reduced = ValueNotifier(false);
    addTearDown(reduced.dispose);
    final focus = FocusNode();
    addTearDown(focus.dispose);
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ValueListenableBuilder(
            valueListenable: reduced,
            builder: (context, isReduced, _) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: isReduced),
              child: FikraSwitcher(
                animateSize: true,
                child: TextField(key: const ValueKey('field'), focusNode: focus, controller: controller),
              ),
            ),
          ),
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    final state = tester.state(find.byType(EditableText));
    for (final value in [true, false]) {
      reduced.value = value;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.state(find.byType(EditableText)), same(state));
      expect(focus.hasFocus, isTrue);
    }
  });

  testWidgets('branches preserve state and hide inactive text, focus, semantics and tickers', (tester) async {
    final index = ValueNotifier(0);
    addTearDown(index.dispose);
    final branches = [
      const _CounterBranch(key: ValueKey('first'), label: 'first'),
      const _CounterBranch(key: ValueKey('second'), label: 'second'),
    ];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFikraTheme(Brightness.dark),
        home: ValueListenableBuilder(
          valueListenable: index,
          builder: (context, value, _) => FikraBranchContainer(index: value, children: branches),
        ),
      ),
    );
    final firstState = tester.state(find.byType(_CounterBranch).first);
    await tester.tap(find.text('first: 0'));
    await tester.pump();
    expect(find.text('first: 1'), findsOneWidget);
    expect(find.text('second: 0'), findsNothing);
    expect(find.text('second: 0', skipOffstage: false), findsOneWidget);

    index.value = 1;
    await tester.pump();
    expect(find.text('first: 1'), findsOneWidget); // brief outgoing fade; already isolated
    expect(find.text('second: 0'), findsOneWidget);
    final hiddenContext = tester.element(find.text('first: 1', skipOffstage: false));
    expect(TickerMode.valuesOf(hiddenContext).enabled, isFalse);
    expect(Focus.of(hiddenContext).canRequestFocus, isFalse);
    final semantics = tester.ensureSemantics();
    try {
      await tester.pump(const Duration(milliseconds: 90));
      expect(find.semantics.byLabel('first: 1'), findsNothing);
      expect(find.semantics.byLabel('second: 0'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
    await tester.pumpAndSettle();

    index.value = 0;
    await tester.pumpAndSettle();
    expect(find.text('first: 1'), findsOneWidget);
    expect(tester.state(find.byType(_CounterBranch).first), same(firstState));
    expect(tester.binding.transientCallbackCount, 0);
  });

  for (final reduced in [false, true]) {
    testWidgets('branch opacity/scale ramps and reduces to one frame ($reduced)', (tester) async {
      final index = ValueNotifier(0);
      addTearDown(index.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: ValueListenableBuilder(
              valueListenable: index,
              builder: (_, value, _) =>
                  FikraBranchContainer(index: value, children: const [Text('first'), Text('second')]),
            ),
          ),
        ),
      );
      double opacity(int i) => tester.widget<FadeTransition>(find.byKey(ValueKey('branch-opacity-$i'))).opacity.value;
      double scale(int i) => tester.widget<ScaleTransition>(find.byKey(ValueKey('branch-scale-$i'))).scale.value;
      index.value = 1;
      await tester.pump();
      expect(opacity(1), reduced ? 1 : 0);
      expect(scale(1), reduced ? 1 : .98);
      if (!reduced) {
        await tester.pump(const Duration(milliseconds: 55));
        expect(opacity(1), inExclusiveRange(0.0, 1.0));
        expect(opacity(0), inExclusiveRange(0.0, 1.0));
        expect(scale(1), inExclusiveRange(.98, 1.0));
        await tester.pump(const Duration(milliseconds: 60));
        expect(find.text('first'), findsNothing);
        expect(opacity(1), lessThan(1));
        await tester.pump(const Duration(milliseconds: 120));
      }
      expect(opacity(1), 1);
      expect(scale(1), 1);
      expect(find.text('first'), findsNothing);
      expect(tester.binding.transientCallbackCount, 0);
    });
  }

  for (final direction in TextDirection.values) {
    testWidgets('push enters from logical end in $direction', (tester) async {
      final controller = AnimationController(vsync: tester, duration: FikraMotion.push);
      addTearDown(controller.dispose);
      final route = MaterialPageRoute<void>(builder: (_) => const SizedBox());
      addTearDown(route.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: direction,
            child: Builder(
              builder: (context) => const FikraPageTransitionsBuilder().buildTransitions(
                route,
                context,
                controller,
                kAlwaysDismissedAnimation,
                const SizedBox.expand(key: ValueKey('page')),
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('page'))).dx,
        direction == TextDirection.rtl ? -FikraMotion.pushOffset : FikraMotion.pushOffset,
      );
      controller.forward();
      await tester.pump();
      await tester.pump(FikraMotion.pushFade);
      final opacity = tester.widget<Opacity>(
        find.ancestor(of: find.byKey(const ValueKey('page')), matching: find.byType(Opacity)).first,
      );
      expect(opacity.opacity, 1);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byKey(const ValueKey('page'))).dx, 0);
    });
  }

  testWidgets('a pushed Material page keeps the full push timeline', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        theme: buildFikraTheme(Brightness.dark).copyWith(platform: TargetPlatform.android),
        home: const Text('home'),
      ),
    );
    final route = MaterialPageRoute<void>(builder: (_) => const Text('detail'));
    navigator.currentState!.push(route);
    await tester.pump();
    expect(route.transitionDuration, FikraMotion.push);
    await tester.pump(FikraMotion.push - const Duration(milliseconds: 1));
    expect(route.animation!.status, AnimationStatus.forward);
    expect(route.animation!.value, lessThan(1));
    await tester.pump(const Duration(milliseconds: 1));
    expect(route.animation!.value, closeTo(1, 0.001));
    await tester.pump(const Duration(milliseconds: 16));
    expect(route.animation!.status, AnimationStatus.completed);
    expect(route.animation!.value, 1);
    await tester.pumpAndSettle();
  });

  for (final reduced in [false, true]) {
    for (final trigger in ['Navigator.pop', 'app-bar back', 'system back', 'Android back button']) {
      testWidgets('$trigger fades without sliding and removes the page within the pop budget (reduced: $reduced)', (
        tester,
      ) async {
        final navigator = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigator,
            theme: buildFikraTheme(Brightness.dark).copyWith(platform: TargetPlatform.android),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
              child: child!,
            ),
            home: const Text('home'),
          ),
        );
        final route = MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(),
            body: const SizedBox.expand(key: ValueKey('popped-page')),
          ),
        );
        navigator.currentState!.push(route);
        await tester.pumpAndSettle();
        final page = find.byKey(const ValueKey('popped-page'), skipOffstage: false);
        final restingPosition = tester.getTopLeft(page);
        switch (trigger) {
          case 'Navigator.pop':
            navigator.currentState!.pop();
          case 'app-bar back':
            await tester.tap(find.byType(BackButton));
          case 'system back':
            await tester.binding.handlePopRoute();
          case 'Android back button':
            // Android 14 also sends button presses through this channel. A
            // zero touch offset must stay on the ordinary button-pop path.
            await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
              'flutter/backgesture',
              const StandardMethodCodec().encodeMethodCall(
                const MethodCall('startBackGesture', {
                  'touchOffset': <double>[0, 0],
                  'progress': 0.0,
                  'swipeEdge': 0,
                }),
              ),
              (_) {},
            );
            await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
              'flutter/backgesture',
              const StandardMethodCodec().encodeMethodCall(const MethodCall('commitBackGesture')),
              (_) {},
            );
        }
        await tester.pump();
        await tester.pump(FikraMotion.pop ~/ 2);
        expect(page, findsOneWidget);
        final halfwayPosition = tester.getTopLeft(page);
        final halfwayOpacity = tester
            .widget<Opacity>(find.ancestor(of: page, matching: find.byType(Opacity)).first)
            .opacity;
        await tester.pump(FikraMotion.pop ~/ 2);
        await tester.pump(const Duration(milliseconds: 16)); // final route disposal frame
        expect(FikraMotion.pop + const Duration(milliseconds: 16), lessThan(FikraMotion.push));
        expect(page, findsNothing);
        expect(halfwayPosition, restingPosition);
        expect(halfwayOpacity, closeTo(0.5, 0.01));
        expect(find.text('home'), findsOneWidget);
      });
    }
  }

  testWidgets('reduced pages use a 180 ms fade with no translation', (tester) async {
    final controller = AnimationController(vsync: tester, duration: FikraMotion.push, reverseDuration: FikraMotion.pop);
    addTearDown(controller.dispose);
    final route = MaterialPageRoute<void>(builder: (_) => const SizedBox());
    addTearDown(route.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) => const FikraPageTransitionsBuilder().buildTransitions(
              route,
              context,
              controller,
              kAlwaysDismissedAnimation,
              const SizedBox.expand(key: ValueKey('reduced-page')),
            ),
          ),
        ),
      ),
    );
    controller.forward();
    await tester.pump();
    await tester.pump(FikraMotion.reducedFade);
    double opacity() => tester
        .widget<Opacity>(
          find.ancestor(of: find.byKey(const ValueKey('reduced-page')), matching: find.byType(Opacity)).first,
        )
        .opacity;
    expect(opacity(), closeTo(1, 0.001));
    expect(tester.getTopLeft(find.byKey(const ValueKey('reduced-page'))), Offset.zero);
    await tester.pumpAndSettle();
    controller.reverse();
    await tester.pump();
    await tester.pump(FikraMotion.pop);
    expect(opacity(), closeTo(0, 0.001));
    expect(tester.getTopLeft(find.byKey(const ValueKey('reduced-page'))), Offset.zero);
    await tester.pumpAndSettle();
  });

  for (final reduced in [false, true]) {
    testWidgets('predictive back follows, cancels and commits continuously (reduced: $reduced)', (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          theme: buildFikraTheme(Brightness.dark).copyWith(platform: TargetPlatform.android),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: child!,
          ),
          home: const Text('home'),
        ),
      );
      Future<void> event(String method, [double? progress]) async {
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/backgesture',
          const StandardMethodCodec().encodeMethodCall(
            MethodCall(
              method,
              progress == null
                  ? null
                  : {
                      'touchOffset': <double>[5, 300],
                      'progress': progress,
                      'swipeEdge': 0,
                    },
            ),
          ),
          (_) {},
        );
        await tester.pump();
      }

      final page = find.byKey(const ValueKey('gesture-page'), skipOffstage: false);
      double opacity() => tester.widget<Opacity>(find.ancestor(of: page, matching: find.byType(Opacity)).first).opacity;
      // Late commits also exercise the translucent part of the entrance fade;
      // checking only halfway would miss a jump because opacity is still 1.
      for (final progress in [0.1, 0.5, 0.9, 1.0]) {
        final route = MaterialPageRoute<void>(builder: (_) => const SizedBox.expand(key: ValueKey('gesture-page')));
        navigator.currentState!.push(route);
        await tester.pumpAndSettle();
        final restingPosition = tester.getTopLeft(page);
        await event('startBackGesture', 0);
        await event('updateBackGestureProgress', progress);
        expect(route.animation!.value, closeTo(1 - progress, 0.001));
        final positionBeforeCancel = tester.getTopLeft(page);
        final opacityBeforeCancel = opacity();
        await event('cancelBackGesture');
        expect(tester.getTopLeft(page), positionBeforeCancel);
        expect(opacity(), closeTo(opacityBeforeCancel, 0.001));
        await tester.pumpAndSettle();
        expect(route.animation!.value, 1);
        expect(tester.getTopLeft(page), restingPosition);
        expect(opacity(), 1);
        expect(navigator.currentState!.userGestureInProgress, isFalse);

        await event('startBackGesture', 0);
        await event('updateBackGestureProgress', progress);
        final positionBeforeCommit = tester.getTopLeft(page);
        final opacityBeforeCommit = opacity();
        await event('commitBackGesture');
        if (progress < 1) {
          expect(tester.getTopLeft(page), positionBeforeCommit);
          expect(opacity(), closeTo(opacityBeforeCommit, 0.001));
          await tester.pump(FikraMotion.pop ~/ 2);
          final remaining = (1 - progress) / 2;
          final fade = Interval(
            0,
            (reduced ? FikraMotion.reducedFade : FikraMotion.pushFade).inMilliseconds / FikraMotion.push.inMilliseconds,
          );
          expect(opacity(), closeTo(fade.transform(remaining), 0.001));
          expect(
            tester.getTopLeft(page),
            reduced
                ? restingPosition
                : restingPosition +
                      Offset(FikraMotion.pushOffset * (1 - FikraMotion.pushCurve.transform(remaining)), 0),
          );
          await tester.pump(FikraMotion.pop ~/ 2);
        }
        await tester.pump(const Duration(milliseconds: 16));
        expect(page, findsNothing);
        expect(find.text('home'), findsOneWidget);
        expect(navigator.currentState!.userGestureInProgress, isFalse);
      }
    });
  }

  testWidgets('dialog dismiss returns false and confirmation returns true', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    late BuildContext pageContext;
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: buildFikraTheme(Brightness.dark),
        home: Builder(
          builder: (context) {
            pageContext = context;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    final dismissed = confirmDestructive(pageContext, title: 'title', message: 'message');
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(await dismissed, isFalse);
    final confirmed = confirmDestructive(pageContext, title: 'title', message: 'message');
    await tester.pumpAndSettle();
    await tester.tap(find.text(lookupAppLocalizations(const Locale('ar')).delete));
    await tester.pumpAndSettle();
    expect(await confirmed, isTrue);
  });
}

class _CounterBranch extends StatefulWidget {
  const _CounterBranch({super.key, required this.label});
  final String label;

  @override
  State<_CounterBranch> createState() => _CounterBranchState();
}

class _CounterBranchState extends State<_CounterBranch> {
  int count = 0;

  @override
  Widget build(BuildContext context) => Center(
    child: TextButton(onPressed: () => setState(() => count++), child: Text('${widget.label}: $count')),
  );
}
