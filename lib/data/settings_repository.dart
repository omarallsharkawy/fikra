import 'files/attachment_store.dart';
import 'local/database.dart';
import 'transcription/services_repository.dart';
import 'transcription/service_keys.dart';

/// Appearance choice. Kept free of Flutter types; the app maps it to ThemeMode.
enum AppTheme { system, light, dark }

/// Language preference, independent of Flutter locale types.
enum AppLanguage { system, ar, en }

/// Narrow preference boundary for the voice experiment, independent of Flutter
/// and native inference. Future engine/automation settings can be added here.
abstract interface class VoiceTextSettings {
  Future<({String? modelName, String? language})> readVoiceTextChoices();
  Future<bool> readAutoTranscribe();
  Future<void> setAutoTranscribe(bool enabled);
  Future<void> setVoiceTextModel(String modelName);
  Future<void> setVoiceTextLanguage(String language);
}

/// App-wide preferences and the "start over" action.
abstract interface class SettingsRepository implements VoiceTextSettings {
  Stream<AppLanguage> watchLanguage();
  Future<void> setLanguage(AppLanguage language);

  Stream<AppTheme> watchTheme();
  Future<void> setTheme(AppTheme theme);

  /// Whether the app already asked for notification permission for
  /// transcription (asked once, the first time a recording is queued).
  Future<bool> readTranscriptionNotificationsAsked();
  Future<void> markTranscriptionNotificationsAsked();

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
  LocalSettingsRepository(this.db, this.files, {TranscriptionServices? transcriptionServices})
    : transcriptionServices = transcriptionServices ?? LocalTranscriptionServices(db, const SecureServiceKeys());
  final TranscriptionServices transcriptionServices;
  final FikraDatabase db;
  final AttachmentStore files;

  static const _themeKey = 'theme';
  static const autoTranscribeKey = 'voice_text_auto_transcribe';
  static const transcriptionNotificationsKey = 'transcription_notifications_asked';
  static const voiceTextModelKey = 'voice_text_model';
  static const voiceTextLanguageKey = 'voice_text_language';
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
      .map((s) => AppLanguage.values.asNameMap()[s?.value] ?? AppLanguage.en);

  @override
  Future<void> setLanguage(AppLanguage language) async {
    // An explicit System choice must remain distinct from the English default.
    await db.into(db.settings).insertOnConflictUpdate(Setting(key: 'language', value: language.name));
  }

  @override
  Future<({String? modelName, String? language})> readVoiceTextChoices() async {
    final rows = await (db.select(
      db.settings,
    )..where((s) => s.key.isIn([voiceTextModelKey, voiceTextLanguageKey]))).get();
    final values = {for (final row in rows) row.key: row.value};
    return (modelName: values[voiceTextModelKey], language: values[voiceTextLanguageKey]);
  }

  @override
  Future<void> setVoiceTextModel(String modelName) async {
    await db.into(db.settings).insertOnConflictUpdate(Setting(key: voiceTextModelKey, value: modelName));
  }

  @override
  Future<void> setVoiceTextLanguage(String language) async {
    if (!const ['ar', 'en', 'auto'].contains(language)) throw ArgumentError.value(language, 'language');
    await db.into(db.settings).insertOnConflictUpdate(Setting(key: voiceTextLanguageKey, value: language));
  }

  @override
  Future<bool> readAutoTranscribe() async =>
      (await (db.select(db.settings)..where((s) => s.key.equals(autoTranscribeKey))).getSingleOrNull())?.value ==
      'true';

  @override
  Future<bool> readTranscriptionNotificationsAsked() async =>
      (await (db.select(
        db.settings,
      )..where((s) => s.key.equals(transcriptionNotificationsKey))).getSingleOrNull())?.value ==
      'true';

  @override
  Future<void> markTranscriptionNotificationsAsked() async {
    await db.into(db.settings).insertOnConflictUpdate(const Setting(key: transcriptionNotificationsKey, value: 'true'));
  }

  @override
  Future<void> setAutoTranscribe(bool enabled) async {
    await db.into(db.settings).insertOnConflictUpdate(Setting(key: autoTranscribeKey, value: '$enabled'));
  }

  @override
  Future<void> wipeAllData() async {
    await transcriptionServices.wipe();
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
