import 'package:fikra/app/providers.dart';
import 'package:fikra/data/groups_repository.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/features/shared/group_form.dart';
import 'package:fikra/features/shared/group_options.dart';
import 'package:fikra/features/shared/group_sheet.dart';
import 'package:fikra/features/shared/note_groups.dart';
import 'package:fikra/features/shared/selection_bar.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';
import 'support/selection_fixture.dart' show host;

/// Every text under [of] is laid out in full: no clipped line, and inside
/// the screen once scrolled to.
void expectAllTextShown(WidgetTester tester, Finder of) {
  for (final element in find.descendant(of: of, matching: find.byType(RichText)).evaluate()) {
    final paragraph = element.renderObject! as RenderParagraph;
    expect(paragraph.didExceedMaxLines, isFalse, reason: paragraph.text.toPlainText());
  }
}

/// The open sheet really has the test's text [scale] (it is scaled above the
/// navigator), and every text in it is shown in full.
void expectSheetShown(WidgetTester tester, double scale) {
  final sheet = find.byType(BottomSheet).last;
  expect(MediaQuery.textScalerOf(tester.element(sheet)).scale(10), moreOrLessEquals(10 * scale));
  expectAllTextShown(tester, sheet);
}

/// The label of the button [key] lies inside the button: not clipped.
void expectLabelInside(WidgetTester tester, String key) {
  final button = find.byKey(ValueKey(key));
  final box = tester.getRect(button).inflate(0.5);
  final text = find.descendant(of: button, matching: find.byType(RichText)).last;
  final label = tester.getRect(text);
  expect(box.contains(label.topLeft) && box.contains(label.bottomRight), isTrue, reason: '$key: $label in $box');
  // The paragraph got all the room its lines need (a fixed-height button
  // squeezes it, and the rest is cut off).
  final paragraph = tester.renderObject<RenderParagraph>(text);
  expect(paragraph.textSize.height, lessThanOrEqualTo(paragraph.size.height + 0.5), reason: key);
  expect(paragraph.didExceedMaxLines, isFalse, reason: key);
}

