import 'dart:typed_data';

enum DiffKind { same, added, removed }

class WordChange {
  const WordChange(this.kind, this.text);
  final DiffKind kind;
  final String text;
}

/// A real word-level edit script, preserving punctuation and every whitespace.
/// Common prefixes/suffixes keep large small-edits cheap. Bounded LCS prevents
/// unrelated 100k-character paragraphs from allocating a quadratic matrix.
List<WordChange> wordDiff(String before, String after) {
  final pattern = RegExp(r'\s+|[\p{L}\p{M}\p{N}_]+|[^\s]', unicode: true);
  final a = pattern.allMatches(before).map((m) => m.group(0)!).toList();
  final b = pattern.allMatches(after).map((m) => m.group(0)!).toList();
  var start = 0, endA = a.length, endB = b.length;
  while (start < endA && start < endB && a[start] == b[start]) {
    start++;
  }
  while (endA > start && endB > start && a[endA - 1] == b[endB - 1]) {
    endA--;
    endB--;
  }
  final result = <WordChange>[];
  void append(DiffKind kind, String text) {
    if (text.isEmpty) return;
    if (result.isNotEmpty && result.last.kind == kind) {
      final old = result.removeLast();
      result.add(WordChange(kind, old.text + text));
    } else {
      result.add(WordChange(kind, text));
    }
  }

  append(DiffKind.same, a.take(start).join());
  final n = endA - start, m = endB - start;
  if ((n + 1) * (m + 1) > 1000000) {
    append(DiffKind.removed, a.sublist(start, endA).join());
    append(DiffKind.added, b.sublist(start, endB).join());
  } else {
    final cols = m + 1, table = Uint32List((n + 1) * (m + 1));
    for (var i = n - 1; i >= 0; i--) {
      for (var j = m - 1; j >= 0; j--) {
        table[i * cols + j] = a[start + i] == b[start + j]
            ? table[(i + 1) * cols + j + 1] + 1
            : (table[(i + 1) * cols + j] >= table[i * cols + j + 1]
                  ? table[(i + 1) * cols + j]
                  : table[i * cols + j + 1]);
      }
    }
    var i = 0, j = 0;
    while (i < n || j < m) {
      if (i < n && j < m && a[start + i] == b[start + j]) {
        append(DiffKind.same, a[start + i]);
        i++;
        j++;
      } else if (j < m && (i == n || table[i * cols + j + 1] > table[(i + 1) * cols + j])) {
        append(DiffKind.added, b[start + j]);
        j++;
      } else {
        append(DiffKind.removed, a[start + i]);
        i++;
      }
    }
  }
  append(DiffKind.same, a.sublist(endA).join());
  return List.unmodifiable(result);
}
