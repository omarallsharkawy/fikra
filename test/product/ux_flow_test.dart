import 'package:fikra/l10n/localizations.dart';
import 'package:fikra/features/workspace/graph_screen.dart';
import 'package:fikra/features/account/session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart' show loadAppFonts;
import 'navigation_test.dart' show boot, cleanup, tapVisible;

void main() {
  setUpAll(loadAppFonts);
  for (final locale in [const Locale('en'), const Locale('ar')]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('capture saves without scrolling while keyboard is open (${locale.languageCode}, $scale)', (
        tester,
      ) async {
        final r = await boot(tester, locale: locale, scale: scale, size: const Size(360, 800));
        await r.session.login('other@example.invalid', 'fixture-only');
        await tester.pumpAndSettle();
        await tapVisible(tester, find.byKey(const ValueKey('nav-add')));
        final field = find.descendant(
          of: find.byKey(ValueKey('capture-content-${r.workspace.selectedProjectId}')),
          matching: find.byType(TextField),
        );
        await tester.ensureVisible(field);
        await tester.enterText(field, 'A thought with the keyboard open');
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        final save = find.byKey(const ValueKey('save-product-note'));
        expect(tester.getRect(save).bottom, lessThanOrEqualTo(500));
        expect(tester.getRect(save).top, greaterThan(0));
        expect(tester.takeException(), isNull);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(r.workspace.notes.single.content, 'A thought with the keyboard open');
        tester.view.resetViewInsets();
        tester.testTextInput.hide();
        await cleanup(tester);
      });
    }
  }
  for (final locale in [const Locale('en'), const Locale('ar')]) {
    testWidgets(
      'history opens confirmed messages and cancellation preserves the conversation (${locale.languageCode})',
      (tester) async {
        final r = await boot(tester, locale: locale, scale: 2, size: const Size(360, 800));
        await r.session.login('reader@example.invalid', 'fixture-only');
        await tester.pumpAndSettle();
        await tapVisible(tester, find.byKey(const ValueKey('nav-2')));
        await tapVisible(tester, find.byKey(const ValueKey('new-conversation')));
        final first = r.chat.current!.conversation.id;
        r.chat.updateDraft('Hello');
        await tester.pumpAndSettle();
        await tapVisible(tester, find.byKey(const ValueKey('send-chat')));
        await tapVisible(tester, find.byKey(const ValueKey('new-conversation')));
        r.chat.updateDraft('Unsent second draft');
        await tester.pumpAndSettle();
        final l10n = tester.element(find.byKey(const ValueKey('conversation-history'))).l10n;
        await tapVisible(tester, find.byKey(const ValueKey('conversation-history')));
        expect(r.chat.draft, 'Unsent second draft');
        await tapVisible(tester, find.byKey(ValueKey('open-conversation-$first')));
        expect(r.chat.current!.conversation.id, first);
        expect(r.chat.current!.messages.first.content, 'Hello');
        await tapVisible(tester, find.byKey(const ValueKey('conversation-history')));
        await tapVisible(tester, find.text(l10n.productDeleteConversation2));
        expect(find.byType(BottomSheet), findsOneWidget);
        await tapVisible(tester, find.text(l10n.cancel));
        expect(r.chat.current!.conversation.id, first);
        expect(r.chat.conversations.length, 2);
        await tapVisible(tester, find.text(l10n.productDeleteConversation2));
        await tapVisible(tester, find.text(l10n.productDelete));
        expect(r.chat.current, isNull);
        expect(r.chat.conversations.length, 1);
        expect(r.workspace.notes.length, 2);
        expect(tester.takeException(), isNull);
        await cleanup(tester);
      },
    );
  }
  testWidgets('recovery has stage-specific headings and returns to sign-in with cleared secrets', (tester) async {
    final r = await boot(tester);
    await tapVisible(tester, find.byKey(const ValueKey('auth-start-login')));
    await tester.enterText(
      find.descendant(of: find.byKey(const ValueKey('account-email')), matching: find.byType(TextField)),
      'reader@example.invalid',
    );
    await tapVisible(tester, find.text('Forgot password?'));
    expect(find.text('Reset your password'), findsOneWidget);
    await tapVisible(tester, find.text('Request reset'));
    expect(find.text('Reset requested'), findsOneWidget);
    await tapVisible(tester, find.text(tester.element(find.byType(Scaffold).first).l10n.apiHaveCode));
    expect(find.text('Choose a new password'), findsOneWidget);
    for (final (key, text) in [('account-password', 'new-fixture-password'), ('account-token', 'fixture-reset')]) {
      await tester.enterText(find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(TextField)), text);
    }
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Reset password'));
    expect(r.session.stage, SessionStage.unauthenticated);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(
            find.descendant(of: find.byKey(const ValueKey('account-password')), matching: find.byType(TextField)),
          )
          .controller!
          .text,
      isEmpty,
    );
    expect(tester.takeException(), isNull);
    await cleanup(tester);
  });
  testWidgets('map receives the main viewport without a project management form', (tester) async {
    final r = await boot(tester, size: const Size(360, 800));
    await r.session.login('reader@example.invalid', 'fixture-only');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const ValueKey('nav-1')));
    final graph = find.byType(ProductNoteGraph);
    expect(tester.getSize(graph).height, greaterThanOrEqualTo(tester.getSize(graph).width));
    expect(find.byKey(const ValueKey('new-product-project')), findsNothing);
    expect(tester.takeException(), isNull);
    await cleanup(tester);
  });
  testWidgets('note editing keeps explicit save reachable above the keyboard', (tester) async {
    final r = await boot(tester, size: const Size(360, 800));
    await r.session.login('reader@example.invalid', 'fixture-only');
    await tester.pumpAndSettle();
    final noteId = r.workspace.notes.first.id;
    final l10n = tester.element(find.byKey(const ValueKey('product-navigation'))).l10n;
    await tapVisible(tester, find.byKey(ValueKey('product-note-$noteId')));
    await tapVisible(tester, find.byKey(const ValueKey('note-menu')));
    await tapVisible(tester, find.text(l10n.productEditNote));
    final field = find.descendant(of: find.byKey(const ValueKey('edit-content')), matching: find.byType(TextField));
    await tester.ensureVisible(field);
    await tester.enterText(field, 'Edited explicitly');
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text(l10n.productSaveEdit)).bottom, lessThan(500));
    await tester.tap(find.text(l10n.productSaveEdit));
    await tester.pumpAndSettle();
    expect(r.workspace.detail!.content, 'Edited explicitly');
    expect(find.byKey(const ValueKey('edit-content')), findsNothing);
    expect(tester.takeException(), isNull);
    tester.view.resetViewInsets();
    tester.testTextInput.hide();
    await cleanup(tester);
  });
  testWidgets('preview explanations stay available behind the compact information action', (tester) async {
    await boot(tester);
    await tapVisible(tester, find.byKey(const ValueKey('development-banner')));
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Preview information'), findsOneWidget);
    expect(find.textContaining('no live backend'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await cleanup(tester);
  });
}
