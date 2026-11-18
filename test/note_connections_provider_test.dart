import 'package:fikra/app/providers.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/features/connections/links_index.dart';
import 'package:fikra/features/connections/links_library_provider.dart';
import 'package:fikra/features/connections/note_connections_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/links_library_data.dart';

void main() {
  test('two note opens share one adjacency derivation per source revision', () async {
    final date = DateTime(2026);
    final notes = [
      for (var i = 0; i < 5000; i++)
        Note(
          id: 'n$i',
          projectId: 'p',
          title: 'Note $i',
          originalText: '',
          source: NoteSource.text,
          status: ProcessingStatus.ready,
          rewrite: RewriteStatus.none,
          imagePaths: '[]',
          concepts: '[]',
          createdAt: date,
          updatedAt: date,
        ),
    ];
    final links = [
      NoteLink(
        id: 'l',
        projectId: 'p',
        sourceId: 'n0',
        targetId: 'n1',
        label: '',
        origin: LinkOrigin.user,
        dismissed: false,
        strength: 1,
        createdAt: date,
      ),
    ];
    final data = largeLibraryData();
    final index = deriveLinks('p', data.notes, data.links, data.groups);
    var derivations = 0;
    final container = ProviderContainer(
      overrides: [
        selectedProjectProvider.overrideWith((ref) => Project(id: 'p', name: 'P', createdAt: date)),
        notesOfProjectProvider('p').overrideWith((ref) => Stream.value(notes)),
        linksOfProjectProvider('p').overrideWith((ref) => Stream.value(links)),
        linksLibraryProvider('p').overrideWith((ref) => index),
      ],
    );
    addTearDown(container.dispose);
    final shared = container.listen(connectionsIndexProvider('p'), (_, next) {
      if (next.hasValue) derivations++;
    });
    addTearDown(shared.close);
    final first = container.listen(noteConnectionsProvider('n0'), (_, _) {});
    addTearDown(first.close);
    await container.read(notesOfProjectProvider('p').future);
    await container.read(linksOfProjectProvider('p').future);
    await container.read(linksLibraryProvider('p').future);
    await container.read(connectionsIndexProvider('p').future);
    await container.pump();
    final before = container.read(connectionsIndexProvider('p')).requireValue;
    expect(container.read(noteConnectionsProvider('n0')).requireValue.confirmed.single.other.id, 'n1');
    first.close();
    shared.close();
    await container.pump();
    final second = container.listen(noteConnectionsProvider('n1'), (_, _) {});
    addTearDown(second.close);
    await container.pump();
    expect(container.read(noteConnectionsProvider('n1')).requireValue.confirmed.single.other.id, 'n0');
    expect(container.read(connectionsIndexProvider('p')).requireValue, same(before));
    expect(derivations, 1);
  });
}
