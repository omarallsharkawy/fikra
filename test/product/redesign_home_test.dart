import 'package:fikra/core/widgets/redesign_widgets.dart';
import 'package:fikra/data/product/development/development_knowledge.dart';
import 'package:fikra/data/product/models.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart' show loadAppFonts;
import 'auth_layout_test.dart' show fill;
import 'navigation_test.dart' show boot, cleanup, tapVisible;

class SearchSpy extends DevelopmentKnowledgeRepository {
  SearchSpy() : super(stepDelay: Duration.zero);
  final queries = <String>[];
  @override
  Future<List<NoteSearchResult>> search(String accountId, String projectId, String query) async {
    queries.add(query);
    return const [
      NoteSearchResult(noteId: 'from-api', title: 'Repository result', content: 'Retrieved content', score: 0.72),
    ];
  }
}

void main() {
  setUpAll(loadAppFonts);
  testWidgets('Home recovers from a load failure into the actual empty state', (tester) async {
    final repo = LoadStateRepository();
    final r = await boot(tester, knowledge: repo);
    await r.session.login('reader@example.invalid', 'fixture-only');
    await tester.pumpAndSettle();
    final l = tester.element(find.byType(Scaffold).first).l10n;
    expect(r.workspace.failure, isNotNull);
    expect(find.text(l.productThisServiceIsUnavailableYourInputHasBeen), findsOneWidget);
    repo.fail = false;
    await tapVisible(tester, find.text(l.productReloadRetry));
    expect(r.workspace.failure, isNull);
    expect(find.text(l.rdFirst), findsOneWidget);
    expect(find.text(l.rdStart), findsOneWidget);
    expect(tester.takeException(), isNull);
    await cleanup(tester);
  });
  for (final lang in ['en', 'ar']) {
    testWidgets('Home uses saved names, real repository search and separate local tags: $lang', (tester) async {
      final repo = SearchSpy();
      final r = await boot(tester, knowledge: repo, locale: Locale(lang));
      await r.session.login('reader@example.invalid', 'fixture-only');
      await tester.pumpAndSettle();
      final l = tester.element(find.byType(Scaffold).first).l10n;
      expect(find.text(l.rdNamePrompt), findsOneWidget);
      await tapVisible(tester, find.text(l.rdAddName));
      final name = find.byType(TextField).last;
      await tester.enterText(name, '  علاء  ');
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text(l.rdSave));
      expect(r.profile.name, 'علاء');
      expect(find.text(l.rdGreet(rdIsolate('علاء'))), findsOneWidget);
      expect(find.text(l.rdNamePrompt), findsNothing);
      final n = r.workspace.notes.first;
      final tag = await r.tags.create('Category');
      await r.tags.assign(n.id, {tag!.id});
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Category').first);
      expect(find.byKey(ValueKey('product-note-${n.id}')), findsOneWidget);
      expect(find.byKey(ValueKey('product-note-${r.workspace.notes.last.id}')), findsNothing);
      await tapVisible(tester, find.text(l.rdAll));
      await fill(tester, 'search-${r.workspace.selectedProjectId}', 'semantic query');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(repo.queries, ['semantic query']);
      expect(find.text('Repository result'), findsOneWidget);
      expect(find.textContaining('0.72'), findsNothing);
      await fill(tester, 'search-${r.workspace.selectedProjectId}', '');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(r.workspace.results, isNull);
      expect(repo.queries, ['semantic query']);
      expect(r.workspace.notes.length, 2);
      expect(tester.takeException(), isNull);
      await cleanup(tester);
    });
    testWidgets('older account name prompt appears once and another account stays private: $lang', (tester) async {
      final r = await boot(tester, locale: Locale(lang));
      await r.session.login('reader@example.invalid', 'fixture-only');
      await tester.pumpAndSettle();
      final l = tester.element(find.byType(Scaffold).first).l10n;
      expect(find.text(l.rdNeutralGreeting), findsOneWidget);
      expect(find.text(l.rdNamePrompt), findsOneWidget);
      await tapVisible(tester, find.text(l.rdLater));
      await r.session.signOut();
      await tester.pumpAndSettle();
      await r.session.login('reader@example.invalid', 'fixture-only');
      await tester.pumpAndSettle();
      expect(find.text(l.rdNamePrompt), findsNothing);
      await r.profile.setName('First account');
      await tester.pumpAndSettle();
      await r.session.signOut();
      await tester.pumpAndSettle();
      await r.session.login('other@example.invalid', 'fixture-only');
      await tester.pumpAndSettle();
      expect(find.textContaining('First account'), findsNothing);
      expect(find.text(l.rdFirst), findsOneWidget);
      expect(find.text(l.rdNamePrompt), findsOneWidget);
      expect(tester.takeException(), isNull);
      await cleanup(tester);
    });
  }
}

class LoadStateRepository extends DevelopmentKnowledgeRepository {
  LoadStateRepository() : super(stepDelay: Duration.zero);
  bool fail = true;
  @override
  Future<List<KnowledgeNote>> notes(String accountId, String projectId) async {
    if (fail) throw const ProductFailure(FailureKind.unavailable);
    return [];
  }
}
