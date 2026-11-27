import 'dart:convert';

import 'package:fikra/core/widgets/redesign_widgets.dart';
import 'package:fikra/data/product/api/api_client.dart';
import 'package:fikra/data/product/models.dart';
import 'package:fikra/features/account/session_controller.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart' show loadAppFonts;
import 'api_integration_test.dart'
    show ScriptTransport, jsonReply, client, pair, user, project, note, conversation, message;
import 'auth_layout_test.dart' show fill, input;
import 'navigation_test.dart' show boot, cleanup;
import 'ui_journeys_test.dart' show capture;

// HTTP body streams complete in the real async zone, like native I/O.
Future<void> tapConnected(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.runAsync(() async {
    await tester.tap(finder);
    await Future<void>.delayed(Duration.zero);
  });
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
  }
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);
  for (final locale in [const Locale('en'), const Locale('ar')]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('connected account, save, map, chat and logout use API repositories ($locale ${scale}x)', (
        tester,
      ) async {
        var created = false;
        final transport = ScriptTransport((c) {
          final path = c.uri.path;
          if (path.endsWith('/verify-email/otp') && c.json['code'] != '123456') {
            return jsonReply({'detail': 'Invalid code'}, status: 400);
          }
          if (path.endsWith('/me')) return jsonReply(user);
          if (path.endsWith('/login') || path.endsWith('/refresh')) return jsonReply(pair('new'));
          if (path.startsWith('/v1/auth/')) return jsonReply({'message': 'accepted'}, status: 202);
          if (path == '/v1/projects') return jsonReply([project]);
          if (path.endsWith('/notes')) {
            if (c.method == 'POST') {
              created = true;
              return jsonReply(note, status: 201);
            }
            return jsonReply(created ? [note] : []);
          }
          if (path == '/v1/notes/note-a') return jsonReply({...note, 'processing_status': 'completed'});
          if (path.endsWith('/connections')) return jsonReply([]);
          if (path.endsWith('/knowledge-graph')) {
            return jsonReply({
              'nodes': created
                  ? [
                      {
                        'id': 'note-a',
                        'title': null,
                        'concepts': ['idea'],
                        'updated_at': '2026-11-27T00:00:00Z',
                      },
                    ]
                  : [],
              'edges': [],
            });
          }
          if (path.endsWith('/search')) {
            return jsonReply([
              {'note_id': 'note-a', 'title': null, 'content': 'A thought', 'score': .8},
            ]);
          }
          if (path.endsWith('/conversations')) return jsonReply(c.method == 'POST' ? conversation : []);
          if (path.endsWith('/messages/stream')) {
            final result = {
              'conversation': conversation,
              'user_message': {
                ...message,
                'id': 'question-a',
                'role': 'user',
                'content': 'Question',
                'sources': [],
                'supported': null,
              },
              'assistant_message': message,
            };
            return ApiResponse(
              200,
              {'content-type': 'text/event-stream'},
              Stream.value(utf8.encode('event: complete\ndata: ${jsonEncode(result)}\n\n')),
              () {},
            );
          }
          fail('Unexpected API operation: ${c.method} $path');
        });
        final runtime = await boot(
          tester,
          api: client(transport),
          locale: locale,
          scale: scale,
          size: const Size(360, 800),
        );
        final l = tester.element(find.byKey(const ValueKey('auth-scroll'))).l10n;
        expect(runtime.session.repository.isDevelopment, isFalse);
        expect(find.byKey(const ValueKey('fixture-reader')), findsNothing);
        expect(find.byKey(const ValueKey('development-banner')), findsNothing);
        await tapConnected(tester, find.byKey(const ValueKey('auth-start-signup')));
        await fill(tester, 'account-name', '  علاء  ');
        await fill(tester, 'account-email', 'TEST@example.invalid ');
        await fill(tester, 'account-password', '1234');
        expect(tester.widget<RdButton>(find.byKey(const ValueKey('account-submit'))).onPressed, isNull);
        await fill(tester, 'account-password', 'abcde');
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
        await tapConnected(tester, find.byKey(const ValueKey('account-submit')));
        expect(runtime.session.stage, SessionStage.awaitingVerification);
        expect(transport.calls.first.json, {'email': 'test@example.invalid', 'password': 'abcde', 'name': 'علاء'});
        expect(find.text(l.apiSixDigitCode), findsOneWidget);
        await fill(tester, 'account-token', '12a34567');
        expect(tester.widget<TextField>(input('account-token')).controller!.text, '123456');
        expect(tester.widget<TextField>(input('account-token')).keyboardType, TextInputType.number);
        await fill(tester, 'account-token', '111111');
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
        await tapConnected(tester, find.byKey(const ValueKey('verify-email')));
        expect(find.text(l.apiInvalidCode), findsOneWidget);
        await fill(tester, 'account-token', '123456');
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
        await tapConnected(tester, find.byKey(const ValueKey('verify-email')));
        expect(runtime.session.stage, SessionStage.unauthenticated);
        expect(tester.widget<TextField>(input('account-password')).controller!.text, isEmpty);
        await tapConnected(tester, find.text(l.rdFg));
        await tapConnected(tester, find.text(l.uxRequestReset));
        expect(find.text(l.apiRecoveryAcknowledgment), findsOneWidget);
        await tapConnected(tester, find.text(l.apiHaveCode));
        await fill(tester, 'account-token', '654321');
        await fill(tester, 'account-password', 'abcde');
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
        await tapConnected(tester, find.text(l.uxResetPassword));
        expect(runtime.session.stage, SessionStage.unauthenticated);
        expect(transport.calls.where((c) => c.uri.path.endsWith('/login')), isEmpty);
        await fill(tester, 'account-password', 'abcde');
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
        await tapConnected(tester, find.byKey(const ValueKey('account-submit')));
        expect(runtime.session.account!.id, 'user-a');
        expect(runtime.profile.name, 'علاء');
        expect(runtime.workspace.selected!.isGeneral, isTrue);
        expect(find.byKey(const ValueKey('development-banner')), findsNothing);
        await tapConnected(tester, find.byKey(const ValueKey('nav-add')));
        await fill(tester, 'capture-content-project-a', 'A thought');
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
        await tapConnected(tester, find.byKey(const ValueKey('save-product-note')));
        expect(runtime.workspace.notes.single.id, 'note-a');
        await tester.runAsync(runtime.workspace.pollNow);
        await tester.pumpAndSettle();
        expect(runtime.workspace.notes.single.processing, ProcessingState.completed);
        await fill(tester, 'search-project-a', 'semantic query');
        await tester.runAsync(() async {
          await tester.testTextInput.receiveAction(TextInputAction.search);
          await Future<void>.delayed(Duration.zero);
        });
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
        expect(runtime.workspace.results!.single.noteId, 'note-a');
        await tapConnected(tester, find.byKey(const ValueKey('nav-1')));
        expect(runtime.workspace.graph.nodes.single.id, 'note-a');
        await tapConnected(tester, find.byKey(const ValueKey('nav-2')));
        await tapConnected(tester, find.byKey(const ValueKey('new-conversation')));
        await fill(tester, 'chat-draft-conversation-a', 'Question');
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
        await tapConnected(tester, find.byKey(const ValueKey('send-chat')));
        expect(runtime.chat.current!.messages.last.content, 'Final answer');
        expect(runtime.chat.current!.messages.last.sources.single.noteId, 'note-a');
        await tapConnected(tester, find.byKey(const ValueKey('nav-3')));
        // Scroll the Me list above the floating navigation at large text sizes.
        await tester.drag(find.byType(ListView).last, const Offset(0, -360));
        await tester.pumpAndSettle();
        await tapConnected(tester, find.text(l.rdOut));
        await tapConnected(tester, find.text(l.rdOut).last);
        expect(runtime.session.stage, SessionStage.unauthenticated);
        expect(runtime.workspace.notes, isEmpty);
        expect(runtime.chat.current, isNull);
        expect(await runtime.session.vault.read(), isNull);
        expect(transport.calls.any((c) => c.uri.path.endsWith('/logout')), isTrue);
        expect(tester.takeException(), isNull);
        if (scale == 1) await capture(tester, 'connected-${locale.languageCode}-welcome');
        await cleanup(tester);
      });
    }
  }
}
