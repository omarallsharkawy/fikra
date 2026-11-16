import 'dart:async';
import 'dart:developer' as developer;

import 'package:drift/drift.dart';

import '../local/database.dart';
import '../local/transcription_order.dart';
import '../settings_repository.dart';
import 'transcription_engine.dart';
import 'transcription_keep_alive.dart';

/// Durable state in SQLite, FIFO scheduling in this process. Enqueue completes
/// after persisting `queued`; [drained] is for tests/maintenance, not save UI.
class TranscriptionQueue {
  TranscriptionQueue(
    this.db,
    this.settings,
    this.engine, {
    required this.processNote,
    this.keepAlive = const NoTranscriptionKeepAlive(),
  });
  final FikraDatabase db;
  final VoiceTextSettings settings;
  final TranscriptionEngineFactory engine;
  final Future<void> Function(String noteId) processNote;

  /// Runs from the first job's start until the queue is empty again.
  final TranscriptionKeepAlive keepAlive;
  bool _kept = false;
  final _pending = <String>{};
  Future<void> _tail = Future.value();
  Future<void> get drained => _tail;

  /// The keep-alive is a convenience: its failure never stops a job.
  Future<void> _keep(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      developer.log('Transcription keep-alive failed', name: 'FIKRA_TRANSCRIPTION');
    }
  }

  Future<NoteAttachment?> _attachment(String id) =>
      (db.select(db.noteAttachments)..where((a) => a.id.equals(id))).getSingleOrNull();
  Future<Note?> _note(String id) => (db.select(db.notes)..where((n) => n.id.equals(id))).getSingleOrNull();

  /// Runs that may start after the app closed mid-transcription. A third start
  /// could crash the app on every launch (a native crash or out-of-memory kill).
  static const maxInterruptedAttempts = 2;

  /// [manual] is the user's retry/redo/transcribe, which starts the attempt
  /// count again. Launch recovery and save wake-ups keep it.
  Future<void> enqueue(String id, {bool redo = false, bool manual = false}) async {
    if (!_pending.add(id)) return;
    // Reserve the FIFO position synchronously, before any database await.
    final ready = Completer<bool>();
    _tail = _tail.then((_) async {
      try {
        if (await ready.future) {
          await _keep(() => keepAlive.start(_pending.length));
          _kept = true;
          await _run(id);
        }
      } catch (_) {
        developer.log('Transcription state could not be saved', name: 'FIKRA_TRANSCRIPTION');
        // A database failure must not poison later jobs. Durable queued/running
        // state is recovered on launch if even the failure write was impossible.
      } finally {
        _pending.remove(id);
        // Success or failure, the last job ends the keep-alive.
        if (_pending.isEmpty && _kept) {
          _kept = false;
          await _keep(keepAlive.stop);
        }
      }
    });
    try {
      final accepted = await db.transaction(() async {
        final a = await _attachment(id);
        if (a == null || a.kind != AttachmentKind.voice || await _note(a.noteId) == null) return false;
        if (!manual && a.transcriptionPolicy == TranscriptionPolicy.off) return false;
        if (!redo && a.transcriptionStatus == TranscriptionStatus.done) return false;
        await (db.update(db.noteAttachments)..where((a) => a.id.equals(id))).write(
          NoteAttachmentsCompanion(
            transcriptionOrder: Value(
              !redo &&
                      const [TranscriptionStatus.queued, TranscriptionStatus.running].contains(a.transcriptionStatus) &&
                      a.transcriptionOrder != null
                  ? a.transcriptionOrder
                  : await nextTranscriptionOrder(db),
            ),
            transcriptionPolicy: manual ? const Value(TranscriptionPolicy.afterSave) : const Value.absent(),
            transcriptionStatus: const Value(TranscriptionStatus.queued),
            transcriptionFailure: const Value(null),
            transcriptionAttempts: manual ? const Value(0) : const Value.absent(),
          ),
        );
        return true;
      });
      ready.complete(accepted);
      // A job joined while another runs: the notification's count goes up.
      if (accepted && _kept) await _keep(() => keepAlive.start(_pending.length));
    } catch (_) {
      ready.complete(false);
      rethrow;
    }
  }

  /// Save already persisted the request atomically with its new attachment.
  /// If this wake-up is interrupted, startup recovery still finds the row.
  Future<void> saved(String noteId, Iterable<String> paths) async {
    final requested = paths.toSet();
    if (requested.isEmpty) return;
    final rows =
        await (db.select(db.noteAttachments)
              ..where((a) => a.noteId.equals(noteId) & a.path.isIn(requested) & a.transcriptionStatus.equals('queued'))
              ..orderBy([(a) => OrderingTerm.asc(a.position)]))
            .get();
    for (final a in rows) {
      await enqueue(a.id);
    }
  }

  Future<void> resumeInterrupted() async {
    final rows =
        await (db.select(db.noteAttachments)
              ..where((a) => a.transcriptionStatus.isIn(['queued', 'running']))
              ..orderBy([
                (a) => OrderingTerm.asc(a.transcriptionOrder),
                (a) => OrderingTerm.asc(a.createdAt),
                (a) => OrderingTerm.asc(a.position),
                (a) => OrderingTerm.asc(a.id),
              ]))
            .get();
    for (final row in rows) {
      if (row.transcriptionPolicy == TranscriptionPolicy.off) continue;
      if (row.transcriptionAttempts >= maxInterruptedAttempts) {
        // Both runs ended with the app closing. Stop until the user asks again.
        await (db.update(db.noteAttachments)..where((a) => a.id.equals(row.id))).write(
          NoteAttachmentsCompanion(
            transcriptionStatus: const Value(TranscriptionStatus.failed),
            transcriptionFailure: Value(TranscriptionFailureReason.interruptedTwice.name),
            transcribedAt: Value(DateTime.now()),
          ),
        );
      } else {
        await enqueue(row.id);
      }
    }
  }

  Future<void> _run(String id) async {
    try {
      final a = await db.transaction(() async {
        final live = await _attachment(id);
        if (live == null ||
            live.kind != AttachmentKind.voice ||
            live.transcriptionPolicy == TranscriptionPolicy.off ||
            await _note(live.noteId) == null) {
          return null;
        }
        // Persisted before inference: a crash inside native code still counts.
        await (db.update(db.noteAttachments)..where((a) => a.id.equals(id))).write(
          NoteAttachmentsCompanion(
            transcriptionStatus: const Value(TranscriptionStatus.running),
            transcriptionAttempts: Value(live.transcriptionAttempts + 1),
          ),
        );
        return live;
      });
      if (a == null) return;
      final selected = await engine();
      final saved = await settings.readVoiceTextChoices();
      final language = const ['ar', 'en', 'auto'].contains(saved.language) ? saved.language! : 'ar';
      final text = (await selected.transcribe(a.path, language: language)).trim();
      if (text.isEmpty) throw const TranscriptionFailure(TranscriptionFailureReason.audioUnreadable);
      final noteId = await db.transaction(() async {
        final live = await _attachment(id);
        if (live == null || live.kind != AttachmentKind.voice || live.transcriptionPolicy == TranscriptionPolicy.off) {
          return null;
        }
        final note = await _note(live.noteId);
        if (note == null) return null;
        final current = note.displayText;
        final previous = live.transcriptNoteText ?? live.transcript;
        final previousPresent = previous != null && previous.isNotEmpty && current.contains(previous);
        final append = live.transcriptCorrection == null && !current.contains(text) && !previousPresent;
        await (db.update(db.noteAttachments)..where((a) => a.id.equals(id))).write(
          NoteAttachmentsCompanion(
            transcript: Value(text),
            transcriptRevision: Value(
              nextTranscriptRevision(live.transcriptRevision, newerMachine: live.transcriptCorrection != null),
            ),
            transcriptNoteText: Value(
              live.transcriptCorrection != null
                  ? live.transcriptNoteText
                  : previousPresent
                  ? previous
                  : text,
            ),
            transcriptionStatus: const Value(TranscriptionStatus.done),
            transcriptionFailure: const Value(null),
            transcriptionEngine: Value(selected.id),
            transcribedAt: Value(DateTime.now()),
          ),
        );
        // On redo, retain the transcript the user already sees in the note.
        // Append the replacement only if they removed the previous transcript.
        // A transcript counts as text the user wrote: it goes into originalText,
        // so "restore original" keeps it, and into an edited or accepted text
        // the note shows, so the visible text has it exactly once.
        String joined(String body) => body.trim().isEmpty ? text : '${body.trimRight()}\n\n$text';
        final original = append && !note.originalText.contains(text) ? joined(note.originalText) : null;
        await (db.update(db.notes)..where((n) => n.id.equals(note.id))).write(
          NotesCompanion(
            // Persist the next AI pass before waking it, for launch recovery.
            status: const Value(ProcessingStatus.processing),
            originalText: original != null ? Value(original) : const Value.absent(),
            editedText: append && note.editedText != null ? Value(joined(note.editedText!)) : const Value.absent(),
            // As in a user edit: a pending proposal no longer matches the text.
            proposedText: append ? const Value(null) : const Value.absent(),
            // An accepted or rejected rewrite keeps its history.
            rewrite: append && note.rewrite == RewriteStatus.pending
                ? const Value(RewriteStatus.none)
                : const Value.absent(),
            updatedAt: append ? Value(DateTime.now()) : const Value.absent(),
          ),
        );
        return note.id;
      });
      // Schedule analysis, but do not hold the transcription FIFO behind AI.
      if (noteId != null) {
        // A scheduling failure must not change a successfully saved transcript.
        try {
          unawaited(
            processNote(noteId).catchError((Object _) {
              developer.log('Note analysis will resume on launch', name: 'FIKRA_TRANSCRIPTION');
            }),
          );
        } catch (_) {
          developer.log('Note analysis will resume on launch', name: 'FIKRA_TRANSCRIPTION');
        }
      }
    } catch (error) {
      final reason = error is TranscriptionFailure ? error.reason : TranscriptionFailureReason.other;
      await (db.update(
        db.noteAttachments,
      )..where((a) => a.id.equals(id) & a.kind.equals('voice') & a.transcriptionPolicy.equals('off').not())).write(
        NoteAttachmentsCompanion(
          transcriptionStatus: const Value(TranscriptionStatus.failed),
          transcriptionFailure: Value(reason.name),
          transcribedAt: Value(DateTime.now()),
        ),
      );
    }
  }
}
