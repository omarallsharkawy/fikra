import 'package:drift/drift.dart' show Value;
import 'package:fikra/core/motion/pressable.dart';
import 'package:fikra/data/groups_repository.dart';
import 'package:fikra/data/links_repository.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:fikra/data/transcription/service_config.dart';
import 'package:fikra/data/transcription/service_keys.dart';
import 'package:fikra/data/transcription/services_repository.dart';
import 'package:fikra/features/add/add_screen.dart';
import 'package:fikra/features/ask/ask_screen.dart';
import 'package:fikra/features/connections/links_library_screen.dart';
import 'package:fikra/features/connections/note_connections_screen.dart';
import 'package:fikra/features/note_details/edit_note_screen.dart';
import 'package:fikra/features/note_details/note_details_screen.dart';
import 'package:fikra/features/notes/notes_screen.dart';
import 'package:fikra/features/projects/project_header.dart';
import 'package:fikra/features/settings/settings_screen.dart';
import 'package:fikra/features/voice_text/voice_text_screen.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_harness.dart';
import 'transcription_scroll.dart';

typedef SeededA11yData = ({Project project, Project otherProject, List<Note> notes, NoteGroup group});

/// Seeds two projects, groups, three ready notes with topics, one confirmed
/// link, one AI suggestion, an Ask question + answer with sources, and a
/// saved transcription service so every main screen and sheet is populated.
Future<SeededA11yData> seedA11yApp(
  WidgetTester tester,
  FikraDatabase db, {
  required Locale locale,
  required ServiceKeyStore serviceKeys,
}) async {
  final l = lookupAppLocalizations(locale);
  final ar = locale.languageCode == 'ar';
  await pumpUntil(tester, find.text(l.startNewProject));
  final seeded = await pumpFuture(tester, () async {
    final projects = LocalProjectsRepository(db);
    final notesRepo = LocalNotesRepository(db);
    final groupsRepo = LocalGroupsRepository(db);
    final linksRepo = LocalLinksRepository(db);
    final chatRepo = LocalChatRepository(db);

    final other = await projects.create(ar ? 'مذاكرة' : 'Study');
    final otherNote = await notesRepo.create(
      projectId: other.id,
      title: ar ? 'خطة الأسبوع' : 'Weekly plan',
      text: ar ? 'مراجعة المحاضرات وحل الشيت.' : 'Review lectures and finish problem set.',
      source: NoteSource.text,
    );
    await notesRepo.markReady(otherNote.id);

    final main = await projects.create(ar ? 'أفكار المنتج' : 'Product ideas');
    await projects.setCurrent(main.id);

    final group = await groupsRepo.create(main.id, ar ? 'التسعير' : 'Pricing', color: 0);
    await groupsRepo.create(main.id, ar ? 'خصم الطلاب' : 'Student plan', parentId: group.id, color: 1);

    final n1 = await notesRepo.create(
      projectId: main.id,
      title: ar ? 'تسعير الاشتراك الشهري' : 'Monthly subscription pricing',
      text: ar
          ? 'نبدأ بباقة بسيطة بـ٩٩ جنيه في الشهر مع تجربة مجانية أسبوعين.'
          : 'Start with a simple monthly tier and a two-week free trial.',
      source: NoteSource.text,
      createdAt: DateTime(2026, 11, 10, 11, 45),
    );
    final n2 = await notesRepo.create(
      projectId: main.id,
      title: ar ? 'مقابلات المستخدمين' : 'User interviews',
      text: ar
          ? 'أغلب الطلبة بيفضلوا الدفع الشهري عن السنوي في الأول.'
          : 'Most students prefer monthly billing over annual commitments at first.',
      source: NoteSource.text,
      createdAt: DateTime(2026, 11, 10, 10, 30),
    );
    final n3 = await notesRepo.create(
      projectId: main.id,
      title: ar ? 'بحث أوفلاين سريع' : 'Fast offline search',
      text: ar
          ? 'الفهرسة المحلية بتخلي البحث فوري من غير نت.'
          : 'Local indexing keeps note search instant without internet.',
      source: NoteSource.text,
      createdAt: DateTime(2026, 11, 10, 9, 0),
    );

    for (final (n, topic, concepts) in [
      (n1, ar ? 'الإيرادات' : 'Revenue', ar ? 'تسعير,اشتراك' : 'pricing,subscription'),
      (n2, ar ? 'البحث' : 'Research', ar ? 'مقابلات,طلاب' : 'interviews,students'),
      (n3, ar ? 'الأداء' : 'Performance', ar ? 'بحث,أوفلاين' : 'search,offline'),
    ]) {
      await (db.update(db.notes)..where((r) => r.id.equals(n.id))).write(
        NotesCompanion(status: const Value(ProcessingStatus.ready), cluster: Value(topic), concepts: Value(concepts)),
      );
    }
    await groupsRepo.assignNotes(group.id, [n1.id]);

    await linksRepo.linkNotes(n1.id, [n2.id], label: ar ? 'مرتبطة بقرارات التسعير' : 'Both inform pricing decisions');
    await db
        .into(db.noteLinks)
        .insert(
          NoteLink(
            id: 'ai-sugg-1',
            projectId: main.id,
            sourceId: n1.id,
            targetId: n3.id,
            label: ar ? 'تجربة المستخدم الأساسية' : 'Core product experience',
            strength: 0.82,
            origin: LinkOrigin.ai,
            dismissed: false,
          ),
        );

    await chatRepo.add(projectId: main.id, role: 'user', body: ar ? 'إيه خطة التسعير؟' : 'What is our pricing plan?');
    await chatRepo.add(
      projectId: main.id,
      role: 'assistant',
      body: ar
          ? 'الخطة تبدأ باشتراك شهري بسيط مع تجربة مجانية لمدة أسبوعين.'
          : 'The plan starts with a simple monthly subscription and a two-week trial.',
      sourceIds: [n1.id, n2.id],
      found: true,
    );

    const svc = TranscriptionService(
      id: 'svc-1',
      name: 'Cloud STT',
      type: TranscriptionServiceType.openAi,
      baseUrl: 'https://api.openai.com/v1',
      batchModel: 'whisper-1',
    );
    await LocalTranscriptionServices(db, serviceKeys).save(svc, key: 'sk-test');
    return (project: main, otherProject: other, notes: [n1, n2, n3], group: group);
  });
  await pumpUntil(tester, find.text(seeded.notes.first.title));
  await tester.pump(const Duration(milliseconds: 500));
  return seeded;
}

