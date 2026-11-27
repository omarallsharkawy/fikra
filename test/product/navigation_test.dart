import 'package:fikra/l10n/localizations.dart';
import 'package:fikra/app/app.dart';
import 'package:fikra/app/providers.dart';
import 'package:fikra/app/product_runtime.dart';
import 'package:fikra/data/product/api/api_client.dart';
import 'package:fikra/data/product/development/development_auth.dart';
import 'package:fikra/features/account/session_controller.dart';
import 'package:fikra/features/capture/local_documents.dart';
import 'package:fikra/data/product/models.dart';
import 'package:fikra/data/product/local_ui_store.dart';
import 'package:fikra/data/product/repositories.dart';
import 'package:fikra/data/product/development/development_knowledge.dart';
import 'package:fikra/features/workspace/graph_screen.dart';
import 'package:fikra/features/workspace/product_widgets.dart';
import 'package:fikra/features/capture/capture_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../support/app_harness.dart' show loadAppFonts;

class DeviceStub implements CaptureDevice {
  @override
  Future<void> start() async {}
  @override
  Future<RecordedClip?> stop(Duration duration) async => RecordedClip('/fixture', 'audio/m4a', duration);
  @override
  Future<void> cancel() async {}
  @override
  Future<void> dispose() async {}
}

class DocumentsStub implements LocalDocuments {
  @override
  Future<LocalDocument?> pickPdf() async => const LocalDocument('/fixture.pdf', 'Local fixture.pdf');
  @override
  Future<void> open(LocalDocument document) async {}
}

Future<ProductRuntime> boot(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  double scale = 1,
  Size size = const Size(430, 932),
  AppTheme theme = AppTheme.dark,
  ApiClient? api,
  KnowledgeRepository? knowledge,
  AuthRepository? auth,
  bool reducedMotion = true,
}) async {
  await initializeDateFormatting();
  tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(
    disableAnimations: reducedMotion,
  );
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.localeTestValue = locale;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appModeProvider.overrideWithValue(api == null ? AppMode.development : AppMode.connected),
        if (api != null) productApiClientProvider.overrideWithValue(api),
        productLocalUiProvider.overrideWithValue(MemoryLocalUiStore()),
        if (api != null) productVaultProvider.overrideWithValue(MemorySessionVault()),
        if (api != null) productAttemptsProvider.overrideWithValue(MemoryAttemptStore()),
        if (auth != null) productAuthProvider.overrideWithValue(auth),
        appThemeProvider.overrideWith((ref) => Stream.value(theme)),
        appLanguageProvider.overrideWith(
          (ref) => Stream.value(locale.languageCode == 'ar' ? AppLanguage.ar : AppLanguage.en),
        ),
        productCaptureDeviceProvider.overrideWithValue(DeviceStub()),
        productDocumentsProvider.overrideWithValue(DocumentsStub()),
        if (api == null || knowledge != null)
          productKnowledgeProvider.overrideWithValue(
            knowledge ?? DevelopmentKnowledgeRepository(stepDelay: const Duration(milliseconds: 10)),
          ),
      ],
      child: const RepaintBoundary(key: ValueKey('product-capture'), child: FikraApp()),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(FikraApp))).read(productRuntimeProvider);
}

