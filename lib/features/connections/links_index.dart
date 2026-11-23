import '../../core/format.dart';
import '../shared/link_pairs.dart';

/// Sendable projections keep derivation independent of Flutter and storage.
typedef LibraryNote = ({
  String id,
  String projectId,
  String title,
  String text,
  String concepts,
  String? groupId,
  String? topic,
  DateTime createdAt,
});
typedef LibraryLink = ({
  String id,
  String projectId,
  String sourceId,
  String targetId,
  String reason,
  bool confirmed,
  bool dismissed,
  double strength,
  DateTime? createdAt,
});
typedef LibraryGroup = ({String id, String projectId, String? parentId});
typedef BrowseEntry = ({LibraryNote note, List<LibraryNote> others});
typedef SuggestionEntry = ({LibraryNote a, LibraryNote b, LibraryLink link});
typedef LibraryView = ({List<BrowseEntry> browse, List<SuggestionEntry> suggestions});
typedef LibraryChip = ({String? group, String? topic});

enum LinksSort { newest, mostLinks, oldest }

typedef LibraryNotesInput = ({String projectId, List<LibraryNote> notes});

String pairKey(String a, String b) => a.compareTo(b) <= 0 ? '$a|$b' : '$b|$a';

/// Test hook counting group-scan iterations in [deriveLinksIndex].
int debugLinksIndexGroupOps = 0;

/// Decides whether pair/group derivation should run on a background isolate,
/// factoring in notes, edges and groups so dense projects under 1,000 notes are
/// offloaded while small projects avoid isolate transfer overhead.
bool shouldIsolateLinksDerivation({required int notes, required int links, required int groups}) =>
    notes >= 1000 || links >= 1500 || groups >= 1000 || notes + links + groups >= 2000;

/// The per-note half of the derivation: it depends only on the notes list, so
/// a link write (accept, reject, analysis) reuses it and never re-lowercases
/// thousands of note bodies. Safe to build on a background isolate.
class LibraryNotes {
  LibraryNotes._(this.projectId, this.byId, this.newest, this.oldest, this.rank, this.haystacks, this.haystackWords);

  final String projectId;
  final Map<String, LibraryNote> byId;

  /// Project notes newest first (ties by id), and oldest first (ties by id).
  final List<LibraryNote> newest, oldest;

  /// Position in [newest], for cheap integer ordering of neighbour lists.
  final Map<String, int> rank;

  /// Normalized title, body and concepts, plus pre-tokenized word lists.
  /// Keystrokes only run matching.
  final Map<String, String> haystacks;
  final Map<String, List<String>> haystackWords;
}

LibraryNotes deriveLibraryNotes(LibraryNotesInput input) {
  final notes = [
    for (final n in input.notes)
      if (n.projectId == input.projectId) n,
  ];
  final newest = List.of(notes)
    ..sort((a, b) {
      final time = b.createdAt.compareTo(a.createdAt);
      return time != 0 ? time : a.id.compareTo(b.id);
    });
  final oldest = notes
    ..sort((a, b) {
      final time = a.createdAt.compareTo(b.createdAt);
      return time != 0 ? time : a.id.compareTo(b.id);
    });
  final haystacks = <String, String>{};
  final haystackWords = <String, List<String>>{};
  for (final n in newest) {
    final h = normalizeArabic('${n.title}\n${n.text}\n${n.concepts}');
    haystacks[n.id] = h;
    haystackWords[n.id] = tokenizeNormalizedArabic(h);
  }
  return LibraryNotes._(
    input.projectId,
    {for (final n in newest) n.id: n},
    newest,
    oldest,
    {for (final (i, n) in newest.indexed) n.id: i},
    haystacks,
    haystackWords,
  );
}

/// Built once per source emission. Every sort order is ready, so keystrokes
/// only filter cached haystacks and never sort.
class LinksIndex {
  LinksIndex._(
    this._notes,
    this._orders,
    this.suggestions,
    this.groupCounts,
    this.topicCounts,
    this.groupIds,
    this.linksSource,
  ) {
    for (final s in suggestions) {
      final key = pairKey(s.a.id, s.b.id);
      suggestionPairs.add(key);
      (suggestionsByNote[s.a.id] ??= []).add(s);
      (suggestionsByNote[s.b.id] ??= []).add(s);
    }
  }

  final suggestionPairs = <String>{};
  final suggestionsByNote = <String, List<SuggestionEntry>>{};

  /// Restore the UI-isolate source identity after a background derivation.
  void attachLinksSource(Object source) => linksSource = source;

  final LibraryNotes _notes;
  final Map<LinksSort, List<BrowseEntry>> _orders;
  final List<SuggestionEntry> suggestions;

  /// Parent counts include children, and count linked notes, never edges.
  final Map<String, int> groupCounts;
  final Map<String, int> topicCounts;
  final Map<String, Set<String>> groupIds;

  /// The links list this index was derived from. A different object means a
  /// newer links emission, which is what [LinkPairBusy] waits for.
  Object? linksSource;
  final _views = <(LibraryChip, String, LinksSort), LibraryView>{};

  Map<String, LibraryNote> get notes => _notes.byId;

  /// Newest first.
  List<BrowseEntry> get browse => _orders[LinksSort.newest]!;

