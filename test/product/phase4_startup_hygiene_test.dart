import 'dart:async';
import 'dart:io';

import 'package:fikra/app/product_runtime.dart';
import 'package:fikra/app/providers.dart';
import 'package:fikra/core/theme/product_theme.dart';
import 'package:fikra/core/widgets/voice_player.dart';
import 'package:fikra/data/files/attachment_store.dart';
import 'package:fikra/data/product/development/development_auth.dart';
import 'package:fikra/data/product/development/development_knowledge.dart';
import 'package:fikra/data/product/models.dart';
import 'package:fikra/data/product/product_preferences.dart';
import 'package:fikra/data/product/repositories.dart';
import 'package:fikra/features/account/session_controller.dart';
import 'package:fikra/features/capture/capture_controller.dart';
import 'package:fikra/features/capture/native_capture_device.dart';
import 'package:fikra/features/workspace/product_widgets.dart';
import 'package:fikra/features/workspace/workspace_controller.dart';
import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import '../support/app_harness.dart' show pumpFuture, pumpUntil;

class _NoopCaptureDevice implements CaptureDevice {
  Completer<void>? cancelGate;
  @override
  Future<void> start() async {}
  @override
  Future<RecordedClip?> stop(Duration duration) async => null;
  @override
  Future<void> cancel() async {
    final gate = cancelGate;
    if (gate != null) await gate.future;
  }
  @override
  Future<void> dispose() async {}
}

class _ConcurrentAttemptStore implements AttemptStore {
  final Completer<CreateAttempt?> readCompleter = Completer<CreateAttempt?>();
  bool readStarted = false;
  int clearCalls = 0;

  @override
  Future<CreateAttempt?> read(String accountId) {
    readStarted = true;
    return readCompleter.future;
  }

  @override
  Future<void> write(CreateAttempt attempt) async {}

  @override
  Future<void> clear(String accountId) async {
    clearCalls++;
  }
}

class _ConcurrentKnowledgeRepo extends DevelopmentKnowledgeRepository {
  _ConcurrentKnowledgeRepo() : super(stepDelay: Duration.zero);

  final Completer<List<KnowledgeProject>> projectsCompleter = Completer<List<KnowledgeProject>>();
  bool projectsStarted = false;

  @override
  Future<List<KnowledgeProject>> projects(String accountId) {
    projectsStarted = true;
    return projectsCompleter.future;
  }

  @override
  Future<List<KnowledgeNote>> notes(String accountId, String projectId) async => const [];
}

class _RefreshingAuthRepo extends DevelopmentAuthRepository {
  int refreshCalls = 0;

  @override
  Future<SessionGrant> login(String email, String password) async {
    final grant = await super.login(email, password);
    return SessionGrant(
      grant.account,
      tokens: TokenPair(
        access: 'access-1',
        refresh: 'refresh-1',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      ),
    );
  }

