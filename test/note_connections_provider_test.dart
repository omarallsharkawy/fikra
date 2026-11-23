import 'package:fikra/app/providers.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/features/connections/links_index.dart';
import 'package:fikra/features/connections/links_library_provider.dart';
import 'package:fikra/features/connections/note_connections_provider.dart';
import 'package:flutter/foundation.dart';
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
    // Closing the first pushed page while the library listener (`shared`) stays
    // active keeps the project's adjacency warm for the next pushed page.
    first.close();
    await container.pump();
    final second = container.listen(noteConnectionsProvider('n1'), (_, _) {});
    addTearDown(second.close);
    await container.pump();
    expect(container.read(noteConnectionsProvider('n1')).requireValue.confirmed.single.other.id, 'n0');
    expect(container.read(connectionsIndexProvider('p')).requireValue, same(before));
    expect(derivations, 1);
  });

  test('inactive project adjacency is disposed while the selected project stays warm', () async {
    final date = DateTime(2026);
    final data = largeLibraryData();
    final notes = [
      for (final project in ['p', 'other'])
        for (final note in data.notes.take(2))
          Note(
            id: note.id,
            projectId: project,
            title: note.title,
            originalText: 'A body retained only while this project is listened to',
            source: NoteSource.text,
            status: ProcessingStatus.ready,
            rewrite: RewriteStatus.none,
            imagePaths: '[]',
            concepts: '[]',
            createdAt: date,
            updatedAt: date,
          ),
    ];
    final container = ProviderContainer(
      overrides: [
        for (final project in ['p', 'other']) ...[
          notesOfProjectProvider(project)
              .overrideWith((ref) => Stream.value(notes.where((n) => n.projectId == project).toList())),
          linksOfProjectProvider(project).overrideWith(
            (ref) => Stream.value([
              NoteLink(
                id: 'link',
                projectId: project,
                sourceId: notes[0].id,
                targetId: notes[1].id,
                label: '',
                origin: LinkOrigin.user,
                dismissed: false,
                strength: 1,
                createdAt: date,
              ),
            ]),
          ),
        ],
      ],
    );
    addTearDown(container.dispose);
    final previous = container.listen(connectionsIndexProvider('p'), (_, _) {});
    addTearDown(previous.close);
    final before = await container.read(connectionsIndexProvider('p').future);
    expect(before[notes[0].id]!.single.other.originalText, contains('retained'));

    final selected = container.listen(connectionsIndexProvider('other'), (_, _) {});
    addTearDown(selected.close);
    final current = await container.read(connectionsIndexProvider('other').future);
    previous.close();
    await container.pump();
    expect(container.read(connectionsIndexProvider('p').exists), isFalse);
    expect(container.read(connectionsIndexProvider('other')).requireValue, same(current));

    final reopened = container.listen(connectionsIndexProvider('p'), (_, _) {});
    addTearDown(reopened.close);
    final after = await container.read(connectionsIndexProvider('p').future);
    expect(after, isNot(same(before)), reason: 'revisiting derives a new snapshot instead of retaining the old one');
    expect(after[notes[0].id]!.single.other.id, notes[1].id);
    reopened.close();
    selected.close();
    await container.pump();
    expect(container.read(connectionsIndexProvider('p').exists), isFalse);
    expect(container.read(connectionsIndexProvider('other').exists), isFalse);
  });

  test('switching from project A to project B disposes project A connections index when unlistened', () async {
    final date = DateTime(2026);
    final disposed = <Object>[];
    final current = ValueNotifier(Project(id: 'a', name: 'A', createdAt: date));
    addTearDown(current.dispose);
    final container = ProviderContainer(
      observers: [_DisposeRecorder(disposed)],
      overrides: [
        selectedProjectProvider.overrideWith((ref) => current.value),
        notesOfProjectProvider('a').overrideWith((ref) => Stream.value(const <Note>[])),
        linksOfProjectProvider('a').overrideWith((ref) => Stream.value(const <NoteLink>[])),
        notesOfProjectProvider('b').overrideWith((ref) => Stream.value(const <Note>[])),
        linksOfProjectProvider('b').overrideWith((ref) => Stream.value(const <NoteLink>[])),
      ],
    );
    addTearDown(container.dispose);

    final subA = container.listen(connectionsIndexProvider('a'), (_, _) {});
    await container.read(connectionsIndexProvider('a').future);
    await container.pump();
    disposed.clear();

    // Leave project A for project B; while subA is still open, A is not disposed.
    current.value = Project(id: 'b', name: 'B', createdAt: date);
    container.invalidate(selectedProjectProvider);
    final subB = container.listen(connectionsIndexProvider('b'), (_, _) {});
    addTearDown(subB.close);
    await container.read(connectionsIndexProvider('b').future);
    await container.pump();
    expect(disposed, isNot(contains(connectionsIndexProvider('a'))));

    // Dropping project A's last listener disposes A's index while B stays alive.
    disposed.clear();
    subA.close();
    await container.pump();

    expect(disposed, contains(connectionsIndexProvider('a')));
    expect(disposed, isNot(contains(connectionsIndexProvider('b'))));
  });
}

final class _DisposeRecorder extends ProviderObserver {
  _DisposeRecorder(this.disposed);
  final List<Object> disposed;

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    disposed.add(context.provider);
  }
}
