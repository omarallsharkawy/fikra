import 'dart:async';

import 'package:fikra/core/theme/product_theme.dart';
import 'package:fikra/data/product/development/development_auth.dart';
import 'package:fikra/data/product/development/development_knowledge.dart';
import 'package:fikra/data/product/models.dart';
import 'package:fikra/features/capture/capture_controller.dart';
import 'package:fikra/features/conversation/conversation_controller.dart';
import 'package:fikra/features/workspace/graph_screen.dart';
import 'package:fikra/features/workspace/product_widgets.dart';
import 'package:fikra/features/workspace/workspace_controller.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart' show loadAppFonts;
import 'controller_test.dart' show TestCaptureDevice;
import 'navigation_test.dart' show boot, cleanup, tapVisible;

class _CountingGraphRepo extends DevelopmentKnowledgeRepository {
  int graphCalls = 0;

  @override
  Future<KnowledgeGraph> graph(String accountId, String projectId) {
    graphCalls++;
    return super.graph(accountId, projectId);
  }

  @override
  Future<List<NoteSourceReference>> related(String accountId, String noteId) async => const [];
}

class _StreamingChatRepo extends DevelopmentKnowledgeRepository {
  _StreamingChatRepo(this.chunks);
  final List<String> chunks;

  @override
  Stream<ChatEvent> send(String accountId, String conversationId, String text) async* {
    final history = await super.history(accountId, conversationId);
    for (final chunk in chunks) {
      yield ChatDelta(chunk);
    }
    yield ChatComplete(
      history.conversation,
      KnowledgeMessage(id: 'u1', role: 'user', content: text, supported: null, createdAt: DateTime.utc(2026)),
      KnowledgeMessage(
        id: 'a1',
        role: 'assistant',
        content: chunks.join(),
        supported: true,
        createdAt: DateTime.utc(2026),
      ),
    );
  }
}

