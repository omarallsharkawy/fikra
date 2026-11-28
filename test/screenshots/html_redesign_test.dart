import 'dart:io';
import 'dart:ui' as ui;

import 'package:fikra/app/product_router.dart';
import 'package:fikra/app/providers.dart';
import 'package:fikra/data/product/api/api_client.dart';
import 'package:fikra/data/product/models.dart';
import 'package:fikra/data/product/development/development_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../product/auth_layout_test.dart' show fill;
import '../product/navigation_test.dart' show boot, cleanup, tapVisible;
import '../support/app_harness.dart' show loadAppFonts;
import '../support/html_reference_repository.dart';

// Synthetic accounts are injected only into this test, never app fallbacks.
class CaptureAuth extends DevelopmentAuthRepository {
  @override
  bool get isDevelopment => false;
  @override
  Future<SessionGrant> login(String email, String password) async {
    final grant = await super.login(email, password);
    return SessionGrant(
      Account(id: grant.account.id, email: 'alaa@example.com', emailVerified: true),
      tokens: grant.tokens,
    );
  }
}

void main() {
  setUpAll(loadAppFonts);
  const phase = String.fromEnvironment('REDESIGN_CAPTURE', defaultValue: 'after');
  const audit = bool.fromEnvironment('RTL_AUDIT');
  for (final lang in ['ar', 'en']) {
    for (final contentLang in audit ? ['ar', 'en'] : [lang]) {
      for (final dark in [false, true]) {
        for (final screen in [
          'landing',
          'signup',
          if (audit) 'signup-filled',
          'login',
          'home',
          'note-detail',
          'map',
          'ask-empty',
          'ask-answered',
          'capture',
          'capture-filled',
          'capture-recording',
          'me',
        ]) {
          testWidgets('HTML comparison $screen $lang $contentLang ${dark ? 'dark' : 'light'}', (tester) async {
            debugDisableShadows = false;
            addTearDown(() => debugDisableShadows = true);
            final api = ApiClient(Uri.parse('https://screenshot.invalid'));
            final r = await boot(
              tester,
              locale: Locale(lang),
              size: const Size(398, 650),
              scale: audit ? 1.3 : 1,
              theme: dark ? AppTheme.dark : AppTheme.light,
              api: api,
              auth: CaptureAuth(),
              knowledge: HtmlReferenceRepository(contentLang),
            );
            if (screen == 'signup' || screen == 'signup-filled') {
              await tapVisible(tester, find.byKey(const ValueKey('auth-start-signup')));
            }
            if (screen == 'login') await tapVisible(tester, find.byKey(const ValueKey('auth-start-login')));
            if (screen == 'signup-filled') {
              await fill(tester, 'account-name', contentLang == 'ar' ? 'محمد @ Microsoft' : 'Alice @ الجامعة');
              await fill(tester, 'account-email', 'owner@example.com');
              await fill(tester, 'account-password', 'Strong-password!');
              tester.testTextInput.hide();
              await tester.pumpAndSettle();
            }
            if (!['landing', 'signup', 'signup-filled', 'login'].contains(screen)) {
              await r.session.login('reader@example.invalid', 'fixture-only');
              await tester.pumpAndSettle();
              await tester.runAsync(() async {
                await r.profile.setName(contentLang == 'ar' ? 'علاء' : 'Alaa');
                final labels = (HtmlReferenceRepository.fixture['tags'] as Map)[contentLang] as Map;
                final tags = <String, String>{};
                for (final key in labels.keys) {
                  final tag = await r.tags.create(
                    labels[key] as String,
                    color: {'uni': 1, 'ai': 0, 'food': 2, 'career': 1}[key] ?? 0,
                  );
                  tags[key as String] = tag!.id;
                }
                for (final row in (r.repository as HtmlReferenceRepository).rows) {
                  await r.tags.assign(row['id'] as String, (row['tags'] as List).map((v) => tags[v]!).toSet());
                }
              });
              await tester.pumpAndSettle();
              final container = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
              final route = switch (screen) {
                'note-detail' => '/note/${r.workspace.notes.first.id}',
                'map' => '/links',
                'ask-empty' || 'ask-answered' => '/ask',
                'capture' || 'capture-filled' || 'capture-recording' => '/add',
                'me' => '/me',
                _ => '/notes',
              };
              container.read(productRouterProvider).go(route);
              await tester.pumpAndSettle();
              if (screen == 'capture-filled' || screen == 'capture-recording') {
                r.workspace.updateDraft(
                  content: contentLang == 'ar'
                      ? 'ال Deep Learning يعني إيه؟ 🌟 (12 kg) https://example.com'
                      : 'Review data science notes tomorrow',
                  titleVisible: true,
                );
                if (screen == 'capture-recording') await r.capture.start();
                await tester.pumpAndSettle();
              }
              if (screen == 'ask-answered') {
                final prompt = (HtmlReferenceRepository.fixture['chat'] as Map)[lang]['prompt'] as String;
                if (audit) {
                  await r.chat.create();
                  r.chat.updateDraft((HtmlReferenceRepository.fixture['chat'] as Map)[contentLang]['prompt'] as String);
                  await r.chat.send();
                  await tester.pumpAndSettle();
                } else {
                  await tapVisible(tester, find.text(prompt));
                }
              }
            }
            expect(tester.takeException(), isNull);
            final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('product-capture')));
            await tester.runAsync(() async {
              final image = await boundary.toImage();
              final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
              final dir = Directory('build/validation/redesign/$phase')..createSync(recursive: true);
              File('${dir.path}/$screen-$lang-${audit ? '$contentLang-' : ''}${dark ? 'dark' : 'light'}.png')
                  .writeAsBytesSync(bytes!.buffer.asUint8List());
              image.dispose();
            });
            debugDisableShadows = true;
            await cleanup(tester);
          });
        }
      }
    }
  }
}
