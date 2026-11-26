import 'dart:io';
import 'dart:ui' as ui;

import 'package:fikra/app/providers.dart';
import 'package:fikra/app/app.dart';
import 'package:fikra/features/workspace/product_widgets.dart';
import 'package:fikra/features/account/session_controller.dart';
import 'package:fikra/features/workspace/graph_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/app_harness.dart' show loadAppFonts;
import 'navigation_test.dart' show boot, cleanup, tapVisible;

Future<void> capture(WidgetTester tester, String name) async {
  if (Platform.environment['FIKRA_SCREENSHOTS'] != '1') return;
  await tester.runAsync(() async {
    final context = tester.element(find.byType(FikraApp));
    for (final theme in ['dark', 'light']) {
      await precacheImage(AssetImage('assets/icons/fikrah-icon-$theme-mode.png'), context);
    }
  });
  await tester.pump();
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('product-capture')));
  await tester.runAsync(() async {
    final img = await boundary.toImage(pixelRatio: 2);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory('build/validation/mobile-ui');
    await dir.create(recursive: true);
    await File('${dir.path}/$name.png').writeAsBytes(data!.buffer.asUint8List());
    img.dispose();
  });
}

void main() {
  setUpAll(loadAppFonts);
  for (final locale in [const Locale('en'), const Locale('ar')]) {
    for (final theme in [AppTheme.dark, AppTheme.light]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('reference journeys ${locale.languageCode} $theme ${scale}x at 360dp', (tester) async {
          final r = await boot(tester, locale: locale, theme: theme, scale: scale, size: const Size(360, 800));
          final name = '${locale.languageCode}-${theme.name}';
          if (scale == 1) await capture(tester, '$name-welcome');
          expect(tester.takeException(), isNull);
          await r.session.login('reader@example.invalid', 'fixture-only');
          await tester.pumpAndSettle();
          if (scale == 1) await capture(tester, '$name-home');
          expect(tester.takeException(), isNull);
          await tapVisible(tester, find.byKey(const ValueKey('nav-add')));
          if (scale == 1) await capture(tester, '$name-capture');
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('save-product-note')),
            350,
            scrollable: find.descendant(of: find.byType(ProductScaffold), matching: find.byType(Scrollable)).first,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          GoRouter.of(tester.element(find.byKey(const ValueKey('save-product-note')))).go('/links');
          await tester.pumpAndSettle();
          final graph = find.byType(ProductNoteGraph);
          await tester.scrollUntilVisible(
            graph,
            250,
            scrollable: find.descendant(of: find.byType(ProductScaffold), matching: find.byType(Scrollable)).first,
          );
          await tester.pumpAndSettle();
          final viewer = find.descendant(of: graph, matching: find.byType(InteractiveViewer));
          final transform = tester.widget<InteractiveViewer>(viewer).transformationController!;
          for (var i = 0; i < 20; i++) {
            await tester.tap(find.byTooltip(locale.languageCode == 'en' ? 'Zoom in' : 'تكبير'));
            await tester.pump();
          }
          expect(transform.value.getMaxScaleOnAxis(), lessThanOrEqualTo(3.00001));
          // Fit restores the full graph after repeated bounded zooms.
          await tester.tap(find.byTooltip(locale.languageCode == 'en' ? 'Fit all ideas' : 'إظهار كل الأفكار'));
          await tester.pumpAndSettle();
          final node = find.byKey(ValueKey('graph-node-${r.workspace.graph.nodes.first.id}'));
          await tester.tap(node);
          await tester.pumpAndSettle();
          if (scale == 1) await capture(tester, '$name-map');
          expect(tester.takeException(), isNull);
          GoRouter.of(tester.element(graph)).go('/ask');
          await tester.pumpAndSettle();
          await tapVisible(tester, find.byKey(const ValueKey('new-conversation')));
          r.chat.updateDraft('Hello');
          await tester.pumpAndSettle();
          await tapVisible(tester, find.byKey(const ValueKey('send-chat')));
          if (scale == 1) await capture(tester, '$name-chat');
          expect(tester.takeException(), isNull);
          GoRouter.of(tester.element(find.byKey(const ValueKey('send-chat')))).go('/me');
          await tester.pumpAndSettle();
          if (scale == 1) await capture(tester, '$name-profile');
          expect(tester.takeException(), isNull);
          GoRouter.of(tester.element(find.byKey(const ValueKey('product-navigation')))).push('/settings');
          await tester.pumpAndSettle();
          if (scale == 1) await capture(tester, '$name-settings');
          expect(tester.takeException(), isNull);
          await cleanup(tester);
        });
      }
    }
  }
  testWidgets('project management lives in settings and General remains reachable', (tester) async {
    final r = await boot(tester, size: const Size(360, 800));
    await r.session.login('reader@example.invalid', 'fixture-only');
    await tester.pumpAndSettle();
    final generalId = r.workspace.selectedProjectId;
    expect(find.byKey(const ValueKey('new-product-project')), findsNothing);
    expect(find.textContaining('General'), findsNothing);
    final router = GoRouter.of(tester.element(find.byKey(const ValueKey('product-navigation'))));
    router.push('/settings');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const ValueKey('manage-product-projects')));
    expect(find.byKey(ValueKey('select-project-$generalId')), findsNothing);
    await tapVisible(tester, find.byKey(const ValueKey('new-product-project')));
    await tester.enterText(find.byType(TextFormField), 'My project');
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();
    final customId = r.workspace.selectedProjectId!;
    expect(r.workspace.selected!.name, 'My project');
    await tapVisible(tester, find.byKey(ValueKey('select-project-$generalId')));
    expect(r.workspace.selected!.isGeneral, isTrue);
    router.pop();
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('Fixture: study plan'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(find.byKey(const ValueKey('new-product-project')), findsNothing);
    await r.workspace.selectProject(customId);
    await r.workspace.deleteProject();
    await tester.pumpAndSettle();
    expect(r.workspace.selectedProjectId, generalId);
    expect(find.text('Fixture: study plan'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await cleanup(tester);
  });
  testWidgets('registration verification returns to sign-in and clears password input', (tester) async {
    final r = await boot(tester);
    await tapVisible(tester, find.text('Sign up with email'));
    for (final (key, text) in [('account-email', 'new@example.invalid'), ('account-password', 'fixture-only')]) {
      await tester.enterText(find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(TextField)), text);
    }
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const ValueKey('account-submit')));
    expect(r.session.stage, SessionStage.awaitingVerification);
    await tester.enterText(
      find.descendant(of: find.byKey(const ValueKey('account-token')), matching: find.byType(TextField)),
      'fixture-verify',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const ValueKey('verify-email')));
    expect(r.session.stage, SessionStage.unauthenticated);
    expect(find.text('Welcome back'), findsOneWidget);
    final password = tester.widget<TextField>(
      find.descendant(of: find.byKey(const ValueKey('account-password')), matching: find.byType(TextField)),
    );
    expect(password.controller!.text, isEmpty);
    await cleanup(tester);
  });
}
