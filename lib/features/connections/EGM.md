# Connections library (redesign phase 3)

`LinksLibraryScreen` is the `/links` branch root. `NoteConnectionsScreen` is
pushed at `/links/note/:id`; both stay inside the shell and consume NavigationInset.
The legacy `/links/graph` address redirects here and selects Map. Full note details still use `/note/:id`.

## Data and performance

`links_index.dart` is pure Dart: sendable note/link/group records, the two
derivation halves `deriveLibraryNotes` (per note: project filter, newest/oldest
orders, ranks, lowercase haystacks) and `deriveLinksIndex` (pairs, neighbours,
counts, suggestions and all three Browse orders), `deriveLinks` (both, for
tests), `LinksIndex.filter`, `pairKey`, and LinksSort. Project IDs
must match for both notes and links. Dismissed, missing and self rows are ignored.
`uniqueLinkPairs` chooses one unordered pair, preferring user rows (accepted AI
is stored as user). Confirmed pairs build bidirectional neighbours; suggestions
sort by strength descending, then createdAt descending, then row ID (sorted as
flat link records: sorting the nested entries cost ~150 ms at 5,000). Browse is
newest first with deterministic ID ties; oldest and most-links (a stable degree
bucket pass over newest) are built in the same derive, so a query never sorts.
Group counts count distinct confirmed-linked notes, parents including children;
topic counts count only ungrouped confirmed-linked notes with nonblank clusters.

`libraryNotesProvider(project)` runs the per-note half only when the notes list
emits (compute for >=1,000 notes). `linksLibraryProvider(project)` watches it,
links and groups, and runs the links half off the UI isolate for large projects, so an accept/reject reuses the
note half. It shares its snapshot with pushed connections pages and records the
stored links list as `linksSource`. Host diagnostic at 5,000 notes / 9,998 rows:
notes half ~19 ms, links half ~20 ms cold and ~8 ms median on a link write,
first search ~4.5 ms. FutureProvider ignores obsolete isolate results. Projections have no Flutter/DB
objects. A keystroke filters precomputed lowercase title/displayText/concepts,
matching the Notes search. LinksIndex retains at most 32 filtered views keyed by
(chip, normalized search, sort). A suggestion matches if one endpoint satisfies
the combined search/chip. Search never derives source data or starts an isolate.

## UI and lifecycle

- ProjectHeader retains Settings and has no graph action. LibraryControls presents Map/Browse/Suggestions, with Map first. Map search/segments are solid and fixed above the canvas; the existing list dock uses Glass. Reading content is solid.
- LibraryChips extends the shared GroupFilterRow with counts and clear-on-retap
  for a selected child; defaults keep Notes behaviour unchanged.
  Choosing a group clears the topic, and vice versa. Deleted filters clear.
- Each project's segment, query, chip, sort and two scroll controllers live in
  the persistent branch widget, without a database/settings write.
- Browse cards and suggestions use lazy slivers. Rows grow with text scale;
  titles/previews use bounded ellipsis, so no fixed itemExtent clips large text.
- SuggestionCard claims a shared project/pair busy flag before awaiting
  acceptPair/dismissPair. Failures use linkUpdateFailed and unlock. Success marks
  the pair done (lists start collapsing it at once) and holds it until a snapshot
  lacks the pair or comes from a newer links list; if that newer snapshot still
  suggests the pair, it unlocks and shows again. The busy notifier listens at
  container level, so it is not paused while the Links tab is hidden, and closes
  that listener with the project's last job. The write itself is shared
  `changeSuggestedPair` (toast with Undo); a call that changed nothing, or one
  blocked by a running Undo, unlocks at once. After Undo the pair returns
  through the next snapshot, which also ends any lock still held.