  @override
  Future<TokenPair> refresh(TokenPair tokens) async {
    refreshCalls++;
    return TokenPair(
      access: 'access-${refreshCalls + 1}',
      refresh: 'refresh-${refreshCalls + 1}',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 4: cold startup & zero-DB preferences', () {
    test('ProductPreferencesStore persists values and recovers from corrupt JSON', () async {
      final dir = await Directory.systemTemp.createTemp('fikra_prefs_');
      addTearDown(() => dir.delete(recursive: true));

      final store1 = ProductPreferencesStore(directory: () async => dir);
      expect(await store1.watchTheme().first, AppTheme.system);
      expect(await store1.watchLanguage().first, AppLanguage.en);

      await store1.setTheme(AppTheme.dark);
      await store1.setLanguage(AppLanguage.ar);
      store1.dispose();

      final store2 = ProductPreferencesStore(directory: () async => dir);
      expect(await store2.watchTheme().first, AppTheme.dark);
      expect(await store2.watchLanguage().first, AppLanguage.ar);
      store2.dispose();

      // Corrupt JSON should cleanly fall back to defaults without throwing.
      await File(p.join(dir.path, 'product_preferences.json')).writeAsString('{broken-json');
      final store3 = ProductPreferencesStore(directory: () async => dir);
      expect(await store3.watchTheme().first, AppTheme.system);
      expect(await store3.watchLanguage().first, AppLanguage.en);
      store3.dispose();
    });

    test('ProductPreferencesStore never drops concurrent updates and keeps state intact on write failure', () async {
      final dir = await Directory.systemTemp.createTemp('fikra_prefs_race_');
      addTearDown(() => dir.delete(recursive: true));

      final dirGate = Completer<Directory>();
      final store = ProductPreferencesStore(directory: () => dirGate.future);
      addTearDown(store.dispose);

      // Start watching and writing before initial load completes.
      final seen = <AppTheme>[];
      final sub = store.watchTheme().listen(seen.add);
      addTearDown(sub.cancel);
      final writeFuture = store.setTheme(AppTheme.dark);

      dirGate.complete(dir);
      await writeFuture;
      await Future<void>.delayed(Duration.zero);

      expect(seen, contains(AppTheme.dark));
      expect(seen.last, AppTheme.dark);

      // Write failure must NOT mutate state or broadcast an unsaved preference.
      var failDir = false;
      final failingStore = ProductPreferencesStore(
        directory: () async {
          if (failDir) throw const FileSystemException('disk full');
          return dir;
        },
      );
      addTearDown(failingStore.dispose);
      final failSeen = <AppTheme>[];
      final failSub = failingStore.watchTheme().listen(failSeen.add);
      addTearDown(failSub.cancel);
      expect(await failingStore.watchTheme().first, AppTheme.dark);

      failDir = true;
      await expectLater(failingStore.setTheme(AppTheme.light), throwsA(isA<FileSystemException>()));
      await Future<void>.delayed(Duration.zero);
      expect(failSeen.last, AppTheme.dark);
      expect(await failingStore.watchTheme().first, AppTheme.dark);
      expect(await File(p.join(dir.path, 'product_preferences.json.tmp')).exists(), isFalse);
    });

    testWidgets('connected mode reads theme and language without booting Drift FikraDatabase', (tester) async {
      final dir = await tester.runAsync(() => Directory.systemTemp.createTemp('fikra_nodb_'));
      addTearDown(() async {
        await tester.runAsync(() async {
          if (dir != null && await dir.exists()) await dir.delete(recursive: true);
        });
      });

      var dbTouched = false;
      final store = ProductPreferencesStore(directory: () async => dir!);
      addTearDown(store.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appModeProvider.overrideWithValue(AppMode.connected),
            productPreferencesStoreProvider.overrideWithValue(store),
            databaseProvider.overrideWith((_) {
              dbTouched = true;
              throw StateError('FikraDatabase must not be opened in connected mode');
            }),
          ],
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Consumer(
              builder: (_, ref, _) {
                final theme = ref.watch(appThemeProvider).value?.name ?? 'loading';
                final lang = ref.watch(appLanguageProvider).value?.name ?? 'loading';
                return Text('$theme|$lang');
              },
            ),
          ),
        ),
      );

      await pumpUntil(tester, find.text('system|en'));
      expect(dbTouched, isFalse);

      final container = ProviderScope.containerOf(tester.element(find.byType(Consumer)));
      await pumpFuture(tester, () => container.read(settingsRepoProvider).setTheme(AppTheme.light));
      await pumpUntil(tester, find.text('light|en'));
      expect(dbTouched, isFalse);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
    });

    test('WorkspaceController.openAccount reads attempts and fetches projects concurrently', () async {
      final attempts = _ConcurrentAttemptStore();
      final repo = _ConcurrentKnowledgeRepo();
      final controller = WorkspaceController(repo, attempts);
      addTearDown(controller.dispose);

      final openFuture = controller.openAccount('acc-1');
      await Future<void>.delayed(Duration.zero);

      // Both futures must have started before either completes.
      expect(attempts.readStarted, isTrue);
      expect(repo.projectsStarted, isTrue);

      attempts.readCompleter.completeError(const FormatException('corrupt'));
      repo.projectsCompleter.complete([
        KnowledgeProject(
          id: 'proj-general',
          name: 'General',
          isGeneral: true,
          createdAt: DateTime(2026),
        ),
      ]);

      await openFuture;
      expect(attempts.clearCalls, 1);
      expect(controller.selectedProjectId, 'proj-general');
      expect(controller.failure, isNull);
    });

    test('WorkspaceController.openAccount fences stale attempt read error after clear()', () async {
      final attempts = _ConcurrentAttemptStore();
      final repo = _ConcurrentKnowledgeRepo();
      final controller = WorkspaceController(repo, attempts);
      addTearDown(controller.dispose);

      final openFuture = controller.openAccount('acc-1');
      await Future<void>.delayed(Duration.zero);

      repo.projectsCompleter.completeError(const ProductFailure(FailureKind.unavailable));
      await openFuture;
      controller.clear();

      // Stale read failing after clear() must NOT invoke attempts.clear().
      attempts.readCompleter.completeError(const FormatException('stale corrupt'));
      await Future<void>.delayed(Duration.zero);
      expect(attempts.clearCalls, 0);
    });
  });

  group('Phase 4: narrow session route and boundary listenables', () {
    test('silent refresh and auth busy/error toggles do not trigger stageListenable or boundaryListenable', () async {
      final auth = _RefreshingAuthRepo();
      final vault = MemorySessionVault();
      final session = SessionController(auth, vault);
      addTearDown(session.dispose);

      var stageNotifications = 0;
      var boundaryNotifications = 0;
      var fullNotifications = 0;
      session.stageListenable.addListener(() => stageNotifications++);
      session.boundaryListenable.addListener(() => boundaryNotifications++);
      session.addListener(() => fullNotifications++);

      // Initial restore -> unauthenticated (stage changes once).
      await session.restore();
      expect(session.stage, SessionStage.unauthenticated);
      expect(stageNotifications, 1);
      expect(boundaryNotifications, 0);

      // Failed login toggles busy/failure only; stage stays unauthenticated.
      await session.login('nobody@example.invalid', 'wrong-pass');
      expect(session.stage, SessionStage.unauthenticated);
      expect(stageNotifications, 1);
      expect(boundaryNotifications, 0);

      // Successful login installs session -> stage and boundary each change once.
      await session.login('reader@example.invalid', 'fixture-only');
      expect(session.stage, SessionStage.authenticated);
      expect(stageNotifications, 2);
      expect(boundaryNotifications, 1);

      // Silent token refresh updates tokens and notifies SessionController,
      // but MUST NOT wake GoRouter or rebuild ProductBoundary.
      final fullBeforeRefresh = fullNotifications;
      final oldAccess = session.tokens!.access;
      final refreshed = await session.refreshAfterUnauthorized(oldAccess);
      expect(refreshed.access, isNot(oldAccess));
      expect(fullNotifications, greaterThan(fullBeforeRefresh));
      expect(stageNotifications, 2);
      expect(boundaryNotifications, 1);
    });
  });

  group('Phase 4: temp file sweep & sign-out hygiene', () {
    test('sweepTempFiles removes only stale inactive rec_* files and leaves documents untouched', () async {
      final docsDir = await Directory.systemTemp.createTemp('fikra_docs_');
      final tempDir = await Directory.systemTemp.createTemp('fikra_temp_');
      addTearDown(() async {
        if (await docsDir.exists()) await docsDir.delete(recursive: true);
        if (await tempDir.exists()) await tempDir.delete(recursive: true);
      });

      final staleRec = File(p.join(tempDir.path, 'rec_1000.m4a'))..writeAsBytesSync([1, 2, 3]);
      final activeRec = File(p.join(tempDir.path, 'rec_2000.m4a'))..writeAsBytesSync([4, 5, 6]);
      final freshRec = File(p.join(tempDir.path, 'rec_3000.m4a'))..writeAsBytesSync([7, 8, 9]);
      final unrelatedTemp = File(p.join(tempDir.path, 'other.tmp'))..writeAsBytesSync([10]);

      final oldTime = DateTime.now().subtract(const Duration(hours: 2));
      await staleRec.setLastModified(oldTime);
      await activeRec.setLastModified(oldTime);

      final store = AttachmentStore(documentsDir: () async => docsDir, tempDir: () async => tempDir);
      await store.sweepTempFiles(activePaths: {activeRec.path}, clearPicker: false);

      expect(await staleRec.exists(), isFalse);
      expect(await activeRec.exists(), isTrue);
      expect(await freshRec.exists(), isTrue);
      expect(await unrelatedTemp.exists(), isTrue);
      // Must NOT create or touch docs/attachments in product mode.
      expect(await Directory(p.join(docsDir.path, 'attachments')).exists(), isFalse);

      // Sign-out sweep with grace: Duration.zero clears fresh inactive recordings too.
      await store.sweepTempFiles(grace: Duration.zero, clearPicker: false);
      expect(await activeRec.exists(), isFalse);
      expect(await freshRec.exists(), isFalse);
      expect(await unrelatedTemp.exists(), isTrue);
    });

    test('ProductRuntime runs onSignOutCleanup on explicit signOut, not on expire', () async {
      var cleanupCalls = 0;
      final runtime = ProductRuntime(
        DevelopmentAuthRepository(),
        MemorySessionVault(),
        DevelopmentKnowledgeRepository(stepDelay: Duration.zero),
        MemoryAttemptStore(),
        _NoopCaptureDevice(),
        onSignOutCleanup: () async {
          cleanupCalls++;
        },
      );
      addTearDown(runtime.dispose);

      await runtime.session.restore();
      await runtime.session.login('reader@example.invalid', 'fixture-only');
      expect(cleanupCalls, 0);

      await runtime.session.expire();
      await Future<void>.delayed(Duration.zero);
      expect(cleanupCalls, 0);

      await runtime.session.login('reader@example.invalid', 'fixture-only');
      await runtime.session.signOut();
      await Future<void>.delayed(Duration.zero);
      expect(cleanupCalls, 1);
    });

    test('ProductRuntime waits for capture cancel and skips sign-out sweep on rapid re-login', () async {
      var cleanupCalls = 0;
      final device = _NoopCaptureDevice();
      final runtime = ProductRuntime(
        DevelopmentAuthRepository(),
        MemorySessionVault(),
        DevelopmentKnowledgeRepository(stepDelay: Duration.zero),
        MemoryAttemptStore(),
        device,
        onSignOutCleanup: () async {
          cleanupCalls++;
        },
      );
      addTearDown(runtime.dispose);

      await runtime.session.restore();
      await runtime.session.login('reader@example.invalid', 'fixture-only');

      // Gate device.cancel() so sign-out cleanup waits for recorder teardown.
      final cancelGate = Completer<void>();
      device.cancelGate = cancelGate;
      await runtime.session.signOut();
      await Future<void>.delayed(Duration.zero);
      expect(cleanupCalls, 0);

      // Rapid re-login before cancel finishes must suppress the stale sweep.
      device.cancelGate = null;
      await runtime.session.login('reader@example.invalid', 'fixture-only');
      cancelGate.complete();
      await Future<void>.delayed(Duration.zero);
      expect(cleanupCalls, 0);
    });
  });

  group('Phase 4: microphone permanentlyDenied & VoicePlayer hygiene', () {
    test('NativeCaptureDevice distinguishes permanentlyDenied/restricted from transient denied', () async {
      final tempDir = await Directory.systemTemp.createTemp('fikra_mic_');
      addTearDown(() => tempDir.delete(recursive: true));
      final store = AttachmentStore(documentsDir: () async => tempDir, tempDir: () async => tempDir);

      final deniedDevice = NativeCaptureDevice(null, () async => PermissionStatus.denied, store);
      await expectLater(
        deniedDevice.start(),
        throwsA(isA<ProductFailure>().having((f) => f.field, 'field', 'microphone')),
      );

      final permDevice = NativeCaptureDevice(null, () async => PermissionStatus.permanentlyDenied, store);
      await expectLater(
        permDevice.start(),
        throwsA(isA<ProductFailure>().having((f) => f.field, 'field', 'microphone_settings')),
      );

      final restrictedDevice = NativeCaptureDevice(null, () async => PermissionStatus.restricted, store);
      await expectLater(
        restrictedDevice.start(),
        throwsA(isA<ProductFailure>().having((f) => f.field, 'field', 'microphone_settings')),
      );
    });

    testWidgets('ProductFailureView shows Open settings CTA only for microphone_settings', (tester) async {
      var opened = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildProductTheme(Brightness.light),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Column(
              children: [
                ProductFailureView(
                  const ProductFailure(FailureKind.validation, field: 'microphone_settings'),
                  onOpenSettings: () => opened++,
                ),
                ProductFailureView(
                  const ProductFailure(FailureKind.validation, field: 'microphone'),
                  onOpenSettings: () => opened++,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final openBtn = find.text('Open settings');
      expect(openBtn, findsOneWidget);
      await tester.tap(openBtn);
      expect(opened, 1);
    });

    testWidgets('VoicePlayer disposes AudioPlayer on setFilePath failure and resets on path change', (tester) async {
      final disposedIds = <String>[];
      var loadCalls = 0;
      const rootChannel = MethodChannel('com.ryanheise.just_audio.methods');
      final messenger = tester.binding.defaultBinaryMessenger;
      final playerChannels = <MethodChannel>[];

      messenger.setMockMethodCallHandler(rootChannel, (call) async {
        if (call.method == 'init') {
          final id = (call.arguments as Map)['id'] as String;
          final eventsCh = MethodChannel('com.ryanheise.just_audio.events.$id');
          final dataCh = MethodChannel('com.ryanheise.just_audio.data.$id');
          final methodCh = MethodChannel('com.ryanheise.just_audio.methods.$id');
          playerChannels.addAll([eventsCh, dataCh, methodCh]);
          messenger.setMockMethodCallHandler(eventsCh, (_) async => null);
          messenger.setMockMethodCallHandler(dataCh, (_) async => null);
          messenger.setMockMethodCallHandler(methodCh, (pCall) async {
            if (pCall.method == 'load') {
              loadCalls++;
              if (loadCalls == 1) {
                throw PlatformException(code: 'load_failed', message: 'missing file');
              }
              return {'duration': 2000000};
            }
            return <String, dynamic>{};
          });
        } else if (call.method == 'disposePlayer') {
          final id = (call.arguments as Map)['id'] as String;
          disposedIds.add(id);
          ServicesBinding.instance.channelBuffers.push('com.ryanheise.just_audio.events.$id', null, (_) {});
          ServicesBinding.instance.channelBuffers.push('com.ryanheise.just_audio.data.$id', null, (_) {});
        }
        return <String, dynamic>{};
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(rootChannel, null);
        for (final ch in playerChannels) {
          messenger.setMockMethodCallHandler(ch, null);
        }
      });

      Widget buildApp(String path) => MaterialApp(
        theme: buildProductTheme(Brightness.light),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: VoicePlayer(path: path, durationMs: 2000)),
      );

      await tester.pumpWidget(buildApp('/tmp/missing.m4a'));
      await tester.pumpAndSettle();

      // Tap play -> setFilePath throws -> player must be disposed and error shown.
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await pumpUntil(tester, find.text('File unavailable'));
      expect(loadCalls, 1);
      expect(disposedIds, isNotEmpty);

      // Switching widget.path resets error state cleanly so the new file can load.
      await tester.pumpWidget(buildApp('/tmp/valid.m4a'));
      await tester.pumpAndSettle();
      expect(find.text('File unavailable'), findsNothing);
    });

    testWidgets('VoicePlayer fences in-flight setFilePath failure across didUpdateWidget path change', (tester) async {
      final firstLoadGate = Completer<void>();
      var loadCalls = 0;
      const rootChannel = MethodChannel('com.ryanheise.just_audio.methods');
      final messenger = tester.binding.defaultBinaryMessenger;
      final playerChannels = <MethodChannel>[];

      messenger.setMockMethodCallHandler(rootChannel, (call) async {
        if (call.method == 'init') {
          final id = (call.arguments as Map)['id'] as String;
          final eventsCh = MethodChannel('com.ryanheise.just_audio.events.$id');
          final dataCh = MethodChannel('com.ryanheise.just_audio.data.$id');
          final methodCh = MethodChannel('com.ryanheise.just_audio.methods.$id');
          playerChannels.addAll([eventsCh, dataCh, methodCh]);
          messenger.setMockMethodCallHandler(eventsCh, (_) async => null);
          messenger.setMockMethodCallHandler(dataCh, (_) async => null);
          messenger.setMockMethodCallHandler(methodCh, (pCall) async {
            if (pCall.method == 'load') {
              loadCalls++;
              if (loadCalls == 1) {
                await firstLoadGate.future;
                throw PlatformException(code: 'load_failed', message: 'stale error');
              }
              return {'duration': 2000000};
            }
            return <String, dynamic>{};
          });
        } else if (call.method == 'disposePlayer') {
          final id = (call.arguments as Map)['id'] as String;
          ServicesBinding.instance.channelBuffers.push('com.ryanheise.just_audio.events.$id', null, (_) {});
          ServicesBinding.instance.channelBuffers.push('com.ryanheise.just_audio.data.$id', null, (_) {});
        }
        return <String, dynamic>{};
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(rootChannel, null);
        for (final ch in playerChannels) {
          messenger.setMockMethodCallHandler(ch, null);
        }
      });

      Widget buildApp(String path) => MaterialApp(
        theme: buildProductTheme(Brightness.light),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: VoicePlayer(path: path, durationMs: 2000)),
      );

      await tester.pumpWidget(buildApp('/tmp/old.m4a'));
      await tester.pumpAndSettle();

      // Start loading old path, then switch path BEFORE load rejects.
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      await tester.pumpWidget(buildApp('/tmp/new.m4a'));
      await tester.pump();

      firstLoadGate.complete();
      await tester.pumpAndSettle();

      // Stale failure from /tmp/old.m4a must NOT poison /tmp/new.m4a.
      expect(find.text('File unavailable'), findsNothing);
    });
  });
}
