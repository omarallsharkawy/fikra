import 'package:path/path.dart' as p;

import 'files/attachment_store.dart';
import 'local/database.dart';

class EmptyNoteException implements Exception {
  const EmptyNoteException();
}

/// A saved attachment has an ID; a picked file or temporary recording has none.
class AttachmentDraft {
  const AttachmentDraft({
    this.id,
    required this.kind,
    required this.path,
    this.name,
    this.bytes,
    this.durationMs,
    this.transcribe = false,
  });
  factory AttachmentDraft.saved(NoteAttachment a) =>
      AttachmentDraft(id: a.id, kind: a.kind, path: a.path, name: a.name, bytes: a.bytes, durationMs: a.durationMs);
  final String? id;
  final AttachmentKind kind;
  final String path;
  final String? name;
  final int? bytes;
  final int? durationMs;

  /// Only new saved voice rows can request work; never run on a temp file.
  final bool transcribe;

  /// Raw display name; localized file-only auto-titles belong to presentation.
  String get fileTitle => name ?? p.basename(path);
}

/// Copies new files before the atomic database operation. Rollback owns only
/// these copies: picked sources and draft recordings survive a failed save.
Future<T> saveAttachmentDraft<T>(
  AttachmentStore store,
  List<AttachmentDraft> draft,
  Future<T> Function(List<AttachmentDraft>) commit,
) async {
  final copied = <String>[];
  try {
    final stored = <AttachmentDraft>[];
    for (final a in draft) {
      if (a.id != null) {
        stored.add(a);
        continue;
      }
      final extension = switch (a.kind) {
        AttachmentKind.pdf => 'pdf',
        AttachmentKind.voice => 'm4a',
        AttachmentKind.image => AttachmentStore.imageExtension(a.name ?? a.path),
      };
      final path = await store.persist(a.path, extension: extension);
      copied.add(path);
      stored.add(
        AttachmentDraft(
          kind: a.kind,
          path: path,
          name: a.name,
          bytes: a.bytes,
          durationMs: a.durationMs,
          transcribe: a.transcribe,
        ),
      );
    }
    return await commit(stored);
  } catch (_) {
    await AttachmentStore.deleteQuietly(copied);
    rethrow;
  }
}

/// Snapshot the save policy. Existing attachments never get re-queued by edits.
List<AttachmentDraft> transcriptionDraft(List<AttachmentDraft> draft, {required bool automatic}) => [
  for (final a in draft)
    AttachmentDraft(
      id: a.id,
      kind: a.kind,
      path: a.path,
      name: a.name,
      bytes: a.bytes,
      durationMs: a.durationMs,
      transcribe: a.id == null && a.kind == AttachmentKind.voice && (automatic || a.transcribe),
    ),
];

/// Only the new copied files requested by this exact save may wake the queue.
List<String> newTranscriptionPaths(List<AttachmentDraft> stored) => [
  for (final a in stored)
    if (a.id == null && a.kind == AttachmentKind.voice && a.transcribe) a.path,
];