/// Visits every main screen and bottom sheet required by phase 8, invoking
/// [onScreen] once each view has settled.
Future<void> visitAllMainScreensAndSheets(
  WidgetTester tester,
  SeededA11yData data, {
  required Locale locale,
  required Future<void> Function(String screenName) onScreen,
}) async {
  final l = lookupAppLocalizations(locale);
  final n1 = data.notes[0];
  final n2 = data.notes[1];

  Future<void> settleFrames() async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  // 1. Notes list with notes
  await onScreen('notes_list');

  // 2. Notes sort sheet
  await tester.tap(find.byKey(const ValueKey('notes-sort')));
  await tester.pump();
  await settleFrames();
  await onScreen('notes_sort_sheet');
  Navigator.of(tester.element(find.byType(BottomSheet))).pop();
  await settleFrames();

  // 3. Projects sheet
  final projectPill = find.descendant(
    of: find.descendant(of: find.byType(NotesScreen), matching: find.byType(ProjectHeader)),
    matching: find.byWidgetPredicate((w) => w is Pressable && w.semanticLabel == l.projectPillA11y(data.project.name)),
  );
  await tester.tap(projectPill);
  await tester.pump();
  await settleFrames();
  await onScreen('projects_sheet');
  Navigator.of(tester.element(find.byType(BottomSheet))).pop();
  await settleFrames();

  // 4. Note details
  final notesScrollable = find.descendant(
    of: find.byType(NotesScreen),
    matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down),
  );
  final firstCard = find.descendant(of: find.byType(NotesScreen), matching: find.byKey(ValueKey(n1.id)));
  await tester.scrollUntilVisible(firstCard, 120, scrollable: notesScrollable);
  await Scrollable.ensureVisible(tester.element(firstCard), alignment: 0.5);
  await tester.pump();
  await tester.tap(firstCard);
  await pumpUntil(tester, find.byType(NoteDetailsScreen));
  await settleFrames();
  await onScreen('note_details');

  // 5. Link options sheet (scroll down to confirmed link options button)
  final linkOptionsBtn = find.byKey(ValueKey('link-options-${n2.id}'));
  await tester.scrollUntilVisible(linkOptionsBtn, 160, scrollable: transcriptionScrollable(NoteDetailsScreen));
  await tester.pump();
  await tester.tap(linkOptionsBtn);
  await tester.pump();
  await settleFrames();
  await onScreen('link_options_sheet');
  Navigator.of(tester.element(find.byType(BottomSheet))).pop();
  await settleFrames();

  // 6. Edit note
  await tester.tap(find.byKey(const ValueKey('note-edit')));
  await pumpUntil(tester, find.byType(EditNoteScreen));
  await settleFrames();
  await onScreen('edit_note');
  Navigator.of(tester.element(find.byType(EditNoteScreen))).pop();
  await pumpUntil(tester, find.byType(NoteDetailsScreen));
  await settleFrames();
  Navigator.of(tester.element(find.byType(NoteDetailsScreen))).pop();
  await pumpUntil(tester, find.byType(NotesScreen));
  await settleFrames();

  // 7. Add with typed text (unfocus so keyboard stays closed and chrome is visible)
  await tester.tap(Tabs.addButton);
  await pumpUntil(tester, find.byType(AddScreen));
  await settleFrames();
  final addFields = find.descendant(of: find.byType(AddScreen), matching: find.byType(TextField));
  await tester.enterText(addFields.at(0), locale.languageCode == 'ar' ? 'فكرة سريعة' : 'Quick thought');
  await tester.enterText(
    addFields.at(1),
    locale.languageCode == 'ar' ? 'نجرب تصميم الكروت الجديد مع الخط الكبير.' : 'Try the card layout with large text.',
  );
  FocusManager.instance.primaryFocus?.unfocus();
  tester.testTextInput.hide();
  await settleFrames();
  await onScreen('add_typed');

  // 8. Links Browse
  await tester.tap(Tabs.finder(Tabs.links));
  await pumpUntil(tester, find.byKey(const ValueKey('links-segment-1')));
  await tester.tap(find.byKey(const ValueKey('links-segment-1')));
  await pumpUntil(tester, find.byType(LinksLibraryScreen));
  await settleFrames();
  await onScreen('links_browse');

  // 9. Links sort sheet
  await tester.tap(find.byKey(const ValueKey('links-sort')));
  await tester.pump();
  await settleFrames();
  await onScreen('links_sort_sheet');
  Navigator.of(tester.element(find.byType(BottomSheet))).pop();
  await settleFrames();

  // 10. Links Suggestions
  await tester.tap(find.byKey(const ValueKey('links-segment-2')));
  await settleFrames();
  await onScreen('links_suggestions');

  // 11. A note's connections page
  await tester.tap(find.byKey(const ValueKey('links-segment-1')));
  await settleFrames();
  final browseScrollable = find
      .descendant(
        of: find.byType(LinksLibraryScreen),
        matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down),
      )
      .hitTestable();
  final browseCard = find.byKey(ValueKey('browse-${n1.id}'));
  await tester.scrollUntilVisible(browseCard, 120, scrollable: browseScrollable);
  await Scrollable.ensureVisible(tester.element(browseCard), alignment: 0.5);
  await tester.pump();
  await tester.tap(browseCard);
  await pumpUntil(tester, find.byType(NoteConnectionsScreen));
  await settleFrames();
  await onScreen('note_connections');
  Navigator.of(tester.element(find.byType(NoteConnectionsScreen))).pop();
  await pumpUntil(tester, find.byType(LinksLibraryScreen));
  await settleFrames();

  // 12. Ask with an answer
  await tester.tap(Tabs.finder(Tabs.ask));
  await pumpUntil(tester, find.byType(AskScreen));
  await settleFrames();
  await onScreen('ask_answer');

  // 13. Settings
  final askSettings = find.descendant(
    of: find.byType(AskScreen),
    matching: find.byKey(const ValueKey('header-settings')),
  );
  await tester.tap(askSettings);
  await pumpUntil(tester, find.byType(SettingsScreen));
  await settleFrames();
  await onScreen('settings');

  // 14. Voice to text settings
  final vtRow = find.byKey(const ValueKey('settings-voice-text'));
  await tester.scrollUntilVisible(vtRow, 140, scrollable: transcriptionScrollable(SettingsScreen));
  await tester.pump();
  await tester.tap(vtRow);
  await pumpUntil(tester, find.byType(VoiceTextScreen));
  await settleFrames();
  await onScreen('voice_text_settings');
}
