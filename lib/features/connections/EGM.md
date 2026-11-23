# Connections library (redesign phase 3)

`LinksLibraryScreen` is the `/links` branch root. `NoteConnectionsScreen` is
pushed at `/links/note/:id`; both stay inside the shell and consume NavigationInset.
The retained graph is a sibling pushed route at `/links/graph`, implemented in
`../links` without a graph refactor. Full note details still use `/note/:id`.

## Data and performance

`links_index.dart` is pure Dart: sendable note/link/group records, the two
derivation halves `deriveLibraryNotes` (per note: project filter, newest/oldest
orders, ranks, `normalizeArabic` haystacks and cached `haystackWords`) and
`deriveLinksIndex` (O(G) `childrenByParent` group map, pairs, neighbours,
counts, suggestions and all three Browse orders), `deriveLinks` (both, for
tests), `shouldIsolateLinksDerivation` (notes, edges, and groups threshold),
`LinksIndex.filter`, `pairKey`, and LinksSort. Project IDs
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
objects. A keystroke filters precomputed `normalizeArabic` title/displayText/concepts
through `matchesNormalizedArabic`, matching the Notes search. LinksIndex retains at most 32 filtered views keyed by
(chip, normalized search, sort). A suggestion matches if one endpoint satisfies
the combined search/chip. Search never derives source data or starts an isolate.

## UI and lifecycle

- ProjectHeader is unchanged, with a named/tooltip graph action. LibraryControls
  overlays a solid Pearl search/sort dock (`c.surface`, `borderGraph`/`line` border, `glassShadows`, no `BackdropFilter`); solid selected segment pills sit
  below. Content scrolls behind it. No reading list uses blur.
- LibraryChips extends the shared GroupFilterRow with counts and clear-on-retap
  for a selected child; defaults keep Notes and graph behaviour unchanged.
  Choosing a group clears the topic, and vice versa. Deleted filters clear.
- Each project's segment, query, chip, sort and two scroll controllers live in
  the persistent branch widget, without a database/settings write.
- Browse cards and suggestions use lazy slivers. Rows grow with text scale;
  titles/previews use bounded ellipsis, so no fixed itemExtent clips large text.
- SuggestionCard claims a shared project/pair busy flag before awaiting
  the shared accept/reject command with the rendered link project. Failures use linkUpdateFailed and unlock. Success marks
  the pair done (lists start collapsing it at once) and holds it until a snapshot
  lacks the pair or comes from a newer links list; if that newer snapshot still
  suggests the pair, it unlocks and shows again. The busy notifier listens at
  container level, so it is not paused while the Links tab is hidden, and closes
  that listener with the project's last job. The write itself is shared
  `changeSuggestedPair` (toast with Undo); a call that changed nothing, or one
  blocked by a running Undo or rejected as PairCommandStale, unlocks at once. After Undo the pair returns
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
  Browse card neighbour titles. Sort options expose selected state. The graph
  button's Tooltip is excluded from semantics, so its label is read once.
  Arabic and English copy is in described ARB entries.

## Verification

links_index_test covers pair rules, counts, sub-groups, matching, ordering,
memoization and the 5,000-note timer. links_library_test and
note_connections_test use the real app/router/Drift streams with gated repository
spies. screenshots/links_library_test covers six views in AR/EN x light/dark.
Flutter tests and rendering require the owner's unrestricted runner. The phone
profile workload is wired through glass_perf_scenario and is not run here.

## Ordering & IA (redesign phase 4)

- `LinksLibraryScreen` uses `HeaderActionButton` (`links-open-graph`, visible caption `headerGraph`, semantic label and excluded tooltip `linksOpenGraph`) in `ProjectHeader.trailing`.
- `LibraryControls` is a `StatefulWidget` owning a `FocusNode` for `links-search` and shows `links-search-clear` (48×48 dp `Pressable` inside `TextFieldTapRegion`, `clearSearch` semantics) when `search.text.isNotEmpty`, clearing the query immediately; focus (and the keyboard) is re-requested only if the field had focus before the tap.

## Motion & delight (redesign phase 7)

- `LinksLibraryScreen` owns per-segment `StaggerController`s (`_browseStagger`, `_suggestionsStagger`) so at most 8 visible Browse or Suggestions cards fade/rise on a visible first load or visible project switch (`onProjectChanged`), and keys `LibraryControls` and `LibraryChips` by `project.id` so count rolls (`SegmentedPill` Suggestions count and group/topic `ChoiceTag` counts) occur only within the visible project.
- `BrowseNoteCard` passes `(LibraryNote, CardOrigin)` (`FikraRadius.md`) to `/links/note/:id`, and `NoteConnectionsScreen`'s `connections-note` passes `(note, origin)` to `/note/:id`.
- P0.1: `StaggerVisibility` owns branch visibility changes and stops both segment staggers offstage. First-load/project-switch decisions read a non-subscribing TickerMode snapshot; tab switches cause zero library screen builds (`test/branch_build_test.dart`).
- Browse and connections source cards wrap their existing pressables in `ContainerTransformSource` for a paint-only fade during note open/pop. Existing pressable/test keys and route extras remain.

## Finishing (redesign phase 8)

- `LinksLibraryScreen` assigns `OrdinalSortKey(0)` to `LibraryControls` and `OrdinalSortKey(1)` to the `IndexedStack` so TalkBack traverses search/sort/segments before list items.
- `LibraryControls` gives `links-search` vertical padding (`14`) for a >= 48 dp tap target and scales `controlHeight` with `textScaler` so `extent` clears large text.
- `LibraryChips` uses `Wrap` + `Semantics(header: true)` for section headings; `NoteConnectionsScreen` marks its title and section headings with `Semantics(header: true)`.

## Push and suggestion performance

- `connectionsIndexProvider(project)` (`autoDispose.family`) maps stored notes and confirmed adjacency once per source emission, off the UI isolate when `shouldIsolateLinksDerivation` triggers. The library warms the active project without rebuilding on completion, keeping the cached index across consecutive opens while releasing unviewed projects when unlistened; `LinksLibraryScreen` also prunes and post-frame disposes deleted projects' `_ProjectView` controllers/timers via `projectsProvider`. `noteConnectionsProvider(noteId)` selects that adjacency and `LinksIndex.suggestionsByNote`, excluding confirmed pairs while the derived snapshot catches up. Two pushed pages share the project work.
- Connections paints its own opaque PearlCanvas within the existing shell insets. ID-validated previews populate a reserved title/two-line body area immediately; live notes replace them. Static title and section shapes cover cold entry. Section snapshots stay fixed until the route entrance completes. NavigationInset remains the scroll clearance.
- Large-project pair derivation uses `compute`; the returned index is reattached to the original links-list identity for stale-lock release. Suggestion pair sets and per-note lookups are cached in the index.
- SuggestionSliver caches pair keys, child widgets and child indices. Claim-only busy changes reach cards, not the list. Successful locks start one incremental collapse; new source snapshots retain unchanged row widgets, removal order and Undo behavior. Lock release checks cached live-pair membership before restoring a row, so stale parent entries cannot restart its collapse timer.

## Brand redesign (phase 1a)

- `links_library_provider.dart` & `links_library_screen.dart`: adds `linksLibraryRequestedSegmentProvider` so Notes' conditional action strip can open `/links` directly on segment 1 (Suggestions) without changing router paths.

SuggestionCard disables actions when either rendered endpoint has a different project from the link. The repository validates both live endpoints against the rendered project in the command transaction.
