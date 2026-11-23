import 'package:fikra/features/connections/links_index.dart';

LibraryNote libraryNote(
  String id, {
  String project = 'p',
  String? group,
  String? topic = 'Ideas',
  String? title,
  String? text,
  String concepts = '',
  int day = 1,
}) => (
  id: id,
  projectId: project,
  groupId: group,
  topic: topic,
  title: title ?? id,
  text: text ?? 'Body $id',
  concepts: concepts,
  createdAt: DateTime(2026, 11, day),
);

LibraryLink libraryLink(
  String id,
  String a,
  String b, {
  bool confirmed = true,
  bool dismissed = false,
  double strength = .5,
  int day = 1,
  String project = 'p',
}) => (
  id: id,
  projectId: project,
  sourceId: a,
  targetId: b,
  reason: 'Shared idea',
  confirmed: confirmed,
  dismissed: dismissed,
  strength: strength,
  createdAt: DateTime(2026, 11, day),
);

/// Same 5,000-note scale as the phone stress seed: one confirmed chain edge and
/// one AI suggestion per note. Projection creation is outside the timed region.
({List<LibraryNote> notes, List<LibraryLink> links, List<LibraryGroup> groups}) largeLibraryData() => (
  notes: [
    for (var i = 0; i < 5000; i++)
      libraryNote('n$i', day: 1 + i % 28, group: i % 3 == 0 ? 'g${i % 5}' : null, topic: 'Topic ${i % 8}'),
  ],
  links: [
    for (var i = 1; i < 5000; i++) ...[
      libraryLink('u$i', 'n$i', 'n${i - 1}'),
      libraryLink('a$i', 'n$i', 'n${(i + 37) % 5000}', confirmed: false, strength: (i % 10) / 10),
    ],
  ],
  groups: [for (var i = 0; i < 5; i++) (id: 'g$i', projectId: 'p', parentId: null)],
);

/// Shared with the direct Dart diagnostic when Flutter's host cannot run.
/// Times both halves cold, then the links half alone as a link write re-runs
/// it (median of five, after the notes half is cached), and one search.
({LinksIndex index, int microseconds, int notesUs, int linksUs, int relinkUs, int searchUs}) measureLargeLibrary() {
  final data = largeLibraryData();
  final timer = Stopwatch()..start();
  final notes = deriveLibraryNotes((projectId: 'p', notes: data.notes));
  final notesUs = timer.elapsedMicroseconds;
  final index = deriveLinksIndex(notes, data.links, data.groups);
  final total = timer.elapsedMicroseconds;
  final relinks = <int>[];
  for (var i = 0; i < 5; i++) {
    // A link write emits a new list with one pair confirmed.
    final links = [
      for (final l in data.links)
        l.id == 'a${i + 1}'
            ? (
                id: l.id,
                projectId: l.projectId,
                sourceId: l.sourceId,
                targetId: l.targetId,
                reason: l.reason,
                confirmed: true,
                dismissed: false,
                strength: l.strength,
                createdAt: l.createdAt,
              )
            : l,
    ];
    timer.reset();
    deriveLinksIndex(notes, links, data.groups);
    relinks.add(timer.elapsedMicroseconds);
  }
  relinks.sort();
  timer.reset();
  index.filter(search: 'body n12', sort: LinksSort.mostLinks);
  return (
    index: index,
    microseconds: total,
    notesUs: notesUs,
    linksUs: total - notesUs,
    relinkUs: relinks[2],
    searchUs: timer.elapsedMicroseconds,
  );
}
