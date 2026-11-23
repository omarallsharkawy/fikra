import 'package:fikra/features/connections/library_session.dart';
import 'package:fikra/data/attachment_draft.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:fikra/features/settings/settings_screen.dart';
import 'package:fikra/features/note_details/edit_note_screen.dart';
import 'package:fikra/features/note_details/note_details_screen.dart';
import 'package:fikra/features/note_details/pdf_viewer_screen.dart';
import 'package:fikra/features/notes/note_card.dart';
import 'package:fikra/core/motion/motion.dart';
import 'package:fikra/app/shell.dart';
import 'package:fikra/data/ai/ai_service.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/app_harness.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('ar'));
  fikraTest('welcome -> demo project -> notes list -> links tab', (tester, db) async {
    final tryDemo = find.text(l10n.welcomeTrySample);
    await pumpUntil(tester, tryDemo);
    expect(Directionality.of(tester.element(tryDemo)), TextDirection.rtl);

    await tester.tap(tryDemo);
    // Newest seeded note: top of the list once seeding finished.
    await pumpUntil(tester, find.text(l10n.sample7Title));
    expect(find.text(l10n.sampleProjectName), findsOneWidget);

    await tester.tap(Tabs.finder(Tabs.links));
    await pumpUntil(tester, find.byKey(LinksLibrarySegment.key(LinksLibrarySegment.browse)));
    expect(find.text(l10n.linksBrowse), findsOneWidget);
  });

  fikraTest('notes search filters after a short pause and clears instantly', (tester, db) async {
    await pumpUntil(tester, find.text(l10n.welcomeTrySample));
    await tester.tap(find.text(l10n.welcomeTrySample));
    await pumpUntil(tester, find.text(l10n.sample7Title));
    expect(find.text(l10n.sample6Title), findsWidgets);

    await tester.enterText(find.byType(TextField).first, 'TCP');
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(l10n.sample6Title), findsWidgets); // debounced: not filtered yet
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(l10n.sample7Title), findsOneWidget);
    expect(find.text(l10n.sample6Title), findsNothing);

    await tester.enterText(find.byType(TextField).first, '');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(l10n.sample6Title), findsWidgets);
  });

  fikraTest('settings: theme choice applies and wipe returns to welcome', (tester, db) async {
    await pumpUntil(tester, find.text(l10n.welcomeTrySample));
    await tester.tap(find.text(l10n.welcomeTrySample));
    await pumpUntil(tester, find.text(l10n.sample7Title));

    await tester.tap(Tabs.finder(Tabs.me));
    await pumpUntil(tester, find.text(l10n.appearance));
    expect(Theme.of(tester.element(find.text(l10n.appearance))).brightness, Brightness.dark);

    await tester.tap(find.text(l10n.themeLight));
    await pumpUntil(tester, find.text(l10n.appearance));
    for (
      var i = 0;
      i < 20 && Theme.of(tester.element(find.text(l10n.appearance))).brightness != Brightness.light;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(Theme.of(tester.element(find.text(l10n.appearance))).brightness, Brightness.light);

    // The voice to text row pushes erase-all below the 800x600 test viewport.
    await tester.scrollUntilVisible(
      find.text(l10n.eraseAll),
      200,
      scrollable: find.descendant(of: find.byType(SettingsScreen), matching: find.byType(Scrollable)).first,
    );
    await Scrollable.ensureVisible(tester.element(find.text(l10n.eraseAll)), alignment: .5);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text(l10n.eraseAll));
    await pumpUntil(tester, find.text(l10n.eraseAllConfirm));
    await tester.tap(find.text(l10n.eraseAllConfirm));
    await pumpUntil(tester, find.text(l10n.welcomeStartWriting));
    await pumpUntil(tester, find.text(l10n.eraseAllDone));
    expect(await pumpFuture(tester, () => db.select(db.notes).get()), isEmpty);
    // The theme choice survives the wipe.
    expect(Theme.of(tester.element(find.text(l10n.welcomeStartWriting))).brightness, Brightness.light);
  });

  fikraTest('add: one composer box holds title, text, tools and save', (tester, db) async {
    await pumpUntil(tester, find.text(l10n.welcomeTrySample));
    await tester.tap(find.text(l10n.welcomeTrySample));
    await pumpUntil(tester, find.text(l10n.sample7Title));

    await tester.tap(Tabs.addButton);
    final save = find.byKey(const ValueKey('add-save'));
    await pumpUntil(tester, save);
    expect(find.byKey(const ValueKey('add-mic')), findsOneWidget);
    expect(find.byKey(const ValueKey('add-pdf')), findsOneWidget);
    expect(find.byKey(const ValueKey('add-image')), findsOneWidget);

    // Empty draft: save does nothing.
    await tester.tap(save);
    await tester.pump(const Duration(milliseconds: 300));
    expect(save, findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'فكرة الكومبوزر');
    await tester.enterText(find.byType(TextField).last, 'البوكس فيه كل حاجة زي الشات.');
    await tester.pump();
    await tester.tap(save);
    await pumpUntil(tester, find.text('فكرة الكومبوزر'));
    await tester.pump(const Duration(seconds: 5)); // let the demo analysis finish
    final notes = await pumpFuture(tester, () => db.select(db.notes).get());
    expect(notes.where((n) => n.title == 'فكرة الكومبوزر'), hasLength(1));
  });

  fikraTest('deleting the last project returns to welcome', (tester, db) async {
    await pumpUntil(tester, find.text(l10n.welcomeStartWriting));

    final projects = LocalProjectsRepository(db);
    final p = await pumpFuture(tester, () => projects.create('مؤقت'));
    await pumpUntil(tester, find.text('مؤقت'));

    await pumpFuture(tester, () => projects.delete(p.id));
    await pumpUntil(tester, find.text(l10n.welcomeStartWriting));
    expect(await pumpFuture(tester, () => db.select(db.projects).get()), isEmpty);
  });

  fikraTest('a note from another project still shows its related notes', (tester, db) async {
    await pumpUntil(tester, find.text(l10n.welcomeStartWriting));
    final projects = LocalProjectsRepository(db);
    final notes = LocalNotesRepository(db);

    late Note a;
    await pumpFuture(tester, () async {
      final p1 = await projects.create('الأول');
      a = await notes.create(projectId: p1.id, title: 'نوت أ', text: 'x', source: NoteSource.text);
      final b = await notes.create(projectId: p1.id, title: 'نوت ب', text: 'y', source: NoteSource.text);
      await notes.applyInsights(
        a.id,
        NoteInsights(
          title: 'نوت أ',
          concepts: const [],
          cluster: 'k',
          links: [ProposedLink(targetId: b.id, label: 'مرتبطة', strength: 1)],
        ),
      );
      await projects.create('التاني'); // becomes the selected project
    });
    await pumpUntil(tester, find.text('التاني'));

    tester.element(find.text('التاني')).push('/note/${a.id}');
    await pumpUntil(tester, find.text('نوت ب'));
  });

  group('attachment navigation', () {
    final opened = <String>[];
    var canOpen = true;
    Future<bool> opener(String path) async {
      opened.add(path);
      return canOpen;
    }

    setUp(() {
      opened.clear();
      canOpen = true;
    });

    Future<Note> seed(WidgetTester tester, FikraDatabase db) async {
      await pumpUntil(tester, find.text(l10n.welcomeStartWriting));
      late Note note;
      await pumpFuture(tester, () async {
        final p = await LocalProjectsRepository(db).create('مشروع');
        final notes = LocalNotesRepository(db);
        note = await notes.create(
          projectId: p.id,
          title: 'ملزمة',
          text: '',
          source: NoteSource.pdf,
          attachments: [
            AttachmentDraft(kind: AttachmentKind.pdf, path: '/files/a.pdf', name: 'a.pdf'),
            for (final path in const ['/files/1.jpg', '/files/2.jpg'])
              AttachmentDraft(kind: AttachmentKind.image, path: path),
          ],
        );
        await notes.markReady(note.id);
      });
      await pumpUntil(tester, find.text('ملزمة'));
      return note;
    }

    Future<void> openNote(WidgetTester tester, Note note) async {
      tester.element(find.text('ملزمة')).push('/note/${note.id}');
      await pumpUntil(
        tester,
        find.byWidgetPredicate(
          (w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('open-pdf-'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
    }

    fikraTest('the PDF row pushes the viewer; photos still open externally', (tester, db) async {
      final note = await seed(tester, db);
      await openNote(tester, note);
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('open-pdf-'),
        ),
      );
      await pumpUntil(tester, find.byType(PdfViewerScreen));
      await pumpUntil(tester, find.text(l10n.pdfLoadFailed));
      final context = tester.element(find.byType(PdfViewerScreen));
      expect(
        GoRouterState.of(context).uri.path,
        '/note/${note.id}/pdf/${(await pumpFuture(tester, () => LocalNotesRepository(db).watchAttachments(note.id).first)).firstOrNull?.id ?? 'missing'}',
      );
      expect(opened, isEmpty);
      await tester.pump(const Duration(milliseconds: 500));
      context.pop();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byKey(const ValueKey('open-photo-1')));
      await tester.pump();
      expect(opened, ['/files/2.jpg']);
    }, opener: opener);

    fikraTest('the PDF card icon opens the note and has no separate hit area', (tester, db) async {
      final note = await seed(tester, db);
      expect(find.byKey(ValueKey('open-pdf-${note.id}')), findsNothing);
      final icon = find.descendant(of: find.byType(NoteCard), matching: find.byIcon(Icons.picture_as_pdf_outlined));
      await tester.tap(icon);
      await pumpUntil(tester, find.byType(NoteDetailsScreen));
      expect(opened, isEmpty);
    }, opener: opener);

    fikraTest('a missing PDF shows the error and can open the stored path elsewhere', (tester, db) async {
      final note = await seed(tester, db);
      // A query parameter must never override the file stored on the note.
      tester
          .element(find.text('ملزمة'))
          .push(
            '/note/${note.id}/pdf/${(await pumpFuture(tester, () => LocalNotesRepository(db).watchAttachments(note.id).first)).firstOrNull?.id ?? 'missing'}?path=/untrusted.pdf',
          );
      await pumpUntil(tester, find.text(l10n.pdfLoadFailed));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byKey(const ValueKey('pdf-open-elsewhere')));
      await tester.pump();
      expect(opened, ['/files/a.pdf']);
      expect(find.byType(PdfViewerScreen), findsOneWidget);
    }, opener: opener);

    fikraTest('says so when nothing on the phone can open it', (tester, db) async {
      canOpen = false;
      await openNote(tester, await seed(tester, db));
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('open-pdf-'),
        ),
      );
      await pumpUntil(tester, find.text(l10n.pdfLoadFailed));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byKey(const ValueKey('pdf-open-elsewhere')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(l10n.openFileFailed), findsOneWidget);
    }, opener: opener);

    fikraTest('a note without a PDF has a failure state on the PDF route', (tester, db) async {
      final pdfNote = await seed(tester, db);
      final note = await pumpFuture(
        tester,
        () =>
            LocalNotesRepository(db)
                .create(projectId: pdfNote.projectId, title: 'text', text: 'text', source: NoteSource.text),
      );
      tester
          .element(find.text('ملزمة'))
          .push(
            '/note/${note.id}/pdf/${(await pumpFuture(tester, () => LocalNotesRepository(db).watchAttachments(note.id).first)).firstOrNull?.id ?? 'missing'}?path=/untrusted.pdf',
          );
      await pumpUntil(tester, find.text(l10n.pdfLoadFailed));
      expect(find.byType(PdfViewerScreen), findsOneWidget);
      expect(opened, isEmpty);
      expect(tester.takeException(), isNull);
    }, opener: opener);

    fikraTest('a deleted note has a failure state on the PDF route', (tester, db) async {
      await seed(tester, db);
      tester.element(find.text('ملزمة')).push('/note/deleted/pdf/missing');
      await pumpUntil(tester, find.text(l10n.pdfLoadFailed));
      expect(tester.takeException(), isNull);
    }, opener: opener);
  });

  fikraTest('an opened note shows its content on the first frame, before the query returns', (tester, db) async {
    await pumpUntil(tester, find.text(l10n.welcomeStartWriting));
    late Note note;
    await pumpFuture(tester, () async {
      final p = await LocalProjectsRepository(db).create('مشروع');
      note = await LocalNotesRepository(db)
          .create(projectId: p.id, title: 'نوت سريعة', text: 'محتوى', source: NoteSource.text);
    });
    await pumpUntil(tester, find.text('مشروع'));

    // The list card under the sliding page shows the same text, so look only
    // inside the details screen.
    // The first frame of a pushed page is built offstage (the hero controller
    // measures it), so the finders include offstage widgets.
    final details = find.byType(NoteDetailsScreen, skipOffstage: false);
    final content = find.descendant(of: details, matching: find.text('محتوى', skipOffstage: false));

    // go_router parses the location asynchronously: pump to the route's first frame.
    Future<void> firstFrameOfDetails() async {
      for (var i = 0; i < 5 && details.evaluate().isEmpty; i++) {
        await tester.pump();
      }
      expect(details, findsOneWidget);
    }

    // Deep link (no note handed over): nothing until the query answers.
    tester.element(find.text('مشروع')).push('/note/${note.id}');
    await firstFrameOfDetails();
    expect(content, findsNothing);
    await pumpUntil(tester, content);
    tester.element(details).pop();
    await tester.pumpAndSettle();

    // From the app (note handed over): drawn with the page itself.
    tester.element(find.text('مشروع')).push('/note/${note.id}', extra: note);
    await firstFrameOfDetails();
    expect(content, findsOneWidget);
  });

  // go_router 18 falls back to NoTransitionPage for Flutter's own MaterialApp,
  // so pushed screens must stay explicit pages with the app's transition.
  fikraTest('note and edit push transitions and the settings alias resolve through the real router', (
    tester,
    db,
  ) async {
    await pumpUntil(tester, find.text(l10n.welcomeStartWriting));
    late Note note;
    await pumpFuture(tester, () async {
      final p = await LocalProjectsRepository(db).create('مشروع');
      note = await LocalNotesRepository(db)
          .create(projectId: p.id, title: 'نوت', text: 'محتوى', source: NoteSource.text);
    });
    await pumpUntil(tester, find.text('مشروع'));

    Future<void> expectSlideIn(String location, Type screen) async {
      tester
          .element(find.byType(AppShell, skipOffstage: false))
          .push(location, extra: location == '/note/${note.id}' ? note : null);
      // go_router parses the location asynchronously; the page appears within a frame or two.
      for (var i = 0; i < 5 && find.byType(screen).evaluate().isEmpty; i++) {
        await tester.pump();
      }
      final route = ModalRoute.of(tester.element(find.byType(screen)))!;
      expect(route, isA<PageRoute<void>>());
      expect((route as PageRoute<void>).transitionDuration, FikraMotion.push, reason: location);
      await tester.pump(FikraMotion.push ~/ 2);
      expect(route.animation!.value, inExclusiveRange(0.0, 1.0), reason: '$location animates');
      await tester.pump(FikraMotion.push); // edit has a blinking cursor, so it never "settles"
      expect(route.animation!.value, 1);
    }

    await expectSlideIn('/note/${note.id}', NoteDetailsScreen);
    await expectSlideIn('/note/${note.id}/edit', EditNoteScreen);
    // System back (not a direct pop) goes through PopScope and the router.
    // Edit leaves through its PopScope and pops a frame later, so allow a
    // couple of frames on top of the 400 ms slide.
    Future<void> systemBack(Type screen) async {
      await tester.binding.handlePopRoute();
      final gone = find.byType(screen, skipOffstage: false);
      for (var ms = 0; ms <= FikraMotion.push.inMilliseconds + 100 && gone.evaluate().isNotEmpty; ms += 50) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(gone, findsNothing, reason: '$screen closes on system back');
    }

    await systemBack(EditNoteScreen); // the form is unchanged, so it leaves without asking
    expect(find.byType(NoteDetailsScreen), findsOneWidget);
    await systemBack(NoteDetailsScreen);
    tester.element(find.byType(AppShell)).go('/settings');
    await pumpUntil(tester, find.byType(SettingsScreen));
    expect(GoRouter.of(tester.element(find.byType(SettingsScreen))).state.uri.path, '/me');
  });
}
