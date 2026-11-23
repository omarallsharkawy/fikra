import 'dart:async';

import 'package:drift/native.dart';
import 'package:fikra/app/providers.dart';
import 'package:fikra/core/theme/fikra_theme.dart';
import 'package:fikra/data/ai/ai_service.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/features/ask/ask_screen.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'support/app_harness.dart';

class _SpyChatRepository implements ChatRepository {
  _SpyChatRepository(this._inner);
  final LocalChatRepository _inner;
  Completer<void>? addGate;
  bool failAdd = false;
  final added = <({String projectId, String role, String body})>[];

  @override
  Stream<List<ChatEntry>> watch(String projectId) => _inner.watch(projectId);

  @override
  Future<void> add({
    required String projectId,
    required String role,
    required String body,
    List<String> sourceIds = const [],
    bool found = true,
  }) async {
    added.add((projectId: projectId, role: role, body: body));
    final gate = addGate;
    if (gate != null && !gate.isCompleted) await gate.future;
    if (failAdd) throw StateError('disk full');
    return _inner.add(projectId: projectId, role: role, body: body, sourceIds: sourceIds, found: found);
  }

  @override
  Future<void> clear(String projectId) => _inner.clear(projectId);
}

class _ControlledAi implements AiService {
  final gates = <String, Completer<ChatAnswer>>{};
  bool failNext = false;

  @override
  Future<NoteInsights> analyze(Note note, List<Note> projectNotes) async =>
      const NoteInsights(title: 't', concepts: [], cluster: 'c', links: []);

  @override
  Future<ChatAnswer> ask(String question, List<Note> projectNotes) async {
    final gate = gates[question];
    if (gate != null) return gate.future;
    if (failNext) {
      failNext = false;
      throw StateError('ai failed');
    }
    return ChatAnswer(text: 'Answer: $question', sourceIds: const [], found: true);
  }
}

