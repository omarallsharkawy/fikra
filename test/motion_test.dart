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
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Pressable(onTap: () => taps++, semanticLabel: 'حفظ', child: const SizedBox(width: 48, height: 48)),
        ),
      ),
    );
    final node = tester.getSemantics(find.bySemanticsLabel('حفظ'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    tester.semantics.tap(find.semantics.byLabel('حفظ'));
    expect(taps, 1);
    semantics.dispose();
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

  testWidgets('branches preserve state and hide inactive text, focus, semantics and tickers', (tester) async {
    final index = ValueNotifier(0);
    addTearDown(index.dispose);
    final branches = [
      const _CounterBranch(key: ValueKey('first'), label: 'first'),
      const _CounterBranch(key: ValueKey('second'), label: 'second'),
    ];
    await tester.pumpWidget(
      MaterialApp(
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
    expect(find.text('first: 1'), findsNothing); // also during the entrance
    expect(find.text('second: 0'), findsOneWidget);
    final hiddenContext = tester.element(find.text('first: 1', skipOffstage: false));
    expect(TickerMode.valuesOf(hiddenContext).enabled, isFalse);
    expect(Focus.of(hiddenContext).canRequestFocus, isFalse);
    final semantics = tester.ensureSemantics();
    await tester.pump(const Duration(milliseconds: 90));
    expect(find.bySemanticsLabel('first: 1'), findsNothing);
    expect(find.bySemanticsLabel('second: 0'), findsOneWidget);
    semantics.dispose();
    await tester.pumpAndSettle();

    index.value = 0;
    await tester.pumpAndSettle();
    expect(find.text('first: 1'), findsOneWidget);
    expect(tester.state(find.byType(_CounterBranch).first), same(firstState));
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('reduced tab changes only fade and settle in 180 ms', (tester) async {
    final index = ValueNotifier(0);
    addTearDown(index.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: ValueListenableBuilder(
            valueListenable: index,
            builder: (context, value, _) =>
                FikraBranchContainer(index: value, children: const [Text('first'), Text('second')]),
          ),
        ),
      ),
    );
    index.value = 1;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    final scale = tester.widget<ScaleTransition>(
      find.descendant(of: find.byType(FikraBranchContainer), matching: find.byType(ScaleTransition)),
    );
    expect(scale.scale.value, 1);
    final fade = tester.widget<FadeTransition>(
      find.descendant(of: find.byType(FikraBranchContainer), matching: find.byType(FadeTransition)),
    );
    expect(fade.opacity.value, closeTo(0.5, 0.01));
    await tester.pump(const Duration(milliseconds: 90));
    await tester.pump(const Duration(milliseconds: 16)); // one frame for the ticker to stop
    expect(tester.binding.transientCallbackCount, 0);
  });

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

  testWidgets('reduced pages use a 180 ms fade with no translation', (tester) async {
    final controller = AnimationController(vsync: tester, duration: FikraMotion.push);
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
    final fades = tester.widgetList<FadeTransition>(
      find.ancestor(of: find.byKey(const ValueKey('reduced-page')), matching: find.byType(FadeTransition)),
    );
    expect(fades.map((fade) => fade.opacity.value), everyElement(closeTo(1, 0.001)));
    expect(tester.getTopLeft(find.byKey(const ValueKey('reduced-page'))), Offset.zero);
    await tester.pumpAndSettle();
    controller.reverse();
    await tester.pump();
    await tester.pump(FikraMotion.reducedFade);
    final outgoingFades = tester.widgetList<FadeTransition>(
      find.ancestor(of: find.byKey(const ValueKey('reduced-page')), matching: find.byType(FadeTransition)),
    );
    expect(outgoingFades.any((fade) => fade.opacity.value < 0.001), isTrue);
    expect(tester.getTopLeft(find.byKey(const ValueKey('reduced-page'))), Offset.zero);
    await tester.pumpAndSettle();
  });

  testWidgets('predictive back can cancel and commit without losing the page', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        theme: buildFikraTheme(Brightness.dark).copyWith(platform: TargetPlatform.android),
        home: const Text('home'),
      ),
    );
    navigator.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Text('detail')));
    await tester.pumpAndSettle();
    final route = ModalRoute.of(tester.element(find.text('detail')))!;

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

    await event('startBackGesture', 0);
    await event('updateBackGestureProgress', 0.5);
    expect(route.animation!.value, closeTo(0.5, 0.01));
    await event('cancelBackGesture');
    await tester.pumpAndSettle();
    expect(route.animation!.value, 1);
    expect(find.text('detail'), findsOneWidget);
    await event('startBackGesture', 0);
    await event('updateBackGestureProgress', 0.5);
    await event('commitBackGesture');
    await tester.pumpAndSettle();
    expect(find.text('detail'), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('dialog dismiss returns false and confirmation returns true', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    late BuildContext pageContext;
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
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
    await tester.tap(find.text('حذف'));
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
