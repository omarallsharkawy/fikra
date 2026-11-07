import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../ids.dart';

/// Owns attachment files (voice recordings, PDFs) on disk.
///
/// Files live in the app's private documents dir under `attachments/`, so they
/// survive cache clears and aren't readable by other apps. The database stores
/// the absolute path in `Notes.attachmentPath`.
class AttachmentStore {
  /// Prefix for in-progress recordings in the temp dir.
  static const recordingPrefix = 'rec_';

  /// Files younger than this are never swept: a save may still be in flight.
  static const sweepGrace = Duration(hours: 1);

  Future<Directory> _dir() async {
    final dir = Directory(p.join((await getApplicationDocumentsDirectory()).path, 'attachments'));
    await dir.create(recursive: true);
    return dir;
  }

  /// Temp path for a new recording.
  Future<String> newRecordingPath() async =>
      p.join((await getTemporaryDirectory()).path, '$recordingPrefix${DateTime.now().millisecondsSinceEpoch}.m4a');

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

  /// Deletes attachment files no note references, plus stale temp recordings.
  /// Best effort: anything left is retried on the next launch.
  Future<void> sweepOrphans(Set<String> referenced) async {
    final cutoff = DateTime.now().subtract(sweepGrace);
    Future<bool> stale(File f) async => (await f.lastModified()).isBefore(cutoff);
    try {
      await for (final f in (await _dir()).list()) {
        if (f is File && !referenced.contains(f.path) && await stale(f)) await deleteQuietly([f.path]);
      }
      await for (final f in (await getTemporaryDirectory()).list()) {
        if (f is File && p.basename(f.path).startsWith(recordingPrefix) && await stale(f)) {
          await deleteQuietly([f.path]);
        }
      }
    } catch (_) {}
  }

  static Future<void> deleteQuietly(Iterable<String> paths) async {
    for (final path in paths) {
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
      } on FileSystemException {
        // Left for the next orphan sweep.
      }
    }
  }
}
