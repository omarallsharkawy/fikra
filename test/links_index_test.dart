import 'package:fikra/features/connections/links_index.dart';
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
}
