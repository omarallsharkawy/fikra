import 'files/attachment_store.dart';
import 'local/database.dart';

/// Appearance choice. Kept free of Flutter types; the app maps it to ThemeMode.
enum AppTheme { system, light, dark }

/// Language preference, independent of Flutter locale types.
enum AppLanguage { system, ar, en }

/// App-wide preferences and the "start over" action.
abstract interface class SettingsRepository {
  Stream<AppLanguage> watchLanguage();
  Future<void> setLanguage(AppLanguage language);

  Stream<AppTheme> watchTheme();
  Future<void> setTheme(AppTheme theme);

  /// Deletes every project, note, link and chat, then every attachment file.
  /// Preferences (like the theme) are kept. Throws [WipeFilesException] if the
  /// data is gone but some files couldn't be deleted (retrying is safe).
  Future<void> wipeAllData();
}

class WipeFilesException implements Exception {
  const WipeFilesException(this.cause);
  final Object cause;

  @override
  String toString() => 'WipeFilesException: $cause';
}

class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository(this.db, this.files);
  final FikraDatabase db;
  final AttachmentStore files;

  static const _themeKey = 'theme';
  static const _currentProjectKey = 'current_project';

  @override
  Stream<AppTheme> watchTheme() => (db.select(db.settings)..where((s) => s.key.equals(_themeKey)))
      .watchSingleOrNull()
      .map((s) => AppTheme.values.asNameMap()[s?.value] ?? AppTheme.system);

  @override
  Future<void> setTheme(AppTheme theme) async {
    if (theme == AppTheme.system) {
      await (db.delete(db.settings)..where((s) => s.key.equals(_themeKey))).go();
    } else {
      await db.into(db.settings).insertOnConflictUpdate(Setting(key: _themeKey, value: theme.name));
    }
  }

  @override
  Stream<AppLanguage> watchLanguage() => (db.select(db.settings)..where((s) => s.key.equals('language')))
      .watchSingleOrNull()
      .map((s) => AppLanguage.values.asNameMap()[s?.value] ?? AppLanguage.system);

  @override
  Future<void> setLanguage(AppLanguage language) async {
    if (language == AppLanguage.system) {
      await (db.delete(db.settings)..where((s) => s.key.equals('language'))).go();
    } else {
      await db.into(db.settings).insertOnConflictUpdate(Setting(key: 'language', value: language.name));
    }
  }

  @override
  Future<void> wipeAllData() async {
    await db.transaction(() async {
      await db.delete(db.chatEntries).go();
      await db.delete(db.noteLinks).go();
      await db.delete(db.notes).go();
      await db.delete(db.noteGroups).go();
      await db.delete(db.projects).go();
      await (db.delete(db.settings)..where((s) => s.key.equals(_currentProjectKey))).go();
    });
    // After the rows: a failure here leaves only unreferenced files, which
    // the next startup sweep also removes.
    try {
      await files.purgeAll();
    } catch (e) {
      throw WipeFilesException(e);
    }
  }
}