void main() {
  setUpAll(loadAppFonts);
  final parent = NoteGroup(
    id: 'g1',
    projectId: 'p',
    name: 'مذاكرة الترم التاني كلها',
    position: 0,
    createdAt: DateTime(2026),
  );

  for (final locale in const [Locale('ar'), Locale('en')]) {
    final l10n = lookupAppLocalizations(locale);
    for (final scale in [1.0, 2.0, 3.0]) {
      testWidgets('the action bar fits at ${scale}x (${locale.languageCode})', (tester) async {
        final bar = SelectionActionBar(
          note: l10n.linkTogetherLimit(6),
          actions: [
            for (final (k, label) in [
              ('link', l10n.linkTogether),
              ('group', l10n.groupAction),
              ('move', l10n.moveConfirm),
              ('delete', l10n.delete),
            ])
              SelectionAction(key: ValueKey('selection-$k'), icon: Icons.circle, label: label, onTap: () {}),
          ],
        );
        await host(
          tester,
          Align(alignment: Alignment.bottomCenter, child: bar),
          locale: locale,
          scale: scale,
        );
        expect(tester.takeException(), isNull);
        expectAllTextShown(tester, find.byType(SelectionActionBar));
        for (final k in ['link', 'group', 'move', 'delete']) {
          final action = find.byKey(ValueKey('selection-$k'));
          await tester.ensureVisible(action);
          await tester.pump();
          final box = tester.getRect(action);
          expect(box.width, greaterThanOrEqualTo(48));
          expect(box.height, greaterThanOrEqualTo(48));
          expect(box.left, greaterThanOrEqualTo(0), reason: k);
          expect(box.right, lessThanOrEqualTo(390), reason: k);
          final text = find.descendant(of: action, matching: find.byType(RichText)).last; // the first is the icon
          final label = tester.getRect(text);
          expect(box.inflate(0.5).contains(label.topLeft) && box.inflate(0.5).contains(label.bottomRight), isTrue);
          // No word is broken across lines: the label is at least as wide as
          // its longest word.
          final paragraph = tester.renderObject<RenderParagraph>(text);
          for (final word in paragraph.text.toPlainText().split(' ')) {
            final painter = TextPainter(
              text: TextSpan(text: word, style: paragraph.text.style),
              textDirection: paragraph.textDirection,
              textScaler: paragraph.textScaler,
            )..layout();
            expect(paragraph.size.width, greaterThanOrEqualTo(painter.width - 0.5), reason: '$k: $word');
            painter.dispose();
          }
        }
        if (scale == 1) {
          // At normal size the four share the width, one line each, no scrolling.
          expect(find.byKey(const ValueKey('selection-bar-scroll')), findsNothing);
          for (final k in ['link', 'group', 'move', 'delete']) {
            final text = find
                .descendant(of: find.byKey(ValueKey('selection-$k')), matching: find.byType(RichText))
                .last;
            expect(tester.renderObject<RenderParagraph>(text).size.height, lessThan(13 * 1.5 * 1.5), reason: k);
          }
        }
      });

      testWidgets('the group sheet and new-group form fit at ${scale}x (${locale.languageCode})', (tester) async {
        final sub = NoteGroup(
          id: 'g2',
          projectId: 'p',
          parentId: 'g1',
          name: 'Sub-group with a long name',
          color: 2,
          position: 1,
          createdAt: DateTime(2026),
        );
        await host(
          tester,
          Consumer(
            builder: (context, ref, _) => Column(
              children: [
                TextButton(
                  onPressed: () => showGroupSheet(context, projectId: 'p', canRemove: true),
                  child: const Text('sheet'),
                ),
                TextButton(
                  onPressed: () => showNewGroupForm(context, projectId: 'p'),
                  child: const Text('form'),
                ),
                TextButton(
                  onPressed: () => askGroupName(context, initial: parent.name),
                  child: const Text('rename'),
                ),
                TextButton(onPressed: () => showGroupOptions(context, ref, parent), child: const Text('options')),
              ],
            ),
          ),
          locale: locale,
          scale: scale,
          overrides: [
            groupsOfProjectProvider('p').overrideWith((ref) => Stream.value([parent, sub])),
            notesOfProjectProvider('p').overrideWith((ref) => Stream.value(const <Note>[])),
            groupsRepoProvider.overrideWithValue(_UnusedGroups()),
          ],
        );
        Future<void> open(String button) async {
          await tester.tap(find.text(button));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));
          expect(tester.takeException(), isNull);
        }

        Future<void> close() async {
          Navigator.of(tester.element(find.byType(BottomSheet).last)).pop();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));
        }

        await open('sheet');
        expect(find.byKey(const ValueKey('group-pick-g2')), findsOneWidget);
        expectSheetShown(tester, scale);
        await close();

        await open('form');
        expect(find.byKey(const ValueKey('group-parent-g1')), findsOneWidget);
        expect(find.byType(GroupColorPicker), findsOneWidget);
        expectSheetShown(tester, scale);
        await tester.enterText(find.descendant(of: find.byType(BottomSheet), matching: find.byType(TextField)), 'x');
        await tester.pump();
        await tester.ensureVisible(find.byKey(const ValueKey('group-create')));
        await tester.pump();
        expect(tester.getRect(find.byKey(const ValueKey('group-create'))).bottom, lessThanOrEqualTo(844));
        expectLabelInside(tester, 'group-create');
        await close();

        await open('rename');
        expectSheetShown(tester, scale);
        await tester.ensureVisible(find.byKey(const ValueKey('group-rename-save')));
        await tester.pump();
        expectLabelInside(tester, 'group-rename-save');
        await close();

        // The options of a group with a sub-group: "put inside" is disabled with why.
        await open('options');
        expectSheetShown(tester, scale);
        expect(find.text(l10n.groupRuleHasChildren), findsOneWidget);
        for (final k in ['group-rename', 'group-color', 'group-nest', 'group-delete']) {
          await tester.ensureVisible(find.byKey(ValueKey(k)));
          await tester.pump();
          expectLabelInside(tester, k);
        }
        await close();
      });
    }
  }
}

/// Never called: the sheets above only read the repository.
class _UnusedGroups implements GroupsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
