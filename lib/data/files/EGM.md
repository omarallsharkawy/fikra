# Attachment File Store

## Overview

Owns voice recordings, PDFs, and photos on disk, and opens them in other apps. Attachments live in the app's private
documents directory under `attachments/`, so they survive cache clears and are
not readable by other apps. In-progress recordings live in the temp directory.
The database holds every live absolute path in `note_attachments.path`. Legacy note columns remain only for migration/recovery.

## Interface

From `attachment_store.dart`:

- `class AttachmentStore`
  - `AttachmentStore({Future<Directory> Function()? documentsDir, Future<Directory> Function()? tempDir})`: the directory getters are injectable for tests; they default to `path_provider`.
  - `static const recordingPrefix = 'rec_'`
  - `static const sweepGrace = Duration(hours: 1)`
  - `Future<String> newRecordingPath()`
  - `Future<String> persist(String source, {required String extension})`
  - `Future<void> sweepOrphans(Set<String> referenced)`
  - `Future<void> purgeAll()`
  - `static Future<void> deleteQuietly(Iterable<String> paths)`
  - `static String imageExtension(String fileName)`: the extension a photo is stored under, never containing `|`.
  - `Future<void> clearPickerCopies()`: best-effort delete of the file picker's cache copies. Runs after Add saves, at launch, and on a full wipe. Edit never clears the picker cache because Add may keep a draft offstage.

From `file_opener.dart`:

- `typedef FileOpener = Future<bool> Function(String path)`
- `Future<bool> openWithSystem(String path)`: opens the file in another app. Returns false instead of throwing.

## Invariants

- Persisted files are named `<uuid v4>.<extension>` inside `attachments/`. Recordings use `rec_<epoch ms>.m4a` in the temp directory.
- `newRecordingPath` only computes a path. It does not create the file.
- `persist` copies and leaves `source` in place. If the copy fails, the partial destination is removed and the error is rethrown.
- `sweepOrphans` must receive every path referenced by any note, in exactly the stored form, because membership is an exact string comparison. An incomplete set would delete live files older than the grace period. `NotesRepository.attachmentPaths()` provides the complete set.
- `sweepOrphans` never deletes a file younger than `sweepGrace`, since a save may still be in flight. In the temp directory it only considers `rec_` files. Deletion and sweeping are best effort and swallow all errors; leftovers are retried on the next launch.
- `purgeAll` ignores references and the grace period, and throws if something cannot be deleted. Callers must remove the database rows first; `LocalSettingsRepository.wipeAllData` does.
- `deleteQuietly` skips missing files and swallows only `FileSystemException`.

## Side Effects

- Creates the `attachments/` directory on demand.
- Copies and deletes files in the private documents directory.
- Deletes `rec_*` files in the temp directory.
- `lib/app/providers.dart` runs `sweepOrphans` once at launch.
- `openWithSystem` starts another app through `open_filex`. The storage permissions that package declares are removed in `android/app/src/main/AndroidManifest.xml`, because only private files are opened.

## Verification

- Run: `flutter analyze && flutter test`
