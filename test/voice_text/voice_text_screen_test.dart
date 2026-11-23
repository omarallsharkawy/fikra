import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:fikra/core/format.dart';
import 'package:fikra/core/widgets/fikra_widgets.dart';
import 'package:fikra/core/widgets/voice_player.dart';
import 'package:fikra/features/shared/inline_recorder.dart';
import 'package:fikra/features/voice_text/voice_text_backend.dart';
import 'package:fikra/features/voice_text/voice_text_controller.dart';
import 'package:fikra/features/voice_text/voice_text_providers.dart';
import 'package:fikra/features/voice_text/voice_text_copy.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_voice_text_backend.dart';
import 'voice_text_fixture.dart';

void main() {
  final l = lookupAppLocalizations(const Locale('en'));
  void reset(WidgetTester tester) => addTearDown(tester.view.reset);
  VoiceTextController controller(WidgetTester t) =>
      ProviderScope.containerOf(t.element(find.byKey(const ValueKey('vt-scroll')))).read(voiceTextControllerProvider);

  testWidgets('primary model rows need no picker; full variants remain in testing', (tester) async {
    reset(tester);
    await pumpVoiceText(tester, FakeVoiceTextBackend());
    expect(find.byType(BottomSheet), findsNothing);
    for (final model in spikeModels.where((m) => m.quantized)) {
      expect(find.byKey(ValueKey('vt-model-${model.modelName}')), findsOneWidget);
      expect(find.textContaining('${model.downloadMb} MB'), findsWidgets);
    }
    expect(find.byKey(const ValueKey('vt-format')), findsNothing);
    expect(find.byKey(const ValueKey('vt-testing-content')), findsNothing);
    await expandVoiceTextTesting(tester);
    for (final model in spikeModels.where((m) => !m.quantized)) {
      await revealVoiceText(tester, 'vt-model-${model.modelName}');
      expect(find.textContaining('${model.downloadMb} MB'), findsWidgets);
    }
    expect(find.byKey(const ValueKey('vt-format')), findsOneWidget);
  });

  testWidgets('radio semantics and model/language choices update and persist', (tester) async {
    reset(tester);
    // The handle is checked before tearDowns run, so it is disposed in the body.
    final semantics = tester.ensureSemantics();
    final fake = FakeVoiceTextBackend()..seed();
    fake.sizes['base-q5_1'] = 123;
    final settings = FakeVoiceTextSettings(modelName: 'tiny-q5_1');
    await pumpVoiceText(tester, fake, settings: settings);
    await tapVoiceText(tester, 'vt-model-base-q5_1');
    expect(controller(tester).model.modelName, 'base-q5_1');
    expect(settings.modelName, 'base-q5_1');
    expect(
      tester.getSemantics(find.byKey(const ValueKey('vt-model-base-q5_1'))).flagsCollection.isSelected,
      Tristate.isTrue,
    );
    await revealVoiceText(tester, 'vt-model-tiny-q5_1');
    expect(
      tester.getSemantics(find.byKey(const ValueKey('vt-model-tiny-q5_1'))).flagsCollection.isSelected,
      Tristate.isFalse,
    );
    semantics.dispose();
    await tapVoiceText(tester, 'vt-language');
    await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text(l.vtAutomatic)));
    await tester.pumpAndSettle();
    expect(settings.language, 'auto');
  });

  for (final state in ['absent', 'invalid', 'valid']) {
    testWidgets('Egyptian model is $state and selected by default when valid', (tester) async {
      reset(tester);
      final fake = FakeVoiceTextBackend()
        ..seed()
        ..egyptianFilePresent = state != 'absent'
        ..egyptianFileValid = state == 'valid';
      await pumpVoiceText(tester, fake);
      final row = find.byKey(ValueKey('vt-model-${egyptianModel.modelName}'));
      if (state != 'valid') {
        expect(row, findsNothing);
        return;
      }
      expect(controller(tester).model, egyptianModel);
      expect(find.descendant(of: row, matching: find.textContaining(l.vtEgyptian)), findsOneWidget);
      expect(find.descendant(of: row, matching: find.textContaining(Fmt.bytes(l, fake.egyptianBytes))), findsOneWidget);
      expect(find.byKey(ValueKey('vt-download-${egyptianModel.modelName}')), findsNothing);
      expect(find.byKey(ValueKey('vt-delete-${egyptianModel.modelName}')), findsNothing);
      await tapVoiceText(tester, 'vt-try-transcribe');
      expect(fake.lastModel, 'ggml-small-egy-cs-q5_1.bin');
    });
  }

  testWidgets('a restored uncompressed choice is visible even while testing is collapsed', (tester) async {
    reset(tester);
    final fake = FakeVoiceTextBackend()..seed();
    fake.sizes['small'] = 123;
    await pumpVoiceText(tester, fake, settings: FakeVoiceTextSettings(modelName: 'small'));
    expect(controller(tester).model.modelName, 'small');
    expect(find.byKey(const ValueKey('vt-model-small')), findsOneWidget);
    expect(find.byKey(const ValueKey('vt-testing-content')), findsNothing);
  });

  testWidgets('download, progress, cancel, retry and delete stay on the target row', (tester) async {
    reset(tester);
    final fake = FakeVoiceTextBackend()..downloadGate = Completer<void>();
    await pumpVoiceText(tester, fake);
    await confirmVoiceTextDownload(tester, l, model: 'base-q5_1');
    expect(fake.downloads, 1);
    expect(controller(tester).model.modelName, 'base-q5_1');
    expect(
      tester.widgetList<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).any((p) => p.value == .25),
      isTrue,
    );
    await tapVoiceText(tester, 'vt-cancel-base-q5_1');
    expect(find.text(l.vtCancelled), findsWidgets);
    fake.downloadGate = null;
    await confirmVoiceTextDownload(tester, l, model: 'base-q5_1');
    await tapVoiceText(tester, 'vt-delete-base-q5_1');
    await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text(l.delete)));
    await tester.pumpAndSettle();
    expect(fake.sizes['base-q5_1'], isNull);
    expect(controller(tester).model.modelName, 'tiny-q5_1');
  });

  testWidgets('testing starts collapsed and toggle exposes expanded semantics', (tester) async {
    reset(tester);
    final semantics = tester.ensureSemantics();
    await pumpVoiceText(tester, FakeVoiceTextBackend());
    await revealVoiceText(tester, 'vt-testing-toggle');
    expect(
      tester.getSemantics(find.byKey(const ValueKey('vt-testing-toggle'))).flagsCollection.isExpanded,
      Tristate.isFalse,
    );
    await expandVoiceTextTesting(tester);
    expect(
      tester.getSemantics(find.byKey(const ValueKey('vt-testing-toggle'))).flagsCollection.isExpanded,
      Tristate.isTrue,
    );
    expect(find.byKey(const ValueKey('vt-testing-content')), findsOneWidget);
    await tapVoiceText(tester, 'vt-testing-toggle');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('vt-testing-content')), findsNothing);
    semantics.dispose();
  });

  testWidgets('record, playback/delete preview and re-run remain available', (tester) async {
    reset(tester);
    final fake = FakeVoiceTextBackend()..seed();
    await pumpVoiceText(tester, fake);
    await tapVoiceText(tester, 'vt-record');
    fake.amplitudes.add(-20);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(InlineRecorder), findsOneWidget);
    await tapVoiceText(tester, 'vt-stop');
    await tapVoiceText(tester, 'vt-try-transcribe');
    expect(fake.clips, hasLength(2));
    expect(fake.transcriptions, 1);
    await expandVoiceTextTesting(tester);
    await tapVoiceText(tester, 'vt-clip-0');
    await tapVoiceText(tester, 'vt-transcribe');
    expect(fake.transcriptions, 2);
    final newest = fake.clips.first.path;
    await revealVoiceText(tester, newest);
    tester.widget<VoicePlayer>(find.byKey(ValueKey(newest))).onDelete!();
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text(l.delete)));
    await tester.pumpAndSettle();
    expect(fake.clips.map((c) => c.path), isNot(contains(newest)));
  });

  testWidgets('format and CPU controls move under testing; speech language stays above Try it', (tester) async {
    reset(tester);
    final fake = FakeVoiceTextBackend()..seed();
    await pumpVoiceText(tester, fake);
    await expandVoiceTextTesting(tester);
    await tapVoiceText(tester, 'vt-format');
    await tester.tap(find.text(l.vtAac));
    await tester.pumpAndSettle();
    await tapVoiceText(tester, 'vt-advanced');
    await tester.tap(find.text(l.vtThreads('2')));
    await tester.pumpAndSettle();
    await tapVoiceText(tester, 'vt-record');
    expect(fake.aac, isTrue);
    await tapVoiceText(tester, 'vt-stop');
    await tapVoiceText(tester, 'vt-transcribe');
    expect(fake.lastThreads, 2);
  });

  testWidgets('main result has text and seconds; testing retains non-breaking units and costs', (tester) async {
    reset(tester);
    final ar = lookupAppLocalizations(const Locale('ar'));
    final fake = FakeVoiceTextBackend()
      ..seed()
      ..runGate = Completer<Map<String, Object?>>();
    await pumpVoiceText(tester, fake, locale: const Locale('ar'));
    await tapVoiceText(tester, 'vt-try-transcribe');
    expect(controller(tester).phase, VoiceTextPhase.transcribing);
    fake.runGate!.complete(sampleVoiceTextRun());
    await tester.pump();
    await tester.pump();
    await revealVoiceText(tester, 'vt-last-result');
    // find.text matches the EditableText inside SelectableText, not SelectableText.
    final transcript = find.byWidgetPredicate((w) => w is SelectableText && w.data == 'بكرة هكتب أفكاري بعد الشغل.');
    expect(tester.widget<SelectableText>(transcript).textDirection, TextDirection.rtl);
    expect(find.text(ar.vtWall(Fmt.isolate('4.00'))), findsOneWidget);
    expect(find.text(ar.vtNumbers), findsNothing);
    await expandVoiceTextTesting(tester);
    await revealVoiceText(tester, 'vt-run-0');
    expect(find.text(ar.vtConversion(Fmt.isolate(ar.vtMs('60')))), findsOneWidget);
    expect(ar.vtMs('60'), '60\u00a0ms');
    expect(find.text(ar.vtMemory(Fmt.isolate(ar.sizeMb('84.0')), Fmt.isolate(ar.sizeMb('146.0')))), findsOneWidget);
  });

  for (final issue in VoiceTextIssue.values) {
    testWidgets('${issue.name} error is brought into view after its action', (tester) async {
      reset(tester);
      final fake = FakeVoiceTextBackend();
      if ([
        VoiceTextIssue.network,
        VoiceTextIssue.interrupted,
        VoiceTextIssue.corrupt,
        VoiceTextIssue.cancelled,
      ].contains(issue)) {
        fake.downloadIssue = issue;
      } else if ([VoiceTextIssue.storage, VoiceTextIssue.storageCheck].contains(issue)) {
        fake.spaceIssue = issue;
      } else if (issue == VoiceTextIssue.permission) {
        fake.recordIssue = issue;
      } else if (issue == VoiceTextIssue.empty) {
        fake.stopIssue = issue;
      } else if (issue == VoiceTextIssue.transcription) {
        fake.seed();
        fake.runIssue = issue;
      } else {
        fake.loadIssue = issue;
      }
      await pumpVoiceText(tester, fake);
      if (fake.downloadIssue != null || fake.spaceIssue != null) {
        await confirmVoiceTextDownload(tester, l);
      } else if (fake.recordIssue != null || fake.stopIssue != null) {
        await tapVoiceText(tester, 'vt-record');
        if (fake.stopIssue != null) await tapVoiceText(tester, 'vt-stop');
      } else if (fake.runIssue != null) {
        await expandVoiceTextTesting(tester);
        await tapVoiceText(tester, 'vt-transcribe');
      }
      await tester.pump(const Duration(milliseconds: 500));
      final banner = find.byKey(const ValueKey('vt-error'));
      expect(find.widgetWithText(StatusBanner, issueMessage(l, issue)), findsWidgets);
      expect(tester.getRect(banner).top, greaterThanOrEqualTo(0));
      expect(tester.getRect(banner).bottom, lessThanOrEqualTo(844));
      expect(tester.state<ScrollableState>(voiceTextScrollable()).position.pixels, 0);
    });
  }

  testWidgets('live partials finish into the everyday result and release the lease', (tester) async {
    reset(tester);
    final fake = FakeVoiceTextBackend()..seed();
    await pumpVoiceText(tester, fake);
    await tapVoiceText(tester, 'vt-live');
    fake.live!.texts.add('كلام مباشر');
    await tester.pump(Duration.zero);
    await revealVoiceText(tester, 'vt-partial');
    expect(find.text('كلام مباشر'), findsOneWidget);
    await tapVoiceText(tester, 'vt-live');
    expect(controller(tester).phase, VoiceTextPhase.idle);
    expect(controller(tester).history.single['mode'], 'live');
  });

  for (final locale in [const Locale('ar'), const Locale('en')]) {
    testWidgets('large text and reduced motion (${locale.languageCode})', (tester) async {
      reset(tester);
      await pumpVoiceText(tester, FakeVoiceTextBackend()..seed(), locale: locale, width: 320, scale: 2);
      await tapVoiceText(tester, 'vt-model-base-q5_1');
      expect(tester.takeException(), isNull);
      await tapVoiceText(tester, 'vt-model-tiny-q5_1');
      await tapVoiceText(tester, 'vt-try-transcribe');
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byKey(const ValueKey('vt-try-transcribe'))).height, greaterThanOrEqualTo(48));
    });
  }
}
