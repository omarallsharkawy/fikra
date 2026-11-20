import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../app/providers.dart';
import '../../data/local/database.dart';
import '../shared/note_groups.dart';
import 'links_index.dart';

/// The per-note half, rebuilt only when the notes list emits. Link writes
/// (accept, reject, analysis) reuse it across background pair derivations.
final libraryNotesProvider = FutureProvider.autoDispose.family<LibraryNotes, String>((ref, projectId) async {
  final notes = ref.watch(notesOfProjectProvider(projectId));
  final notesFuture = ref.watch(notesOfProjectProvider(projectId).future);
  final allNotes = notes.hasValue ? notes.requireValue : await notesFuture;
  final LibraryNotesInput input = (projectId: projectId, notes: [for (final n in allNotes) projectNote(n)]);
  // Lowercasing 5,000 bodies exceeds a phone frame; keep large projects off
  // the UI isolate. Small projects avoid isolate start/transfer overhead.
  return allNotes.length >= 1000
      ? compute(deriveLibraryNotes, input, debugLabel: 'links-library-notes')
      : deriveLibraryNotes(input);
});

/// Only source providers invalidate the derivation; UI state is deliberately
/// absent. Both list and pushed pages share this project snapshot.
final linksLibraryProvider = FutureProvider.autoDispose.family<LinksIndex, String>((ref, projectId) async {
  final notes = ref.watch(libraryNotesProvider(projectId));
  final links = ref.watch(linksOfProjectProvider(projectId));
  final groups = ref.watch(groupsOfProjectProvider(projectId));
  // Watch every source before awaiting, so every emission invalidates the
  // snapshot. FutureProvider discards stale completions automatically.
  final notesFuture = ref.watch(libraryNotesProvider(projectId).future);
  final linksFuture = ref.watch(linksOfProjectProvider(projectId).future);
  final groupsFuture = ref.watch(groupsOfProjectProvider(projectId).future);
  final loaded = await Future.wait<Object>([
    notes.hasValue ? Future.value(notes.requireValue) : notesFuture,
    links.hasValue ? Future.value(links.requireValue) : linksFuture,
    groups.hasValue ? Future.value(groups.requireValue) : groupsFuture,
  ]);
  final allLinks = loaded[1] as List<NoteLink>;
  final allGroups = loaded[2] as List<NoteGroup>;
  final input = (
    notes: loaded[0] as LibraryNotes,
    links: [
      for (final l in allLinks)
        (
          id: l.id,
          projectId: l.projectId,
          sourceId: l.sourceId,
          targetId: l.targetId,
          reason: l.label,
          confirmed: l.origin == LinkOrigin.user,
          dismissed: l.dismissed,
          strength: l.strength,
          createdAt: l.createdAt,
        ),
    ],
    groups: [for (final g in allGroups) (id: g.id, projectId: g.projectId, parentId: g.parentId)],
  );
  final index = input.notes.byId.length >= 1000
      ? await compute(_deriveIndex, input, debugLabel: 'links-library-pairs')
      : _deriveIndex(input);
  index.attachLinksSource(allLinks);
  return index;
});

LibraryNote projectNote(Note n) => (
  id: n.id,
  projectId: n.projectId,
  title: n.title,
  text: n.displayText,
  concepts: n.concepts,
  groupId: n.groupId,
  topic: n.cluster,
  createdAt: n.createdAt,
);

typedef _IndexInput = ({LibraryNotes notes, List<LibraryLink> links, List<LibraryGroup> groups});
LinksIndex _deriveIndex(_IndexInput input) => deriveLinksIndex(input.notes, input.links, input.groups);

class _LinksLibraryRequestedSegment extends Notifier<int?> {
  @override
  int? build() => null;

  void request(int segment) => state = segment;
  void clear() => state = null;
}

/// One-shot segment request (e.g. from Notes action strip to open Suggestions).
final linksLibraryRequestedSegmentProvider = NotifierProvider<_LinksLibraryRequestedSegment, int?>(
  _LinksLibraryRequestedSegment.new,
);
