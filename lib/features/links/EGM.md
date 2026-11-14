# Links

## Overview

The knowledge graph tab, mounted at `/links` by `lib/app/router.dart`. User groups are nested frames, ungrouped analysis topics are rows, notes are nodes, and links are curves. With no groups, the legacy row geometry is retained. Layout is a pure computation that can run off the UI thread for large projects.

## Interface

- `graph_layout.dart`
  - Typedefs `GraphNote`, `GraphLink`, and `GraphPosition`: record projections. `GraphLink` includes row `id` and `isUser` for options and source styling. `GraphLayout.edges` contains the cached pure cubic geometry.
  - `GraphInput(notes, links, {rtl = true, generalLabel = '', groups = const [], memberships = const {}, headerExtent = 64})`: fields `notes`, `links`, `rtl`, `generalLabel`, `signature`; method `sameData(GraphInput other)`.
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
- Only ready notes are cards. Null/blank/whitespace topics share the localized general row. Grouped non-ready notes are counted and appear in +N overflow sheets.
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
- The graph shows its empty state when `readyCount < 2` and there are no groups; empty groups remain visible.
- InteractiveViewer pinch zoom is limited to 0.5..2.5. The pre-existing zoom-button formula uses `getMaxScaleOnAxis` (including Z), which can overstate XY scale below 1; phase 4 leaves button behavior unchanged. Line tolerance uses actual XY scale independently.
- Zoom buttons anchor at the current `InteractiveViewer` viewport centre measured by its `LayoutBuilder`, not the entire screen. Height-only resizing refreshes this size without resetting the reading-start transform.
- The canvas sits in a `RepaintBoundary`, so panning and zooming do not repaint nodes and edges.

## Side Effects

- Spawns a background isolate through Flutter's `compute` (debug label `links-layout`) for large graphs.
- Line taps and selected-card semantic actions open shared `showLinkOptions`: edit reason / confirmed removal for user links, accept / reject for suggestions through `LinksRepository`. Frame options reuse `showGroupOptions`; topic conversion and multi-selection reuse the shared group and selection writes described below.
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

## Group frames and graph selection (phase 5b)

- `graph_input.dart` is a pure part of `graph_layout.dart`: `GraphGroup` projections, `GraphFrame` (group, bounds, header, subtree count and note IDs), and the existing `GraphInput`. Group metadata, memberships and text-scaled header extent participate in the collision-safe memo comparison. All data remains isolate-sendable; existing worker thresholds and latest-input rules stay unchanged.
- `graph_frames_layout.dart` packs top-level groups in position/id order. Direct notes wrap into rows, then child frames are inset 24 dp after those rows. Empty groups keep a header. Width comes from card/child content, with a 240 dp header minimum; names never affect geometry. The logical result is mirrored once for RTL. Parent counts include children; counts include non-ready notes, represented explicitly by the final row’s +N card/sheet, while only ready notes receive cards.
- Above the small-project exception, 12 notes per row, 20 visible note rows, 240 cards and 1000 edges are shared across the entire graph. A final group row accounts for all remaining notes with its overflow card, including a zero-card row when the budget is exhausted. Empty frames/overflow-only rows do not consume the visible-note-row budget. Topic rows follow all frames under Suggested topics; fully hidden topics use the existing aggregate overflow sheet. Their topic sheets also offer conversion. Small projects retain the existing uncapped policy and chronology. Equal-sized topics also retain the legacy chronological tie order even when database streams arrive newest-first.
- `GraphRow` adds optional groupId, logical start, explicit label top and canMakeGroup; existing public fields and `positionInRow` remain. `GraphLayout` adds frames, suggestedTop and morePosition. No existing Keys/public names were removed or renamed. Added `links-content` keeps the canvas mounted while both the selection header and action bar change, including during a held pointer.
- `graph_frames.dart` builds named semantics containers and 48 dp options controls using group token colours on borders only. Focus mutes a frame's border/text only when no focused card lies in its subtree. Header height scales with system text size. Blank header taps are inert, including during focus. Same-row arcs have a dedicated lane below headers; `graph_capsules.dart` always blocks every frame header independently of caller obstacles. Painted edges ignore pointers so header controls remain reachable; header hit tests never open a line.
- Topic conversion reads the complete project's ungrouped notes with the raw topic, including hidden/non-ready notes, claims selectionBusyProvider before awaiting, creates one group, and calls shared assignSelectionGroup. The existing localized grouping toast and stale-safe Undo restore notes and delete only the still-empty created group. Blank/null topics use the fallback and offer no conversion. Options open one shared showGroupOptions sheet at a time.
- `graph_hold.dart` tracks raw pointers without joining the gesture arena. kLongPressTimeout starts a selection only within screen-space computeHitSlop; any second pointer cancels all pending holds, even when lifted before the deadline. Releasing a completed hold consumes its tap. The equivalent semantic long-press action remains available. InteractiveViewer pan/pinch and zoom buttons remain active in selection mode.
- `graph_selection.dart` wires SelectionHeader/SelectionActionBar to the four existing shared actions and guard. Selected cards show checked semantics and an explicit check icon. An open preview is removed immediately when selection starts (no outgoing preview transition); focus and line/frame controls are disabled in selection mode; the bar occupies layout space above the shell tab bar. Back, close, last deselect, project switch, leaving the tab and disappearing/non-visible cards clear or prune selection using the notes-list conventions. Shared actions retain snapshot identity while awaiting.
- Verification: graph_frames_layout_test, graph_frames_widget_test, graph_selection_test; existing phase 4 geometry, hit-testing, focus, cache and phone regressions; graph_frames_test screenshot fixture (57–60) in both languages/themes. Host geometry+cache regression compares paired warm medians at 240 nodes/1000 edges/five groups against the same no-group workload, with a 10% margin. Real-phone profile and TalkBack remain device checks.

