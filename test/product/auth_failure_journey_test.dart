import 'dart:io';

import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart' show loadAppFonts;
import 'api_integration_test.dart' show ScriptTransport, client, jsonReply;
import 'auth_layout_test.dart' show fill, input;
import 'connected_journeys_test.dart' show tapConnected;
import 'navigation_test.dart' show boot, cleanup;
import 'ui_journeys_test.dart' show capture;

void main() {
  setUpAll(loadAppFonts);
  for (final locale in [const Locale('en'), const Locale('ar')]) {
    testWidgets('registration name validation is specific and never exposes server input ($locale)', (tester) async {
      final transport = ScriptTransport(
        (_) => jsonReply({
          'detail': [
            {
              'loc': ['body', 'name'],
              'type': 'missing',
              'msg': 'private server diagnostic',
              'input': 'private input',
            },
          ],
        }, status: 422),
      );
      await boot(tester, api: client(transport), locale: locale);
      final l = tester.element(find.byKey(const ValueKey('auth-scroll'))).l10n;
      await tapConnected(tester, find.byKey(const ValueKey('auth-start-signup')));
      await fill(tester, 'account-name', 'Owner');
      await fill(tester, 'account-email', 'owner@example.com');
      await fill(tester, 'account-password', 'test-password');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tapConnected(tester, find.byKey(const ValueKey('account-submit')));
      expect(find.text(l.rdNameInvalid), findsOneWidget);
      expect(find.text(l.authCheckDetails), findsNothing);
      expect(find.textContaining('private'), findsNothing);
      expect(tester.widget<TextField>(input('account-name')).controller!.text, 'Owner');
      expect(tester.widget<TextField>(input('account-password')).controller!.text, 'test-password');
      await cleanup(tester);
    });
    for (final scale in [1.0, 2.0]) {
      testWidgets('login and signup failures remain visible and preserve input ($locale ${scale}x)', (tester) async {
        var connectionFailure = true;
        final transport = ScriptTransport((_) {
          if (connectionFailure) throw const SocketException('never display this private detail');
          return jsonReply({'detail': 'Invalid email or password'}, status: 401);
        });
        await boot(tester, api: client(transport), locale: locale, scale: scale, size: const Size(360, 800));
        final l = tester.element(find.byKey(const ValueKey('auth-scroll'))).l10n;
        await tapConnected(tester, find.byKey(const ValueKey('auth-start-login')));
        await fill(tester, 'account-email', 'reader@example.com');
        await fill(tester, 'account-password', 'test-password');
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        await tapConnected(tester, find.byKey(const ValueKey('account-submit')));
        expect(find.text(l.authConnectionError), findsOneWidget);
        expect(tester.widget<TextField>(input('account-email')).controller!.text, 'reader@example.com');
        expect(tester.widget<TextField>(input('account-password')).controller!.text, 'test-password');
        expect(
          tester
              .widget<EditableText>(find.descendant(of: input('account-password'), matching: find.byType(EditableText)))
              .focusNode
              .hasFocus,
          isFalse,
        );
        tester.view.resetViewInsets();
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
        final feedbackRect = tester.getRect(find.byKey(const ValueKey('auth-feedback')));
        expect(feedbackRect.top, greaterThanOrEqualTo(0));
        expect(feedbackRect.bottom, lessThanOrEqualTo(800));
        if (scale == 1) await capture(tester, 'repair-${locale.languageCode}-login-error');
        connectionFailure = false;
        await tapConnected(tester, find.byKey(const ValueKey('account-submit')));
        expect(find.text(l.authCredentialsError), findsOneWidget);
        await tapConnected(tester, find.text(l.rdNw));
        expect(find.byKey(const ValueKey('auth-feedback')), findsNothing);
        connectionFailure = true;
        await fill(tester, 'account-name', 'Owner');
        await fill(tester, 'account-password', 'test-password');
        await tapConnected(tester, find.byKey(const ValueKey('account-submit')));
        expect(find.text(l.authConnectionError), findsOneWidget);
        if (scale == 1) {
          await tester.ensureVisible(find.byKey(const ValueKey('auth-feedback')));
          await capture(tester, 'repair-${locale.languageCode}-signup-error');
        }
        expect(tester.takeException(), isNull);
        await cleanup(tester);
      });
    }
  }
}
