import 'dart:io';

import 'package:fikra/l10n/localizations.dart';

import 'dart:ui' show ImageByteFormat;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:fikra/app/app.dart';
import 'package:fikra/app/providers.dart';
import 'package:fikra/data/files/attachment_store.dart';
import 'package:fikra/data/files/file_opener.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/features/note_details/pdf_document_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Tab indexes in AppShell (right to left in RTL).
abstract final class Tabs {
  static const add = 0, notes = 1, links = 2, ask = 3;
  static Finder finder(int i) => find.byKey(ValueKey('nav-$i'));
}

/// A widget test that boots the real app on an in-memory database.
///
/// Cleanup runs inside the test body on purpose: drift schedules a zero-length
/// timer when Riverpod cancels its stream queries, and flutter_test checks for
/// pending timers before any tearDown would run.
void fikraTest(
  String description,
  Future<void> Function(WidgetTester tester, FikraDatabase db) body, {
  Object? tags,
  Brightness brightness = Brightness.dark,
  FileOpener? opener,
  Locale locale = const Locale('ar'),
  DateTime Function()? clock,
  PdfDocumentLoader? pdfLoader,
}) {
  testWidgets(description, (tester) async {
    tester.platformDispatcher.localeTestValue = locale;
    tester.platformDispatcher.localesTestValue = [locale];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    await initializeDateFormatting();
    final db = FikraDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      RepaintBoundary(
        key: appBoundaryKey,
        child: ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            if (clock != null) appClockProvider.overrideWithValue(clock),
            attachmentStoreProvider.overrideWithValue(_NoFilesStore()),
            if (opener != null) fileOpenerProvider.overrideWithValue(opener),
            // No native PDFium calls in widget tests, including missing-file cases.
            pdfDocumentLoaderProvider.overrideWithValue(
              pdfLoader ?? (path) async => throw FileSystemException('', path),
            ),
          ],
          child: const FikraApp(),
        ),
      ),
    );
    try {
      await body(tester, db);
    } finally {
      await tester.pumpWidget(const SizedBox()); // dispose providers → cancel queries
      await tester.pump(Duration.zero); // flush drift's close timer
      await tester.runAsync(db.close);
    }
  }, tags: tags);
}

/// Widget tests don't touch the disk (real file I/O stalls in the fake-async
/// zone); file handling is covered by test/settings_test.dart.
class _NoFilesStore extends AttachmentStore {
  @override
  Future<void> sweepOrphans(Set<String> referenced) async {}

  @override
  Future<void> purgeAll() async {}
}

/// Wraps the whole app; [saveScreenshot] captures it.
const appBoundaryKey = ValueKey('app-boundary');

/// Writes the current frame to `build/screenshots/<name>.png`.
Future<void> saveScreenshot(WidgetTester tester, String name) async {
  await tester.pump(const Duration(milliseconds: 400)); // let springs settle
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(appBoundaryKey));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: tester.view.devicePixelRatio);
    final png = await image.toByteData(format: ImageByteFormat.png);
    final file = File('build/screenshots/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(png!.buffer.asUint8List());
  });
}

/// Pumps until [finder] matches, letting real async work (drift) run in
/// between. Fails after [timeout] instead of hanging.
Future<void> pumpUntil(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 10)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump(const Duration(milliseconds: 16));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
}

/// Runs [action] (e.g. a repository call) in the test's zone and pumps until
/// it completes. Database work must not go through `tester.runAsync`: drift's
/// lock lives in the fake-async zone and would deadlock.
Future<T> pumpFuture<T>(
  WidgetTester tester,
  Future<T> Function() action, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  var done = false;
  late T result;
  Object? error;
  action().then(
    (v) {
      result = v;
      done = true;
    },
    onError: (Object e) {
      error = e;
      done = true;
    },
  );
  final end = DateTime.now().add(timeout);
  while (!done) {
    if (DateTime.now().isAfter(end)) throw TestFailure('Timed out waiting for action');
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await tester.pump(const Duration(milliseconds: 16));
  }
  if (error != null) throw error!;
  return result;
}

/// Loads the real Arabic font and Material icons so rendered text/icons look
/// like the app instead of test boxes. Needed for screenshots only.
Future<void> loadAppFonts() async {
  // Plugins without a test implementation: answer their channels with null.
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('com.llfbandit.record/messages'),
    (call) async => null,
  );
  final arabic = FontLoader('NotoSansArabic');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    arabic.addFont(Future.value(ByteData.sublistView(File('assets/fonts/NotoSansArabic-$w.ttf').readAsBytesSync())));
  }
  await arabic.load();
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '${Platform.environment['HOME']}/development/flutter';
  final icons = File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  final fonts = '$flutterRoot/bin/cache/artifacts/material_fonts';
  final roboto = FontLoader('Roboto');
  for (final w in ['Regular', 'Medium', 'Bold']) {
    final f = File('$fonts/Roboto-$w.ttf');
    if (f.existsSync()) roboto.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
  }
  await roboto.load();
  if (icons.existsSync()) {
    await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())))).load();
  }
}

/// Resolve the current app copy, including during a runtime language switch.
AppLocalizations testL10n(WidgetTester tester) => AppLocalizations.of(tester.element(find.byType(Navigator).first));
