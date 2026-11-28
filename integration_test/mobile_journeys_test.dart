// Real connected-client journeys on the already authenticated profile install.
// No provider overrides, credentials, sample responses or existing-note mutations.
// The only server writes belong to a newly created, uniquely named QA project.
import 'package:fikra/app/product_runtime.dart';
import 'package:fikra/app/providers.dart';
import 'package:fikra/features/account/session_controller.dart';
import 'package:fikra/features/conversation/conversation_controller.dart';
import 'package:fikra/features/workspace/note_graph.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:fikra/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

Future<void> waitFor(WidgetTester tester, bool Function() ready, String reason, {int seconds = 60}) async {
  final deadline = DateTime.now().add(Duration(seconds: seconds));
  while (!ready() && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 150));
  }
  expect(ready(), isTrue, reason: reason);
  await tester.pump(const Duration(milliseconds: 250));
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await waitFor(tester, () => finder.evaluate().isNotEmpty, 'Control is present');
  await tester.ensureVisible(finder.first);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(finder.first);
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> hideKeyboard(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  await waitFor(tester, () => tester.view.viewInsets.bottom == 0, 'Native keyboard closes', seconds: 15);
}

// Profile builds reject the debug-only '-1' text-input client ID used by
// WidgetTester.enterText. Drive the public IME client method instead: this runs
// the actual formatters/onChanged pipeline and leaves the Android IME attached.
Future<void> typeText(WidgetTester tester, Finder field, String text) async {
  final state = tester.state<EditableTextState>(editable(field));
  state.requestKeyboard();
  await tester.pump(const Duration(milliseconds: 300));
  state.updateEditingValue(
    TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
  expect(state.widget.controller.text, text);
}

AppLocalizations strings(WidgetTester tester) => tester.element(find.byType(Scaffold).first).l10n;
Finder keyed(String value) => find.byKey(ValueKey(value));
Finder editable(Finder root) => find.descendant(of: root, matching: find.byType(EditableText), matchRoot: true);

Future<void> checkNativeEditor(WidgetTester tester, Finder field, Finder action, TextDirection direction) async {
  await waitFor(tester, () => tester.view.viewInsets.bottom > 0, 'Real Android IME is open', seconds: 15);
  final state = tester.state<EditableTextState>(editable(field));
  expect(state.widget.textDirection, direction);
  expect(state.widget.focusNode.hasFocus, isTrue);
  final render = state.renderEditable;
  final caret = render
      .getLocalRectForCaret(state.widget.controller.selection.extent)
      .shift(render.localToGlobal(Offset.zero));
  final visibleBottom =
      (tester.view.physicalSize.height - tester.view.viewInsets.bottom) / tester.view.devicePixelRatio;
  expect(caret.top, greaterThanOrEqualTo(0));
  expect(caret.bottom, lessThanOrEqualTo(visibleBottom + 1), reason: 'Native keyboard must not cover the caret');
  expect(action.hitTestable(), findsOneWidget, reason: 'The action remains reachable with the native keyboard');
  expect(tester.getRect(action).bottom, lessThanOrEqualTo(visibleBottom + 1));
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('connected mobile journeys retain RTL input, drafts and real repository results', (tester) async {
    final checks = <String>[];
    binding.reportData = {'checks': checks, 'backend': 'existing connected API', 'complete': false};
    await app.main();
    await waitFor(tester, () => find.byType(MaterialApp).evaluate().isNotEmpty, 'App starts');
    final container = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)), listen: false);
    final runtime = container.read(productRuntimeProvider);
    expect(container.read(appModeProvider), AppMode.connected);
    await waitFor(tester, () => runtime.session.stage != SessionStage.restoring, 'Existing session restores');
    expect(
      runtime.session.stage,
      SessionStage.authenticated,
      reason: 'Sign in on the normal profile app first; never enter secrets in this test',
    );
    await waitFor(
      tester,
      () => !runtime.workspace.loading && runtime.workspace.selected != null,
      'Real workspace loads',
    );
    checks.add('Existing authenticated session and workspace restored');
    final account = runtime.workspace.accountId!;
    final previousProject = runtime.workspace.selectedProjectId!;
    final previousLanguage = container.read(appLanguageProvider).value ?? AppLanguage.en;
    final previousTheme = container.read(appThemeProvider).value ?? AppTheme.system;
    final runName = 'FIKRAH QA ${DateTime.now().toUtc().millisecondsSinceEpoch}';
    String? ownedProject;
    String phase = 'Create isolated QA project';
    try {
      await tap(tester, keyed('nav-3'));
      await tap(tester, find.byTooltip(strings(tester).uiSettings));
      await tap(tester, keyed('manage-product-projects'));
      await tap(tester, keyed('new-product-project'));
      await typeText(tester, find.byType(TextField).last, runName);
      await tap(tester, find.text(strings(tester).productSave));
      await waitFor(
        tester,
        () => !runtime.workspace.busy && runtime.workspace.selected?.name == runName,
        'Project creation persisted on the real server',
      );
      ownedProject = runtime.workspace.selectedProjectId!;
      expect(ownedProject, isNot(previousProject));
      await hideKeyboard(tester);
      await tester.pageBack();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pageBack();
      await tester.pump(const Duration(milliseconds: 500));
      checks.add('Created isolated QA project through Settings');
      final ownedNotes = <String>[];
      for (final uiLanguage in [AppLanguage.ar, AppLanguage.en]) {
        for (final contentLanguage in ['ar', 'en']) {
          phase = 'Capture/edit ${uiLanguage.name} UI, $contentLanguage content';
          await tap(tester, keyed('nav-3'));
          await tap(
            tester,
            find.text(uiLanguage == AppLanguage.ar ? strings(tester).languageArabic : strings(tester).languageEnglish),
          );
          await waitFor(tester, () => container.read(appLanguageProvider).value == uiLanguage, 'Live language switch');
          final theme = contentLanguage == 'ar' ? AppTheme.light : AppTheme.dark;
          await tap(tester, find.text(theme == AppTheme.light ? strings(tester).rdLight : strings(tester).rdDark));
          await waitFor(tester, () => container.read(appThemeProvider).value == theme, 'Live theme switch');
          await tap(tester, keyed('nav-0'));
          await tap(tester, keyed('nav-add'));
          final field = keyed('capture-content-$ownedProject');
          await waitFor(tester, () => field.evaluate().isNotEmpty, 'Capture opens');
          expect(
            tester.state<EditableTextState>(editable(field)).widget.controller.text,
            isEmpty,
            reason: 'A new idea must not contain an earlier recording or draft',
          );
          final uiDirection = uiLanguage == AppLanguage.ar ? TextDirection.rtl : TextDirection.ltr;
          expect(tester.state<EditableTextState>(editable(field)).widget.textDirection, uiDirection);
          final body = contentLanguage == 'ar'
              ? 'الـ Deep Learning يعني إيه؟ 🌟 محمد @ Microsoft. رابط https://example.com/qa (12 kg).\n'
                        'خطة اختبار: نتعلم الشبكات العصبية ونراجع الملاحظات كل يوم.\n' *
                    6
              : 'Deep Learning study plan 🌟 محمد @ Microsoft. URL https://example.com/qa (12 kg).\n'
                        'Review neural networks and save useful thoughts every day.\n' *
                    6;
          await tap(tester, field);
          await typeText(tester, field, body);
          await tester.pump(const Duration(milliseconds: 700));
          await checkNativeEditor(
            tester,
            field,
            keyed('save-product-note'),
            contentLanguage == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          );
          await hideKeyboard(tester);
          await tap(tester, find.byTooltip(strings(tester).rdCancel));
          await tap(tester, keyed('nav-add'));
          expect(
            tester.state<EditableTextState>(editable(field)).widget.controller.text,
            body,
            reason: 'Closing and reopening retains the real encrypted draft',
          );
          await tap(tester, field);
          await typeText(tester, field, body);
          await tester.pump(const Duration(milliseconds: 700));
          await checkNativeEditor(
            tester,
            field,
            keyed('save-product-note'),
            contentLanguage == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          );
          await tap(tester, keyed('save-product-note'));
          await waitFor(
            tester,
            () =>
                !runtime.workspace.busy &&
                runtime.workspace.notes.any((n) => !ownedNotes.contains(n.id) && n.content == body.trim()),
            'Save persists the intended content once',
            seconds: 90,
          );
          await hideKeyboard(tester);
          final note = runtime.workspace.notes.firstWhere(
            (n) => !ownedNotes.contains(n.id) && n.content == body.trim(),
          );
          ownedNotes.add(note.id);
          expect(runtime.workspace.notes.where((n) => n.content == body.trim()).length, 1);
          await tap(tester, keyed('product-note-${note.id}'));
          await waitFor(
            tester,
            () => !runtime.workspace.detailLoading && runtime.workspace.detail?.id == note.id,
            'Note detail returns the saved note',
          );
          expect(runtime.workspace.detail!.content, body.trim());
          await tap(tester, keyed('note-menu'));
          await tap(tester, find.text(strings(tester).productEditNote));
          final edited = '${body.trim()}\n${contentLanguage == 'ar' ? 'تعديل محفوظ 123.' : 'Persisted edit 123.'}';
          await tap(tester, keyed('edit-content'));
          await typeText(tester, keyed('edit-content'), edited);
          await tester.pump(const Duration(milliseconds: 700));
          await checkNativeEditor(
            tester,
            keyed('edit-content'),
            keyed('save-note-edit'),
            contentLanguage == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          );
          await tap(tester, keyed('save-note-edit'));
          await waitFor(
            tester,
            () => !runtime.workspace.busy && runtime.workspace.detail?.content == edited,
            'Note edit persists on the real API',
          );
          await hideKeyboard(tester);
          final server = await runtime.repository.readNote(account, note.id);
          expect(server.content, edited);
          if (runtime.workspace.supportsFavorite) {
            await tap(tester, keyed('note-menu'));
            await tap(tester, find.text(strings(tester).rdPin));
            await waitFor(
              tester,
              () => !runtime.workspace.busy && runtime.workspace.detail?.isFavorite == true,
              'Pin persists',
            );
            expect((await runtime.repository.readNote(account, note.id)).isFavorite, isTrue);
          }
          await tap(tester, find.byTooltip(strings(tester).rdHome));
          checks.add(phase);
        }
      }
      phase = 'Real search, graph and conversation';
      await tap(tester, keyed('nav-0'));
      final search = keyed('search-$ownedProject');
      await typeText(tester, search, 'neural networks');
      await waitFor(
        tester,
        () => !runtime.workspace.searching && runtime.workspace.results != null,
        'Debounced search returns a real response',
      );
      expect(runtime.workspace.searchFailure, isNull);
      await typeText(tester, search, '');
      await hideKeyboard(tester);
      await waitFor(
        tester,
        () => runtime.workspace.notes.any((n) => !n.processing.pending),
        'Background processing reaches a terminal state',
        seconds: 120,
      );
      await tap(tester, keyed('nav-1'));
      await waitFor(tester, () => !runtime.workspace.graphLoading, 'Graph loads', seconds: 90);
      expect(runtime.workspace.graphFailure, isNull);
      expect(runtime.workspace.graph.nodes, isNotEmpty, reason: 'Real processed notes are available on the graph');
      final graphNote = runtime.workspace.graph.nodes.first.id;
      await tester.drag(find.byType(ProductNoteGraph), const Offset(18, 10));
      await tester.pump(const Duration(milliseconds: 500));
      await tap(tester, keyed('graph-node-$graphNote'));
      await tap(tester, find.text(strings(tester).rdOpen));
      await waitFor(
        tester,
        () => !runtime.workspace.detailLoading && runtime.workspace.detail?.id == graphNote,
        'A graph node opens the corresponding real note',
      );
      final original = runtime.workspace.detail!;
      if (original.proposal != null && original.proposal!.trim().isNotEmpty) {
        await tap(tester, keyed('accept-proposal'));
        await tap(tester, find.text(strings(tester).rdUndo));
        await waitFor(tester, () => runtime.undo.forNote(graphNote) == null, 'Apply is undone before commit');
        expect((await runtime.repository.readNote(account, graphNote)).content, original.content);
        checks.add('Real refinement proposal Apply/Undo preserves the server content');
      } else {
        binding.reportData!['proposalTest'] = 'Not available from the real API in this run';
      }
      await tap(tester, keyed('note-menu'));
      await tap(tester, find.text(strings(tester).rdDel));
      await tap(tester, find.text(strings(tester).rdDel).last);
      await tap(tester, find.text(strings(tester).rdUndo));
      await waitFor(tester, () => !runtime.undo.hiddenIds.contains(graphNote), 'Delete is undone before commit');
      expect((await runtime.repository.readNote(account, graphNote)).id, graphNote);
      checks.add('Real search, graph pan/open and Delete/Undo completed');
      await tap(tester, keyed('nav-2'));
      expect(find.text(strings(tester).rdScope), findsNothing);
      await tap(tester, keyed('new-conversation'));
      await waitFor(tester, () => !runtime.chat.loading && runtime.chat.current != null, 'Conversation created');
      final question = 'لخّص خطة Deep Learning في الملاحظات، مع ذكر المصدر إن وجد؟';
      await tap(tester, keyed('chat-question'));
      await typeText(tester, keyed('chat-question'), question);
      await tester.pump(const Duration(milliseconds: 700));
      await checkNativeEditor(tester, keyed('chat-question'), keyed('send-chat'), TextDirection.rtl);
      await tap(tester, keyed('send-chat'));
      await waitFor(
        tester,
        () => runtime.chat.sendState != SendState.sending,
        'SSE reaches a terminal state',
        seconds: 180,
      );
      expect(runtime.chat.failure, isNull);
      expect(runtime.chat.sendState, SendState.idle);
      expect(runtime.chat.current!.messages.any((m) => m.role == 'user' && m.content == question), isTrue);
      expect(runtime.chat.current!.messages.any((m) => m.role == 'assistant' && m.content.trim().isNotEmpty), isTrue);
      await hideKeyboard(tester);
      await tap(tester, keyed('conversation-history'));
      final conversationId = runtime.chat.current!.conversation.id;
      await tap(tester, keyed('open-conversation-$conversationId'));
      await waitFor(tester, () => !runtime.chat.loading, 'Authoritative conversation history reopens');
      await tap(tester, keyed('conversation-history'));
      await tap(tester, find.text(strings(tester).productDeleteConversation2));
      await tap(tester, find.text(strings(tester).productDelete));
      await waitFor(tester, () => runtime.chat.current == null && !runtime.chat.loading, 'QA conversation deleted');
      checks.add('Real SSE response, mixed Arabic composer, history reopening and deletion');
      expect(tester.takeException(), isNull);
      binding.reportData!['complete'] = true;
    } finally {
      binding.reportData!['lastPhase'] = phase;
      // Restore preferences and selection even when a real service or assertion fails.
      await hideKeyboard(tester);
      await container.read(settingsRepoProvider).setLanguage(previousLanguage);
      await container.read(settingsRepoProvider).setTheme(previousTheme);
      final owned = runtime.workspace.projects.where((p) => p.id == ownedProject && p.name == runName && !p.isGeneral);
      if (ownedProject != null && owned.length == 1 && runtime.session.account?.id == account) {
        await runtime.repository.deleteProject(account, ownedProject);
        binding.reportData!['qaProjectRemoved'] = true;
      }
      await runtime.workspace.openAccount(account);
      if (runtime.workspace.projects.any((p) => p.id == previousProject)) {
        await runtime.workspace.selectProject(previousProject);
      }
      binding.reportData!['preferencesRestored'] = true;
    }
  }, timeout: const Timeout(Duration(minutes: 12)));
}