- SuggestionSliver retains removed snapshots for a 220 ms decelerating
  fade/collapse of that item only. A leaving row stays after its nearest
  surviving predecessor, so a second removal mid-collapse never moves it. Reduced motion removes instantly. Removal
  timers and controllers are disposed; unrelated rows have no ticker. Empty
  content appears after the final collapse. Changing search/chip resets the
  removal bookkeeping, rather than animating filtered-out rows. Search uses the
  Notes 180 ms debounce (clearing is instant); the trimmed query keys it.
- The group chip is validated against the live groups stream; topics against
  the derived index. A chip with no matches shows linksFilterEmptyBody, never
  an empty quoted query, on both segments.
- Connections shows the source note, confirmed entries (shared linksOfNote),
  this note's suggestions (minus pairs already confirmed, since the links stream
  can lead the derived index) and shared link picker. Both lists use the shared project adjacency and per-note suggestion indexes. The page's own note in a suggestion is not a link. Confirmed options/long press
  delegate to showLinkOptions, retaining edit/removal and failure semantics.
  Its source card opens full details; other rows push another connections page.
  A missing/moved note pops only its current route; invalid background pages
  wait until uncovered, so they cannot pop a newer details route or sheet.
- The private note-details rows do not fit the required body preview/no-reason
  layout. They remain unchanged; actions, pair rules, titles and picker are reused.
- The segments are the shared SegmentedPill (soft sliding selected pill) with
  selected button state; the count uses linksSuggestionsCount/…A11y and is
  hidden at zero. Action semantics name both notes, each bidi-isolated, as do
  Browse card neighbour titles. Sort options expose selected state. Map segment controls preserve selected semantics.
  Arabic and English copy is in described ARB entries.

## Verification

links_index_test covers pair rules, counts, sub-groups, matching, ordering,
memoization and the 5,000-note timer. links_library_test and
note_connections_test use the real app/router/Drift streams with gated repository
spies. screenshots/links_library_test covers six views in AR/EN x light/dark.
Flutter tests and rendering require the owner's unrestricted runner. The phone
profile workload is wired through glass_perf_scenario and is not run here.

## Ordering & IA (redesign phase 4)

- `LibraryControls` is a `StatefulWidget` owning a `FocusNode` for `links-search` and shows `links-search-clear` (48×48 dp `Pressable` inside `TextFieldTapRegion`, `clearSearch` semantics) when `search.text.isNotEmpty`, clearing the query immediately; focus (and the keyboard) is re-requested only if the field had focus before the tap.

## Motion & delight (redesign phase 7)

- `LinksLibraryScreen` owns per-segment `StaggerController`s (`_browseStagger`, `_suggestionsStagger`) so at most 8 visible Browse or Suggestions cards fade/rise on a visible first load or visible project switch (`onProjectChanged`), and keys `LibraryControls` and `LibraryChips` by `project.id` so count rolls (`SegmentedPill` Suggestions count and group/topic `ChoiceTag` counts) occur only within the visible project.
- `BrowseNoteCard` passes `(LibraryNote, CardOrigin)` (`FikraRadius.md`) to `/links/note/:id`, and `NoteConnectionsScreen`'s `connections-note` passes `(note, origin)` to `/note/:id`.

## Finishing (redesign phase 8)

- `LinksLibraryScreen` assigns `OrdinalSortKey(0)` to `LibraryControls` and `OrdinalSortKey(1)` to the `IndexedStack` so TalkBack traverses search/sort/segments before list items.
- `LibraryControls` gives `links-search` vertical padding (`14`) for a >= 48 dp tap target and scales `controlHeight` with `textScaler` so `extent` clears large text.
- `LibraryChips` uses `Wrap` + `Semantics(header: true)` for section headings; `NoteConnectionsScreen` marks its title and section headings with `Semantics(header: true)`.

## Push and suggestion performance

