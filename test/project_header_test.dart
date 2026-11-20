import 'package:fikra/app/providers.dart';
import 'package:fikra/core/motion/pressable.dart';
import 'package:fikra/core/theme/fikra_theme.dart';
import 'package:fikra/core/theme/tokens.dart';
import 'package:fikra/core/widgets/solid_surface.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/features/projects/project_header.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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

void expectHeaderLayout(
  WidgetTester tester,
  HeaderCase header,
  AppLocalizations l10n,
  double width,
  double scale, {
  String? expectedProjectName,
}) {
  final title = find.text(header.title);
  final root = find.ancestor(of: title, matching: find.byType(ProjectHeader));
  expectSingleLineTitle(tester, header.title);
  final titleParagraph = tester.renderObject<RenderParagraph>(title);
  expect((titleParagraph.text as TextSpan).style!.fontSize, 28);
  expect(titleParagraph.textScaler.scale(28), closeTo(28 * scale, 0.01));
  final rtl = l10n.localeName == 'ar';
  expect(Directionality.of(tester.element(title)), rtl ? TextDirection.rtl : TextDirection.ltr);

  final name = expectedProjectName ?? l10n.sampleProjectName;
  final projectNameFinder = find.descendant(of: root, matching: find.text(name));
  final projectText = tester.widget<Text>(projectNameFinder);
  expect(projectText.maxLines, 1);
  expect(projectText.overflow, TextOverflow.ellipsis);
  final projectParagraph = tester.renderObject<RenderParagraph>(projectNameFinder);
  final ellipsis = TextPainter(
    text: TextSpan(text: '${name.characters.first}\u2026', style: projectText.style),
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
    matching: find.byWidgetPredicate((w) => w is Pressable && w.semanticLabel == l10n.projectPillA11y(name)),
  );
  final settings = find.descendant(of: root, matching: find.byKey(const ValueKey('header-settings')));
  final titleRect = tester.getRect(title);
  final chipRect = tester.getRect(chip);
  final settingsRect = tester.getRect(settings);

  // Project chip sits in its own row below the title, aligned to the start edge.
  expect(chipRect.top - titleRect.bottom, greaterThanOrEqualTo(FikraSpace.s8 - 0.01));
  if (rtl) {
    expect(chipRect.right, closeTo(width - FikraSpace.screen, 0.01));
  } else {
    expect(chipRect.left, closeTo(FikraSpace.screen, 0.01));
  }

  for (final rect in [titleRect, chipRect, settingsRect]) {
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(width));
  }
  for (final rect in [chipRect, settingsRect]) {
    expect(rect.width, greaterThanOrEqualTo(Pressable.minTargetSize));
    expect(rect.height, greaterThanOrEqualTo(Pressable.minTargetSize));
  }

  final settingsSurface = find.descendant(of: settings, matching: find.byType(SolidSurface));
  expect(tester.getSize(settingsSurface).height, greaterThanOrEqualTo(Pressable.minTargetSize));
  final settingsLabel = find.descendant(of: settings, matching: find.text(l10n.settings));
  if (settingsLabel.evaluate().isNotEmpty) {
    final gear = find.descendant(of: settings, matching: find.byIcon(Icons.settings_outlined));
    expect((tester.getCenter(gear).dy - tester.getCenter(settingsLabel).dy).abs(), lessThan(2));
  }

  if (header.action) {
    final action = find.descendant(
      of: root,
      matching: find.byWidgetPredicate((w) => w is Pressable && w.semanticLabel == l10n.clearChatA11y),
    );
    expect(action.hitTestable(), findsOneWidget);
    expect(tester.getRect(action).width, greaterThanOrEqualTo(Pressable.minTargetSize));
    expect(tester.getRect(action).height, greaterThanOrEqualTo(Pressable.minTargetSize));
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
    // The bare settings pill still has room for its label; the wrapped one does not.
    expect(find.text(l10n.settings), findsOneWidget);
    expect(find.text(long), findsNothing);
    expect(tester.getSize(find.byType(HeaderActionButton).first).width, greaterThanOrEqualTo(Pressable.minTargetSize));
  });

  for (final language in ['ar', 'en']) {
    final locale = Locale(language);
    final l10n = lookupAppLocalizations(locale);

    testWidgets(
      'settings pill is >= 48 dp tall with gear and text in one row, and navigates to /settings ($language)',
      (tester) async {
        addTearDown(tester.view.reset);
        final semantics = tester.ensureSemantics();
        try {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(390, 844);
          String? pushedLocation;
          final router = GoRouter(
            initialLocation: '/notes',
            routes: [
              GoRoute(
                path: '/notes',
                builder: (context, _) => Scaffold(body: ProjectHeader(title: l10n.notesTitle)),
              ),
              GoRoute(
                path: '/settings',
                builder: (context, state) {
                  pushedLocation = state.matchedLocation;
                  return const Scaffold(body: Center(child: Text('settings-route')));
                },
              ),
            ],
          );
          addTearDown(router.dispose);

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                selectedProjectProvider.overrideWithValue(
                  Project(id: 'sample', name: l10n.sampleProjectName, createdAt: DateTime(2026, 11, 10)),
                ),
              ],
              child: MaterialApp.router(
                routerConfig: router,
                locale: locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                theme: buildFikraTheme(Brightness.light),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final settings = find.byKey(const ValueKey('header-settings'));
          expect(settings, findsOneWidget);
          final surface = find.descendant(of: settings, matching: find.byType(SolidSurface));
          expect(tester.getSize(surface).height, greaterThanOrEqualTo(Pressable.minTargetSize));
          expect(tester.getSize(settings).height, greaterThanOrEqualTo(Pressable.minTargetSize));

          final gear = find.descendant(of: settings, matching: find.byIcon(Icons.settings_outlined));
          final label = find.descendant(of: settings, matching: find.text(l10n.settings));
          expect(gear, findsOneWidget);
          expect(label, findsOneWidget);
          expect((tester.getCenter(gear).dy - tester.getCenter(label).dy).abs(), lessThan(2));
          expect((tester.getCenter(settings).dy - tester.getCenter(find.text(l10n.notesTitle)).dy).abs(), lessThan(2));

          final node = tester.getSemantics(settings);
          expect(node.label, l10n.settings);
          expect(node.flagsCollection.isButton, isTrue);

          await tester.tap(settings);
          await tester.pumpAndSettle();
          expect(pushedLocation, '/settings');
          expect(find.text('settings-route'), findsOneWidget);
        } finally {
          semantics.dispose();
        }
      },
    );

    testWidgets('project chip sits in its own row below the title and ellipsizes long names ($language)', (
      tester,
    ) async {
      addTearDown(tester.view.reset);
      final longName = language == 'ar'
          ? 'اسم مشروع طويل جداً جداً لاختبار القطع بنقاط الحذف في السطر الثاني من الهيدر'
          : 'A very long project name to verify natural width up to the row max and ellipsis truncation';
      await pumpProjectHeaders(
        tester,
        locale: locale,
        headers: [(title: l10n.notesTitle, action: false)],
        width: 360,
        projectName: longName,
      );
      final header = (title: l10n.notesTitle, action: false);
      expectHeaderLayout(tester, header, l10n, 360, 1.0, expectedProjectName: longName);
      final titleRect = tester.getRect(find.text(l10n.notesTitle));
      final chipRect = tester.getRect(
        find.byWidgetPredicate((w) => w is Pressable && w.semanticLabel == l10n.projectPillA11y(longName)),
      );
      final settingsRect = tester.getRect(find.byKey(const ValueKey('header-settings')));
      expect(chipRect.top, greaterThan(titleRect.bottom));
      expect(chipRect.top, greaterThanOrEqualTo(settingsRect.bottom));
    });

    testWidgets(
      'at text scale 2.0 and 360 dp width there is no overflow and settings becomes 48 dp icon-only ($language)',
      (tester) async {
        addTearDown(tester.view.reset);
        final semantics = tester.ensureSemantics();
        try {
          final headers = tabHeaders(l10n);
          await pumpProjectHeaders(tester, locale: locale, headers: headers, width: 360, height: 960, scale: 2.0);
          expect(tester.takeException(), isNull);

          for (final header in headers) {
            final root = find.ancestor(of: find.text(header.title), matching: find.byType(ProjectHeader));
            final settings = find.descendant(of: root, matching: find.byKey(const ValueKey('header-settings')));
            expect(settings, findsOneWidget);
            expect(find.descendant(of: settings, matching: find.text(l10n.settings)), findsNothing);

            final surface = find.descendant(of: settings, matching: find.byType(SolidSurface));
            expect(tester.getSize(surface), const Size(48, 48));
            final gear = find.descendant(of: settings, matching: find.byIcon(Icons.settings_outlined));
            expect(tester.widget<Icon>(gear).size, 24);

            final node = tester.getSemantics(settings);
            expect(node.label, l10n.settings);
            expect(node.flagsCollection.isButton, isTrue);

            final chip = find.descendant(
              of: root,
              matching: find.byWidgetPredicate(
                (w) => w is Pressable && w.semanticLabel == l10n.projectPillA11y(l10n.sampleProjectName),
              ),
            );
            expect(tester.getRect(chip).top, greaterThan(tester.getRect(find.text(header.title)).bottom));
            expect(tester.getRect(settings).left, greaterThanOrEqualTo(0));
            expect(tester.getRect(settings).right, lessThanOrEqualTo(360));
          }
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  testWidgets('in RTL the settings pill is on the left edge and the title is on the right', (tester) async {
    addTearDown(tester.view.reset);
    const locale = Locale('ar');
    final l10n = lookupAppLocalizations(locale);
    await pumpProjectHeaders(tester, locale: locale, headers: [(title: l10n.notesTitle, action: false)], width: 390);
    final titleRect = tester.getRect(find.text(l10n.notesTitle));
    final settingsRect = tester.getRect(find.byKey(const ValueKey('header-settings')));
    expect(settingsRect.left, closeTo(FikraSpace.screen, 0.01));
    expect(titleRect.right, closeTo(390 - FikraSpace.screen, 0.01));
    expect(settingsRect.right, lessThan(titleRect.left));
    expect((settingsRect.center.dy - titleRect.center.dy).abs(), lessThan(6));
  });

  for (final language in ['ar', 'en']) {
    final locale = Locale(language);
    final l10n = lookupAppLocalizations(locale);

    Future<void> verifyThresholdWithOverrides(
      WidgetTester tester, {
      required HeaderCase header,
      required bool boldText,
      double? letterSpacingOverride,
      double? wordSpacingOverride,
    }) async {
      await pumpProjectHeaders(
        tester,
        locale: locale,
        headers: [header],
        width: 520,
        boldText: boldText,
        letterSpacingOverride: letterSpacingOverride,
        wordSpacingOverride: wordSpacingOverride,
      );
      expect(tester.takeException(), isNull);
      final settings = find.byKey(const ValueKey('header-settings'));
      expect(find.descendant(of: settings, matching: find.text(l10n.settings)), findsOneWidget);

      final titleWidth = tester.getSize(find.text(header.title)).width;
      final settingsWidth = tester.getSize(settings).width;
      final actionWidth = header.action
          ? tester
                    .getSize(find.byWidgetPredicate((w) => w is Pressable && w.semanticLabel == l10n.clearChatA11y))
                    .width +
                FikraSpace.s8
          : 0.0;
      final renderedFitWidth = FikraSpace.screen * 2 + titleWidth + FikraSpace.s12 + actionWidth + settingsWidth;

      // Sweep 1 dp steps across the collapse boundary: every width below the
      // threshold must collapse to the 48 dp icon-only circle without overflow,
      // and every width above must keep the horizontal pill without overflow.
      final low = renderedFitWidth.floor() - 6;
      final high = renderedFitWidth.ceil() + 6;
      double? collapsedMaxWidth;
      double? pillMinWidth;
      for (var w = low; w <= high; w++) {
        await pumpProjectHeaders(
          tester,
          locale: locale,
          headers: [header],
          width: w.toDouble(),
          boldText: boldText,
          letterSpacingOverride: letterSpacingOverride,
          wordSpacingOverride: wordSpacingOverride,
        );
        expect(tester.takeException(), isNull, reason: 'overflow at width $w ($language)');
        final hasLabel = find.descendant(of: settings, matching: find.text(l10n.settings)).evaluate().isNotEmpty;
        final surface = find.descendant(of: settings, matching: find.byType(SolidSurface));
        if (hasLabel) {
          pillMinWidth ??= w.toDouble();
          expect(tester.getSize(surface).height, greaterThanOrEqualTo(Pressable.minTargetSize));
        } else {
          expect(pillMinWidth, isNull, reason: 'pill unexpectedly collapsed again at wider width $w ($language)');
          collapsedMaxWidth = w.toDouble();
          expect(tester.getSize(surface), const Size(48, 48));
        }
      }
      expect(collapsedMaxWidth, isNotNull, reason: 'expected circle state below threshold ($language)');
      expect(pillMinWidth, isNotNull, reason: 'expected pill state above threshold ($language)');
      expect(pillMinWidth, collapsedMaxWidth! + 1);
    }

    testWidgets('boldText override collapses cleanly around threshold without overflow ($language)', (tester) async {
      addTearDown(tester.view.reset);
      await verifyThresholdWithOverrides(tester, header: (title: l10n.askTitle, action: true), boldText: true);
    });

    testWidgets('boldText plus letter/word spacing overrides collapse cleanly around threshold ($language)', (
      tester,
    ) async {
      addTearDown(tester.view.reset);
      await verifyThresholdWithOverrides(
        tester,
        header: (title: l10n.addTitle, action: false),
        boldText: true,
        letterSpacingOverride: 2.0,
        wordSpacingOverride: 8.0,
      );
    });
  }
}
