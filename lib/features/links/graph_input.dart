part of 'graph_layout.dart';

typedef GraphGroup = ({String id, String? parentId, String name, int? color, int position});

class GraphFrame {
  const GraphFrame(this.group, this.bounds, this.count, this.noteIds, {this.headerExtent = GraphLayout.headerHeight});
  final GraphGroup group;
  final GraphPosition bounds;
  final int count;
  final double headerExtent;
  final Set<String> noteIds;
  GraphPosition get header => (left: bounds.left, top: bounds.top, width: bounds.width, height: headerExtent);
}

class GraphInput {
  GraphInput(
    this.notes,
    this.links, {
    this.rtl = true,
    this.generalLabel = '',
    this.groups = const [],
    this.memberships = const {},
    this.headerExtent = GraphLayout.headerHeight,
    this.labelSizes = const {},
    this.suggestedSize = (width: 180, height: 24),
  }) : signature = Object.hash(
         rtl,
         generalLabel,
         headerExtent,
         Object.hashAllUnordered(labelSizes.entries.map((e) => (e.key, e.value))),
         suggestedSize,
         notes.length,
         links.length,
         Object.hashAllUnordered(notes),
         Object.hashAllUnordered(links),
         Object.hashAllUnordered(groups),
         Object.hashAllUnordered(memberships.entries.map((e) => (e.key, e.value))),
       );

  final List<GraphNote> notes;
  final List<GraphLink> links;
  final List<GraphGroup> groups;
  final Map<String, String> memberships;
  final bool rtl;
  final String generalLabel;
  final double headerExtent;
  final Map<String, GraphTextSize> labelSizes;
  final GraphTextSize suggestedSize;

  /// Ignores stream ordering and fields outside the projections. Includes time
  /// (ranking), status, titles, and edge appearance as well as topology.
  final int signature;

  /// Check equality after hashing too: a hash collision must not hide an edit.
  bool sameData(GraphInput other) =>
      signature == other.signature &&
      rtl == other.rtl &&
      generalLabel == other.generalLabel &&
      headerExtent == other.headerExtent &&
      suggestedSize == other.suggestedSize &&
      labelSizes.length == other.labelSizes.length &&
      labelSizes.entries.every((e) => other.labelSizes[e.key] == e.value) &&
      _sameRecords(notes, other.notes) &&
      _sameRecords(links, other.links) &&
      _sameRecords(groups, other.groups) &&
      memberships.length == other.memberships.length &&
      memberships.entries.every((e) => other.memberships[e.key] == e.value);

  static bool _sameRecords<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    // Database streams normally retain their ordering. Avoid building a large
    // frequency map on the common, unchanged-data path.
    var sameOrder = true;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        sameOrder = false;
        break;
      }
    }
    if (sameOrder) return true;
    final counts = <T, int>{};
    for (final value in a) {
      counts.update(value, (count) => count + 1, ifAbsent: () => 1);
    }
    for (final value in b) {
      final count = counts[value];
      if (count == null) return false;
      if (count == 1) {
        counts.remove(value);
      } else {
        counts[value] = count - 1;
      }
    }
    return counts.isEmpty;
  }
}
