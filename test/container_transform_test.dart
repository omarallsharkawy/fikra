import 'package:fikra/core/motion/container_transform.dart';
import 'package:fikra/core/motion/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderOpacity;
import 'package:flutter_test/flutter_test.dart';

const _textKey = ValueKey('page-text');
const _pageKey = ValueKey('page-size');
const _start = Rect.fromLTWH(20, 120, 350, 96);
const _full = Rect.fromLTWH(0, 0, 390, 844);

void _expectUnscaledPage(WidgetTester tester) {
  final text = find.byKey(_textKey);
  expect(text, findsOneWidget);
  expect(tester.getSize(find.byKey(_pageKey)), _full.size);
  expect(find.ancestor(of: text, matching: find.byType(FittedBox)), findsNothing);
  final transforms = tester.widgetList<Transform>(find.ancestor(of: text, matching: find.byType(Transform)));
  for (final transform in transforms) {
    final matrix = transform.transform;
    // Translation is allowed; the entire linear part must remain identity.
    for (var row = 0; row < 3; row++) {
      for (var column = 0; column < 3; column++) {
        expect(matrix.entry(row, column), closeTo(row == column ? 1 : 0, 0.000001));
      }
    }
  }
}

double _opacity(WidgetTester tester) =>
    tester.widget<Opacity>(find.ancestor(of: find.byKey(_textKey), matching: find.byType(Opacity))).opacity;

void _expectFlight(WidgetTester tester, double t, Rect origin) {
  _expectUnscaledPage(tester);
  final rect = tester.getRect(find.byKey(const ValueKey('note-container-transform')));
  final expected = Rect.lerp(origin, _full, t)!;
  expect(rect.left, closeTo(expected.left, 0.001));
  expect(rect.top, closeTo(expected.top, 0.001));
  expect(rect.width, closeTo(expected.width, 0.001));
  expect(rect.height, closeTo(expected.height, 0.001));
  final clip = tester.widget<ClipRRect>(find.ancestor(of: find.byKey(_textKey), matching: find.byType(ClipRRect)));
  expect(clip.clipBehavior, Clip.antiAlias);
  expect((clip.borderRadius as BorderRadius).topLeft.x, closeTo(24 * (1 - t), 0.000001));
  expect(
    _opacity(tester),
    closeTo(
      const Interval(FikraMotion.containerFadeStart, FikraMotion.containerFadeEnd, curve: Curves.easeOut).transform(t),
      0.000001,
    ),
  );
}

