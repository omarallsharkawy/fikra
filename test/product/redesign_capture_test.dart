import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart' show loadAppFonts;
import 'navigation_test.dart' show boot, cleanup, tapVisible;
import 'voice_save_lifecycle_test.dart' show VoiceSaveRepository;

void main() {
  setUpAll(loadAppFonts);
  for (final lang in ['ar', 'en']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Capture preserves the editable draft, appends real transcripts once and fits $lang $scale', (
        tester,
      ) async {
        final r = await boot(
          tester,
          locale: Locale(lang),
          scale: scale,
          size: const Size(360, 800),
          knowledge: VoiceSaveRepository(),
        );
        await r.session.login('other@example.invalid', 'fixture-only');
        await tester.pumpAndSettle();
        await tapVisible(tester, find.byKey(const ValueKey('nav-add')));
        final l = tester.element(find.byKey(const ValueKey('save-product-note'))).l10n;
        expect(find.text(l.uxCaptureHint), findsNothing);
        expect(find.text(l.uxCaptureDetails), findsNothing);
        final content = find.descendant(
          of: find.byKey(ValueKey('capture-content-${r.workspace.selectedProjectId}')),
          matching: find.byType(TextField),
        );
        await tester.enterText(content, 'بداية الفكرة');
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(content).textDirection, TextDirection.rtl);
        await tapVisible(tester, find.text(l.rdAddt));
        final title = find.descendant(
          of: find.byKey(ValueKey('capture-title-${r.workspace.selectedProjectId}')),
          matching: find.byType(TextField),
        );
        await tester.enterText(title, 'My title');
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
        await r.capture.start();
        await r.capture.stop();
        await tester.pumpAndSettle();
        await tapVisible(tester, find.byKey(const ValueKey('transcribe-product-voice')));
        expect(r.workspace.draft.content, 'بداية الفكرة\n\nReviewed voice text');
        await tester.pump();
        await tester.pump();
        expect(r.workspace.draft.content, 'بداية الفكرة\n\nReviewed voice text');
        await tapVisible(tester, find.byTooltip(l.rdCancel));
        expect(r.capture.active, isFalse);
        await tapVisible(tester, find.byKey(const ValueKey('nav-add')));
        expect(tester.widget<TextField>(content).controller!.text, 'بداية الفكرة\n\nReviewed voice text');
        expect(tester.widget<TextField>(title).controller!.text, 'My title');
        await tapVisible(tester, find.byKey(const ValueKey('save-product-note')));
        expect(r.workspace.notes.single.content, 'بداية الفكرة\n\nReviewed voice text');
        expect(tester.takeException(), isNull);
        await cleanup(tester);
      });
    }
  }
}
