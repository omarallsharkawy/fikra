/// Exact, standalone copied blocks only. A transcript may itself contain blank
/// lines; neither punctuation nor whitespace inside the block is normalized.
int? uniqueTranscriptParagraph(String body, String copy) {
  if (copy.isEmpty) return null;
  int? found;
  var cursor = 0;
  while (cursor <= body.length - copy.length) {
    final at = body.indexOf(copy, cursor);
    if (at < 0) break;
    final end = at + copy.length;
    final before = at == 0 || RegExp(r'\r?\n[ \t]*\r?\n$').hasMatch(body.substring(0, at));
    final after = end == body.length || RegExp(r'^\r?\n[ \t]*\r?\n').hasMatch(body.substring(end));
    if (before && after) {
      if (found != null) return null;
      found = at;
    }
    cursor = at + 1;
  }
  return found;
}

String? replaceTranscriptParagraph(String body, String copy, String replacement) {
  final at = uniqueTranscriptParagraph(body, copy);
  return at == null ? null : body.replaceRange(at, at + copy.length, replacement);
}
