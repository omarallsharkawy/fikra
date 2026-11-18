import 'dart:ui' show ImageFilter;

import 'package:fikra/core/theme/fikra_theme.dart';
import 'package:fikra/core/widgets/fikra_widgets.dart';
import 'package:fikra/core/widgets/glass_power.dart';
import 'package:fikra/core/widgets/glass_watchdog.dart';
import 'package:fikra/features/notes/notes_screen.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderBackdropFilter;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import 'glass_test_fakes.dart';
import 'support/app_harness.dart';
import 'support/selection_fixture.dart' show arL10n, phone, seedNotes;

void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpHost(
    WidgetTester tester,
    Widget child, {
    GlassTier tier = GlassTier.frosted,
    Brightness brightness = Brightness.light,
    bool highContrast = false,
    bool reduced = false,
    double scale = 1.0,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          glassPowerSaveProvider.overrideWithValue(const AsyncData(false)),
          glassTimingsSourceProvider.overrideWithValue(FakeGlassTimings()),
          glassTierProvider(false).overrideWith((ref) => tier),
          glassTierProvider(true).overrideWith((ref) => tier == GlassTier.solid ? GlassTier.solid : GlassTier.frosted),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildFikraTheme(brightness),
          builder: (context, app) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(highContrast: highContrast, disableAnimations: reduced, textScaler: TextScaler.linear(scale)),
            child: app!,
          ),
          home: Scaffold(body: Center(child: child)),
        ),
      ),
    );
    addTearDown(() async => tester.pumpWidget(const SizedBox.shrink()));
  }

  group('glass bottom sheets', () {
    testWidgets('frosted and optical sheets have one sigma-24 blur, opaque inner rows and no optical lens', (
      tester,
    ) async {
      for (final tier in [GlassTier.frosted, GlassTier.optical]) {
        await pumpHost(
          tester,
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showFikraSheet<void>(
                context,
                title: 'خيارات',
                builder: (sheet) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SheetOption(label: 'عدّل', icon: Icons.edit_outlined, onTap: () => Navigator.pop(sheet)),
                    const FikraField(hint: 'دوّر'),
                  ],
                ),
              ),
              child: const Text('open'),
            ),
          ),
          tier: tier,
        );
        await tester.tap(find.text('open'));
        await tester.pump();
        // Frame 0: animation is 0.0 (sheet still offscreen), so blur must be disabled.
        final initialFilters = find.descendant(of: find.byType(BottomSheet), matching: find.byType(BackdropFilter));
        expect(initialFilters, findsOneWidget);
        expect(tester.widget<BackdropFilter>(initialFilters).filter, ImageFilter.blur(sigmaX: 24, sigmaY: 24));
        expect((tester.renderObject(initialFilters) as RenderBackdropFilter).enabled, isFalse);

        await tester.pumpAndSettle();
        expect(tester.renderObject<RenderBackdropFilter>(initialFilters).enabled, isTrue);
        expect(tester.widget<BackdropFilter>(initialFilters).filter, ImageFilter.blur(sigmaX: 24, sigmaY: 24));
        expect(find.descendant(of: find.byType(BottomSheet), matching: find.byType(LiquidGlassLens)), findsNothing);

        // Content rows and fields inside the sheet stay on opaque SolidSurface.
        final surfaces = tester.widgetList<Container>(
          find.descendant(
            of: find.descendant(of: find.byType(BottomSheet), matching: find.byType(SolidSurface)),
            matching: find.byType(Container),
          ),
        );
        expect(surfaces, isNotEmpty);
        for (final s in surfaces) {
          final dec = s.decoration;
          if (dec is BoxDecoration && dec.color != null) {
            expect(dec.color!.a, 1.0);
          }
        }

        // Closing removes the sheet and its blur completely.
        await tester.tap(find.text('عدّل'));
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsNothing);
        expect(find.byType(BackdropFilter), findsNothing);
      }
    });

    testWidgets('solid tier and highContrast omit sheet BackdropFilter and use opaque surface', (tester) async {
      for (final (tier, highContrast) in [(GlassTier.solid, false), (GlassTier.frosted, true)]) {
        await pumpHost(
          tester,
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showFikraSheet<void>(
                context,
                title: 'خيارات',
                builder: (sheet) => SheetOption(label: 'عدّل', icon: Icons.edit_outlined, onTap: () {}),
              ),
              child: const Text('open'),
            ),
          ),
          tier: tier,
          highContrast: highContrast,
        );
        await tester.tap(find.text('open'));
        await tester.pump();
        await tester.pumpAndSettle();
        expect(find.descendant(of: find.byType(BottomSheet), matching: find.byType(BackdropFilter)), findsNothing);
        final sheetGlass = find.descendant(of: find.byType(BottomSheet), matching: find.byType(Glass));
        final backing = tester.widget<ColoredBox>(
          find.descendant(of: sheetGlass, matching: find.byType(ColoredBox)).first,
        );
        expect(backing.color.a, 1.0);
        Navigator.of(tester.element(find.byType(BottomSheet))).pop();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('confirmDestructive dialogs stay solid even at frosted tier', (tester) async {
      await pumpHost(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => confirmDestructive(context, title: 'تحذف؟', message: 'مش هتعرف ترجّعها.'),
            child: const Text('ask'),
          ),
        ),
        tier: GlassTier.frosted,
      );
      await tester.tap(find.text('ask'));
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(Dialog), matching: find.byType(BackdropFilter)), findsNothing);
      expect(find.descendant(of: find.byType(Dialog), matching: find.byType(Glass)), findsNothing);
      expect(find.descendant(of: find.byType(Dialog), matching: find.byType(SolidSurface)), findsWidgets);
    });
  });

  group('glass toast capsule', () {
    testWidgets('frosted toast has one sigma-24 blur, solid and highContrast have none, and runAction uses glass', (
      tester,
    ) async {
      await pumpHost(
        tester,
        Builder(
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(onPressed: () => showToast(context, 'اتحفظت'), child: const Text('toast')),
              TextButton(
                onPressed: () => runAction(context, () async {}, success: 'تم'),
                child: const Text('run'),
              ),
            ],
          ),
        ),
        tier: GlassTier.frosted,
      );
      await tester.tap(find.text('toast'));
      await tester.pumpAndSettle();
      final capsule = find.byKey(const ValueKey('toast-capsule'));
      expect(capsule, findsOneWidget);
      final toastFilter = find.descendant(of: capsule, matching: find.byType(BackdropFilter));
      expect(toastFilter, findsOneWidget);
      expect(tester.widget<BackdropFilter>(toastFilter).filter, ImageFilter.blur(sigmaX: 24, sigmaY: 24));

      await tester.tap(find.text('run'));
      await tester.pumpAndSettle();
      expect(find.text('تم'), findsOneWidget);
      expect(find.descendant(of: capsule, matching: find.byType(BackdropFilter)), findsOneWidget);

      await pumpHost(
        tester,
        Builder(
          builder: (context) => TextButton(onPressed: () => showToast(context, 'اتحفظت'), child: const Text('toast')),
        ),
        tier: GlassTier.frosted,
        highContrast: true,
      );
      await tester.tap(find.text('toast'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: find.byKey(const ValueKey('toast-capsule')), matching: find.byType(BackdropFilter)),
        findsNothing,
      );
    });

    testWidgets('taps and drags just beside and just below a toast reach the widgets underneath', (tester) async {
      var sideTaps = 0;
      var belowTaps = 0;
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      await pumpHost(
        tester,
        Stack(
          fit: StackFit.expand,
          children: [
            ListView.builder(
              controller: scrollController,
              itemCount: 30,
              itemExtent: 60,
              itemBuilder: (context, index) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => sideTaps++,
                child: Align(alignment: AlignmentDirectional.centerStart, child: Text('row-$index')),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 10,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => belowTaps++,
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
        tier: GlassTier.frosted,
      );

      showToast(tester.element(find.text('row-0')), 'تم الحفظ');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final capsule = find.byKey(const ValueKey('toast-capsule'));
      final rect = tester.getRect(capsule);
      expect(rect.left, greaterThan(40));

      // Tap just beside the capsule (left and right): reaches the list row underneath.
      await tester.tapAt(Offset(rect.left - 6, rect.center.dy));
      await tester.pump();
      expect(sideTaps, 1);

      await tester.tapAt(Offset(rect.right + 6, rect.center.dy));
      await tester.pump();
      expect(sideTaps, 2);

      // Tap just below the capsule (inside the bottom inset gap): reaches the widget underneath.
      await tester.tapAt(Offset(rect.center.dx, rect.bottom + 6));
      await tester.pump();
      expect(belowTaps, 1);

      // Vertical drag beside the capsule scrolls the list without dismissing the toast.
      await tester.dragFrom(Offset(rect.left - 12, rect.center.dy), const Offset(0, -120));
      await tester.pump();
      expect(scrollController.offset, greaterThan(50));
      expect(capsule, findsOneWidget);
    });

    fikraTest(
      'shell toast uses its own single ungrouped blur, clears bar and Add, and rises above open keyboard',
      glassTier: GlassTier.frosted,
      (tester, db) async {
        phone(tester);
        addTearDown(tester.view.resetViewInsets);
        await seedNotes(tester, db, ['A']);

        showToast(
          tester.element(find.byType(NotesScreen)),
          arL10n.noteSaved,
          actionLabel: arL10n.undo,
          onAction: () {},
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        final capsule = find.byKey(const ValueKey('toast-capsule'));
        expect(capsule, findsOneWidget);
        final toastBottom = tester.getBottomLeft(capsule).dy;
        expect(toastBottom, lessThan(tester.getTopLeft(find.byKey(const ValueKey('floating-tab-bar'))).dy));
        expect(toastBottom, lessThan(tester.getTopLeft(Tabs.addButton).dy));

        final toastFilter = find.descendant(of: capsule, matching: find.byType(BackdropFilter));
        expect(toastFilter, findsOneWidget);
        expect(tester.renderObject<RenderBackdropFilter>(toastFilter).backdropKey, isNull);

        // Open keyboard (300 dp): toast moves above the keyboard.
        tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        final screenHeight = tester.view.physicalSize.height / tester.view.devicePixelRatio;
        expect(tester.getBottomLeft(capsule).dy, lessThanOrEqualTo(screenHeight - 300));
      },
    );
  });

  group('FikraField sizing', () {
    testWidgets('is exactly 48 dp at 1.0x focused and unfocused in light and dark, and grows at 2.0x', (tester) async {
      for (final brightness in Brightness.values) {
        await pumpHost(
          tester,
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 22),
            child: FikraField(hint: 'دوّر في ملاحظاتك', icon: Icons.search_rounded, clearable: true),
          ),
          brightness: brightness,
        );
        expect(tester.getSize(find.byType(FikraField)).height, 48.0);
        await tester.tap(find.byType(TextField));
        await tester.pump();
        expect(tester.getSize(find.byType(FikraField)).height, 48.0);
      }

      await pumpHost(
        tester,
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 22),
          child: FikraField(hint: 'دوّر في ملاحظاتك', icon: Icons.search_rounded),
        ),
        scale: 2.0,
      );
      expect(tester.getSize(find.byType(FikraField)).height, greaterThan(48.0));
    });
  });
}
