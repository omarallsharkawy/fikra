import 'package:fikra/data/product/development/development_knowledge.dart';
import 'package:fikra/data/product/models.dart';
import 'package:fikra/features/workspace/note_graph.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart' show loadAppFonts;
import 'navigation_test.dart' show boot, cleanup, tapVisible;

class GraphLoadRepository extends DevelopmentKnowledgeRepository {
  GraphLoadRepository() : super(stepDelay: Duration.zero);
  bool fail = true, empty = false;
  @override
  Future<KnowledgeGraph> graph(String accountId, String projectId) async {
    if (fail) throw const ProductFailure(FailureKind.unavailable);
    return empty ? const KnowledgeGraph() : super.graph(accountId, projectId);
  }
}

void main() {
  setUpAll(loadAppFonts);
  for (final lang in ['en', 'ar']) {
    testWidgets('graph selection, drag, camera controls and note navigation: $lang', (tester) async {
      final r = await boot(tester, locale: Locale(lang));
      await r.session.login('reader@example.invalid', 'fixture-only');
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const ValueKey('nav-1')));
      final l = tester.element(find.byType(Scaffold).first).l10n;
      expect(find.text(l.rdLinks(2, 1)), findsOneWidget);
      expect(find.text(l.rdHint), findsOneWidget);
      await tapVisible(tester, find.text(l.rdOk));
      expect(find.text(l.rdHint), findsNothing);
      final id = r.workspace.graph.nodes.first.id;
      final node = find.byKey(ValueKey('graph-node-$id'));
      expect(tester.getSize(node).width, greaterThanOrEqualTo(44));
      expect(tester.getSize(node).height, greaterThanOrEqualTo(44));
      await tapVisible(tester, node);
      expect(find.text(l.rdOpen), findsOneWidget);
      final before = tester.getCenter(node);
      await tester.drag(node, const Offset(35, 25));
      await tester.pumpAndSettle();
      expect((tester.getCenter(node) - before).distance, greaterThan(10));
      final viewport = find.descendant(of: find.byType(ProductNoteGraph), matching: find.byType(AspectRatio));
      final other = find.byKey(ValueKey('graph-node-${r.workspace.graph.nodes.last.id}'));
      final separation = (tester.getCenter(node) - tester.getCenter(other)).distance;
      final origin = tester.getTopLeft(viewport);
      final left = await tester.startGesture(origin + const Offset(50, 15), pointer: 1);
      final right = await tester.startGesture(origin + const Offset(110, 15), pointer: 2);
      await left.moveBy(const Offset(-30, 0));
      await right.moveBy(const Offset(30, 0));
      await tester.pump();
      await left.up();
      await right.up();
      await tester.pumpAndSettle();
      expect((tester.getCenter(node) - tester.getCenter(other)).distance, greaterThan(separation * 1.2));
      await tester.longPressAt(tester.getTopLeft(viewport) + const Offset(10, 10));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text(l.uiZoomOut));
      await tapVisible(tester, find.text(l.uiZoomOut));
      await tapVisible(tester, find.text(l.uiFitIdeas));
      expect(tester.getSize(node).width, greaterThanOrEqualTo(44));
      await tapVisible(tester, find.text(l.rdOpen));
      expect(r.workspace.detail!.id, id);
      expect(tester.takeException(), isNull);
      await cleanup(tester);
    });
  }
  testWidgets('graph recovers from a typed error and handles an empty authoritative result', (tester) async {
    final repo = GraphLoadRepository();
    final r = await boot(tester, knowledge: repo);
    await r.session.login('reader@example.invalid', 'fixture-only');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const ValueKey('nav-1')));
    final l = tester.element(find.byType(Scaffold).first).l10n;
    expect(r.workspace.graphFailure, isNotNull);
    expect(find.text(l.productNoCompletedNotesInThisProjectYet), findsNothing);
    expect(find.text(l.productThisServiceIsUnavailableYourInputHasBeen), findsOneWidget);
    repo.fail = false;
    await tapVisible(tester, find.text(l.productReloadRetry));
    expect(find.byType(ProductNoteGraph), findsOneWidget);
    repo.empty = true;
    await r.workspace.loadGraph();
    await tester.pumpAndSettle();
    expect(find.byType(ProductNoteGraph), findsNothing);
    expect(find.text(l.productNoCompletedNotesInThisProjectYet), findsOneWidget);
    expect(find.text(l.rdLinks(0, 0)), findsOneWidget);
    expect(tester.takeException(), isNull);
    await cleanup(tester);
  });
}
