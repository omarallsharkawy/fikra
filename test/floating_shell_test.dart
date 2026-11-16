import 'package:fikra/app/tab_bar/floating_navigation.dart';
import 'package:fikra/features/add/add_screen.dart';
import 'package:fikra/core/widgets/toasts.dart';
import 'package:fikra/features/note_details/note_details_screen.dart';
import 'package:fikra/features/links/links_screen.dart';
import 'package:fikra/features/notes/notes_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';
import 'support/selection_fixture.dart';

Finder notesScrollable() => find.descendant(
  of: find.byType(NotesScreen),
  matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down),
);

void main() {
  fikraTest('last Notes item scrolls completely clear of bar and Add, including safe area', (tester, db) async {
    phone(tester);
    tester.view.padding = const FakeViewPadding(bottom: 34 * 3);
    tester.view.viewPadding = const FakeViewPadding(bottom: 34 * 3);
    final (_, _, notes) = await seedNotes(tester, db, List.generate(45, (i) => 'Note $i'));
    final lastRow = find.byKey(ValueKey(notes[0].id));
    await tester.scrollUntilVisible(lastRow, 500, scrollable: notesScrollable());
    final position = tester.state<ScrollableState>(notesScrollable()).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pumpAndSettle();
    final bottom = tester.getBottomLeft(lastRow).dy;
    expect(bottom, lessThan(tester.getTopLeft(find.byKey(const ValueKey('floating-tab-bar'))).dy - 8));
    expect(bottom, lessThan(tester.getTopLeft(Tabs.addButton).dy));
  });

  fikraTest('a pushed Notes branch page and its list scroll survive a live slide away and back', (tester, db) async {
    phone(tester);
    final (_, _, notes) = await seedNotes(tester, db, List.generate(25, (i) => 'Note $i'));
    final position = tester.state<ScrollableState>(notesScrollable()).position;
    position.jumpTo(350);
    await tester.pumpAndSettle();
    final offset = position.pixels;
    // Production /note routes still live above the shell. Push this real details
    // widget onto Notes' own Navigator to exercise the persistent branch stack.
    final navigator = Navigator.of(tester.element(find.byType(NotesScreen)));
    navigator.push<void>(
      MaterialPageRoute(
        builder: (_) => NoteDetailsScreen(noteId: notes[24].id, initial: notes[24]),
      ),
    );
    await tester.pumpAndSettle();
    final details = tester.state(find.byType(NoteDetailsScreen));
    final pointer = await tester.startGesture(tester.getCenter(Tabs.finder(Tabs.notes)));
    addTearDown(pointer.removePointer);
    for (final tab in [Tabs.links, Tabs.ask, Tabs.links, Tabs.notes]) {
      await pointer.moveTo(tester.getCenter(Tabs.finder(tab)));
      await tester.pump();
    }
    await pointer.up();
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(NoteDetailsScreen)), same(details));
    expect(navigator.canPop(), isTrue);
    navigator.pop();
    await tester.pumpAndSettle();
    expect(position.pixels, offset);
  });

  fikraTest('existing toasts stay above navigation and do not block tab taps', (tester, db) async {
    phone(tester);
    await seedNotes(tester, db, ['A']);
    showToast(tester.element(find.byType(NotesScreen)), arL10n.noteSaveFailed);
    await tester.pumpAndSettle();
    expect(
      tester.getBottomLeft(find.text(arL10n.noteSaveFailed)).dy,
      lessThan(tester.getTopLeft(find.byKey(const ValueKey('floating-tab-bar'))).dy),
    );
    await tester.tap(Tabs.finder(Tabs.links));
    await tester.pumpAndSettle();
  });

  fikraTest('keyboard frames reuse the shell tree and do not rebuild other branch screens', (tester, db) async {
    phone(tester);
    addTearDown(tester.view.resetViewInsets);
    await seedNotes(tester, db, ['A', 'B']);
    await tester.tap(Tabs.finder(Tabs.links));
    await tester.pumpAndSettle();
    await tester.tap(Tabs.finder(Tabs.notes));
    await tester.pumpAndSettle();
    final links = LinksScreen.builds;
    final closed = tester.widget(find.byType(FloatingNavigation));
    tester.view.viewInsets = const FakeViewPadding(bottom: 80 * 3);
    await tester.pump();
    final open = tester.widget(find.byType(FloatingNavigation));
    expect(open, isNot(same(closed)));
    // Later keyboard-animation frames only change the inset's height.
    for (final height in [160, 240, 300]) {
      tester.view.viewInsets = FakeViewPadding(bottom: height * 3.0);
      await tester.pump();
      expect(tester.widget(find.byType(FloatingNavigation)), same(open));
    }
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    // The offstage Links screen only re-pads; its build is not repeated.
    expect(LinksScreen.builds, links);
  });

  fikraTest('Add button retains draft and keyboard hides both floating controls', (tester, db) async {
    final semantics = tester.ensureSemantics();
    phone(tester);
    await seedNotes(tester, db, ['A']);
    await tester.tap(Tabs.addButton);
    await tester.pumpAndSettle();
    final fields = find.descendant(of: find.byType(AddScreen), matching: find.byType(TextField));
    final title = fields.at(0);
    await tester.enterText(title, 'Draft stays');
    tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 110));
    final opacity = find.ancestor(
      of: find.byKey(const ValueKey('floating-navigation')),
      matching: find.byType(AnimatedOpacity),
    );
    expect(tester.widget<AnimatedOpacity>(opacity).opacity, 0);
    // The live tree: bySemanticsLabel can still see a node excluded mid-test.
    expect(find.semantics.byLabel(arL10n.navAdd), findsNothing);
    expect(find.semantics.byLabel(arL10n.navNotes), findsNothing);
    expect(Tabs.addButton.hitTestable(), findsNothing);
    expect(Tabs.finder(Tabs.notes).hitTestable(), findsNothing);
    tester.view.viewInsets = const FakeViewPadding();
    tester.testTextInput.hide();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(Tabs.finder(Tabs.notes));
    await tester.pumpAndSettle();
    await tester.tap(Tabs.addButton);
    await tester.pumpAndSettle();
    expect(find.text('Draft stays'), findsOneWidget);
    semantics.dispose();
  });
}
