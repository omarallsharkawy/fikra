# Links

## Overview

The knowledge graph tab, mounted at `/links` by `lib/app/router.dart`. Each cluster is a row, notes are nodes, and links are curves. Layout is a pure computation that can run off the UI thread for large projects.

## Interface

- `graph_layout.dart`
  - Typedefs `GraphNote`, `GraphLink`, and `GraphPosition`: record projections.
  - `GraphInput(notes, links)`: fields `notes`, `links`, `signature`; method `sameData(GraphInput other)`.
  - `GraphRow`: fields `cluster`, `notes`, `visible`, `index`; getter `hiddenCount`.
  - `GraphLayout`: constants `nodeWidth`, `nodeHeight`, `gapX`, `rowHeight`, `padding`, `smallProjectLimit` (60); fields `rows`, `hiddenRows`, `nodes`, `positions`, `links`, `readyCount`, `width`, `height`; method `positionInRow(int row, int column)`.
  - `GraphLayout.fromInput(GraphInput)`: static callback for Flutter's `compute`.
  - `GraphLayout.compute(notes, links, {maxNodesPerRow = 12, maxNodes = 240, maxRows = 20, maxEdges = 1000, preserveSmallProjectsUpTo = smallProjectLimit})`.
- `links_screen.dart`
  - `LinksScreen`: `ConsumerStatefulWidget` with no parameters.
- Consumes `selectedNotesProvider`, `selectedLinksProvider`, and `selectedProjectProvider` from `lib/app/providers.dart`, plus `ProjectHeader` from [projects](../projects/EGM.md).

## Invariants

- `graph_layout.dart` imports only `dart:math`, so it stays isolate-safe. Its projections never carry note bodies or attachments.
- `GraphNote.status` is `ProcessingStatus.index`, and `compute` hard-codes `status == 1` as ready. Reordering `ProcessingStatus` in `lib/data/local/database.dart` breaks the graph.
- Only ready notes are placed. A note with a null cluster goes into one fixed fallback cluster.
- Clusters are ordered by descending size.
- When `notes.length <= preserveSmallProjectsUpTo` (counting every status), every ready note and every link between them is kept, in ascending `createdAt` order within a row.
- Above that size, each row is ordered by link degree descending, then `createdAt` descending, then `id` ascending. Rows respect `maxNodesPerRow`, `maxNodes`, and `maxRows`; a cluster with no remaining capacity moves to `hiddenRows`; only the `maxEdges` strongest links are kept.
- `GraphLayout.positions` holds visible notes only. The first note of each row is on the right, and the initial view starts at the canvas's right edge.
- `GraphInput.sameData` compares records after comparing hashes, so a hash collision cannot hide an edit.
- `_updateGraph` runs only when a source list's identity changes, and keeps the current layout when the projection is unchanged.
- Layout runs in an isolate when there are more than 300 notes, or more than `smallProjectLimit` notes and more than 600 links. Otherwise it runs synchronously.
- At most one worker runs at a time, and `_pending` holds only the latest input. A result is installed only when its input is still `identical` to `_input`.
- `_setProject` clears the cached sources, inputs, layout, error flag, selection, and viewport fit when the project changes.
- The selection is cleared when a new layout no longer contains the selected node.
- The graph shows its empty state when `readyCount < 2`.
- Zoom is limited to 0.5..2.5.
- The canvas sits in a `RepaintBoundary`, so panning and zooming do not repaint nodes and edges.

## Side Effects

- Spawns a background isolate through Flutter's `compute` (debug label `links-layout`) for large graphs.
- Writes no application data.
- Pushes `/note/<id>`, passing the full `Note` as `extra` when the graph still holds it; navigates to `/add` from the empty state.
- Invalidates `selectedNotesProvider` and `selectedLinksProvider` on retry.

## Verification

- Run: `flutter analyze && flutter test`
- `test/graph_layout_test.dart` imports `graph_layout.dart` directly.
