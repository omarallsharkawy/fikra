import 'package:fikra/app/providers.dart';
import 'package:fikra/core/motion/pressable.dart';
import 'package:fikra/core/theme/fikra_theme.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/features/projects/project_header.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';

typedef HeaderCase = ({String title, bool action});

List<HeaderCase> tabHeaders(AppLocalizations l10n) => [
  (title: l10n.addTitle, action: false),
  (title: l10n.notesTitle, action: false),
  (title: l10n.linksTitle, action: false),
  (title: l10n.askTitle, action: true),
];

/// Real typography and the same optional action as Ask, without database I/O.
Future<void> pumpProjectHeaders(
  WidgetTester tester, {
  required Locale locale,
  required List<HeaderCase> headers,
  double width = 390,
  double scale = 1,
  Widget Function(Widget action)? wrapAction,
  String? actionLabel,
}) async {
  final l10n = lookupAppLocalizations(locale);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 640);
  await tester.pumpWidget(
    RepaintBoundary(
      key: appBoundaryKey,
      child: ProviderScope(
        overrides: [
          selectedProjectProvider.overrideWithValue(
            Project(id: 'sample', name: l10n.sampleProjectName, createdAt: DateTime(2026, 11, 10)),
          ),
        ],
        child: MaterialApp(
          locale: locale,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildFikraTheme(Brightness.dark),
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: Column(
                  children: [
                    for (final header in headers)
                      ProjectHeader(
                        title: header.title,
                        trailing: header.action
                            ? (wrapAction ?? (w) => w)(
                                HeaderActionButton(
                                  icon: Icons.delete_sweep_outlined,
                                  label: actionLabel ?? l10n.clear,
                                  semanticLabel: l10n.clearChatA11y,
                                  onTap: () {},
                                ),
                              )
                            : null,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void expectSingleLineTitle(WidgetTester tester, String title) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(title));
  final natural = TextPainter(
    text: paragraph.text,
    textDirection: paragraph.textDirection,
    textScaler: paragraph.textScaler,
    locale: paragraph.locale,
  )..layout();
  expect(paragraph.size.height, closeTo(natural.height, 0.01), reason: 'The full title must render on one line');
  expect(paragraph.size.width, greaterThanOrEqualTo(natural.width - 0.01), reason: 'Keep normal-size title width');
  expect(paragraph.didExceedMaxLines, isFalse);
  natural.dispose();
}

void expectHeaderLayout(WidgetTester tester, HeaderCase header, AppLocalizations l10n, double width, double scale) {
  final title = find.text(header.title);
  final root = find.ancestor(of: title, matching: find.byType(ProjectHeader));
  expectSingleLineTitle(tester, header.title);
  final titleParagraph = tester.renderObject<RenderParagraph>(title);
  expect((titleParagraph.text as TextSpan).style!.fontSize, 26);
  expect(titleParagraph.textScaler.scale(26), closeTo(26 * scale, 0.01));
  expect(Directionality.of(tester.element(title)), l10n.localeName == 'ar' ? TextDirection.rtl : TextDirection.ltr);

  final projectName = find.descendant(of: root, matching: find.text(l10n.sampleProjectName));
  final projectText = tester.widget<Text>(projectName);
  expect(projectText.maxLines, 1);
  expect(projectText.overflow, TextOverflow.ellipsis);
  final projectParagraph = tester.renderObject<RenderParagraph>(projectName);
  final ellipsis = TextPainter(
    text: TextSpan(text: '${l10n.sampleProjectName.characters.first}\u2026', style: projectText.style),
    textDirection: projectParagraph.textDirection,
    textScaler: projectParagraph.textScaler,
    locale: projectParagraph.locale,
  )..layout();
  expect(
    projectParagraph.size.width,
    greaterThanOrEqualTo(ellipsis.width),
    reason: 'The project name must show at least an initial and ellipsis',
  );
  ellipsis.dispose();
  final chip = find.descendant(
    of: root,
    matching: find.byWidgetPredicate(
      (w) => w is Pressable && w.semanticLabel == l10n.projectPillA11y(l10n.sampleProjectName),
    ),
  );
  final settings = find.descendant(
    of: root,
    matching: find.byWidgetPredicate((w) => w is Pressable && w.semanticLabel == l10n.settings),
  );
  final titleRect = tester.getRect(title);
  final chipRect = tester.getRect(chip);
  final settingsRect = tester.getRect(settings);
  final sameRow = (titleRect.center.dy - chipRect.center.dy).abs() < 1;
  if (sameRow) {
    final gap = l10n.localeName == 'ar' ? titleRect.left - chipRect.right : chipRect.left - titleRect.right;
    expect(gap, greaterThanOrEqualTo(12 - 0.01));
  } else {
    expect(chipRect.top - titleRect.bottom, greaterThanOrEqualTo(8 - 0.01));
  }
  for (final rect in [titleRect, chipRect, settingsRect]) {
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(width));
  }
  for (final rect in [chipRect, settingsRect]) {
    expect(rect.width, greaterThanOrEqualTo(48));
    expect(rect.height, greaterThanOrEqualTo(48));
  }
  if (header.action) {
    final action = find.descendant(
      of: root,
      matching: find.byWidgetPredicate((w) => w is Pressable && w.semanticLabel == l10n.clearChatA11y),
    );
    expect(action.hitTestable(), findsOneWidget);
    expect(tester.getRect(action).width, greaterThanOrEqualTo(48));
  }
  expect(tester.takeException(), isNull);
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('Arabic Add header renders the complete title on one line', (tester) async {
    addTearDown(tester.view.reset);
    final locale = const Locale('ar');
    final title = lookupAppLocalizations(locale).addTitle;
    await pumpProjectHeaders(tester, locale: locale, headers: [(title: title, action: false)]);
    expectSingleLineTitle(tester, title);
  });

  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 390.0]) {
      for (final scale in [1.0, 1.3]) {
        testWidgets('all tab headers: $language, $width dp, text scale $scale', (tester) async {
          addTearDown(tester.view.reset);
          final locale = Locale(language);
          final l10n = lookupAppLocalizations(locale);
          final headers = tabHeaders(l10n);
          await pumpProjectHeaders(tester, locale: locale, headers: headers, width: width, scale: scale);
          for (final header in headers) {
            expectHeaderLayout(tester, header, l10n, width, scale);
          }
        });
      }
    }
  }

  testWidgets('a wrapped header action gets no reserved label room, so it shows icon-only', (tester) async {
    addTearDown(tester.view.reset);
    const locale = Locale('en');
    final l10n = lookupAppLocalizations(locale);
    const long = 'A much longer caption than any real one';
    await pumpProjectHeaders(
      tester,
      locale: locale,
      headers: [(title: l10n.askTitle, action: true)],
      actionLabel: long,
      wrapAction: (action) => Padding(padding: EdgeInsets.zero, child: action),
    );
    expect(tester.takeException(), isNull);
    // The bare settings button still has room for its caption; the wrapped one does not.
    expect(find.text(l10n.settings), findsOneWidget);
    expect(find.text(long), findsNothing);
    expect(tester.getSize(find.byType(HeaderActionButton).first).width, greaterThanOrEqualTo(Pressable.minTargetSize));
  });
}
