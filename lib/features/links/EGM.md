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
  - Library file. Holds the imports and `_LinksScreenState`: graph and viewport fields, `dispose`, the `_setState` forwarder for the part-file extensions, and `build` (error, loading, empty and graph states, the zoom tools row, the no-links banner, and the selected-node preview). Everything else is in the `part` files below, which see its private members.
- `links_graph_data.dart` (part): `extension _LinksGraphData on _LinksScreenState` with `_setProject`, `_updateGraph`, `_acceptLayout`, `_computePending`.
- `links_viewport.dart` (part): `extension _LinksViewport on _LinksScreenState` with `_home` (initial transform), `_zoom`, and `_graphCanvas`, the `LayoutBuilder` + `InteractiveViewer` canvas that fits the view once per project, canvas width and viewport width.
- `links_navigation.dart` (part): `extension _LinksNavigation on _LinksScreenState` with `_openNote`, `_showCluster`, `_showMoreClusters`.
- `graph_nodes.dart` (part): `_Node`, `_OverflowNode`, `_NodePreview`, and the helpers `_rect` and `_graphTitle`.
- `edges_painter.dart` (part): `_EdgesPainter`, the link curves.
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
