/// Choose one row per unordered pair. The first row wins unless a later user
/// row replaces a suggestion. Callers filter dismissed/missing rows first.
/// Kept free of Flutter and database types for the graph layout isolate.
List<T> uniqueLinkPairs<T>(
  Iterable<T> links, {
  required String Function(T) source,
  required String Function(T) target,
  required bool Function(T) isUser,
}) {
  final chosen = <(String, String), T>{};
  for (final link in links) {
    final a = source(link), b = target(link);
    if (a == b) continue;
    final pair = a.compareTo(b) <= 0 ? (a, b) : (b, a);
    final current = chosen[pair];
    if (current == null || (!isUser(current) && isUser(link))) chosen[pair] = link;
  }
  return chosen.values.toList();
}