void main() {
  Future<({FikraDatabase db, _SpyChatRepository chat, _ControlledAi ai, ProviderContainer container})> hostAsk(
    WidgetTester tester,
  ) async {
    await initializeDateFormatting();
    final db = FikraDatabase(NativeDatabase.memory());
    final chat = _SpyChatRepository(LocalChatRepository(db));
    final ai = _ControlledAi();
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        chatRepoProvider.overrideWithValue(chat),
        aiServiceProvider.overrideWithValue(ai),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildFikraTheme(Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const Scaffold(body: AskScreen()),
        ),
      ),
    );
    return (db: db, chat: chat, ai: ai, container: container);
  }

  Future<void> teardownAsk(WidgetTester tester, FikraDatabase db, ProviderContainer container) async {
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await tester.pump(Duration.zero);
    await pumpFuture(tester, db.close);
  }

  Finder inputField() => find.byType(TextField);
  Finder sendButton() => find.bySemanticsLabel(lookupAppLocalizations(const Locale('en')).send);

  testWidgets('unchanged input clears after user message stores', (tester) async {
    final env = await hostAsk(tester);
    try {
      await pumpFuture(tester, () => env.container.read(projectsRepoProvider).create('Alpha'));
      await tester.pump();
      await tester.enterText(inputField(), 'First question');
      await tester.pump();
      await tester.tap(sendButton());
      await tester.pump();
      await pumpUntil(tester, find.text('Answer: First question'));
      expect(tester.widget<TextField>(inputField()).controller!.text, isEmpty);
    } finally {
      await teardownAsk(tester, env.db, env.container);
    }
  });

  testWidgets('retyped draft while chat.add is in flight survives completion', (tester) async {
    final env = await hostAsk(tester);
    try {
      await pumpFuture(tester, () => env.container.read(projectsRepoProvider).create('Alpha'));
      await tester.pump();
      final gate = env.chat.addGate = Completer<void>();
      addTearDown(() {
        if (!gate.isCompleted) gate.complete();
      });

      await tester.enterText(inputField(), 'First question');
      await tester.pump();
      await tester.tap(sendButton());
      await tester.pump();

      // User starts typing the next draft before chat.add finishes.
      await tester.enterText(inputField(), 'Next draft typed mid-flight');
      await tester.pump();

      gate.complete();
      await pumpUntil(tester, find.text('Answer: First question'));
      expect(tester.widget<TextField>(inputField()).controller!.text, 'Next draft typed mid-flight');
    } finally {
      await teardownAsk(tester, env.db, env.container);
    }
  });

  testWidgets('failing chat.add preserves the draft and shows error toast', (tester) async {
    final env = await hostAsk(tester);
    try {
      await pumpFuture(tester, () => env.container.read(projectsRepoProvider).create('Alpha'));
      await tester.pump();
      env.chat.failAdd = true;

      await tester.enterText(inputField(), 'Keep me on failure');
      await tester.pump();
      await tester.tap(sendButton());
      await tester.pump();
      await tester.pump();

      expect(tester.widget<TextField>(inputField()).controller!.text, 'Keep me on failure');
      expect(find.text(lookupAppLocalizations(const Locale('en')).askFailed), findsOneWidget);
    } finally {
      await teardownAsk(tester, env.db, env.container);
    }
  });

  testWidgets('preset suggestion does not clear manual text in the composer', (tester) async {
    final env = await hostAsk(tester);
    try {
      final project = await pumpFuture(tester, () => env.container.read(projectsRepoProvider).create('Alpha'));
      await pumpFuture(
        tester,
        () => env.container
            .read(notesRepoProvider)
            .create(projectId: project.id, title: 'Design notes', text: 'Body', source: NoteSource.text),
      );
      final chipText = lookupAppLocalizations(const Locale('en')).askSuggestion('Design notes');
      await pumpUntil(tester, find.text(chipText));

      await tester.enterText(inputField(), 'Manual draft');
      await tester.pump();
      await tester.tap(find.text(chipText));
      await tester.pump();
      await pumpUntil(tester, find.text('Answer: $chipText'));

      expect(tester.widget<TextField>(inputField()).controller!.text, 'Manual draft');
    } finally {
      await teardownAsk(tester, env.db, env.container);
    }
  });

  testWidgets('project B is not blocked by project A request and ignores A failure toast', (tester) async {
    final env = await hostAsk(tester);
    try {
      final projects = env.container.read(projectsRepoProvider);
      final projectA = await pumpFuture(tester, () => projects.create('Project A'));
      final projectB = await pumpFuture(tester, () => projects.create('Project B'));
      await pumpFuture(tester, () => projects.setCurrent(projectA.id));
      await tester.pump();

      final gateA = env.ai.gates['Question A'] = Completer<ChatAnswer>();
      addTearDown(() {
        if (!gateA.isCompleted) gateA.complete(const ChatAnswer(text: 'Late A', sourceIds: [], found: true));
      });

      await tester.enterText(inputField(), 'Question A');
      await tester.pump();
      await tester.tap(sendButton());
      await tester.pump();
      expect(find.byKey(const ValueKey('thinking')), findsOneWidget);

      // Switch to project B while A is still awaiting AI.
      await pumpFuture(tester, () => projects.setCurrent(projectB.id));
      await pumpUntil(tester, find.text('Project B'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('thinking')), findsNothing);

      // Project B can send immediately and receives its own answer.
      await tester.enterText(inputField(), 'Question B');
      await tester.pump();
      await tester.tap(sendButton());
      await tester.pump();
      await pumpUntil(tester, find.text('Answer: Question B'));

      // Project A failing while viewing project B must not show an error toast in B.
      gateA.completeError(StateError('network error'));
      await tester.pump();
      await tester.pump();
      expect(find.text(lookupAppLocalizations(const Locale('en')).askFailed), findsNothing);
      expect(env.chat.added.where((e) => e.projectId == projectA.id && e.role == 'user'), hasLength(1));
      expect(env.chat.added.where((e) => e.projectId == projectB.id && e.role == 'assistant'), hasLength(1));
    } finally {
      await teardownAsk(tester, env.db, env.container);
    }
  });
}
