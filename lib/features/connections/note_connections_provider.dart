import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../app/providers.dart';
import '../../data/local/database.dart';
import '../shared/note_links.dart';
import 'links_index.dart';
import 'links_library_provider.dart';

typedef NoteConnections = ({List<NoteLinkEntry> confirmed, List<SuggestionEntry> suggestions});

/// Shared by every pushed page; mapping and adjacency happen once per emission.
final connectionsIndexProvider = FutureProvider.family<Map<String, List<NoteLinkEntry>>, String>((
  ref,
  projectId,
) async {
  final notes = ref.watch(notesOfProjectProvider(projectId));
  final links = ref.watch(linksOfProjectProvider(projectId));
  final notesFuture = ref.watch(notesOfProjectProvider(projectId).future);
  final linksFuture = ref.watch(linksOfProjectProvider(projectId).future);
  final loaded = await Future.wait<Object>([
    notes.hasValue ? Future.value(notes.requireValue) : notesFuture,
    links.hasValue ? Future.value(links.requireValue) : linksFuture,
  ]);
  final input = (projectId: projectId, notes: loaded[0] as List<Note>, links: loaded[1] as List<NoteLink>);
  return input.notes.length >= 1000
      ? compute(_deriveConnections, input, debugLabel: 'note-connections-adjacency')
      : _deriveConnections(input);
});

typedef _ConnectionsInput = ({String projectId, List<Note> notes, List<NoteLink> links});

Map<String, List<NoteLinkEntry>> _deriveConnections(_ConnectionsInput input) {
  final byId = {
    for (final n in input.notes)
      if (n.projectId == input.projectId) n.id: n,
  };
  final adjacency = <String, List<NoteLink>>{};
  for (final l in input.links) {
    if (l.projectId != input.projectId || l.dismissed || l.origin != LinkOrigin.user) continue;
    (adjacency[l.sourceId] ??= []).add(l);
    (adjacency[l.targetId] ??= []).add(l);
  }
  return {for (final e in adjacency.entries) e.key: linksOfNote(e.key, e.value, byId)};
}

/// Opening another note only looks up its adjacency, never scans the project.
final noteConnectionsProvider = Provider.autoDispose.family<AsyncValue<NoteConnections>, String>((ref, noteId) {
  final projectId = ref.watch(selectedProjectProvider)?.id;
  if (projectId == null) return const AsyncLoading();
  final confirmedIndex = ref.watch(connectionsIndexProvider(projectId));
  final library = ref.watch(linksLibraryProvider(projectId));
  if (confirmedIndex.hasError) return AsyncError(confirmedIndex.error!, confirmedIndex.stackTrace!);
  if (library.hasError) return AsyncError(library.error!, library.stackTrace!);
  if (!confirmedIndex.hasValue || !library.hasValue) return const AsyncLoading();
  final confirmed = confirmedIndex.requireValue[noteId] ?? const <NoteLinkEntry>[];
  final linked = {for (final e in confirmed) e.other.id};
  return AsyncData((
    confirmed: confirmed,
    // Raw links can lead the isolate snapshot. Never show a confirmed pair twice.
    suggestions: [
      for (final s in library.requireValue.suggestionsByNote[noteId] ?? const <SuggestionEntry>[])
        if (!linked.contains(s.a.id == noteId ? s.b.id : s.a.id)) s,
    ],
  ));
});
