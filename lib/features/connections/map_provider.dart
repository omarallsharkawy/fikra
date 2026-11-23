import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/note_groups.dart';
import 'links_library_provider.dart';
import 'map_index.dart';
import 'note_connections_provider.dart';

/// Every source is watched before awaiting; stale isolate results are discarded
/// by Riverpod. The existing shared adjacency is also used by connections pages.
final linksMapProvider = FutureProvider.autoDispose.family<MapIndex, String>((ref, project) async {
  final library = ref.watch(linksLibraryProvider(project).future);
  final adjacency = ref.watch(connectionsIndexProvider(project).future);
  final groups = ref.watch(groupsOfProjectProvider(project).future);
  final index = await library;
  final confirmed = await adjacency;
  final allGroups = await groups;
  final MapInput input = (
    library: index,
    adjacency: {
      for (final e in confirmed.entries) e.key: [for (final n in e.value) n.other.id],
    },
    groups: [for (final g in allGroups) (id: g.id, name: g.name, parentId: g.parentId, color: g.color)],
  );
  return index.notes.length >= 1000 ? compute(deriveMap, input, debugLabel: 'links-map') : deriveMap(input);
});
