import 'package:fikra/app/providers.dart';
import 'package:fikra/core/widgets/redesign_widgets.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart' show loadAppFonts;
import 'api_integration_test.dart' show ScriptTransport, client, jsonReply;
import 'auth_layout_test.dart' show fill, input;
import 'connected_journeys_test.dart' show tapConnected;
import 'navigation_test.dart' show boot, cleanup, tapVisible;

void main() {
  setUpAll(loadAppFonts);
  for (final lang in ['ar', 'en']) {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      testWidgets('name-first registration validates every field without changing the API: $lang $theme', (
        tester,
      ) async {
        final transport = ScriptTransport((_) => jsonReply({'message': 'accepted'}, status: 202));
        final runtime = await boot(tester, api: client(transport), locale: Locale(lang), theme: theme);
        final l = tester.element(find.byKey(const ValueKey('auth-scroll'))).l10n;
        expect(find.textContaining('Google sign-in'), findsNothing);
        expect(find.byKey(const ValueKey('fixture-reader')), findsNothing);
        await tapVisible(tester, find.byKey(const ValueKey('auth-start-signup')));
        bool enabled() => tester.widget<RdButton>(find.byKey(const ValueKey('account-submit'))).onPressed != null;
        expect(tester.getTopLeft(input('account-name')).dy, lessThan(tester.getTopLeft(input('account-email')).dy));
        expect(tester.widget<TextField>(input('account-name')).autofillHints, contains(AutofillHints.givenName));
        expect(enabled(), isFalse);
        await fill(tester, 'account-email', 'reader@example.invalid');
        await fill(tester, 'account-password', 'abcde');
        expect(enabled(), isFalse);
        await fill(tester, 'account-name', '   ');
        expect(enabled(), isFalse);
        await fill(tester, 'account-name', 'ع' * 41);
        expect(tester.widget<TextField>(input('account-name')).controller!.text, 'ع' * 40);
        expect(tester.widget<TextField>(input('account-name')).textDirection, TextDirection.rtl);
        await fill(tester, 'account-name', '  Alice  ');
        expect(tester.widget<TextField>(input('account-name')).textDirection, TextDirection.ltr);
        await fill(tester, 'account-email', 'bad-address');
        expect(enabled(), isFalse);
        await fill(tester, 'account-email', 'OWNER@example.invalid ');
        expect(enabled(), isTrue);
        expect(transport.calls, isEmpty);
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
        await tapConnected(tester, find.byKey(const ValueKey('account-submit')));
        expect(transport.calls.single.json, {'email': 'owner@example.invalid', 'password': 'abcde'});
        await tester.runAsync(() => runtime.profile.bind('owner', 'owner@example.invalid'));
        expect(runtime.profile.name, 'Alice');
        expect(runtime.profile.initial, 'A');
        expect(find.text(l.apiSixDigitCode), findsOneWidget);
        expect(tester.takeException(), isNull);
        await cleanup(tester);
      });
    }
  }
}
