import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../ids.dart';

/// Owns attachment files (voice recordings, PDFs, photos) on disk.
///
/// Files live in the app's private documents dir under `attachments/`, so they
/// survive cache clears and aren't readable by other apps. The database stores
/// each absolute path in `note_attachments.path`.
class AttachmentStore {
  /// The directory getters are injectable so tests can use temp folders.
  AttachmentStore({Future<Directory> Function()? documentsDir, Future<Directory> Function()? tempDir})
    : _documents = documentsDir ?? getApplicationDocumentsDirectory,
      _temp = tempDir ?? getTemporaryDirectory;

  final Future<Directory> Function() _documents;
  final Future<Directory> Function() _temp;

  /// Prefix for in-progress recordings in the temp dir.
  static const recordingPrefix = 'rec_';

  /// Files younger than this are never swept: a save may still be in flight.
  static const sweepGrace = Duration(hours: 1);

  Future<Directory> _dir() async {
    final dir = Directory(p.join((await _documents()).path, 'attachments'));
    await dir.create(recursive: true);
    return dir;
  }

  /// Temp path for a new recording.
  Future<String> newRecordingPath() async =>
      p.join((await _temp()).path, '$recordingPrefix${DateTime.now().millisecondsSinceEpoch}.m4a');

  /// Copies [source] into private storage and returns the new path. A partial
  /// copy is removed if the copy fails.
  Future<String> persist(String source, {required String extension}) async {
    final dest = p.join((await _dir()).path, '${newId()}.$extension');
    try {
      await File(source).copy(dest);
    } catch (_) {
      await deleteQuietly([dest]);
      rethrow;
    }
    return dest;
  }

  /// The extension a photo is stored under. Anything unexpected becomes `jpg`,
  /// because stored paths are joined with `|` and must never contain one.
  static String imageExtension(String fileName) {
    final raw = p.extension(fileName).replaceFirst('.', '').toLowerCase();
    return RegExp(r'^[a-z0-9]{1,8}$').hasMatch(raw) ? raw : 'jpg';
  }

  /// Deletes the copies the file picker left in the cache. Best effort.
  Future<void> clearPickerCopies() async {
    try {
      await FilePicker.clearTemporaryFiles();
    } catch (_) {}
  }

  /// Deletes stale temp recordings (`rec_*.m4a`) and cached file-picker copies
  /// without touching the legacy local documents/attachments directory.
  Future<void> sweepTempFiles({
    Set<String> activePaths = const {},
    Duration? grace,
    bool clearPicker = true,
  }) async {
    final effectiveGrace = grace ?? sweepGrace;
    final cutoff = DateTime.now().subtract(effectiveGrace);
    try {
      await for (final f in (await _temp()).list()) {
        if (f is! File) continue;
        if (!p.basename(f.path).startsWith(recordingPrefix)) continue;
        if (activePaths.contains(f.path)) continue;
        if (effectiveGrace <= Duration.zero || (await f.lastModified()).isBefore(cutoff)) {
          await deleteQuietly([f.path]);
        }
      }
    } catch (_) {}
    if (clearPicker) await clearPickerCopies();
  }

  /// Deletes attachment files no note references, plus stale temp recordings.
  /// Best effort: anything left is retried on the next launch.
  Future<void> sweepOrphans(Set<String> referenced) async {
    final cutoff = DateTime.now().subtract(sweepGrace);
    Future<bool> stale(File f) async => (await f.lastModified()).isBefore(cutoff);
    try {
      await for (final f in (await _dir()).list()) {
        if (f is File && !referenced.contains(f.path) && await stale(f)) await deleteQuietly([f.path]);
      }
    } catch (_) {}
    await sweepTempFiles();
  }

  /// Deletes every attachment and temp recording, referenced or not.
  /// Unlike [sweepOrphans] it throws if something couldn't be deleted.
  Future<void> purgeAll() async {
    final dir = await _dir();
    await dir.delete(recursive: true);
    await for (final f in (await _temp()).list()) {
      if (f is File && p.basename(f.path).startsWith(recordingPrefix)) await f.delete();
    }
    await clearPickerCopies();
  }

  static Future<void> deleteQuietly(Iterable<String> paths) async {
    for (final path in paths) {
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
      } catch (_) {
        // Cleanup is best effort, including non-I/O errors. Left for the next orphan sweep.
      }
    }
  }
}