  LibraryView filter({
    LibraryChip chip = (group: null, topic: null),
    String search = '',
    LinksSort sort = LinksSort.newest,
  }) {
    final query = normalizeArabic(search);
    final key = (chip, query, sort);
    final cached = _views[key];
    if (cached != null) return cached;
    final groups = groupIds[chip.group];
    final haystacks = _notes.haystacks;
    final haystackWords = _notes.haystackWords;
    final queryWords = query.isEmpty ? const <String>[] : tokenizeNormalizedArabic(query);
    bool matches(LibraryNote n) =>
        (chip.group == null || (groups?.contains(n.groupId) ?? false)) &&
        (chip.topic == null || (n.groupId == null && n.topic?.trim() == chip.topic)) &&
        (query.isEmpty ||
            matchesNormalizedArabic(
              haystacks[n.id]!,
              query,
              haystackWords: haystackWords[n.id]!,
              queryWords: queryWords,
            ));
    final view = (
      browse: _orders[sort]!.where((r) => matches(r.note)).toList(),
      suggestions: suggestions.where((s) => matches(s.a) || matches(s.b)).toList(),
    );
    // Bound a session's queries, retaining recent exact combinations.
    if (_views.length == 32) _views.remove(_views.keys.first);
    _views[key] = view;
    return view;
  }
}

/// Both halves in one call, for tests and small one-off derivations.
LinksIndex deriveLinks(String projectId, List<LibraryNote> notes, List<LibraryLink> links, List<LibraryGroup> groups) =>
    deriveLinksIndex(deriveLibraryNotes((projectId: projectId, notes: notes)), links, groups);

/// The per-link half: pairs, neighbours, counts and the three browse orders.
/// Linear apart from the suggestion sort; safe to run on a background isolate.
/// [source] is the stored links list the projection came from (see
/// [LinksIndex.linksSource]); it defaults to [links].
LinksIndex deriveLinksIndex(LibraryNotes notes, List<LibraryLink> links, List<LibraryGroup> groups, {Object? source}) {
  final projectId = notes.projectId, byId = notes.byId, rank = notes.rank;
  final projectGroups = <LibraryGroup>[];
  final childrenByParent = <String, List<String>>{};
  for (final g in groups) {
    debugLinksIndexGroupOps++;
    if (g.projectId != projectId) continue;
    projectGroups.add(g);
    if (g.parentId case final parentId?) {
      (childrenByParent[parentId] ??= []).add(g.id);
    }
  }
  final groupIds = <String, Set<String>>{};
  for (final g in projectGroups) {
    final ids = <String>{g.id};
    debugLinksIndexGroupOps++;
    if (childrenByParent[g.id] case final children?) {
      for (final childId in children) {
        debugLinksIndexGroupOps++;
        ids.add(childId);
      }
    }
    groupIds[g.id] = ids;
  }
  final pairs = uniqueLinkPairs(
    links.where(
      (l) => l.projectId == projectId && !l.dismissed && byId.containsKey(l.sourceId) && byId.containsKey(l.targetId),
    ),
    source: (l) => l.sourceId,
    target: (l) => l.targetId,
    isUser: (l) => l.confirmed,
  );
  final neighbours = <String, List<LibraryNote>>{};
  final suggested = <LibraryLink>[];
  for (final l in pairs) {
    if (l.confirmed) {
      final a = byId[l.sourceId]!, b = byId[l.targetId]!;
      (neighbours[a.id] ??= []).add(b);
      (neighbours[b.id] ??= []).add(a);
    } else {
      suggested.add(l);
    }
  }
  // Strongest, then newest, then id. Sorting the flat link records is far
  // cheaper than sorting the nested suggestion entries (2 vs 150 ms at 5,000).
  final epoch = DateTime(1970);
  suggested.sort((a, b) {
    final strength = b.strength.compareTo(a.strength);
    if (strength != 0) return strength;
    final time = (b.createdAt ?? epoch).compareTo(a.createdAt ?? epoch);
    return time != 0 ? time : a.id.compareTo(b.id);
  });
  final suggestions = <SuggestionEntry>[
    for (final l in suggested) (a: byId[l.sourceId]!, b: byId[l.targetId]!, link: l),
  ];
  for (final others in neighbours.values) {
    if (others.length > 1) others.sort((x, y) => rank[x.id]! - rank[y.id]!);
  }
  List<BrowseEntry> ordered(List<LibraryNote> order) => [
    for (final n in order)
      if (neighbours[n.id] case final others?) (note: n, others: others),
  ];
  final newest = ordered(notes.newest);
  // Most links first, ties newest first: a stable bucket pass over [newest].
  final byDegree = <int, List<BrowseEntry>>{};
  for (final row in newest) {
    (byDegree[row.others.length] ??= []).add(row);
  }
  final degrees = byDegree.keys.toList()..sort((a, b) => b - a);
  final directCounts = <String, int>{}, topics = <String, int>{};
  for (final row in newest) {
    final n = row.note;
    if (n.groupId != null) {
      directCounts.update(n.groupId!, (v) => v + 1, ifAbsent: () => 1);
    } else {
      final topic = n.topic?.trim();
      if (topic != null && topic.isNotEmpty) topics.update(topic, (v) => v + 1, ifAbsent: () => 1);
    }
  }
  final counts = {for (final g in groupIds.entries) g.key: g.value.fold(0, (n, id) => n + (directCounts[id] ?? 0))};
  return LinksIndex._(
    notes,
    {
      LinksSort.newest: newest,
      LinksSort.oldest: ordered(notes.oldest),
      LinksSort.mostLinks: [for (final d in degrees) ...byDegree[d]!],
    },
    suggestions,
    counts,
    topics,
    groupIds,
    source ?? links,
  );
}
