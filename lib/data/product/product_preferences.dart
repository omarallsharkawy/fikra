import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../settings_repository.dart';

/// Lightweight JSON-backed preference store for product mode (`connected` /
/// `development`), avoiding a full Drift SQLite database boot at cold start
/// just to read theme and language.
class ProductPreferencesStore {
  ProductPreferencesStore({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;

  static const _fileName = 'product_preferences.json';

  final Future<Directory> Function() _directory;
  final _themeController = StreamController<AppTheme>.broadcast();
  final _languageController = StreamController<AppLanguage>.broadcast();

  AppTheme _theme = AppTheme.system;
  AppLanguage _language = AppLanguage.en;
  bool _loaded = false;
  bool _disposed = false;
  Future<void>? _loading;
  Future<void> _writeQueue = Future<void>.value();

  Future<void> _ensureLoaded() {
    if (_loaded) return Future<void>.value();
    return _loading ??= _load().whenComplete(() => _loading = null);
  }

  Future<void> _load() async {
    try {
      final dir = await _directory();
      final file = File(p.join(dir.path, _fileName));
      if (await file.exists()) {
        final raw = await file.readAsString();
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final themeName = decoded['theme'];
          if (themeName is String) {
            _theme = AppTheme.values.asNameMap()[themeName] ?? AppTheme.system;
          }
          final languageName = decoded['language'];
          if (languageName is String) {
            _language = AppLanguage.values.asNameMap()[languageName] ?? AppLanguage.en;
          }
        }
      }
    } catch (_) {
      // Corrupt JSON or unavailable platform directory falls back to defaults.
    } finally {
      _loaded = true;
    }
  }

  Stream<AppTheme> watchTheme() => Stream<AppTheme>.multi((controller) {
    StreamSubscription<AppTheme>? sub;
    var cancelled = false;
    controller.onCancel = () {
      cancelled = true;
      return sub?.cancel();
    };
    unawaited(
      _ensureLoaded().then((_) {
        if (cancelled || _disposed) {
          if (!controller.isClosed) unawaited(controller.close());
          return;
        }
        // Subscribe synchronously before emitting initial value so updates
        // committed concurrently with load completion are never missed.
        sub = _themeController.stream.listen(controller.add, onDone: controller.close);
        controller.add(_theme);
      }),
    );
  });

  Stream<AppLanguage> watchLanguage() => Stream<AppLanguage>.multi((controller) {
    StreamSubscription<AppLanguage>? sub;
    var cancelled = false;
    controller.onCancel = () {
      cancelled = true;
      return sub?.cancel();
    };
    unawaited(
      _ensureLoaded().then((_) {
        if (cancelled || _disposed) {
          if (!controller.isClosed) unawaited(controller.close());
          return;
        }
        sub = _languageController.stream.listen(controller.add, onDone: controller.close);
        controller.add(_language);
      }),
    );
  });

  Future<void> setTheme(AppTheme theme) => _commit(theme: theme);

  Future<void> setLanguage(AppLanguage language) => _commit(language: language);

  Future<void> _commit({AppTheme? theme, AppLanguage? language}) {
    final next = _writeQueue.then((_) async {
      await _ensureLoaded();
      if (_disposed) return;
      final nextTheme = theme ?? _theme;
      final nextLanguage = language ?? _language;
      final snapshot = jsonEncode({'theme': nextTheme.name, 'language': nextLanguage.name});
      final dir = await _directory();
      await dir.create(recursive: true);
      final target = File(p.join(dir.path, _fileName));
      final temp = File(p.join(dir.path, '$_fileName.tmp'));
      try {
        await temp.writeAsString(snapshot, flush: true);
        await temp.rename(target.path);
      } catch (_) {
        try {
          if (await temp.exists()) await temp.delete();
        } catch (_) {
          /* Best-effort temp cleanup on failed write. */
        }
        rethrow;
      }
      if (_disposed) return;
      _theme = nextTheme;
      _language = nextLanguage;
      if (theme != null && !_themeController.isClosed) _themeController.add(nextTheme);
      if (language != null && !_languageController.isClosed) _languageController.add(nextLanguage);
    });
    _writeQueue = next.catchError((Object _) {});
    return next;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_themeController.close());
    unawaited(_languageController.close());
  }
}

/// Product-mode [SettingsRepository] adapter backed by [ProductPreferencesStore].
/// Only appearance and language are active in product mode; legacy local-demo
/// voice/DB operations are no-ops/unsupported.
class ProductPreferencesRepository implements SettingsRepository {
  ProductPreferencesRepository(this.store);

  final ProductPreferencesStore store;

  @override
  Stream<AppTheme> watchTheme() => store.watchTheme();

  @override
  Future<void> setTheme(AppTheme theme) => store.setTheme(theme);

  @override
  Stream<AppLanguage> watchLanguage() => store.watchLanguage();

  @override
  Future<void> setLanguage(AppLanguage language) => store.setLanguage(language);

  @override
  Future<({String? modelName, String? language})> readVoiceTextChoices() async => (modelName: null, language: null);

  @override
  Future<bool> readAutoTranscribe() async => false;

  @override
  Future<void> setAutoTranscribe(bool enabled) async {}

  @override
  Future<void> setVoiceTextModel(String modelName) async {}

  @override
  Future<void> setVoiceTextLanguage(String language) async {}

  @override
  Future<bool> readTranscriptionNotificationsAsked() async => false;

  @override
  Future<void> markTranscriptionNotificationsAsked() async {}

  @override
  Future<void> wipeAllData() async {}
}
