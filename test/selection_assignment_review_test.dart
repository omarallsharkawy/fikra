import 'package:fikra/app/providers.dart';
import 'package:fikra/core/widgets/fikra_widgets.dart';
import 'package:fikra/data/groups_repository.dart';
import 'package:fikra/data/local/database.dart';
import 'package:fikra/features/shared/selection_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';
import 'support/selection_fixture.dart';

void main() {
  fikraTest('fresh assignment snapshot is not filtered by a stale project provider', locale: const Locale('en'), (
    t,
    db,
  ) async {
    phone(t);
    final (p, _, notes) = await seedNotes(t, db, ['A', 'B'], l10n: enL10n);
    final group = await pumpFuture(t, () => LocalGroupsRepository(db).create(p.id, 'Target'));
    final fresh = await pumpFuture(t, () => refreshed(db));
    await host(
      t,
      Consumer(
        builder: (context, ref, _) {
          final stale = ref.watch(notesOfProjectProvider(p.id));
          return FikraButton(
            key: ValueKey(stale.hasValue ? 'stale-ready' : 'stale-loading'),
            label: 'Assign',
            onPressed: () async {
              final guard = ref.read(selectionBusyProvider.notifier);
              if (!guard.claim()) return;
              try {
                await assignSelectionGroup(
                  context,
                  ref,
                  projectId: p.id,
                  notes: fresh.where((n) => n.projectId == p.id).toList(),
                  target: group,
                  freshlyRead: true,
                );
              } finally {
                guard.release();
              }
            },
          );
        },
      ),
      locale: const Locale('en'),
      overrides: [
        databaseProvider.overrideWithValue(db),
        notesOfProjectProvider(p.id).overrideWith((ref) => Stream.value(const <Note>[])),
      ],
    );
    await settle(t, find.byKey(const ValueKey('stale-ready')));
    await t.tap(find.text('Assign'));
    await pumpAnimations(t);
    expect((await readNote(t, db, notes.first.id)).groupId, group.id);
    expect((await readNote(t, db, notes.last.id)).groupId, group.id);
    await t.tap(find.text(enL10n.undo));
    await pumpAnimations(t);
    expect((await readNote(t, db, notes.first.id)).groupId, isNull);
    expect((await allGroups(t, db)).single.id, group.id);
  });
}

Future<List<Note>> refreshed(FikraDatabase db) => db.select(db.notes).get();
