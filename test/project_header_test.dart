import 'package:fikra/app/providers.dart';
import 'package:fikra/core/motion/pressable.dart';
import 'package:fikra/core/theme/fikra_theme.dart';
import 'package:fikra/core/theme/tokens.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/features/projects/project_header.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
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
  Brightness brightness = Brightness.dark,
  double width = 390,
  double height = 640,
  double scale = 1,
  bool boldText = false,
  double? lineHeightScaleFactorOverride,
  double? letterSpacingOverride,
  double? wordSpacingOverride,
  String? projectName,
  Widget Function(Widget action)? wrapAction,
  String? actionLabel,
}) async {
  final l10n = lookupAppLocalizations(locale);
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  await tester.pumpWidget(
    RepaintBoundary(
      key: appBoundaryKey,
      child: ProviderScope(
        overrides: [
          selectedProjectProvider.overrideWithValue(
            Project(id: 'sample', name: projectName ?? l10n.sampleProjectName, createdAt: DateTime(2026, 11, 10)),
          ),
        ],
        child: MaterialApp(
          locale: locale,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildFikraTheme(brightness),
          home: Builder(
            builder: (context) {
              var media = MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale), boldText: boldText);
              if (lineHeightScaleFactorOverride != null ||
                  letterSpacingOverride != null ||
                  wordSpacingOverride != null) {
                media = media.applyTextStyleOverrides(
                  lineHeightScaleFactorOverride: lineHeightScaleFactorOverride,
                  letterSpacingOverride: letterSpacingOverride,
                  wordSpacingOverride: wordSpacingOverride,
                  paragraphSpacingOverride: null,
                );
              }
              return MediaQuery(
                data: media,
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
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void expectHeaderLayout(
  WidgetTester tester,
  HeaderCase header,
  AppLocalizations l10n,
  double width,
  double scale, {
  String? expectedProjectName,
}) {
  final root = find.ancestor(of: find.text(header.title), matching: find.byType(ProjectHeader));
  expect(find.descendant(of: root, matching: find.byKey(const ValueKey('header-settings'))), findsNothing);
  final title = find.text(header.title);
  final titleParagraph = tester.renderObject<RenderParagraph>(title);
  expect((titleParagraph.text as TextSpan).style!.fontSize, 28);
  expect(titleParagraph.textScaler.scale(28), closeTo(28 * scale, 0.01));
  final rtl = l10n.localeName == 'ar';
  expect(Directionality.of(tester.element(title)), rtl ? TextDirection.rtl : TextDirection.ltr);

  final name = expectedProjectName ?? l10n.sampleProjectName;
  final chip = find.descendant(
    of: root,
    matching: find.byWidgetPredicate((w) => w is Pressable && w.semanticLabel == l10n.projectPillA11y(name)),
  );
  final titleRect = tester.getRect(find.text(header.title));
  final chipRect = tester.getRect(chip);
  expect(chipRect.top, greaterThanOrEqualTo(titleRect.bottom + 8));
  expect(chipRect.width, greaterThanOrEqualTo(48));
  expect(chipRect.height, greaterThanOrEqualTo(48));
  expect(chipRect.left, greaterThanOrEqualTo(0));
  expect(chipRect.right, lessThanOrEqualTo(width));
  expect(tester.widget<Text>(find.descendant(of: chip, matching: find.text(name))).overflow, TextOverflow.ellipsis);
  if (l10n.localeName == 'ar') {
    expect(chipRect.right, closeTo(width - FikraSpace.screen, .01));
  } else {
    expect(chipRect.left, closeTo(FikraSpace.screen, .01));
  }
}

void main() {
  setUpAll(loadAppFonts);
  for (final language in ['ar', 'en']) {
    final locale = Locale(language);
    final l = lookupAppLocalizations(locale);
    for (final scale in [1.0, 1.3, 2.0]) {
      for (final width in [320.0, 390.0]) {
        testWidgets('project header has no Settings and retains chip $language $width $scale', (tester) async {
          addTearDown(tester.view.reset);
          final headers = tabHeaders(l);
          await pumpProjectHeaders(tester, locale: locale, headers: headers, width: width, height: 1200, scale: scale);
          expect(tester.takeException(), isNull);
          for (final header in headers) {
            expectHeaderLayout(tester, header, l, width, scale);
          }
        });
      }
    }
    testWidgets('long project and accessibility spacing fit $language', (tester) async {
      addTearDown(tester.view.reset);
      final name = List.filled(12, l.sampleProjectName).join(' ');
      await pumpProjectHeaders(
        tester,
        locale: locale,
        headers: [(title: l.notesTitle, action: false)],
        width: 360,
        projectName: name,
        boldText: true,
        letterSpacingOverride: 2,
        wordSpacingOverride: 8,
      );
      expectHeaderLayout(tester, (title: l.notesTitle, action: false), l, 360, 1, expectedProjectName: name);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('wrapped action uses icon only and keeps its accessible name', (tester) async {
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    try {
      final l = lookupAppLocalizations(const Locale('en'));
      await pumpProjectHeaders(
        tester,
        locale: const Locale('en'),
        headers: [(title: l.askTitle, action: true)],
        wrapAction: (w) => Padding(padding: EdgeInsets.zero, child: w),
      );
      expect(find.text(l.clear), findsNothing);
      final action = find.byType(HeaderActionButton);
      expect(tester.getSize(action), const Size(48, 48));
      expect(tester.getSemantics(action).label, l.clearChatA11y);
    } finally {
      semantics.dispose();
    }
  });
}