- `connectionsIndexProvider(project)` is an auto-disposed family that maps stored notes and confirmed adjacency once per source emission, off the UI isolate for large projects. The library warms it without rebuilding on completion; its listener preserves sharing across consecutive opens in the selected project. The adjacency snapshot is released after the last library/Map/pushed-page listener leaves, rather than retaining every visited project's note bodies. `noteConnectionsProvider(noteId)` selects that adjacency and `LinksIndex.suggestionsByNote`, excluding confirmed pairs while the derived snapshot catches up. Two pushed pages share the project work.
- Connections paints its own opaque PearlCanvas within the existing shell insets. ID-validated previews populate a reserved title/two-line body area immediately; live notes replace them. Static title and section shapes cover cold entry. Section snapshots stay fixed until the initial route entrance completes; that completion is latched, so provider updates during reverse/pop use live sections and cannot restore placeholders or removed rows. NavigationInset remains the scroll clearance.
- Large-project pair derivation uses `compute`; the returned index is reattached to the original links-list identity for stale-lock release. Suggestion pair sets and per-note lookups are cached in the index.
- SuggestionSliver caches pair keys, child widgets and child indices. Claim-only busy changes reach cards, not the list. Successful locks start one incremental collapse; new source snapshots retain unchanged row widgets, removal order and Undo behavior. Lock release checks cached live-pair membership before restoring a row, so stale parent entries cannot restart its collapse timer.

## Links Map

- `library_session.dart` owns session-only per-project segment choices (0 Map, 1 Browse, 2 Suggestions). Missing choices default to Map. Search/chips/sorts and list scroll controllers remain per-project screen state. `/links/graph` explicitly selects Map via this provider.
- `map_provider.dart` watches `linksLibraryProvider`, the shared `connectionsIndexProvider` adjacency and live groups before awaiting. It derives once per revision using `compute` at >=1,000 notes; UI query, selection and transforms never invalidate it. Obsolete results are discarded by FutureProvider.
- `map_index.dart` is isolate-safe. Top-level groups include child memberships; ungrouped/missing-group notes join Others. Without groups, trimmed topics become clusters. Size/ID ordering is deterministic. At most eight overview clusters include Others (seven named slots when needed). Every note belongs to exactly one cluster. Confirmed pairs aggregate to cross-cluster edge counts. Cluster notes rank by confirmed degree/ID and cap at 20; ego caps at 12 confirmed neighbours and four strongest suggestions, with exact omitted totals and +N. Isolated notes are searchable through `LinksIndex.searchNotes` and the existing lowercase index.
- `MapLayout` precomputes mirrored two-column packing or radial ego geometry, including a labelled overflow node. There is no physics, per-frame layout or per-node widget tree.
- `map_canvas.dart` owns a native picture and disposed TextPainters, keyed by revision, level, theme palette/style, locale, TextScaler, direction, width and selection. One CustomPainter draws all edges, capsules and ellipsized titles/counts. InteractiveViewer transforms a RepaintBoundary child, with world-coordinate taps. Each painted node supplies ordered focusable semantics with title/connection count and activation; the canvas has a total/omitted summary. Zoom controls occupy a solid row beneath the canvas and preserve the viewport centre. Ego starts at native 1x centred on the selected note, with a pan hint; it never auto-fits away text scaling. Large text and short screens use a bounded canvas plus a scrollable solid page, clipped above a fixed NavigationInset clearance.
- `links_map.dart` owns project/cluster/note breadcrumbs, visible Back and active-Map-only Android system Back, direct note search, totals, +N lists and a scrollable SolidSurface selection card below the canvas. Note opens push `/links/note/:id`; suggestion accept/reject share pair locks, `changeSuggestedPair` and Undo. Selection never places actions or text over edges. Level changes use a single 220 ms fade (zero under Reduce Motion); outgoing content cannot receive input or semantics. NavigationInset keeps the moving canvas above the glass bar.
- Regressions: `map_index_test`, `map_provider_test`, `links_map_test` and updated phone/library/connections/IA fixtures. `screenshots/links_map_test` captures overview/cluster/ego in AR/EN x light/dark. `integration_test/links_perf_scenario` reports `map_pan` overview/ego metrics, six pans and two zooms each, targeting raster p95 <= 6.5 ms on the reviewer's Realme. No phone result is claimed by host tests.
