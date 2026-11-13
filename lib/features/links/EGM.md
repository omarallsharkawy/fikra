# Links

## Overview

The knowledge graph tab, mounted at `/links` by `lib/app/router.dart`. Each cluster is a row, notes are nodes, and links are curves. Layout is a pure computation that can run off the UI thread for large projects.

## Interface

- `graph_layout.dart`
  - Typedefs `GraphNote`, `GraphLink`, and `GraphPosition`: record projections. `GraphLink` includes row `id` and `isUser` for options and source styling. `GraphLayout.edges` contains the cached pure cubic geometry.
  - `GraphInput(notes, links, {rtl = true, generalLabel = ''})`: fields `notes`, `links`, `rtl`, `generalLabel`, `signature`; method `sameData(GraphInput other)`.
  - `GraphRow`: fields `cluster`, `notes`, `visible`, `index`; getter `hiddenCount`.
  - `GraphLayout`: constants `nodeWidth`, `nodeHeight`, `gapX`, `rowHeight`, `padding`, `smallProjectLimit` (60); fields `rows`, `hiddenRows`, `nodes`, `positions`, `links`, `readyCount`, `width`, `height`; method `positionInRow(int row, int column)`.
  - `GraphLayout.fromInput(GraphInput)`: static callback for Flutter's `compute`.
  - `GraphLayout.compute(notes, links, {rtl = true, generalLabel = '', maxNodesPerRow = 12, maxNodes = 240, maxRows = 20, maxEdges = 1000, preserveSmallProjectsUpTo = smallProjectLimit})`.
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

- `graph_layout.dart` imports only `dart:math` and the pure shared `link_pairs.dart`, so it stays isolate-safe. Its `graph_geometry.dart` part assigns ports and builds flattened curves with no Flutter objects. Its projections never carry note bodies or attachments.
- `GraphNote.status` is `ProcessingStatus.index`, and `compute` hard-codes `status == 1` as ready. Reordering `ProcessingStatus` in `lib/data/local/database.dart` breaks the graph.
- Only ready notes are placed. A note with a null cluster goes into the supplied localized fallback cluster.
- Clusters are ordered by descending size.
- When `notes.length <= preserveSmallProjectsUpTo` (counting every status), every ready note and every unique note pair between them is kept, in ascending `createdAt` order within a row.
- Above that size, each row is ordered by link degree descending, then `createdAt` descending, then `id` ascending. Rows respect `maxNodesPerRow`, `maxNodes`, and `maxRows`; a cluster with no remaining capacity moves to `hiddenRows`; only the `maxEdges` strongest links are kept.
- `GraphLayout.positions` holds visible notes only. The first note of each row and the initial view start at the reading start (right for RTL, left for LTR).
- `GraphInput.sameData` compares records after comparing hashes, so a hash collision cannot hide an edit.
- `_updateGraph` runs when a source list identity, direction, or general-group label changes, and keeps the current layout when the projection is unchanged.
- Layout runs in an isolate when there are more than 300 notes, or more than `smallProjectLimit` notes and more than 600 links. Otherwise it runs synchronously.
- At most one worker runs at a time, and `_pending` holds only the latest input. A result is installed only when its input is still `identical` to `_input`.
- `_setProject` clears the cached sources, inputs, layout, error flag, selection, and viewport fit when the project changes.
- The selection is cleared when a new layout no longer contains the selected node.
- The graph shows its empty state when `readyCount < 2`.
- InteractiveViewer pinch zoom is limited to 0.5..2.5. The pre-existing zoom-button formula uses `getMaxScaleOnAxis` (including Z), which can overstate XY scale below 1; phase 4 leaves button behavior unchanged. Line tolerance uses actual XY scale independently.
- Zoom buttons anchor at the current `InteractiveViewer` viewport centre measured by its `LayoutBuilder`, not the entire screen. Height-only resizing refreshes this size without resetting the reading-start transform.
- The canvas sits in a `RepaintBoundary`, so panning and zooming do not repaint nodes and edges.

## Side Effects

- Spawns a background isolate through Flutter's `compute` (debug label `links-layout`) for large graphs.
- Line taps and selected-card semantic actions open shared `showLinkOptions`: edit reason / confirmed removal for user links, accept / reject for suggestions through `LinksRepository`. Other graph interactions write no application data.
- Pushes `/note/<id>`, passing the full `Note` as `extra` when the graph still holds it; navigates to `/add` from the empty state.
- Invalidates `selectedNotesProvider` and `selectedLinksProvider` on retry.

## Localization

Localized counts, node metadata, fallback titles, accessibility text and group controls use `context.l10n`. UI passes a localized general-group label and direction into the pure graph computation; stored group names and link reasons remain unchanged.

## Verification

- Run: `flutter analyze && flutter test`
- `test/graph_layout_test.dart` imports `graph_layout.dart` directly.

Graph nodes, selected previews, link reasons and cluster sheets all resolve titles through shared `noteTitleText`, the same fallback used by note cards/details. `phone_regressions_test.dart` covers blank node text and viewport-centred zoom in both directions, including height-only resize.

