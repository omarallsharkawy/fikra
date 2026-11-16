import 'dart:async';
import 'dart:developer' as developer;

import 'package:drift/drift.dart';

import '../local/database.dart';
import 'transcript_paragraph.dart';

class TranscriptConflict implements Exception {
  const TranscriptConflict();
}

class TranscriptUpdate {
  const TranscriptUpdate(this.noteId, this.revision, {required this.noteChanged});
  final String noteId;
  final int revision;

  /// The note now holds the saved text (replaced, appended or already equal).
  /// False means the copy was unsafe to touch and an append should be offered.
  final bool noteChanged;
}

/// Revision is an opaque monotonic token. Its low bit records a newer machine
/// result while a correction exists; correction/restore saves clear that bit.
/// Both bodies and the attachment are checked/written in the same transaction.
class TranscriptCorrections {
  TranscriptCorrections(this.db, {required this.processNote});
  final FikraDatabase db;
  final Future<void> Function(String id) processNote;

  Future<TranscriptUpdate> save(String id, {required int revision, String? correction, bool append = false}) async {
    final result = await db.transaction(() async {
      final a = await (db.select(db.noteAttachments)..where((a) => a.id.equals(id))).getSingleOrNull();
      if (a == null || a.kind != AttachmentKind.voice || a.transcriptRevision != revision || a.transcript == null) {
        throw const TranscriptConflict();
      }
      final note = await (db.select(db.notes)..where((n) => n.id.equals(a.noteId))).getSingleOrNull();
      if (note == null) throw const TranscriptConflict();
      final text = (correction ?? a.transcript!).trim();
      if (text.isEmpty) throw const TranscriptConflict();
      final marker = a.transcriptNoteText;
      String? original, edited;
      if (append) {
        String joined(String body) => uniqueTranscriptParagraph(body, text) != null
            ? body
            : body.trim().isEmpty
            ? text
            : '${body.trimRight()}\n\n$text';
        original = uniqueTranscriptParagraph(note.originalText, text) != null
            ? note.originalText
            : joined(note.originalText);
        edited = note.editedText == null
            ? null
            : uniqueTranscriptParagraph(note.editedText!, text) != null
            ? note.editedText
            : joined(note.editedText!);
      } else if (marker != null) {
        original = replaceTranscriptParagraph(note.originalText, marker, text);
        edited = note.editedText == null ? null : replaceTranscriptParagraph(note.editedText!, marker, text);
      }
      final safe = original != null && (note.editedText == null || edited != null);
      // An identical body needs no write: keep a pending proposal and skip analysis.
      final rewritten = safe && (original != note.originalText || edited != note.editedText);
      final next = nextTranscriptRevision(a.transcriptRevision);
      await (db.update(
        db.noteAttachments,
      )..where((v) => v.id.equals(id) & v.transcriptRevision.equals(revision))).write(
        NoteAttachmentsCompanion(
          transcriptCorrection: Value(correction == null ? null : text),
          correctedAt: Value(correction == null ? null : DateTime.now()),
          transcriptRevision: Value(next),
          transcriptNoteText: safe ? Value(text) : const Value.absent(),
        ),
      );
      if (rewritten) {
        await (db.update(db.notes)..where((n) => n.id.equals(note.id))).write(
          NotesCompanion(
            originalText: Value(original),
            editedText: Value(edited),
            proposedText: const Value(null),
            rewrite: note.rewrite == RewriteStatus.pending ? const Value(RewriteStatus.none) : const Value.absent(),
            status: const Value(ProcessingStatus.processing),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
      return (TranscriptUpdate(note.id, next, noteChanged: safe), rewritten);
    });
    // The correction is committed. Analysis can take the AI timeout and waits
    // behind other notes, so never hold the editor; launch recovery resumes it.
    if (result.$2) {
      try {
        unawaited(
          processNote(result.$1.noteId).catchError((Object _) {
            developer.log('Note analysis will resume on launch', name: 'FIKRA_TRANSCRIPTION');
          }),
        );
      } catch (_) {
        developer.log('Note analysis will resume on launch', name: 'FIKRA_TRANSCRIPTION');
      }
    }
    return result.$1;
  }
}
