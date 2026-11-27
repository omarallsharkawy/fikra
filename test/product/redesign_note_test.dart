import 'dart:ui' as ui;

import 'package:fikra/app/product_router.dart';
import 'package:fikra/data/product/development/development_knowledge.dart';
import 'package:fikra/data/product/models.dart';
import 'package:fikra/features/workspace/note_share.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart' show loadAppFonts;
import 'navigation_test.dart' show boot, cleanup, tapVisible;

class NoteSpy extends DevelopmentKnowledgeRepository {
  NoteSpy() : super(stepDelay: Duration.zero);
  int deletes = 0, accepts = 0;
  final favorites = <bool>[];
  @override
  Future<void> deleteNote(String accountId, String noteId) async {
    deletes++;
    await super.deleteNote(accountId, noteId);
  }

  @override
  Future<KnowledgeNote> refine(String accountId, String noteId, int generation, RefinementAction action) async {
    if (action == RefinementAction.accept) accepts++;
    return super.refine(accountId, noteId, generation, action);
  }

  @override
  Future<KnowledgeNote> setFavorite(String accountId, String noteId, bool value) async {
    favorites.add(value);
    return super.setFavorite(accountId, noteId, value);
  }
}

void main() {
  setUpAll(loadAppFonts);
  for (final lang in ['en', 'ar']) {
    testWidgets('note proposal, tags, favorite and both Undo journeys use real state: $lang', (tester) async {
      final r = await boot(tester, knowledge: NoteSpy(), locale: Locale(lang));
      // The spy in this runtime is the actual repository, with no parallel UI state.
      final actual = r.repository as NoteSpy;
      await r.session.login('reader@example.invalid', 'fixture-only');
      await tester.pumpAndSettle();
      final note = r.workspace.notes.first;
      final container = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
      container.read(productRouterProvider).go('/note/${note.id}');
      await tester.pumpAndSettle();
      final l = tester.element(find.byType(Scaffold).first).l10n;
      await tapVisible(tester, find.text(l.rdBefore));
      expect(find.byKey(const ValueKey('refinement-proposal')), findsNothing);
      await tapVisible(tester, find.text(l.rdAfter));
      expect(find.text(note.proposal!), findsOneWidget);
      await tapVisible(tester, find.text(l.rdChg));
      expect(find.byKey(const ValueKey('refinement-proposal')), findsOneWidget);
      await tapVisible(tester, find.byKey(const ValueKey('accept-proposal')));
      expect(r.undo.actions, hasLength(1));
      expect(actual.accepts, 0);
      await tapVisible(tester, find.text(l.rdUndo));
      expect(r.undo.actions, isEmpty);
      expect(actual.accepts, 0);
      expect(find.byKey(const ValueKey('accept-proposal')), findsOneWidget);

      await tapVisible(tester, find.byKey(const ValueKey('note-menu')));
      await tapVisible(tester, find.text(l.rdPin));
      expect(actual.favorites, [true]);
      expect(r.workspace.detail!.isFavorite, isTrue);
      await tapVisible(tester, find.byKey(const ValueKey('note-menu')));
      await tapVisible(tester, find.text(l.rdUnpin));
      expect(actual.favorites, [true, false]);

      await tapVisible(tester, find.byKey(const ValueKey('note-add-tag')));
      await tapVisible(tester, find.text(l.rdNewTag));
      await tester.enterText(find.byType(TextField).last, '  تعلّم  ');
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text(l.rdSave).last);
      await tapVisible(tester, find.text(l.rdSave));
      expect(r.tags.forNote(note.id).single.label, 'تعلّم');
      expect(r.workspace.detail!.concepts, note.concepts);

      await tapVisible(tester, find.byKey(const ValueKey('note-menu')));
      await tapVisible(tester, find.text(l.rdDel));
      await tapVisible(tester, find.text(l.rdDel));
      expect(r.undo.hiddenIds, {note.id});
      expect(actual.deletes, 0);
      expect(find.byKey(ValueKey('product-note-${note.id}')), findsNothing);
      await tapVisible(tester, find.text(l.rdUndo));
      expect(r.undo.hiddenIds, isEmpty);
      expect(find.byKey(ValueKey('product-note-${note.id}')), findsOneWidget);
      expect(actual.deletes, 0);
      expect(tester.takeException(), isNull);
      await cleanup(tester);
    });
  }

  testWidgets('real note image is a valid PNG and native share errors stay typed', (tester) async {
    await boot(tester);
    final context = tester.element(find.byType(Scaffold).first);
    final bytes = await tester.runAsync(
      () => noteCardPng(
        context,
        title: 'فكرة عربية — A real thought',
        content: 'A device-provided note, with العربية and a second line.\nNo prototype text.',
        timestamp: 'Today · 10:30 AM',
        tags: ['Learning'],
      ),
    );
    final codec = await tester.runAsync(() => ui.instantiateImageCodec(bytes!));
    final frame = await tester.runAsync(codec!.getNextFrame);
    expect(frame!.image.width, 760);
    expect(frame.image.height, greaterThan(250));
    frame.image.dispose();
    codec.dispose();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    const channel = MethodChannel('fikrah/share');
    MethodCall? sent;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      sent = call;
      return null;
    });
    final sharing = DeviceNoteSharing();
    expect(sharing.available, isTrue);
    await sharing.share(bytes!, filename: 'fikrah-note-test.png', mime: 'image/png');
    expect(sent!.method, 'file');
    expect(sent!.arguments['filename'], 'fikrah-note-test.png');
    expect(sent!.arguments['bytes'], bytes);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(code: 'private-error'),
    );
    await expectLater(
      sharing.share(bytes, filename: 'fikrah-note-test.png', mime: 'image/png'),
      throwsA(isA<ProductFailure>()),
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
    await cleanup(tester);
  });
}
