import 'dart:async';

import '../ai/ai_service.dart';
import '../local/database.dart';
import '../repositories.dart';

/// Runs the AI pass after a note is saved: processing → ready | failed.
///
/// Analyzes the typed text plus the transcripts saved on the note's
/// recordings. Edits, accepted rewrites and PDF text are not analyzed, so a note
/// without a transcript is analyzed exactly as before transcription existed.
/// A note with neither goes straight to ready.
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
      final transcripts = [
        for (final a in await notes.watchAttachments(id).first)
          if (a.kind == AttachmentKind.voice && (a.transcript?.trim().isNotEmpty ?? false)) a.transcript!.trim(),
      ];
      final typed = basis.originalText.trim();
      final analyzed = transcripts.isEmpty
          ? basis
          : basis.copyWith(originalText: [if (typed.isNotEmpty) typed, ...transcripts].join('\n\n'));
      if (analyzed.originalText.trim().isEmpty) {
        if (!linksOnly) await notes.markReady(id);
        return;
      }
      if (!linksOnly) await notes.markProcessing(id);
      final projectNotes = await notes.notesOf(basis.projectId);
      var insights = await ai.analyze(analyzed, projectNotes).timeout(timeout);
      if (transcripts.isNotEmpty) {
        // A rewrite of typed text plus transcripts is not the text the note
        // shows, and accepting it could bring back a transcript the user removed.
        insights = NoteInsights(
          title: insights.title,
          concepts: insights.concepts,
          cluster: insights.cluster,
          links: insights.links,
        );
      }
      // The stored note stays the basis, so edits made meanwhile still win.
      await notes.applyInsights(id, insights, basis: basis, linksOnly: linksOnly);
    } catch (_) {
      if (linksOnly) return;
      try {
        await notes.markFailed(id);
      } catch (_) {} // note deleted meanwhile
    }
  }
}
