import 'dart:io';

import 'package:fikra/l10n/localizations.dart';

import 'dart:ui' show ImageByteFormat;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:fikra/app/app.dart';
import 'package:fikra/app/providers.dart';
import 'package:fikra/data/files/attachment_store.dart';
import 'package:fikra/data/ai/ai_service.dart';
import 'package:fikra/data/files/file_opener.dart';
import 'package:fikra/data/links_repository.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/data/repositories.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
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
  AttachmentStore? attachmentStore,
  AiService? aiService,
  NotesRepository Function(FikraDatabase)? notesRepository,
  LinksRepository Function(FikraDatabase)? linksRepository,
  AudioRecorder Function()? recorderFactory,
  Future<PermissionStatus> Function()? microphonePermission,
  List<String>? audioEvents,
  Future<void> Function(String path)? pauseAudio,
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
    mockAudioPlayers(events: audioEvents, pause: pauseAudio);
    final db = FikraDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      RepaintBoundary(
        key: appBoundaryKey,
        child: ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            if (notesRepository != null) notesRepoProvider.overrideWithValue(notesRepository(db)),
            if (linksRepository != null) linksRepoProvider.overrideWithValue(linksRepository(db)),
            if (recorderFactory != null) audioRecorderFactoryProvider.overrideWithValue(recorderFactory),
            if (microphonePermission != null) microphonePermissionProvider.overrideWithValue(microphonePermission),
            if (aiService != null) aiServiceProvider.overrideWithValue(aiService),
            if (clock != null) appClockProvider.overrideWithValue(clock),
            attachmentStoreProvider.overrideWithValue(attachmentStore ?? _NoFilesStore()),
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

/// A local audio channel fake: no native audio or file decoding in widget tests.
void mockAudioPlayers({List<String>? events, Future<void> Function(String path)? pause}) {
  final paths = <String, String>{};
  String? uriIn(Object? value) {
    if (value is Map) {
      if (value['uri'] is String) return value['uri'] as String;
      for (final v in value.values) {
        final found = uriIn(v);
        if (found != null) return found;
      }
    } else if (value is List) {
      for (final v in value) {
        final found = uriIn(v);
        if (found != null) return found;
      }
    }
    return null;
  }

  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(const MethodChannel('com.ryanheise.just_audio.methods'), (call) async {
    if (call.method == 'disposePlayer') {
      events?.add('dispose:${paths[(call.arguments as Map)['id']] ?? (call.arguments as Map)['id']}');
      final id = (call.arguments as Map)['id'] as String;
      ServicesBinding.instance.channelBuffers.push('com.ryanheise.just_audio.events.$id', null, (_) {});
      ServicesBinding.instance.channelBuffers.push('com.ryanheise.just_audio.data.$id', null, (_) {});
      await Future<void>.value();
    }
    if (call.method == 'init') {
      final id = (call.arguments as Map)['id'] as String;
      events?.add('init:$id');
      messenger.setMockMethodCallHandler(MethodChannel('com.ryanheise.just_audio.events.$id'), (_) async => null);
      messenger.setMockMethodCallHandler(MethodChannel('com.ryanheise.just_audio.data.$id'), (_) async => null);
      messenger.setMockMethodCallHandler(MethodChannel('com.ryanheise.just_audio.methods.$id'), (method) async {
        if (method.method == 'load') {
          final uri = uriIn(method.arguments);
          paths[id] = uri == null ? id : Uri.parse(uri).toFilePath();
          events?.add('load:${paths[id]}');
          ServicesBinding.instance.channelBuffers.push(
            'com.ryanheise.just_audio.events.$id',
            const StandardMethodCodec().encodeSuccessEnvelope({
              'processingState': 3,
              'updateTime': 0,
              'updatePosition': 0,
              'bufferedPosition': 0,
              'duration': 61000000,
              'currentIndex': 0,
            }),
            (_) {},
          );
          return {'duration': 61000000};
        }
        if (method.method == 'play' || method.method == 'pause') {
          events?.add('${method.method}:${paths[id] ?? id}');
          if (method.method == 'pause') await pause?.call(paths[id] ?? id);
        }
        return <String, dynamic>{};
      });
    }
    return <String, dynamic>{};
  });
}
