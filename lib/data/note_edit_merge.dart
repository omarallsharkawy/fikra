import 'local/database.dart';
import 'processing/transcript_paragraph.dart';

class NoteEditConflict implements Exception {
  const NoteEditConflict();
}

/// The bodies and stable transcript identities the editor actually displayed.
class NoteEditBasis {
  const NoteEditBasis(this.note, this.attachments);
  final Note note;
  final List<NoteAttachment> attachments;
}

String _join(String body, String text) => body.trim().isEmpty ? text : '${body.trimRight()}\n\n$text';

/// Only attachment-identified changes may be merged into a typed draft.
String reconcileNoteEdit(NoteEditBasis basis, String draft, Note live, List<NoteAttachment> attachments) {
  final base = basis.note;
  if (base.id != live.id) throw const NoteEditConflict();
  if (draft.trim() == base.displayText.trim()) return live.displayText.trim();
  if (base.displayText == live.displayText && base.originalText == live.originalText) return draft.trim();
  final old = {for (final a in basis.attachments) a.id: a};
  var original = base.originalText;
  var body = base.displayText;
  final additions = <String, String>{};
  for (final a in attachments) {
    final before = old[a.id];
    final marker = a.transcriptNoteText;
    if (marker == null || marker == before?.transcriptNoteText) continue;
    if (before == null || a.transcriptRevision <= before.transcriptRevision) throw const NoteEditConflict();
    final previous = before.transcriptNoteText;
    if (previous == null || live.originalText.startsWith(_join(base.originalText, marker))) {
      additions[a.id] = marker;
    } else {
      final nextOriginal = replaceTranscriptParagraph(original, previous, marker);
      final nextBody = replaceTranscriptParagraph(body, previous, marker);
      if (nextOriginal == null || nextBody == null) throw const NoteEditConflict();
      original = nextOriginal;
      body = nextBody;
    }
  }
  // The exact append chain proves which identities contributed, including two
  // attachments with equal words. Text equality never suppresses an identity.
  final ordered = <String>[];
  while (additions.isNotEmpty) {
    final entry = additions.entries
        .where(
          (e) =>
              live.originalText == _join(original, e.value) ||
              live.originalText.startsWith('${_join(original, e.value)}\n\n'),
        )
        .firstOrNull;
    if (entry == null) throw const NoteEditConflict();
    original = _join(original, entry.value);
    ordered.add(entry.value);
    additions.remove(entry.key);
  }
  var expectedBody = body;
  for (final text in ordered) {
    expectedBody = _join(expectedBody, text);
  }
  if (base.editedText == null && live.editedText == null) {
    if (base.extractedText != live.extractedText) throw const NoteEditConflict();
    expectedBody = [original.trim(), (base.extractedText ?? '').trim()].where((s) => s.isNotEmpty).join('\n\n');
  }
  if (original != live.originalText || expectedBody != live.displayText) throw const NoteEditConflict();
  var merged = _mergeLines(base.displayText, draft.trim(), body);
  for (final text in ordered) {
    merged = _join(merged, text);
  }
  return merged;
}

class _Hunk {
  const _Hunk(this.start, this.end, this.lines);
  final int start, end;
  final List<String> lines;
}

List<_Hunk> _diff(List<String> base, List<String> other) {
  if (base.length * other.length > 1000000) throw const NoteEditConflict();
  final lengths = List.generate(base.length + 1, (_) => List.filled(other.length + 1, 0));
  for (var i = base.length - 1; i >= 0; i--) {
    for (var j = other.length - 1; j >= 0; j--) {
      lengths[i][j] = base[i] == other[j]
          ? lengths[i + 1][j + 1] + 1
          : (lengths[i + 1][j] > lengths[i][j + 1] ? lengths[i + 1][j] : lengths[i][j + 1]);
    }
  }
  final result = <_Hunk>[];
  var i = 0, j = 0;
  while (i < base.length || j < other.length) {
    if (i < base.length && j < other.length && base[i] == other[j]) {
      i++;
      j++;
      continue;
    }
    final start = i;
    final lines = <String>[];
    while (i < base.length || j < other.length) {
      if (i < base.length && j < other.length && base[i] == other[j]) break;
      if (j < other.length && (i == base.length || lengths[i][j + 1] >= lengths[i + 1][j])) {
        lines.add(other[j++]);
      } else {
        i++;
      }
    }
    result.add(_Hunk(start, i, lines));
  }
  return result;
}

String _mergeLines(String baseText, String draft, String background) {
  final base = baseText.split('\n');
  final user = _diff(base, draft.split('\n'));
  final remote = _diff(base, background.split('\n'));
  final changes = [...user];
  for (final h in remote) {
    final overlaps = user
        .where(
          (u) =>
              u.start < h.end && h.start < u.end ||
              u.start == h.start ||
              (u.start == u.end && u.start > h.start && u.start < h.end),
        )
        .toList();
    if (overlaps.isEmpty) {
      changes.add(h);
      continue;
    }
    if (overlaps.length != 1) throw const NoteEditConflict();
    final u = overlaps.single;
    // An explicit deletion stays deleted. Competing replacements need review.
    if (u.start <= h.start && u.end >= h.end && u.lines.every((s) => s.isEmpty)) continue;
    if (u.start == h.start && u.end == h.end && u.lines.join('\n') == h.lines.join('\n')) continue;
    throw const NoteEditConflict();
  }
  changes.sort((a, b) => b.start.compareTo(a.start));
  for (final h in changes) {
    base.replaceRange(h.start, h.end, h.lines);
  }
  return base.join('\n');
}