New verification keys: `graph-frame-<groupId>`, `graph-group-options-<groupId>`, `graph-make-group-<rowIndex>`, `graph-check-<noteId>`, `graph-topic-convert-sheet`, and `links-content`. Existing node, edge, reason, cluster and shared selection keys stay unchanged.

## Phase 5b review corrections

- `graph_labels.dart`: sendable GraphTextSize metrics and GraphLabel bounds. TextPainter merges the ambient DefaultTextStyle, locale, scaler and bold setting; a rounding allowance prevents short Latin labels from turning into ellipses. Topic controls follow the measured label at its logical end with an 8 dp gap. The label/control line leaves a 6 dp exit lane above card ports; ordinary no-group cards, row heights and unobstructed cubics retain their original geometry. Suggested-title height is reserved before labels/controls, including scaled text.
- `graph_routing.dart`, `graph_arc_route.dart`, `graph_ports.dart`: headers, title, labels and 48 dp controls are shared routing/hit obstacles. Clear cubics are retained. Collisions use curved exits into free side gutters with stable per-link channels, or a short skirt into a free same-row arc span. Port direction, sectors, twelve shared slots, insets and arc rise rules remain. Extreme unrouteable text overlaps are masked by the edge painter’s reserved-rectangle clip and opaque label backing. GraphEdge.curves holds cubic pieces; its original endpoint/control API remains. Bounds, flattened hit ink, solid Paths, dashes and capsules all follow those pieces. Capsules sample short segmented exits more finely so a routed connector keeps its reason when space permits; existing phase 4 capsule assertions stay unchanged.
- `graph_compact.dart`: group first rows start with 8 dp clearance, enlarged only to the actual tallest first-row arc + 6 dp. Rank ports once, shift the pure layout, then route. Only retained routes are flattened, completely before the layout leaves the worker. GraphEdgeInk writes one packed Float32 buffer without a temporary list/division for each dash; its 5-on/5-off phase survives corners.
- Group +N announcements and sheets count/list only hiddenNotes, not the last visible slice. The hidden snapshot is copied once per sheet. Groups/deep descendants/cycles not reached by the two-level traversal get a top-level fallback frame; no group or assigned note silently disappears. Group wrapping and the small-project exception remain unchanged.
- `_home` permits a positive RTL reading-start translation when the canvas is narrower than the viewport. The summary owns the remaining toolbar width and can wrap instead of sharing half its space with Spacer.
- Card semantics use graphNoteInGroup and layout-snapshot ordinal keys (safe across a project switch) for header → own cards → child header → child cards. This is group-aware labelling/order, not fake structural containment. Frame/topic/+N controls have disabled styling, enabled:false and no tap action during selection. Frame/topic callbacks were already null in selection; the review adds their visual state and fixes the previously active overflow callbacks.
- Holds use the device’s MediaQuery gesture settings; InteractiveViewer interaction start also cancels a pending timer. Pan/pinch/zoom remain active.
- Topic conversion trims and grapheme-cuts to groupNameMaxLength, freshly queries groups and reuses a same-named top-level group (never a child). Undo then restores only notes; a newly made target is removed only if still empty. assignSelectionGroup(freshlyRead:true) trusts the just-read repository snapshot instead of filtering against a stale provider. The picker’s default pruning policy remains unchanged.
- Selection action wiring/guard/snapshot lives once in shared/note_selection_actions.dart (noteSelectionActions). Notes and graph retain their own lifecycle and set-identity completion callbacks. It uses the owning screen’s context/ref so pruning the bar cannot lose a completed action’s toast/Undo.
- Tests: graph_review_layout_test (native/flattened ink, measured controls, ports, compact/scaled layout, legacy geometry, processing/hidden notes and malformed trees), graph_review_widget_test (real-font bounds, RTL/summary, gesture settings, semantic order, disabled controls and hidden sheet), graph_topic_review_test (graphemes, reuse/Undo, topic plurals) and selection_assignment_review_test (preloaded stale provider). Existing notes-list tests remain unchanged; phase 4 geometry/cache/focus/hit tests remain regression gates.