Future<void> cleanup(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 1));
  tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
  tester.platformDispatcher.clearLocaleTestValue();
  tester.platformDispatcher.clearTextScaleFactorTestValue();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);
  testWidgets('creation timestamps use the stored instant with local weekday, date and time', (tester) async {
    await initializeDateFormatting();
    final stored = DateTime(2001, 1, 1, 14, 5).toUtc();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) => Text(productTimestamp(context, stored))),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Monday'), findsOneWidget);
    expect(find.textContaining('Jan 1, 2001'), findsOneWidget);
    expect(find.textContaining('2:05'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('default app gates private routes and explicitly opens a fixture workspace', (tester) async {
    final r = await boot(tester);
    expect(r.session.stage, SessionStage.unauthenticated);
    expect(find.byKey(const ValueKey('development-banner')), findsOneWidget);
    await tapVisible(tester, find.byKey(const ValueKey('fixture-reader')));
    expect(r.session.stage, SessionStage.authenticated);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-0')), findsOneWidget);
    expect(r.workspace.selected!.isGeneral, isTrue);
    expect(find.text('Fixture: neural networks'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await cleanup(tester);
  });
  testWidgets('composer saves optional-title text separately from processing and opens details', (tester) async {
    final r = await boot(tester);
    await r.session.login('other@example.invalid', 'fixture-only');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const ValueKey('nav-add')));
    final field = find.descendant(
      of: find.byKey(ValueKey('capture-content-${r.workspace.selectedProjectId}')),
      matching: find.byType(TextField),
    );
    await tester.enterText(field, 'A captured thought');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const ValueKey('save-product-note')));
    expect(find.text('A captured thought'), findsOneWidget);
    expect(find.text('Saved · queued'), findsOneWidget);
    await tapVisible(tester, find.byKey(ValueKey('product-note-${r.workspace.notes.single.id}')));
    expect(find.text('Saved content'), findsOneWidget);
    expect(find.byKey(const ValueKey('note-processing-state')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await cleanup(tester);
  });
  testWidgets('Arabic note headings keep RTL direction inside the English interface', (tester) async {
    final r = await boot(tester);
    await r.session.login('other@example.invalid', 'fixture-only');
    await tester.pumpAndSettle();
    r.workspace.updateDraft(title: 'فكرة عربية', content: 'A saved thought');
    final saved = await r.workspace.save();
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(ValueKey('product-note-${saved!.id}')));
    expect(tester.widget<Text>(find.text('فكرة عربية')).textDirection, TextDirection.rtl);
    expect(
      tester
          .widget<SelectableText>(find.byWidgetPredicate((w) => w is SelectableText && w.data == 'A saved thought'))
          .textDirection,
      TextDirection.ltr,
    );
    expect(tester.takeException(), isNull);
    await cleanup(tester);
  });
  testWidgets('navigation exposes note graph and conversation history without legacy actions', (tester) async {
    final r = await boot(tester);
    await r.session.login('reader@example.invalid', 'fixture-only');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const ValueKey('nav-1')));
    expect(find.byType(ProductNoteGraph), findsOneWidget);
    expect(r.workspace.graph.nodes.length, 2);
    await tapVisible(tester, find.byKey(const ValueKey('nav-2')));
    await tapVisible(tester, find.byKey(const ValueKey('new-conversation')));
    expect(r.chat.current, isNotNull);
    expect(find.byKey(const ValueKey('conversation-history')), findsOneWidget);
    r.chat.updateDraft('Hello');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const ValueKey('send-chat')));
    expect(r.chat.current!.messages.last.supported, isNull);
    expect(find.byKey(const ValueKey('chat-preview')), findsNothing);
    expect(find.text('Restore original'), findsNothing);
    expect(find.text('Move to project'), findsNothing);
    expect(tester.takeException(), isNull);
    await cleanup(tester);
  });
  testWidgets('sign-out destroys private route state before opening the other account', (tester) async {
    final r = await boot(tester);
    await r.session.login('reader@example.invalid', 'fixture-only');
    await tester.pumpAndSettle();
    r.workspace.updateDraft(content: 'Private retained input');
    await r.session.signOut();
    await tester.pumpAndSettle();
    expect(find.text('Fixture: neural networks'), findsNothing);
    expect(find.text('Private retained input'), findsNothing);
    await tapVisible(tester, find.byKey(const ValueKey('fixture-other')));
    expect(r.workspace.notes, isEmpty);
    expect(r.workspace.draft.content, isEmpty);
    expect(find.text('No notes yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await cleanup(tester);
  });
  for (final locale in [const Locale('en'), const Locale('ar')]) {
    testWidgets('account and notes fit ${locale.languageCode} at 2x text size', (tester) async {
      final r = await boot(tester, locale: locale, scale: 2);
      expect(tester.takeException(), isNull);
      await r.session.login('reader@example.invalid', 'fixture-only');
      await tester.pumpAndSettle();
      expect(find.byType(DevelopmentBanner), findsOneWidget);
      expect(tester.takeException(), isNull);
      await cleanup(tester);
    });
  }
}
