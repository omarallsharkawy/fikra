import 'package:fikra/core/theme/fikra_theme.dart';
import 'package:fikra/features/connections/map_canvas.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'map_index_test.dart' show mapOf;
import 'support/links_library_data.dart';

void main() {
  testWidgets('painter caches transforms; invalidation disposes pictures for data, theme, locale and text scale', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    var index = mapOf([libraryNote('a'), libraryNote('b')], []);
    var level = index.overview();
    var brightness = Brightness.light;
    var locale = const Locale('en');
    var scale = 1.0;
    final activated = <String>[];
    Future<void> render() => tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildFikraTheme(brightness),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: MapCanvas(
                index: index,
                level: level,
                ego: false,
                selected: null,
                onNode: (n) => activated.add(n.id),
              ),
            ),
          ),
        ),
      ),
    );
    LinksMapPainter painter() =>
        tester.widget<CustomPaint>(find.byKey(const ValueKey('map-paint'))).painter! as LinksMapPainter;
    await render();
    final semantics = tester.ensureSemantics();
    try {
      await tester.pump();
      tester.semantics.tap(find.semantics.byLabel(RegExp('^Ideas, ')));
      expect(activated, ['topic:Ideas']);
      var previous = painter().picture;
      final controller = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer)).transformationController!;
      controller.value = Matrix4.translationValues(-10, -20, 0)..scaleByDouble(1.2, 1.2, 1.2, 1);
      await tester.pump();
      expect(painter().picture, same(previous));
      for (final change in [
        () {
          index = mapOf([libraryNote('a', title: 'Changed'), libraryNote('b')], []);
          level = index.overview();
        },
        () {
          index = mapOf(index.notes.values.toList(), [libraryLink('u', 'a', 'b')]);
          level = index.overview();
        },
        () {
          brightness = Brightness.dark;
        },
        () {
          locale = const Locale('ar');
        },
        () {
          scale = 2;
        },
      ]) {
        change();
        await render();
        await tester.pump(const Duration(milliseconds: 300));
        expect(painter().picture, isNot(same(previous)));
        expect(previous.debugDisposed, isTrue);
        previous = painter().picture;
      }
      await tester.pumpWidget(const SizedBox());
      expect(previous.debugDisposed, isTrue);
    } finally {
      semantics.dispose();
    }
  });
  testWidgets('dense ego starts at native size and preserves 2x text and 48dp targets', (tester) async {
    final index = mapOf(
      [for (var i = 0; i < 18; i++) libraryNote('n$i')],
      [
        for (var i = 1; i <= 13; i++) libraryLink('u$i', 'n0', 'n$i'),
        for (var i = 14; i < 18; i++) libraryLink('a$i', 'n0', 'n$i', confirmed: false),
      ],
    );
    final level = index.ego('n0');
    for (final scale in [1.0, 2.0]) {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildFikraTheme(Brightness.light),
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: SizedBox(
                  width: 360,
                  height: 600,
                  child: MapCanvas(
                    key: ValueKey(scale),
                    index: index,
                    level: level,
                    ego: true,
                    selected: 'n0',
                    onNode: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final painter = tester.widget<CustomPaint>(find.byKey(const ValueKey('map-paint'))).painter! as LinksMapPainter;
      final viewer = tester.widget<InteractiveViewer>(find.byKey(const ValueKey('map-viewport')));
      final zoom = viewer.transformationController!.value.getMaxScaleOnAxis();
      expect(zoom, 1);
      expect(painter.layout.nodeHeight, 76 * scale);
      expect(painter.layout.nodeHeight * zoom, greaterThanOrEqualTo(48));
      expect(painter.layout.nodeWidth * zoom, greaterThanOrEqualTo(48));
      final centre = painter.layout.positions['n0']!;
      final box = tester.renderObject<RenderBox>(find.byKey(const ValueKey('map-paint')));
      expect(
        (box.localToGlobal(Offset(centre.x, centre.y)) - tester.getCenter(find.byKey(const ValueKey('map-viewport'))))
            .distance,
        lessThan(.01),
      );
    }
  });
}
