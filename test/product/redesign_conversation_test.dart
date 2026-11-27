import 'dart:async';

import 'package:fikra/core/widgets/redesign_widgets.dart';
import 'package:fikra/data/product/development/development_knowledge.dart';
import 'package:fikra/data/product/models.dart';
import 'package:fikra/features/conversation/conversation_screen.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart' show loadAppFonts;
import 'navigation_test.dart' show boot, cleanup, tapVisible;

class StreamingRepository extends DevelopmentKnowledgeRepository {
  StreamingRepository() : super(stepDelay: Duration.zero);
  int creates = 0, deletes = 0;
  final sent = <String>[];
  final stream = StreamController<ChatEvent>();
  late Conversation created;
  ConversationHistory? completed;
  @override
  Future<Conversation> createConversation(String accountId, String projectId) async {
    creates++;
    return created = await super.createConversation(accountId, projectId);
  }

  @override
  Stream<ChatEvent> send(String accountId, String conversationId, String text) {
    sent.add(text);
    return stream.stream;
  }

  void finish(KnowledgeNote note) {
    final user = KnowledgeMessage(
      id: 'server-user',
      role: 'user',
      content: sent.single,
      supported: null,
      createdAt: DateTime(2026),
    );
    final reply = KnowledgeMessage(
      id: 'server-answer',
      role: 'assistant',
      content: 'An authoritative repository answer.',
      supported: true,
      createdAt: DateTime(2026),
      sources: [NoteSourceReference(note.id, note.title)],
    );
    completed = ConversationHistory(created, [user, reply]);
    stream.add(ChatComplete(created, user, reply));
  }

  @override
  Future<ConversationHistory> history(String accountId, String conversationId) async =>
      completed?.conversation.id == conversationId ? completed! : await super.history(accountId, conversationId);
  @override
  Future<void> deleteConversation(String accountId, String conversationId) async {
    deletes++;
    await super.deleteConversation(accountId, conversationId);
    completed = null;
  }
}

void main() {
  setUpAll(loadAppFonts);
  for (final lang in ['en', 'ar']) {
    testWidgets('Ask creates only on intent, renders the stream and real citations, and manages history: $lang', (
      tester,
    ) async {
      final repo = StreamingRepository(), r = await boot(tester, knowledge: repo, locale: Locale(lang));
      addTearDown(repo.stream.close);
      await r.session.login('reader@example.invalid', 'fixture-only');
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const ValueKey('nav-2')));
      final l = tester.element(find.byType(Scaffold).first).l10n;
      expect(repo.creates, 0);
      expect(find.text(l.rdScope), findsOneWidget);
      expect(tester.getTopLeft(find.text(l.rdScope)).dy, greaterThan(0));
      await tapVisible(tester, find.text(l.rdChips0));
      expect(repo.creates, 1);
      expect(repo.sent, [l.rdChips0]);
      repo.stream.add(const ChatDelta('An actual streaming fragment'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('chat-preview')), findsOneWidget);
      expect(find.text(l.rdBased(3)), findsNothing);
      await tester.enterText(find.byKey(const ValueKey('chat-question')), 'My next question');
      repo.finish(r.workspace.notes.first);
      await tester.pumpAndSettle();
      expect(r.chat.draft, 'My next question');
      expect(find.byKey(const ValueKey('chat-preview')), findsNothing);
      expect(find.text('An authoritative repository answer.'), findsOneWidget);
      expect(find.text(l.rdBased(1)), findsOneWidget);

      final confirm = rdConfirm(
        tester.element(find.byType(ProductConversationScreen)),
        title: 'Confirmation',
        message: 'Stay on this screen',
        confirm: 'Continue',
      );
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text(l.rdCancel));
      expect(await confirm, isFalse);
      expect(find.byType(ProductConversationScreen), findsOneWidget);
      expect(r.chat.draft, 'My next question');
      r.chat.updateDraft('');
      await tester.pumpAndSettle();
      final note = r.workspace.notes.first;
      await tapVisible(tester, find.byKey(ValueKey('chat-source-${note.id}')));
      expect(r.workspace.detail!.id, note.id);
      await tapVisible(tester, find.byTooltip(l.rdHome));
      await tapVisible(tester, find.byKey(const ValueKey('conversation-history')));
      await tapVisible(tester, find.byKey(ValueKey('open-conversation-${repo.created.id}')));
      expect(find.text('An authoritative repository answer.'), findsOneWidget);
      await tapVisible(tester, find.byKey(const ValueKey('conversation-history')));
      await tapVisible(tester, find.text(l.productDeleteConversation2));
      await tapVisible(tester, find.text(l.productDelete));
      expect(repo.deletes, 1);
      expect(r.chat.current, isNull);
      expect(r.workspace.notes, hasLength(2));
      expect(tester.takeException(), isNull);
      await cleanup(tester);
    });
  }
}