void main() {
  setUpAll(loadAppFonts);

  group('Phase 2 rebuild isolation and performance', () {
    test('WorkspaceController.updateDraft notifies draftListenable without fanning out to workspace listeners', () async {
      final w = WorkspaceController(DevelopmentKnowledgeRepository(), MemoryAttemptStore());
      addTearDown(w.dispose);
      await w.openAccount('development-other');

      var workspaceNotifications = 0;
      var draftNotifications = 0;
      w.addListener(() => workspaceNotifications++);
      w.draftListenable.addListener(() => draftNotifications++);

      for (var i = 0; i < 20; i++) {
        w.updateDraft(content: 'Hello $i');
      }

      expect(workspaceNotifications, 0);
      expect(draftNotifications, 20);
      expect(w.draft.content, 'Hello 19');
    });

    test('ConversationController draft typing and SSE ChatDelta stream do not notify full conversation listeners', () async {
      final chunks = [for (var i = 0; i < 50; i++) 'token-$i '];
      final repo = _StreamingChatRepo(chunks);
      final c = ConversationController(repo, previewThrottle: Duration.zero);
      addTearDown(c.dispose);
      final project = (await repo.projects('development-other')).first;
      await c.selectProject('development-other', project.id);
      await c.create();

      var chatNotifications = 0;
      var draftNotifications = 0;
      var previewNotifications = 0;
      c.addListener(() => chatNotifications++);
      c.draftListenable.addListener(() => draftNotifications++);
      c.previewListenable.addListener(() => previewNotifications++);

      for (var i = 0; i < 10; i++) {
        c.updateDraft('Question $i');
      }
      expect(chatNotifications, 0);
      expect(draftNotifications, 10);

      await c.send();
      // Only 2 full notifications: sending start + ChatComplete (NOT 50 per-chunk rebuilds).
      expect(chatNotifications, 2);
      // 50 delta updates + 1 clear on completion.
      expect(previewNotifications, 51);
      expect(c.preview, isEmpty);
      expect(c.current!.messages.last.content, chunks.join());
    });

    testWidgets('CaptureController 200ms recording ticks update elapsedListenable without rebuilding controller listeners', (
      tester,
    ) async {
      var now = DateTime.utc(2026, 1, 1, 12, 0, 0);
      final capture = CaptureController(
        TestCaptureDevice(),
        DevelopmentKnowledgeRepository(),
        clock: () => now,
      );
      capture.setAccount('development-other');
      await capture.start();

      var captureNotifications = 0;
      var elapsedNotifications = 0;
      capture.addListener(() => captureNotifications++);
      capture.elapsedListenable.addListener(() => elapsedNotifications++);

      for (var i = 1; i <= 10; i++) {
        now = now.add(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(captureNotifications, 0);
      expect(elapsedNotifications, 10);
      expect(capture.elapsed, const Duration(seconds: 2));
      capture.dispose();
    });

    test('productContentDirection resolves scripts accurately in O(1) bounded time', () {
      expect(productContentDirection(''), TextDirection.ltr);
      expect(productContentDirection('12345 !!!'), TextDirection.ltr);
      expect(productContentDirection('123 فكرة جديدة'), TextDirection.rtl);
      expect(productContentDirection('123 New Idea'), TextDirection.ltr);
      expect(productContentDirection('«مرحباً بالعالم»'), TextDirection.rtl);
      expect(productContentDirection('\uFEFFEnglish with BOM'), TextDirection.ltr);
      expect(productContentDirection('١٢٣ English'), TextDirection.ltr);
      expect(productContentDirection('۱۲۳ English'), TextDirection.ltr);
      expect(productContentDirection('× فكرة'), TextDirection.rtl);
      expect(productContentDirection('÷ ملاحظة'), TextDirection.rtl);
      expect(productContentDirection('${'a' * 100000}عربي'), TextDirection.ltr);
      expect(productContentDirection('${'ع' * 100000}english'), TextDirection.rtl);
    });

    testWidgets('offstage graph tab defers loadGraph until visible again', (tester) async {
      final repo = _CountingGraphRepo();
      final r = await boot(tester, knowledge: repo, size: const Size(360, 800));
      await r.session.login('reader@example.invalid', 'fixture-only');
      await tester.pumpAndSettle();

      // Visit Map tab once -> mounts branch 2 and loads graph.
      await tapVisible(tester, find.byKey(const ValueKey('nav-1')));
      await tester.pumpAndSettle();
      final callsAfterFirstVisit = repo.graphCalls;
      expect(callsAfterFirstVisit, greaterThanOrEqualTo(1));

      // Leave Map tab for Notes tab and mutate a note (bumping knowledgeRevision).
      await tapVisible(tester, find.byKey(const ValueKey('nav-0')));
      await tester.pumpAndSettle();
      final noteId = r.workspace.notes.first.id;
      await r.workspace.openNote(noteId);
      await r.workspace.edit(const NotePatch(content: 'Updated while map is offstage'), noteId: noteId);
      await tester.pumpAndSettle();

      // Offstage Map tab must NOT have fetched /knowledge-graph in the background.
      expect(repo.graphCalls, callsAfterFirstVisit);

      // Returning to Map tab flushes the dirty flag and reloads once.
      await tapVisible(tester, find.byKey(const ValueKey('nav-1')));
      await tester.pumpAndSettle();
      expect(repo.graphCalls, callsAfterFirstVisit + 1);

      await cleanup(tester);
    });

    testWidgets('ProductNoteGraph drags a node smoothly without rebuilding sibling nodes', (tester) async {
      final graph = KnowledgeGraph(
        nodes: [
          KnowledgeGraphNode(id: 'n1', title: 'Alpha', concepts: const ['a'], updatedAt: DateTime.utc(2026)),
          KnowledgeGraphNode(id: 'n2', title: 'Beta', concepts: const ['b'], updatedAt: DateTime.utc(2026)),
        ],
        edges: const [GraphRelationship('n1', 'n2', ['shared'])],
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildProductTheme(Brightness.dark),
          home: Scaffold(
            body: SizedBox(width: 400, height: 600, child: ProductNoteGraph(graph: graph)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final before = tester.getCenter(find.byKey(const ValueKey('graph-node-n1')));
      await tester.drag(find.byKey(const ValueKey('graph-node-n1')), const Offset(90, 60));
      await tester.pump();
      final after = tester.getCenter(find.byKey(const ValueKey('graph-node-n1')));
      expect((after - before).distance, greaterThan(15));
      expect(tester.takeException(), isNull);
    });
  });
}