## Connectors (links phase 4)

- `shared/link_pairs.dart` selects one row per unordered pair, preferring the first user row over suggestions; self links are dropped. Graph filtering and degree ranking retain the existing node positions and limits. Deduplication precedes edge capping.
- `graph_geometry.dart` (part of the pure layout library): `GraphPoint`, `GraphEdge`, `buildGraphEdges`, `hitTestGraphEdge`. Top/bottom ports are assigned separately per card border. Top-edge left arcs, incoming row connectors and right arcs occupy consecutive sectors, sorted by the other card's logical x, then y/id. Distribute across at most 12 slots with 18 dp corner insets (additional edges share slots); mirror only after ranking. Between rows the upper card's bottom connects to the lower card's top with vertical cubic tangents; same-row top ports use a span-dependent rise `18 + 24 * span / (1 + span)` dp, approaching 42 dp without reaching the preceding row. Nested spans have distinct heights.
- `GraphEdge` caches a flattened polyline (at most 0.2 logical-pixel error, subdivision depth capped at 12) and control-hull bounds. Completed taps only: reject card/overflow interiors, prefilter edge bounds, then compare point-to-segment distances and choose the nearest within `24 / actualXYScale`. Cost O(cards + edges + candidate segments); pan/pinch updates do no edge hit testing.
- `graph_edge_paths.dart`: `GraphEdgePaths` / `CachedGraphEdge` retain `GraphEdgeInk` by id, style and four cubic points across accepted layouts. A wrapper carries current metadata, so renames/reason edits update the graph without rebuilding unchanged ink. Only changed shapes/styles build a cubic Path and packed Float32 dash-segment buffer; no path metrics or per-dash Paths. Suggestions draw one `drawRawPoints(PointMode.lines)` buffer per edge. The cache holds only the current capped layout. `rebuiltEdges` and `sameInk` support regression checks; `shouldRepaint` compares actual ink identities, dimmed-edge set and palette colours. A dedicated `graph-edges-layer` RepaintBoundary isolates card press animation from edge painting.
- User links are solid accent, width 2; suggestions are dashed (5 dp dash / 5 dp gap), graphEdge at 0.55 alpha, width 1.2. Each endpoint has a filled 3 dp dot. Selection preserves the selected note and its direct neighbours, but only incident edges stay bright; every other edge uses 0.16 alpha. Other cards, overflow controls and row labels use opaque muted colours composited from existing textMeta/screen tokens; card text contrast stays at least 3:1 in both themes, with no per-card Opacity layer. `graph_capsules.dart` places selected nonblank incident capsules only. It tries the midpoint and nearby curve parameters, narrows from 160 down to 72 dp, and omits a capsule if it still overlaps an inflated card, overflow, measured single-line row label or previous capsule. Text measurements include system scaling, ellipsis, padding and border. Row labels are bounded at 320 dp with ellipsis; capsules ignore pointers and add no shape semantics.
- Accessibility: the selected card merges one named custom semantics action per linked note, each opening the same options sheet. Existing localized `linkOptionsA11y` supplies the action names; repeated titles receive numeric suffixes so Flutter cannot collapse equal-labelled actions. Painted edges and capsules add no shape semantics. Focus changes are immediate; existing sheet, press and preview motion continues to respect reduced motion.
- Existing keys stay unchanged. Added `graph-edges`, `graph-focus-<noteId>` and `graph-reason-<linkId>` for verification. Geometry/path tests allow 750 ms each for a cold host build of 240 nodes / 1000 edges; these are regression guards, not Android frame budgets.
- Verification: `test/graph_geometry_test.dart`, `test/graph_connectors_test.dart`, updated `test/graph_layout_test.dart`, screenshots `42_graph_connectors` / `43_graph_focus` in Arabic/English and dark/light. Real-device frame/memory comparison still uses `integration_test/stress_test.dart` and `docs/scalability.md`.

## Phase 4 review corrections

- `GraphLayout.linkCount` counts valid project pairs using the shared user-preference rule, before visibility/edge capping, excluding self/missing pairs. The header consumes this instead of raw repository rows.
- `_openLink` resolves the row by id first; if analysis replaced it while geometry was pending, it resolves the same unordered pair from live rows with user preference. Dismissed rows never open.
- `graph-focus-<noteId>` remains but is now a KeyedSubtree. `graph-cluster-<rowIndex>` and `graph-edges-layer` were added. The former `CachedGraphEdge.dashed` Path is replaced by `dashPoints`; public GraphEdgeInk contains reusable drawing data. `GraphLayout` also exposes `linkCount`, and `GraphEdge.pointAt` supports capsule placement.
- `test/graph_review_test.dart` covers contrast, row/overflow fading, press repaint isolation, stale id fallback, header count, rename refresh/cache reuse, RTL tapping, preview interception, overflow sheets and long-heading collision bounds. Geometry tests cover the reported crossing, nested heights, 30-edge slot sharing, collision placement, pre-cap counting, and 240/1000 full/single-change cache budgets. The screen-space tap regression uses the real zoom-out button (XY 0.8, Z 1); the existing button-scale issue remains unchanged.
