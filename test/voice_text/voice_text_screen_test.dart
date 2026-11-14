import 'dart:async';

import 'package:fikra/core/widgets/fikra_widgets.dart';
import 'package:fikra/core/format.dart';
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

  testWidgets('empty screen offers exact sizes and all six multilingual models', (tester) async {
    reset(tester);
    await pumpVoiceText(tester, FakeVoiceTextBackend());
    expect(find.text(l.vtIntro), findsOneWidget);
    expect(find.textContaining('30.7 MB'), findsWidgets);
    await tapVoiceText(tester, 'vt-model-picker');
    for (final model in spikeModels) {
      await revealVoiceText(tester, 'vt-model-${model.modelName}', sheet: true);
      expect(find.textContaining('${model.downloadMb} MB'), findsWidgets);
    }
    expect(tester.takeException(), isNull);
  });

  for (final state in ['absent', 'invalid', 'valid']) {
    testWidgets('Egyptian local model is $state', (tester) async {
      reset(tester);
      final fake = FakeVoiceTextBackend()
        ..seed()
        ..egyptianFilePresent = state != 'absent'
        ..egyptianFileValid = state == 'valid';
      await pumpVoiceText(tester, fake);
      await tapVoiceText(tester, 'vt-model-picker');
      final row = find.byKey(ValueKey('vt-model-${egyptianModel.modelName}'));
      if (state != 'valid') {
        expect(row, findsNothing);
        final container = ProviderScope.containerOf(tester.element(find.byKey(const ValueKey('vt-scroll'))));
        expect(container.read(voiceTextControllerProvider).models, isNot(contains(egyptianModel)));
        return;
      }
      await revealVoiceText(tester, 'vt-model-${egyptianModel.modelName}', sheet: true);
      expect(find.descendant(of: row, matching: find.textContaining(l.vtEgyptian)), findsOneWidget);
      expect(find.descendant(of: row, matching: find.textContaining(Fmt.bytes(l, fake.egyptianBytes))), findsOneWidget);
      await tapVoiceText(tester, 'vt-model-${egyptianModel.modelName}', sheet: true);
      final container = ProviderScope.containerOf(tester.element(find.byKey(const ValueKey('vt-scroll'))));
      final c = container.read(voiceTextControllerProvider);
      expect(c.models.take(3), [spikeModels.first, egyptianModel, spikeModels[1]]);
      expect(c.model, egyptianModel);
      expect(find.byKey(const ValueKey('vt-download')), findsNothing);
      expect(find.byKey(const ValueKey('vt-delete-model')), findsNothing);
      await tapVoiceText(tester, 'vt-transcribe');
      expect(fake.lastModel, 'ggml-small-egy-cs-q5_1.bin');
      expect(c.history.single['model'], 'ggml-small-egy-cs-q5_1.bin');
    });
  }

  testWidgets('download confirmation, progress, cancellation and retry', (tester) async {
    reset(tester);
    final fake = FakeVoiceTextBackend()..downloadGate = Completer<void>();
    await pumpVoiceText(tester, fake);
    await confirmVoiceTextDownload(tester, l);
    expect(fake.downloads, 1);
    expect(find.byKey(const ValueKey('vt-cancel-download')), findsOneWidget);
    final progress = tester.widgetList<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    expect(progress.any((p) => p.value == .25), isTrue);
    await tapVoiceText(tester, 'vt-cancel-download');
    expect(find.text(l.vtCancelled), findsWidgets);
    fake.downloadGate = null;
    await confirmVoiceTextDownload(tester, l);
    // The cancelled banner disappears when the retry starts, shifting the list.
    await revealVoiceText(tester, 'vt-delete-model');
    expect(find.text(l.vtDeleteModel), findsOneWidget);
    expect(fake.sizes, isNotEmpty);
    await tapVoiceText(tester, 'vt-delete-model');
    await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text(l.delete)));
    await tester.pumpAndSettle();
    expect(fake.sizes, isEmpty);
  });

  testWidgets('record, play, select, delete and transcribe one clip with another model', (tester) async {
    reset(tester);
    final fake = FakeVoiceTextBackend()..seed();
    await pumpVoiceText(tester, fake);
    await tapVoiceText(tester, 'vt-record');
    fake.amplitudes.add(-20);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(InlineRecorder), findsOneWidget);
    await tapVoiceText(tester, 'vt-stop');
    expect(fake.clips, hasLength(2));
    expect(find.byType(VoicePlayer), findsWidgets);
    await tapVoiceText(tester, 'vt-clip-0');
    await tapVoiceText(tester, 'vt-transcribe');
    expect(fake.transcriptions, 1);
    expect(fake.lastThreads, 4);
    await tapVoiceText(tester, 'vt-model-picker');
    await tapVoiceText(tester, 'vt-model-base-q5_1', sheet: true);
    await tester.pumpAndSettle();
    await confirmVoiceTextDownload(tester, l);
    await tapVoiceText(tester, 'vt-transcribe');
    expect(fake.lastModel, 'ggml-base-q5_1.bin');
    expect(fake.clips, hasLength(2));
    // The real player is rendered with its delete affordance; no native call
    // is made until play is tapped. Its existing tests cover audio channels.
    final newest = fake.clips.first.path;
    await revealVoiceText(tester, newest);
    final player = tester.widget<VoicePlayer>(find.byKey(ValueKey(newest)));
    player.onDelete!();
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text(l.delete)));
    await tester.pumpAndSettle();
    expect(fake.clips.map((c) => c.path), isNot(contains(newest)));
    expect(fake.clips, hasLength(1));
  });

  testWidgets('AAC, language and advanced CPU choices use app sheets', (tester) async {
    reset(tester);
    final fake = FakeVoiceTextBackend()..seed();
    await pumpVoiceText(tester, fake);
    await tapVoiceText(tester, 'vt-format');
    await tester.tap(find.text(l.vtAac));
    await tester.pumpAndSettle();
    await tapVoiceText(tester, 'vt-record');
    expect(fake.aac, isTrue);
    await tapVoiceText(tester, 'vt-stop');
    await tapVoiceText(tester, 'vt-language');
    await tester.tap(find.text(l.vtAutomatic).last);
    await tester.pumpAndSettle();
    await tapVoiceText(tester, 'vt-advanced');
    await tester.tap(find.text(l.vtThreads('2')));
    await tester.pumpAndSettle();
    await tapVoiceText(tester, 'vt-transcribe');
    expect(fake.lastLanguage, 'auto');
    expect(fake.lastThreads, 2);
  });

  testWidgets('inference keeps working state, locks navigation, then shows selectable RTL text and costs', (
    tester,
  ) async {
    reset(tester);
    final fake = FakeVoiceTextBackend()
      ..seed()
      ..runGate = Completer<Map<String, Object?>>();
    await pumpVoiceText(tester, fake);
    await tapVoiceText(tester, 'vt-transcribe');
    expect(find.byKey(const ValueKey('vt-working')), findsOneWidget);
    // PopScope is generic (PopScope<Object> here), so byType(PopScope) never matches.
    expect(find.byWidgetPredicate((w) => w is PopScope && !w.canPop), findsOneWidget);
    fake.runGate!.complete(sampleVoiceTextRun());
    await tester.pump();
    await tester.pump();
    await revealVoiceText(tester, 'vt-result-card');
    // find.text matches the EditableText inside SelectableText, not SelectableText.
    final transcript = find.byWidgetPredicate((w) => w is SelectableText && w.data == 'بكرة هكتب أفكاري بعد الشغل.');
    expect(tester.widget<SelectableText>(transcript).textDirection, TextDirection.rtl);
    // Numbers are wrapped in direction isolates, so match the formatted phrase.
    expect(find.text(l.vtFaster(Fmt.isolate('3.0'))), findsOneWidget);
    expect(find.textContaining('84.0'), findsOneWidget);
    expect(find.textContaining('146.0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Arabic result keeps each Latin unit beside its number', (tester) async {
    reset(tester);
    final ar = lookupAppLocalizations(const Locale('ar'));
    await pumpVoiceText(tester, FakeVoiceTextBackend()..seed(), locale: const Locale('ar'));
    await tapVoiceText(tester, 'vt-transcribe');
    await revealVoiceText(tester, 'vt-result-card');
    // Without one isolate around number and unit, RTL lays it out as "MB 84.0".
    final mb = Fmt.isolate(ar.sizeMb('84.0'));
    expect(find.text(ar.vtMemory(mb, Fmt.isolate(ar.sizeMb('146.0')))), findsOneWidget);
    expect(find.text(ar.vtConversion(Fmt.isolate(ar.vtMs('60')))), findsOneWidget);
  });

  for (final issue in VoiceTextIssue.values) {
    testWidgets('visible plain ${issue.name} error', (tester) async {
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
        if (fake.spaceIssue != null) expect(fake.downloads, 0);
      } else if (fake.recordIssue != null || fake.stopIssue != null) {
        await tapVoiceText(tester, 'vt-record');
        if (fake.stopIssue != null) await tapVoiceText(tester, 'vt-stop');
      } else if (fake.runIssue != null) {
        await tapVoiceText(tester, 'vt-transcribe');
      }
      expect(find.text(issueMessage(l, issue)), findsWidgets);
      // The persistent banner sits above the control that failed; scroll back to it.
      tester.state<ScrollableState>(voiceTextScrollable()).position.jumpTo(0);
      await tester.pump();
      expect(find.widgetWithText(StatusBanner, issueMessage(l, issue)), findsOneWidget);
    });
  }

  testWidgets('live partials and final numbers; recorder lease is released', (tester) async {
    reset(tester);
    final fake = FakeVoiceTextBackend()..seed();
    await pumpVoiceText(tester, fake);
    await tapVoiceText(tester, 'vt-live');
    fake.live!.texts.add('كلام مباشر');
    // With no frame pending, a bare pump() runs microtasks only after its frame;
    // elapsing zero time delivers the stream event before the frame is built.
    await tester.pump(Duration.zero);
    // The partial is shown above the live button the helper scrolled to the top.
    await tester.ensureVisible(find.text('كلام مباشر', skipOffstage: false));
    await tester.pump();
    expect(find.text('كلام مباشر'), findsOneWidget);
    await tapVoiceText(tester, 'vt-live');
    final context = tester.element(find.byKey(const ValueKey('vt-scroll')));
    final container = ProviderScope.containerOf(context);
    expect(container.read(voiceTextControllerProvider).phase, VoiceTextPhase.idle);
    expect(container.read(voiceTextControllerProvider).history.first['mode'], 'live');
  });

  for (final locale in [const Locale('ar'), const Locale('en')]) {
    testWidgets('large text and reduced motion (${locale.languageCode})', (tester) async {
      reset(tester);
      final fake = FakeVoiceTextBackend()..seed();
      await pumpVoiceText(tester, fake, locale: locale, width: 320, scale: 2);
      await tapVoiceText(tester, 'vt-model-picker');
      expect(tester.takeException(), isNull);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await tapVoiceText(tester, 'vt-transcribe');
      expect(tester.takeException(), isNull);
      final button = tester.getSize(find.byKey(const ValueKey('vt-transcribe')));
      expect(button.height, greaterThanOrEqualTo(48));
    });
  }
}
