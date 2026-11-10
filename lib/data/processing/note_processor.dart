import 'dart:async';

import '../ai/ai_service.dart';
import '../local/database.dart';
import '../repositories.dart';

/// Runs the AI pass after a note is saved: processing → ready | failed.
///
/// Only typed text is analyzed. Attachments are never parsed, so a note with
/// nothing typed goes straight to ready.
///
/// The note is already stored before this runs, so a failure never loses what
/// the user wrote. Jobs run one at a time so each analysis sees the concepts
/// of the notes processed before it (two quick saves still get linked).
/// Results are applied against the snapshot they were computed from, so edits
/// made while the AI was working win (see [NotesRepository.applyInsights]).
class NoteProcessor {
  NoteProcessor(this.notes, this.ai, {this.timeout = const Duration(seconds: 90)});

  final NotesRepository notes;
  final AiService ai;

  /// A job that takes longer is marked failed and the queue moves on.
  final Duration timeout;

  Future<void> _queue = Future.value();

  /// Queues [note] for analysis. The returned future completes when its job
  /// is done; it never throws.
  Future<void> process(Note note) {
    final job = _queue.then((_) => _run(note.id));
    _queue = job.catchError((_) {});
    return job;
  }

  Future<void> retry(String id) async {
    final note = await notes.watchNote(id).first;
    if (note != null) await process(note);
  }

  /// Re-queues notes left in `processing` (the app was killed mid-analysis).
  Future<void> resumeInterrupted() async {
    for (final n in await notes.notesWithStatus(ProcessingStatus.processing)) {
      unawaited(process(n));
    }
  }

  /// Rebuilds concepts and links without changing processing or rewrite state.
  Future<void> relink(Iterable<String> ids) async {
    for (final id in ids.toSet()) {
      final job = _queue.then((_) => _run(id, linksOnly: true));
      _queue = job.catchError((_) {});
    }
    await _queue;
  }

  Future<void> _run(String id, {bool linksOnly = false}) async {
    try {
      final basis = await notes.watchNote(id).first;
      if (basis == null) return; // deleted while queued
      if (basis.originalText.trim().isEmpty) {
        if (!linksOnly) await notes.markReady(id);
        return;
      }
      if (!linksOnly) await notes.markProcessing(id);
      final projectNotes = await notes.notesOf(basis.projectId);
      final insights = await ai.analyze(basis, projectNotes).timeout(timeout);
      await notes.applyInsights(id, insights, basis: basis, linksOnly: linksOnly);
    } catch (_) {
      if (linksOnly) return;
      try {
        await notes.markFailed(id);
      } catch (_) {} // note deleted meanwhile
    }
  }
}
