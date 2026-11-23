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
    bool transcribe = false,
    TranscriptionPolicy? policy,
    this.policyChanged = false,
  }) : policy = policy ?? (transcribe ? TranscriptionPolicy.afterSave : null);
  factory AttachmentDraft.saved(NoteAttachment a) => AttachmentDraft(
    id: a.id,
    kind: a.kind,
    path: a.path,
    name: a.name,
    bytes: a.bytes,
    durationMs: a.durationMs,
    policy: a.transcriptionPolicy,
  );
  final String? id;
  final AttachmentKind kind;
  final String path;
  final String? name;
  final int? bytes;
  final int? durationMs;

  /// Only new saved voice rows can request work; never run on a temp file.
  final TranscriptionPolicy? policy;
  final bool policyChanged;

  /// A save request, distinct from a saved recording's durable policy.
  bool get transcribe => id == null && kind == AttachmentKind.voice && policy == TranscriptionPolicy.afterSave;
  AttachmentDraft withPolicy(TranscriptionPolicy value) => AttachmentDraft(
    id: id,
    kind: kind,
    path: path,
    name: name,
    bytes: bytes,
    durationMs: durationMs,
    policy: value,
    policyChanged: true,
  );

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
          policy: a.policy,
          policyChanged: a.policyChanged,
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
      policyChanged: a.policyChanged,
      policy: a.kind != AttachmentKind.voice
          ? TranscriptionPolicy.off
          : a.policy ?? (a.id == null && automatic ? TranscriptionPolicy.afterSave : TranscriptionPolicy.off),
    ),
];

/// Only the new copied files requested by this exact save may wake the queue.
List<String> newTranscriptionPaths(List<AttachmentDraft> stored) => [
  for (final a in stored)
    if (a.id == null && a.kind == AttachmentKind.voice && a.transcribe) a.path,
];