Future<BuildContext> _host(WidgetTester tester, {bool reduced = false, GlobalKey? sourceKey}) async {
  tester.view.physicalSize = _full.size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late BuildContext root;
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
        child: child!,
      ),
      home: Builder(
        builder: (context) {
          root = context;
          return Scaffold(
            body: Stack(
              children: [
                Positioned.fromRect(
                  rect: _start,
                  child: ContainerTransformSource(key: sourceKey, child: const Text('source card')),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
  return root;
}

PageRoute<void> _route(BuildContext context, {Rect? Function()? currentRect, CardOrigin? origin}) =>
    ContainerTransformPage<void>(
      origin: origin ?? CardOrigin(initialRect: _start, borderRadius: 24, currentRect: currentRect),
      child: const SizedBox.expand(
        key: _pageKey,
        child: Align(
          alignment: Alignment.topCenter,
          child: Text('حروف عربية ثابتة', key: _textKey),
        ),
      ),
    ).createRoute(context) as PageRoute<void>;

void main() {
  for (final reduced in [false, true]) {
    testWidgets('source card fades at paint time, restores on pop/disposal; reduced=$reduced', (tester) async {
      final sourceKey = GlobalKey();
      final root = await _host(tester, reduced: reduced, sourceKey: sourceKey);
      final source = tester.renderObject<RenderOpacity>(find.byKey(sourceKey));
      final origin = CardOrigin.fromContext(sourceKey.currentContext!)!;
      final navigator = Navigator.of(root);
      final route = _route(root, origin: origin);
      navigator.push(route);
      await tester.pump();
      for (final milliseconds in [8, 20, 40, 70]) {
        await tester.pump(Duration(milliseconds: milliseconds));
        expect(source.opacity, reduced ? 1 : closeTo(1 - _opacity(tester), 0.000001));
      }
      await tester.pump(FikraMotion.push);
      navigator.pop();
      await tester.pump();
      for (final milliseconds in [20, 30, 40]) {
        await tester.pump(Duration(milliseconds: milliseconds));
        expect(source.opacity, reduced ? 1 : closeTo(1 - _opacity(tester), 0.000001));
      }
      await tester.pump(FikraMotion.containerPop);
      expect(source.opacity, 1);

      final interrupted = _route(root, origin: origin);
      navigator.push(interrupted);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 90));
      navigator.removeRoute(interrupted);
      await tester.pump();
      expect(source.opacity, 1);
    });
  }

  testWidgets('clip and fade morph both ways while Arabic page text stays at final size and scale one', (tester) async {
    final root = await _host(tester);
    var liveOrigin = _start;
    final route = _route(root, currentRect: () => liveOrigin);
    final navigator = Navigator.of(root);
    navigator.push(route);
    await tester.pump();
    var lastWidth = _start.width;
    var lastOpacity = 0.0;
    for (final milliseconds in [0, 8, 12, 20, 30, 50, 100]) {
      await tester.pump(Duration(milliseconds: milliseconds));
      final raw = route.animation!.value;
      _expectFlight(tester, FikraMotion.pushCurve.transform(raw), _start);
      final width = tester.getSize(find.byKey(const ValueKey('note-container-transform'))).width;
      expect(width, greaterThanOrEqualTo(lastWidth));
      expect(_opacity(tester), greaterThanOrEqualTo(lastOpacity));
      lastWidth = width;
      lastOpacity = _opacity(tester);
    }
    expect(lastOpacity, 1);
    await tester.pump(FikraMotion.push);
    _expectUnscaledPage(tester);
    expect(find.byKey(const ValueKey('note-container-transform')), findsNothing);

    // Pop follows the live card, even if it moved since opening the page.
    liveOrigin = _start.translate(0, 40);
    navigator.pop();
    await tester.pump();
    lastWidth = _full.width;
    lastOpacity = 1;
    for (final milliseconds in [8, 20, 40, 50, 60, 70]) {
      await tester.pump(Duration(milliseconds: milliseconds));
      final raw = route.animation!.value;
      _expectFlight(tester, 1 - FikraMotion.pushCurve.transform(1 - raw), liveOrigin);
      final width = tester.getSize(find.byKey(const ValueKey('note-container-transform'))).width;
      expect(width, lessThanOrEqualTo(lastWidth));
      expect(_opacity(tester), lessThanOrEqualTo(lastOpacity));
      lastWidth = width;
      lastOpacity = _opacity(tester);
    }
    expect(lastOpacity, 0);
    await tester.pump(FikraMotion.containerPop);
    expect(find.byKey(_textKey), findsNothing);
  });

  testWidgets('Reduce Motion keeps the full rect, fade-only entrance and short pop fallback', (tester) async {
    final root = await _host(tester, reduced: true);
    final route = _route(root, currentRect: () => _start);
    final navigator = Navigator.of(root);
    navigator.push(route);
    await tester.pump();
    for (final milliseconds in [30, 30, 60, 60]) {
      await tester.pump(Duration(milliseconds: milliseconds));
      _expectUnscaledPage(tester);
      expect(tester.getRect(find.byKey(const ValueKey('ct-body'))), _full);
      expect(find.byKey(const ValueKey('note-container-transform')), findsNothing);
      expect(
        _opacity(tester),
        closeTo(
          (route.animation!.value * FikraMotion.push.inMilliseconds / FikraMotion.reducedFade.inMilliseconds).clamp(
            0,
            1,
          ),
          0.000001,
        ),
      );
      for (final transform in tester.widgetList<Transform>(
        find.ancestor(of: find.byKey(_textKey), matching: find.byType(Transform)),
      )) {
        expect(transform.transform.isIdentity(), isTrue);
      }
    }
    await tester.pump(FikraMotion.push);
    navigator.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    _expectUnscaledPage(tester);
    expect(_opacity(tester), closeTo(route.animation!.value, 0.000001));
    expect(find.byKey(const ValueKey('note-container-transform')), findsNothing);
    await tester.pump(FikraMotion.pop);
    expect(find.byKey(_textKey), findsNothing);
  });
}
