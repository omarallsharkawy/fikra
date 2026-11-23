import 'package:fikra/app/app.dart';
import 'package:fikra/app/providers.dart';
import 'package:fikra/app/product_runtime.dart';
import 'package:fikra/features/account/session_controller.dart';
import 'package:fikra/features/capture/local_documents.dart';
import 'package:fikra/data/product/models.dart';
import 'package:fikra/data/product/development/development_knowledge.dart';
import 'package:fikra/features/workspace/graph_screen.dart';
import 'package:fikra/features/workspace/product_widgets.dart';
import 'package:fikra/features/capture/capture_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

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

Future<ProductRuntime> boot(WidgetTester tester, {Locale locale = const Locale('en'), double scale = 1}) async {
  await initializeDateFormatting();
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.localeTestValue = locale;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appModeProvider.overrideWithValue(AppMode.development),
        appThemeProvider.overrideWith((ref) => Stream.value(AppTheme.dark)),
        appLanguageProvider.overrideWith(
          (ref) => Stream.value(locale.languageCode == 'ar' ? AppLanguage.ar : AppLanguage.en),
        ),
        productCaptureDeviceProvider.overrideWithValue(DeviceStub()),
        productDocumentsProvider.overrideWithValue(DocumentsStub()),
        productKnowledgeProvider.overrideWithValue(
          DevelopmentKnowledgeRepository(stepDelay: const Duration(milliseconds: 10)),
        ),
      ],
      child: const FikraApp(),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(FikraApp))).read(productRuntimeProvider);
}

Future<void> cleanup(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 1));
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
    expect(find.text('Conversation history'), findsOneWidget);
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
