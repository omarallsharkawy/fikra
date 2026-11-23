// flutter test test/screenshots/phase7_motion_test.dart --run-skipped -t screenshots
@Tags(['screenshots'])
library;

import 'dart:async';
import 'dart:io';

import 'package:fikra/app/shell.dart';
import 'package:fikra/core/motion/motion.dart';
import 'package:fikra/core/widgets/glass_quality.dart';
import 'package:fikra/data/attachment_draft.dart';
import 'package:fikra/data/files/attachment_store.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/features/add/add_screen.dart';
import 'package:fikra/features/notes/notes_screen.dart';
import 'package:fikra/features/shared/attachment_editor.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../support/app_harness.dart';
import '../support/fake_transcription_engine.dart';
import '../support/recording_fake.dart';

class _ScreenshotStore extends AttachmentStore {
  _ScreenshotStore(this.dir) : super(documentsDir: () async => dir(), tempDir: () async => dir());
  final Directory Function() dir;
  @override
  Future<String> persist(String source, {required String extension}) async => '${dir().path}/saved.m4a';
  @override
  Future<void> sweepOrphans(Set<String> referenced) async {}
  @override
  Future<void> clearPickerCopies() async {}
}

void main() {
  setUpAll(loadAppFonts);
  late Directory tempDir;
  final store = _ScreenshotStore(() => tempDir);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('fikra-shot-p7-');
    addTearDown(() => tempDir.delete(recursive: true));
  });

  for (final locale in [const Locale('ar'), const Locale('en')]) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      final gate = Completer<String>();
      fikraTest(
        'phase 7 motion screenshots (${locale.languageCode}, ${brightness.name})',
        locale: locale,
        brightness: brightness,
        glassTier: GlassTier.frosted,
        attachmentStore: store,
        microphonePermission: () async => PermissionStatus.granted,
        aiService: FakeTranscriptionAi(),
        transcriptionEngine: FakeTranscriptionEngine(action: (_, _) => gate.future),
        clock: () => DateTime(2026, 11, 10, 12),
        tags: 'screenshots',
        (tester, db) async {
          tester.view.devicePixelRatio = 3;
          tester.view.physicalSize = const Size(390 * 3, 844 * 3);
          tester.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
          tester.view.viewPadding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
          addTearDown(tester.view.reset);

          final fakeRec = RecordingFake([])
            ..amplitudeSequence = [-42, -28, -14, -5, -18, -34, -9, -12, -24, -4, -16, -30, -8, -19];
          final prevRec = RecordPlatform.instance;
          RecordPlatform.instance = fakeRec;
          addTearDown(() => RecordPlatform.instance = prevRec);

          final l10n = lookupAppLocalizations(locale);
          final isAr = locale.languageCode == 'ar';
          String path(String name) => '${locale.languageCode}/${brightness.name}/phase7_$name';

          await pumpUntil(tester, find.text(l10n.welcomeStartWriting));
          await pumpFuture(tester, () async {
            final p = await LocalProjectsRepository(db).create(isAr ? 'مشروع التخرج' : 'Capstone');
            final repo = LocalNotesRepository(db);
            for (var i = 1; i <= 18; i++) {
              final n = await repo.create(
                projectId: p.id,
                title: isAr ? 'فكرة رقم $i' : 'Idea #$i',
                text: isAr
                    ? 'تفاصيل الملاحظة رقم $i لمراجعة الحركة والانتقالات بسلاسة.'
                    : 'Note #$i body text for reviewing smooth motion and bar transitions.',
                source: NoteSource.text,
                createdAt: DateTime(2026, 11, 10, 11, i),
              );
              await repo.markReady(n.id);
            }
          });
          await pumpUntil(tester, find.text(isAr ? 'فكرة رقم 18' : 'Idea #18'));
          await tester.pump(const Duration(milliseconds: 450));

          // 1. Save tick mid-animation.
          await tester.tap(Tabs.addButton);
          await pumpUntil(tester, find.byType(AddScreen));
          await tester.pump(const Duration(milliseconds: 300));
          final fields = find.descendant(of: find.byType(AddScreen), matching: find.byType(TextField));
          await tester.enterText(fields.first, isAr ? 'ملخص سريع' : 'Quick summary');
          await tester.enterText(
            fields.last,
            isAr ? 'نقطة مهمة من المحاضرة النهارده.' : 'Key takeaway from today’s lecture.',
          );
          await tester.pump();
          final saveBtn = find.byKey(const ValueKey('add-save'));
          await tester.tap(saveBtn);
          final add = tester.state(find.byType(AddScreen)) as AttachmentEditing<AddScreen>;
          await pumpFuture(tester, () async {
            while (add.saving) {
              await Future<void>.delayed(const Duration(milliseconds: 5));
            }
          });
          ScaffoldMessenger.of(tester.element(find.byType(AddScreen))).hideCurrentSnackBar();
          await tester.pump(const Duration(milliseconds: 95));
          expect(find.byType(SaveTickMark), findsOneWidget);
          await saveScreenshot(tester, path('save_tick'), settle: Duration.zero);
          await tester.pump(FikraMotion.saveTick + const Duration(milliseconds: 100));

          // 2. Recording with breathing pulse ring and live waveform.
          await tester.tap(Tabs.addButton);
          await pumpUntil(tester, find.byType(AddScreen));
          await tester.pump(const Duration(milliseconds: 300));
          final recState = tester.state(find.byType(AddScreen)) as AttachmentEditing<AddScreen>;
          await pumpFuture(tester, recState.startRecording);
          for (var i = 0; i < 24; i++) {
            await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 92)));
            await tester.pump(const Duration(milliseconds: 92));
          }
          await saveScreenshot(tester, path('recording'), settle: Duration.zero);

          // 3. Activity capsule above the bar while recording on another tab.
          await tester.tap(find.byKey(const ValueKey('add-close')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 450));
          await tester.pump(const Duration(seconds: 1));
          expect(find.byKey(const ValueKey('activity-capsule')), findsOneWidget);
          await saveScreenshot(tester, path('capsule_recording'), settle: Duration.zero);

          await tester.tap(find.byKey(const ValueKey('activity-capsule')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 350));
          await pumpFuture(tester, recState.cancelRecording);
          await tester.pump(const Duration(milliseconds: 300));

          // 4. Activity capsule above the bar while background transcription runs.
          await tester.runAsync(() => File('${tempDir.path}/voice.m4a').writeAsString('audio'));
          recState.updateDraft(
            () => recState.draftFiles = [
              AttachmentDraft(
                kind: AttachmentKind.voice,
                path: '${tempDir.path}/voice.m4a',
                durationMs: 4000,
                policy: TranscriptionPolicy.afterSave,
              ),
            ],
          );
          await tester.pump();
          await Scrollable.ensureVisible(tester.element(saveBtn), alignment: 0.5);
          await tester.pump(const Duration(milliseconds: 300));
          await tester.tap(saveBtn);
          await pumpFuture(tester, () async {
            while (recState.saving) {
              await Future<void>.delayed(const Duration(milliseconds: 5));
            }
          });
          await tester.pump(FikraMotion.saveTick + const Duration(milliseconds: 100));
          await pumpUntil(tester, find.byType(NotesScreen));
          await pumpUntil(tester, find.byKey(const ValueKey('activity-capsule')));
          ScaffoldMessenger.of(tester.element(find.byKey(const ValueKey('activity-capsule')))).hideCurrentSnackBar();
          await tester.pump(const Duration(milliseconds: 450));
          await saveScreenshot(tester, path('capsule_transcribing'), settle: Duration.zero);
          gate.complete(isAr ? 'نص مفرّغ' : 'Transcribed text');
          await tester.pump(const Duration(milliseconds: 300));

          // 5. Shrunk floating tab bar with the debug experiment flag ON.
          ProviderScope.containerOf(tester.element(find.byType(AppShell)))
              .read(navBarShrinkEnabledProvider.notifier)
              .setEnabled(true);
          await tester.pump();
          final notesScroll = find.descendant(
            of: find.byType(NotesScreen),
            matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down),
          );
          await tester.drag(notesScroll, const Offset(0, -240));
          await tester.pump(const Duration(milliseconds: 200));
          expect(tester.getSize(find.byType(FikraNavBar)).height, closeTo(FikraMotion.barShrunkHeight, 0.5));
          await saveScreenshot(tester, path('shrunk_bar'), settle: Duration.zero);
        },
      );
    }
  }
}
