part of 'graph_layout.dart';

/// Re-attach links of folded notes to their capsule. Links inside one capsule
/// are dropped; several links between the same two endpoints are drawn once
/// (a user link wins the style). A merged line carries a reason only when it
/// stands for exactly one link, so it never shows one reason for many.
List<GraphLink> _foldGraphLinks(
  List<GraphLink> pairs,
  List<GraphNote> ready,
  Map<String, GraphNote> nodes,
  Map<String, String> foldedNotes,
) {
  final readyIds = ready.map((n) => n.id).toSet();
  final capsules = foldedNotes.values.toSet();
  bool endpoint(String id) => nodes.containsKey(id) || capsules.contains(id);
  // [pairs] has one row per note pair: untouched links pass straight through.
  final visible = <GraphLink>[], folded = <GraphLink>[];
  for (final l in pairs) {
    final source = foldedNotes[l.sourceId], target = foldedNotes[l.targetId];
    if (source == null && target == null) {
      if (nodes.containsKey(l.sourceId) && nodes.containsKey(l.targetId)) visible.add(l);
      continue;
    }
    if (source == target || !readyIds.contains(l.sourceId) || !readyIds.contains(l.targetId)) continue;
    final s = source ?? l.sourceId, t = target ?? l.targetId;
    if (!endpoint(s) || !endpoint(t)) continue;
    folded.add((id: l.id, sourceId: s, targetId: t, label: l.label, strength: l.strength, isUser: l.isUser));
  }
  (String, String) key(GraphLink l) =>
      l.sourceId.compareTo(l.targetId) <= 0 ? (l.sourceId, l.targetId) : (l.targetId, l.sourceId);
  final bundled = <(String, String), int>{};
  for (final l in folded) {
    bundled.update(key(l), (n) => n + 1, ifAbsent: () => 1);
  }
  return [
    ...visible,
    for (final l in uniqueLinkPairs(
      folded,
      source: (l) => l.sourceId,
      target: (l) => l.targetId,
      isUser: (l) => l.isUser,
    ))
      bundled[key(l)]! > 1
          ? (id: l.id, sourceId: l.sourceId, targetId: l.targetId, label: '', strength: l.strength, isUser: l.isUser)
          : l,
  ];
}
