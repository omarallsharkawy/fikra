import 'package:fikra/app/providers.dart';
import 'package:fikra/features/account/session_controller.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart' show loadAppFonts;
import 'navigation_test.dart' show boot, cleanup, tapVisible;
import 'ui_journeys_test.dart' show capture;

Finder input(String key) => find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(TextField));

Future<void> fill(WidgetTester tester, String key, String value) async {
  await tester.ensureVisible(input(key));
  await tester.enterText(input(key), value);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);
  for (final locale in [const Locale('en'), const Locale('ar')]) {
    for (final theme in [AppTheme.dark, AppTheme.light]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('auth stages remain usable at 360dp with keyboard: $locale $theme ${scale}x', (tester) async {
          final runtime = await boot(tester, locale: locale, theme: theme, scale: scale, size: const Size(360, 800));
          final l = tester.element(find.byKey(const ValueKey('auth-scroll'))).l10n;
          final name = 'auth-${locale.languageCode}-${theme.name}';
          if (scale == 1) await capture(tester, '$name-welcome');
          await tapVisible(tester, find.byKey(const ValueKey('auth-start-login')));
          expect(find.text(l.rdWb), findsOneWidget);
          if (scale == 1) await capture(tester, '$name-login');
          await fill(tester, 'account-email', 'reader@example.invalid');
          expect(tester.widget<TextField>(input('account-email')).textInputAction, TextInputAction.next);
          expect(tester.widget<TextField>(input('account-email')).textDirection, TextDirection.ltr);
          await tester.testTextInput.receiveAction(TextInputAction.next);
          await tester.pumpAndSettle();
          expect(
            tester.widget<TextField>(input('account-password')).focusNode?.hasFocus ??
                tester
                    .widget<EditableText>(
                      find.descendant(of: input('account-password'), matching: find.byType(EditableText)),
                    )
                    .focusNode
                    .hasFocus,
            isTrue,
          );
          await fill(tester, 'account-password', 'fixture-only');
          tester.view.viewInsets = const FakeViewPadding(bottom: 300);
          await tester.pumpAndSettle();
          await tester.ensureVisible(input('account-password'));
          await tester.pumpAndSettle();
          expect(tester.getRect(input('account-password')).bottom, lessThanOrEqualTo(500));
          final submit = find.byKey(const ValueKey('account-submit'));
          await tester.ensureVisible(submit);
          await tester.pumpAndSettle();
          expect(tester.getRect(submit).bottom, lessThanOrEqualTo(500));
          expect(tester.takeException(), isNull);
          tester.view.resetViewInsets();
          tester.testTextInput.hide();
          await tester.pumpAndSettle();
          await tapVisible(tester, find.text(l.rdFg));
          expect(find.text(l.uxRecoveryTitle), findsOneWidget);
          expect(tester.getTopLeft(find.text(l.uxRecoveryTitle)).dy, greaterThan(0));
          expect(find.byKey(const ValueKey('account-password')), findsNothing);
          if (scale == 1) await capture(tester, '$name-forgot');
          await tapVisible(tester, find.text(l.uxRequestReset));
          expect(runtime.session.stage, SessionStage.recoverySent);
          expect(find.byType(TextField), findsNothing);
          if (scale == 1) await capture(tester, '$name-requested');
          await tapVisible(tester, find.text(l.apiHaveCode));
          expect(find.text(l.uxResetTitle), findsOneWidget);
          expect(tester.widget<TextField>(input('account-password')).controller!.text, isEmpty);
          expect(
            tester.getTopLeft(input('account-token')).dy,
            lessThan(tester.getTopLeft(input('account-password')).dy),
          );
          if (scale == 1) await capture(tester, '$name-reset');
          await fill(tester, 'account-token', 'fixture-reset');
          await fill(tester, 'account-password', 'new-fixture-password');
          tester.testTextInput.hide();
          await tester.pumpAndSettle();
          await tapVisible(tester, find.text(l.uxResetPassword));
          expect(runtime.session.stage, SessionStage.unauthenticated);
          expect(tester.widget<TextField>(input('account-password')).controller!.text, isEmpty);
          await tapVisible(tester, find.text(l.rdNw));
          expect(find.text(l.rdMk), findsNWidgets(2));
          expect(find.text(l.rdFg), findsNothing);
          expect(find.text(l.productResetPreviewCompleteSignInAgain), findsNothing);
          if (scale == 1) await capture(tester, '$name-signup');
          await fill(tester, 'account-name', '  علاء  ');
          await fill(tester, 'account-email', 'fresh@example.invalid');
          await fill(tester, 'account-password', 'fixture-only');
          tester.testTextInput.hide();
          await tester.pumpAndSettle();
          await tapVisible(tester, find.byKey(const ValueKey('account-submit')));
          expect(runtime.session.stage, SessionStage.awaitingVerification);
          if (scale == 1) await capture(tester, '$name-verify');
          await tapVisible(tester, find.byKey(const ValueKey('auth-back')));
          expect(tester.widget<TextField>(input('account-password')).controller!.text, isEmpty);
          await tapVisible(tester, find.text(l.rdNw));
          await fill(tester, 'account-password', 'fixture-only');
          tester.testTextInput.hide();
          await tester.pumpAndSettle();
          await tapVisible(tester, find.byKey(const ValueKey('account-submit')));
          expect(runtime.session.stage, SessionStage.awaitingVerification);
          await fill(tester, 'account-token', 'fixture-verify');
          tester.testTextInput.hide();
          await tester.pumpAndSettle();
          await tapVisible(tester, find.byKey(const ValueKey('verify-email')));
          expect(runtime.session.stage, SessionStage.unauthenticated);
          expect(tester.widget<TextField>(input('account-password')).controller!.text, isEmpty);
          await tapVisible(tester, find.byKey(const ValueKey('auth-back')));
          expect(find.text(l.rdTagl), findsOneWidget);
          expect(tester.takeException(), isNull);
          await cleanup(tester);
        });
      }
    }
  }
}
