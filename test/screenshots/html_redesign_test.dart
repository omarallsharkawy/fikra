import 'dart:io';
import 'dart:ui' as ui;

import 'package:fikra/app/product_router.dart';
import 'package:fikra/app/providers.dart';
import 'package:fikra/data/product/api/api_client.dart';
import 'package:fikra/data/product/development/development_auth.dart';
import 'package:fikra/data/product/development/development_knowledge.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../product/navigation_test.dart' show boot, cleanup, tapVisible;
import '../support/app_harness.dart' show loadAppFonts;

// Synthetic accounts are injected only into this test, never app fallbacks.
class CaptureAuth extends DevelopmentAuthRepository {
  @override
  bool get isDevelopment => false;
}

void main() {
  setUpAll(loadAppFonts);
  const phase = String.fromEnvironment('REDESIGN_CAPTURE', defaultValue: 'after');
  for (final lang in ['ar', 'en']) {
    for (final dark in [false, true]) {
      for (final screen in ['landing', 'signup', 'login', 'home', 'note-detail', 'map', 'ask-empty', 'capture', 'me']) {
        testWidgets('HTML comparison $screen $lang ${dark ? 'dark' : 'light'}', (tester) async {
          debugDisableShadows = false;
          addTearDown(() => debugDisableShadows = true);
          final api = ApiClient(Uri.parse('https://screenshot.invalid'));
          final r = await boot(
            tester,
            locale: Locale(lang),
            size: const Size(398, 650),
            theme: dark ? AppTheme.dark : AppTheme.light,
            api: api,
            auth: CaptureAuth(),
            knowledge: DevelopmentKnowledgeRepository(stepDelay: Duration.zero),
          );
          final l = tester.element(find.byType(Scaffold).first).l10n;
          if (screen == 'signup') await tapVisible(tester, find.text(l.uiSignUpEmail));
          if (screen == 'login') await tapVisible(tester, find.text(l.uiLogIn));
          if (!['landing', 'signup', 'login'].contains(screen)) {
            await r.session.login('reader@example.invalid', 'fixture-only');
            await tester.pumpAndSettle();
            final container = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
            final route = switch (screen) {
              'note-detail' => '/note/${r.workspace.notes.first.id}',
              'map' => '/links',
              'ask-empty' => '/ask',
              'capture' => '/add',
              'me' => '/me',
              _ => '/notes',
            };
            container.read(productRouterProvider).go(route);
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
          final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('product-capture')));
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
            final dir = Directory('build/validation/redesign/$phase')..createSync(recursive: true);
            File('${dir.path}/$screen-$lang-${dark ? 'dark' : 'light'}.png')
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
