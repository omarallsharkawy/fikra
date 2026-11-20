import 'dart:math' as math;
import 'dart:ui' show SemanticsAction, Tristate;

import 'package:fikra/core/theme/tokens.dart';
import 'package:fikra/core/widgets/glass_quality.dart';
import 'package:fikra/features/connections/links_library_screen.dart';
import 'package:fikra/features/notes/notes_screen.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/a11y_fixture.dart';
import 'support/app_harness.dart';
import 'support/fake_external_transcription.dart';
import 'voice_text/fake_voice_text_backend.dart';

class _ExcludingTextContrastGuideline extends MinimumTextContrastGuideline {
  const _ExcludingTextContrastGuideline(this.excluded);
  final Set<String> excluded;

  @override
  bool shouldSkipNode(SemanticsData data) => super.shouldSkipNode(data) || excluded.contains(data.label);
}

double _wcagRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  for (final code in ['ar', 'en']) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      final locale = Locale(code);
      final serviceKeys = MemoryServiceKeys();
      final voiceBackend = FakeVoiceTextBackend()
        ..arabic = (code == 'ar')
        ..seed();

      fikraTest(
        'all main screens and sheets meet TalkBack guidelines ($code, ${brightness.name})',
        locale: locale,
        brightness: brightness,
        glassTier: GlassTier.frosted,
        serviceKeys: serviceKeys,
        voiceTextBackend: voiceBackend,
        (tester, db) async {
          WidgetController.hitTestWarningShouldBeFatal = true;
          addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(390, 844);
          addTearDown(tester.view.reset);

          final l = lookupAppLocalizations(locale);
          final semantics = tester.ensureSemantics();
          try {
            final data = await seedA11yApp(tester, db, locale: locale, serviceKeys: serviceKeys);
            await visitAllMainScreensAndSheets(
              tester,
              data,
              locale: locale,
              onScreen: (screenName) async {
                await expectLater(
                  tester,
                  meetsGuideline(androidTapTargetGuideline),
                  reason: '$screenName ($code ${brightness.name}) tap targets',
                );
                await expectLater(
                  tester,
                  meetsGuideline(labeledTapTargetGuideline),
                  reason: '$screenName ($code ${brightness.name}) labeled tap targets',
                );
                // 11sp NotoSansArabic strokes are <1px at 1x DPR so _ContrastReport samples anti-aliased fringes instead of the >=5.3:1 text color.
                final Set<String> ar11spFalsePositives = code != 'ar'
                    ? const <String>{}
                    : brightness == Brightness.light
                    ? switch (screenName) {
                        'links_browse' || 'links_suggestions' => {l.linksSuggestedForYou},
                        'ask_answer' => {l.askDemoBadge},
                        'voice_text_settings' => {l.vtExperimental},
                        _ => const <String>{},
                      }
                    : switch (screenName) {
                        'ask_answer' => {l.askDemoBadge},
                        'voice_text_settings' => {l.vtExperimental},
                        _ => const <String>{},
                      };
                final palette = brightness == Brightness.light ? FikraPalette.light : FikraPalette.dark;
                for (final label in ar11spFalsePositives) {
                  final matches = find.text(label).hitTestable().evaluate();
                  expect(matches, isNotEmpty, reason: '$screenName excluded "$label" matched nothing');
                  for (final el in matches) {
                    final style = DefaultTextStyle.of(el).style.merge((el.widget as Text).style);
                    expect(_wcagRatio(style.color!, palette.canvas), greaterThanOrEqualTo(4.5));
                    expect(_wcagRatio(style.color!, palette.chip), greaterThanOrEqualTo(4.5));
                  }
                }
                final guideline = ar11spFalsePositives.isEmpty
                    ? textContrastGuideline
                    : _ExcludingTextContrastGuideline(ar11spFalsePositives);
                await expectLater(
                  tester,
                  meetsGuideline(guideline),
                  reason: '$screenName ($code ${brightness.name}) text contrast',
                );
              },
            );
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }

  for (final code in ['ar', 'en']) {
    final locale = Locale(code);
    final serviceKeys = MemoryServiceKeys();
    final voiceBackend = FakeVoiceTextBackend()
      ..arabic = (code == 'ar')
      ..seed();

    fikraTest(
      'semantics spot-checks: localized labels, headers, buttons, selected states, excluded decorative icons, RTL order ($code)',
      locale: locale,
      brightness: Brightness.light,
      glassTier: GlassTier.frosted,
      serviceKeys: serviceKeys,
      voiceTextBackend: voiceBackend,
      (tester, db) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.reset);

        final l = lookupAppLocalizations(locale);
        final semantics = tester.ensureSemantics();
        try {
          final data = await seedA11yApp(tester, db, locale: locale, serviceKeys: serviceKeys);

          // Main screen header is marked as header; tab buttons have labels, button & selected flags.
          final notesTitleNode = tester.getSemantics(
            find.descendant(of: find.byType(NotesScreen), matching: find.text(l.notesTitle)),
          );
          expect(notesTitleNode.flagsCollection.isHeader, isTrue);

          final navNotes = tester.getSemantics(Tabs.finder(Tabs.notes));
          expect(navNotes.label, l.navHome);
          expect(navNotes.flagsCollection.isButton, isTrue);
          expect(navNotes.flagsCollection.isSelected, Tristate.isTrue);

          final navLinks = tester.getSemantics(Tabs.finder(Tabs.links));
          expect(navLinks.label, l.navMap);
          expect(navLinks.flagsCollection.isButton, isTrue);
          expect(navLinks.flagsCollection.isSelected, Tristate.isFalse);

          final navAdd = tester.getSemantics(Tabs.addButton);
          expect(navAdd.label, l.navAdd);
          expect(navAdd.flagsCollection.isButton, isTrue);

          // Decorative MaterialIcons never expose raw icon-codepoint semantics nodes.
          void verifyNoRawIconNodes(SemanticsNode node) {
            if (!node.isMergedIntoParent && !node.flagsCollection.isHidden) {
              for (final rune in node.label.runes) {
                expect(rune < 0xE000 || rune > 0xF8FF, isTrue, reason: 'Unexcluded icon glyph in $node');
              }
            }
            node.visitChildren((child) {
              verifyNoRawIconNodes(child);
              return true;
            });
          }

          final root = tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!;
          verifyNoRawIconNodes(root);

          // In RTL, the visible tab bar reading order follows visual right-to-left order:
          // Notes (rightmost) -> Links -> Ask -> Add (leftmost).
          if (code == 'ar') {
            final ordered = <String>[];
            void walkTraversal(SemanticsNode node) {
              if (!node.isMergedIntoParent &&
                  !node.flagsCollection.isHidden &&
                  node.getSemanticsData().hasAction(SemanticsAction.tap) &&
                  node.label.isNotEmpty) {
                ordered.add(node.label);
              }
              for (final child in node.debugListChildrenInOrder(DebugSemanticsDumpOrder.traversalOrder)) {
                walkTraversal(child);
              }
            }

            walkTraversal(root);
            final notesIdx = ordered.indexOf(l.navHome);
            final linksIdx = ordered.indexOf(l.navMap);
            final askIdx = ordered.indexOf(l.navAsk);
            final addIdx = ordered.indexOf(l.navAdd);
            expect(notesIdx, greaterThanOrEqualTo(0));
            expect(linksIdx, greaterThan(notesIdx));
            expect(askIdx, greaterThan(linksIdx));
            expect(addIdx, greaterThan(askIdx));

            expect(ordered.indexOf(l.navMe), greaterThan(askIdx));
            expect(ordered.indexOf(l.projectPillA11y(data.project.name)), greaterThanOrEqualTo(0));
            expect(find.byKey(const ValueKey('header-settings')), findsNothing);
          }

          // Links Browse: LibraryControls (search/sort/segments) precede list cards in traversal order.
          await tester.tap(Tabs.finder(Tabs.links));
          await pumpUntil(tester, find.byType(LinksLibraryScreen));
          await tester.pump(const Duration(milliseconds: 500));
          final linksOrdered = <String>[];
          void walkLinks(SemanticsNode node) {
            if (!node.isMergedIntoParent && !node.flagsCollection.isHidden && node.label.isNotEmpty) {
              linksOrdered.add(node.label);
            }
            for (final child in node.debugListChildrenInOrder(DebugSemanticsDumpOrder.traversalOrder)) {
              walkLinks(child);
            }
          }

          walkLinks(root);
          final sortIdx = linksOrdered.indexOf(l.linksSort);
          final browseIdx = linksOrdered.indexOf(l.linksBrowse);
          final groupHeaderIdx = linksOrdered.indexOf(l.linksGroups);
          expect(sortIdx, greaterThan(0));
          expect(browseIdx, greaterThan(sortIdx));
          expect(groupHeaderIdx, greaterThan(browseIdx));

          // Sort sheet: header flag on sheet title and selected flag on current option.
          await tester.tap(find.byKey(const ValueKey('links-sort')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          final sheetTitle = tester.getSemantics(
            find.descendant(of: find.byType(BottomSheet), matching: find.text(l.linksSort)),
          );
          expect(sheetTitle.flagsCollection.isHeader, isTrue);
          final newestOpt = tester.getSemantics(
            find.descendant(of: find.byKey(const ValueKey('links-sort-newest')), matching: find.text(l.linksNewest)),
          );
          expect(newestOpt.flagsCollection.isSelected, Tristate.isTrue);
        } finally {
          semantics.dispose();
        }
      },
    );
  }
}
