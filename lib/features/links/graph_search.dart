import '../shared/link_pairs.dart';
import 'graph_layout.dart';

enum GraphSearchKind { note, link, group }

/// Indexed once per accepted data projection, independent of layout caps/folds.
class GraphSearchResult {
  const GraphSearchResult(
    this.kind,
    this.id,
    this.title, {
    this.otherTitle = '',
    this.reason = '',
    this.noteIds = const [],
  });
  final GraphSearchKind kind;
  final String id, title, otherTitle, reason;
  final List<String> noteIds;
}

class GraphSearchIndex {
  GraphSearchIndex(GraphInput input) {
    final notes = {
      for (final n in input.notes)
        if (n.status == 1) n.id: n,
    };
    final pairs = uniqueLinkPairs(
      input.links.where((l) => notes.containsKey(l.sourceId) && notes.containsKey(l.targetId)),
      source: (l) => l.sourceId,
      target: (l) => l.targetId,
      isUser: (l) => l.isUser,
    );
    _entries = [
      for (final n in notes.values)
        (n.title.toLowerCase(), GraphSearchResult(GraphSearchKind.note, n.id, n.title, noteIds: [n.id])),
      for (final l in pairs)
        (
          l.label.toLowerCase(),
          GraphSearchResult(
            GraphSearchKind.link,
            l.id,
            notes[l.sourceId]!.title,
            otherTitle: notes[l.targetId]!.title,
            reason: l.label,
            noteIds: [l.sourceId, l.targetId],
          ),
        ),
      for (final g in input.groups) (g.name.toLowerCase(), GraphSearchResult(GraphSearchKind.group, g.id, g.name)),
    ];
  }
  late final List<(String, GraphSearchResult)> _entries;
  static const resultLimit = 30;

  List<GraphSearchResult> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _entries.where((e) => e.$1.contains(q)).take(resultLimit).map((e) => e.$2).toList();
  }
}
