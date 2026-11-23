import 'package:fikra/app/providers.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/features/connections/links_index.dart';
import 'package:fikra/features/connections/links_library_provider.dart';
import 'package:fikra/features/shared/note_groups.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/links_library_data.dart';

void main() {
  test('confirmed rows win reverse suggestions; dismissed, self, missing and foreign rows are skipped', () {
    final index = deriveLinks(
      'p',
      [libraryNote('a'), libraryNote('b'), libraryNote('c'), libraryNote('foreign', project: 'q')],
      [
        libraryLink('ai', 'b', 'a', confirmed: false),
        libraryLink('user', 'a', 'b'),
        libraryLink('dismissed', 'a', 'c', confirmed: false, dismissed: true),
        libraryLink('foreign-note', 'a', 'foreign'),
        libraryLink('foreign-link', 'a', 'c', project: 'q'),
        libraryLink('self', 'a', 'a'),
        libraryLink('missing', 'a', 'gone'),
      ],
      [],
    );
    expect(index.browse.map((e) => e.note.id), ['a', 'b']);
    expect(index.browse.every((e) => e.others.length == 1), isTrue);
    expect(index.suggestions, isEmpty);
  });

  test('counts are distinct linked notes, parents include children, topics exclude grouped notes', () {
    final index = deriveLinks(
      'p',
      [
        libraryNote('a', group: 'parent'),
        libraryNote('b', group: 'child'),
        libraryNote('c', topic: ' Topic '),
        libraryNote('d', topic: 'Topic'),
        libraryNote('unlinked', topic: 'Unused'),
      ],
      [libraryLink('ab', 'a', 'b'), libraryLink('ac', 'a', 'c'), libraryLink('cd', 'c', 'd')],
      [(id: 'parent', projectId: 'p', parentId: null), (id: 'child', projectId: 'p', parentId: 'parent')],
    );
    expect(index.groupCounts, {'parent': 2, 'child': 1});
    expect(index.topicCounts, {'Topic': 2});
    expect(index.filter(chip: (group: 'parent', topic: null)).browse.map((e) => e.note.id), ['a', 'b']);
    expect(index.filter(chip: (group: 'child', topic: null)).browse.single.note.id, 'b');
    expect(index.filter(chip: (group: null, topic: 'Topic')).browse.map((e) => e.note.id), ['c', 'd']);
  });

  test('sorts, trimmed case-insensitive title/body/concept search and memoized combined filters', () {
    final index = deriveLinks(
      'p',
      [
        libraryNote('a', day: 1, title: 'Flutter', group: 'g'),
        libraryNote('b', day: 2, text: 'FLUTTER body'),
        libraryNote('c', day: 3, concepts: 'Flutter'),
      ],
      [libraryLink('ab', 'a', 'b'), libraryLink('ac', 'a', 'c')],
      [(id: 'g', projectId: 'p', parentId: null)],
    );
    expect(index.filter().browse.map((e) => e.note.id), ['c', 'b', 'a']);
    expect(index.filter(sort: LinksSort.oldest).browse.map((e) => e.note.id), ['a', 'b', 'c']);
    expect(index.filter(sort: LinksSort.mostLinks).browse.map((e) => e.note.id), ['a', 'c', 'b']);
    expect(index.filter(search: ' flutter ').browse.length, 3);
    expect(index.filter(search: 'flutter', chip: (group: 'g', topic: null)).browse.single.note.id, 'a');
    expect(identical(index.filter(search: 'FLUTTER'), index.filter(search: 'flutter')), isTrue);
  });

  test('suggestions are unordered pairs, strongest then newest; either endpoint matches search and chip', () {
    final index = deriveLinks(
      'p',
      [libraryNote('a', group: 'g'), libraryNote('b'), libraryNote('c')],
      [
        libraryLink('old', 'a', 'b', confirmed: false, strength: .8),
        libraryLink('reverse', 'b', 'a', confirmed: false, strength: 1),
        libraryLink('new', 'a', 'c', confirmed: false, strength: .8, day: 2),
        libraryLink('strong', 'b', 'c', confirmed: false, strength: .9),
      ],
      [(id: 'g', projectId: 'p', parentId: null)],
    );
    expect(index.suggestions.map((e) => e.link.id), ['strong', 'new', 'old']);
    expect(index.filter(search: 'Body a', chip: (group: 'g', topic: null)).suggestions.map((e) => e.link.id), [
      'new',
      'old',
    ]);
    expect(index.filter(search: 'Body b', chip: (group: 'g', topic: null)).suggestions, isEmpty);
  });

  test('5,000-note derivation timer (host diagnostic, not a phone frame budget)', () {
    final diagnostic = measureLargeLibrary();
    final index = diagnostic.index;
    // ignore: avoid_print
    print(
      'FIKRA_LINKS_DERIVE_5000_US=${diagnostic.microseconds} '
      'notes=${diagnostic.notesUs} links=${diagnostic.linksUs} '
      'relink_median=${diagnostic.relinkUs} search=${diagnostic.searchUs}',
    );
    expect(index.browse.length, 5000);
    expect(index.suggestions.length, 4999);
    expect(diagnostic.microseconds / 1000, lessThan(1000));
    // A link write only re-runs the links half; it must stay well under the
    // cold derive that used to run on every accept/reject.
    expect(diagnostic.relinkUs, lessThan(diagnostic.microseconds));
  });

  test('group scan is O(G) across many empty and nested groups and keeps direct-child semantics', () {
    List<LibraryGroup> makeGroups(int count) => [
      for (var i = 0; i < count; i++) (id: 'g$i', projectId: 'p', parentId: i > 0 && i % 5 == 1 ? 'g${i - 1}' : null),
      // Grandchild and foreign-project groups should keep existing semantics.
      (id: 'grand', projectId: 'p', parentId: 'g1'),
      (id: 'foreign', projectId: 'other', parentId: 'g0'),
    ];

    final notes = deriveLibraryNotes((
      projectId: 'p',
      notes: [
        libraryNote('a', group: 'g0'),
        libraryNote('b', group: 'g1'),
        libraryNote('c', group: 'grand'),
      ],
    ));
    final links = [libraryLink('ab', 'a', 'b'), libraryLink('bc', 'b', 'c')];

    debugLinksIndexGroupOps = 0;
    final small = deriveLinksIndex(notes, links, makeGroups(100));
    final ops100 = debugLinksIndexGroupOps;

    debugLinksIndexGroupOps = 0;
    final large = deriveLinksIndex(notes, links, makeGroups(1000));
    final ops1000 = debugLinksIndexGroupOps;

    // Linear growth (~10x for 10x groups), never quadratic (~100x).
    expect(ops1000, lessThan(3 * 1005));
    expect(ops1000 / ops100, lessThan(15));

    // Exact behaviour: parent includes self + direct children only; foreign ignored.
    expect(small.groupIds['g0'], {'g0', 'g1'});
    expect(small.groupIds['g1'], {'g1', 'grand'});
    expect(small.groupIds.containsKey('foreign'), isFalse);
    expect(small.groupCounts['g0'], 2);
    expect(small.groupCounts['g1'], 2);
    expect(small.groupCounts['g2'], 0);
    expect(large.groupIds['g0'], {'g0', 'g1'});
    expect(large.groupCounts['g0'], 2);
  });

  test(
    'isolate threshold considers notes, edges and groups; dense <1000-note and small projects match deriveLinks',
    () async {
      expect(shouldIsolateLinksDerivation(notes: 20, links: 30, groups: 4), isFalse);
      expect(shouldIsolateLinksDerivation(notes: 300, links: 2000, groups: 5), isTrue);
      expect(shouldIsolateLinksDerivation(notes: 100, links: 50, groups: 1000), isTrue);
      expect(shouldIsolateLinksDerivation(notes: 800, links: 1200, groups: 50), isTrue);
      expect(shouldIsolateLinksDerivation(notes: 1000, links: 0, groups: 0), isTrue);

      final date = DateTime(2026, 11, 1);
      for (final (noteCount, edgeCount, groupCount, expectedIsolate) in [(20, 30, 4, false), (120, 1800, 10, true)]) {
        expect(shouldIsolateLinksDerivation(notes: noteCount, links: edgeCount, groups: groupCount), expectedIsolate);
        final dbNotes = [
          for (var i = 0; i < noteCount; i++)
            Note(
              id: 'n$i',
              projectId: 'p',
              title: 'Title $i',
              originalText: 'Body $i',
              source: NoteSource.text,
              status: ProcessingStatus.ready,
              rewrite: RewriteStatus.none,
              imagePaths: '[]',
              concepts: '[]',
              groupId: i < groupCount ? 'g$i' : null,
              createdAt: date.add(Duration(minutes: i)),
              updatedAt: date.add(Duration(minutes: i)),
            ),
        ];
        final dbLinks = [
          for (var i = 0; i < edgeCount; i++)
            NoteLink(
              id: 'l$i',
              projectId: 'p',
              sourceId: 'n${i % noteCount}',
              targetId: 'n${(i % noteCount + 1 + (i ~/ noteCount)) % noteCount}',
              label: '',
              origin: i.isEven ? LinkOrigin.user : LinkOrigin.ai,
              dismissed: false,
              strength: ((i % 9) + 1) / 10,
              createdAt: date.add(Duration(seconds: i)),
            ),
        ];
        final dbGroups = [
          for (var i = 0; i < groupCount; i++)
            NoteGroup(
              id: 'g$i',
              projectId: 'p',
              name: 'Group $i',
              parentId: i == 1 ? 'g0' : null,
              position: i,
              createdAt: date,
            ),
        ];

        final expected = deriveLinks(
          'p',
          [for (final n in dbNotes) projectNote(n)],
          [
            for (final l in dbLinks)
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
          [for (final g in dbGroups) (id: g.id, projectId: g.projectId, parentId: g.parentId)],
        );

        final container = ProviderContainer(
          overrides: [
            notesOfProjectProvider('p').overrideWith((ref) => Stream.value(dbNotes)),
            linksOfProjectProvider('p').overrideWith((ref) => Stream.value(dbLinks)),
            groupsOfProjectProvider('p').overrideWith((ref) => Stream.value(dbGroups)),
          ],
        );
        addTearDown(container.dispose);
        final sub = container.listen(linksLibraryProvider('p'), (_, _) {});
        addTearDown(sub.close);
        final actual = await container.read(linksLibraryProvider('p').future);

        expect(actual.browse.map((e) => e.note.id), expected.browse.map((e) => e.note.id));
        expect(actual.suggestions.map((e) => e.link.id), expected.suggestions.map((e) => e.link.id));
        expect(actual.groupCounts, expected.groupCounts);
        expect(actual.groupIds, expected.groupIds);
      }
    },
  );
}
