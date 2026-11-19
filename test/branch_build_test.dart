import 'package:fikra/core/motion/stagger.dart';
import 'package:fikra/core/motion/stagger_visibility.dart';
import 'package:fikra/features/connections/links_library_screen.dart';
import 'package:fikra/features/notes/notes_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';
import 'support/selection_fixture.dart';

List<StaggerController> _controllers(WidgetTester tester, Type screen) => tester
    .widget<StaggerVisibility>(
      find.descendant(of: find.byType(screen, skipOffstage: false), matching: find.byType(StaggerVisibility)),
    )
    .controllers;

void _start(List<StaggerController> controllers) {
  for (final controller in controllers) {
    controller.reset();
    controller.maybeStart(projectId: 'visibility-probe', visibleIds: ['probe'], tickerEnabled: true, reduced: false);
    expect(controller.isAnimating, isTrue);
  }
}

void main() {
  fikraTest('branch switches rebuild neither heavy screen and stop hidden Notes/Browse/Suggestions staggers', (
    tester,
    db,
  ) async {
    phone(tester);
    await seedNotes(tester, db, ['A', 'B']);
    await tester.tap(Tabs.finder(Tabs.links));
    await pumpAnimations(tester);
    final linksControllers = _controllers(tester, LinksLibraryScreen);
    await tester.tap(Tabs.finder(Tabs.notes));
    await pumpAnimations(tester);
    final notesControllers = _controllers(tester, NotesScreen);

    var notesBuilds = 0;
    var linksBuilds = 0;
    final previous = debugOnRebuildDirtyWidget;
    debugOnRebuildDirtyWidget = (element, builtOnce) {
      previous?.call(element, builtOnce);
      if (element.widget is NotesScreen) notesBuilds++;
      if (element.widget is LinksLibraryScreen) linksBuilds++;
    };
    addTearDown(() => debugOnRebuildDirtyWidget = previous);

    for (var cycle = 0; cycle < 2; cycle++) {
      _start(notesControllers);
      await tester.pump(const Duration(milliseconds: 8));
      await tester.tap(Tabs.finder(Tabs.links));
      await tester.pump();
      expect(notesControllers.single.isAnimating, isFalse);
      expect(notesControllers.single.slotOf('probe'), isNull);
      _start(linksControllers);
      await tester.pump(const Duration(milliseconds: 8));
      await tester.tap(Tabs.finder(Tabs.ask));
      await tester.pump();
      for (final controller in linksControllers) {
        expect(controller.isAnimating, isFalse);
        expect(controller.slotOf('probe'), isNull);
      }
      await tester.tap(Tabs.finder(Tabs.notes));
      await pumpAnimations(tester);
      expect(notesControllers.single.isAnimating, isFalse);
      expect(notesBuilds, 0);
      expect(linksBuilds, 0);
    }
  });

  fikraTest('Reduce Motion stops already running staggers through the visibility leaf', (tester, db) async {
    phone(tester);
    await seedNotes(tester, db, ['A']);
    final controllers = _controllers(tester, NotesScreen);
    _start(controllers);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pump();
    expect(controllers.single.isAnimating, isFalse);
    expect(controllers.single.slotOf('probe'), isNull);
  });
}
