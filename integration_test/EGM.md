# Integration tests

`stress_test.dart` seeds the isolated stress database in batches, with six ordered attachments (two of each kind) on every fourth note, and times `watchProjectAttachments` as used by cards. No legacy attachment fields are written. It retains the existing scroll/search/Map/AI timing approach and never touches real user files. Run the profile drive command at the top of the file on `com.fikra.app.stress`; do not use the production install for migration experiments.

Stress link seed rows explicitly include v6 origin ai, dismissed false and createdAt; the UI and stress workload are unchanged.

The stress attachment seed now explicitly sets v7 transcriptionStatus.none, matching the generated required row constructor; no inference or workload change is introduced.

## Pearl glass profile scenario

FIKRA_GLASS_PERF=true selects glass_perf_scenario.dart after the same stress DB
seed and notes-list open, skipping the unrelated stress steps. The exact profile
drive command is at the top of both files. The package remains
com.fikra.app.stress, and no production DB/files are touched. The real floating bar and Add replace the stationary debug preview. Each requested solid/frosted/
optical tier gets two seconds of warm-up then six 2-second scroll traversals. After collecting the scroll metrics, one
synthetic pointer is held for six Notes→Links→Ask→Links→Notes cycles (12 moves
per segment, 16 ms cadence), followed by release/settle. Branches are warmed
outside the traces. Separate slide traces and slide_across_tabs frame metrics
are included for each tier, with the same percentiles and over-budget counts.
traceAction and FrameTiming report per-tier build/raster p50/p90/p95/p99,
phase-budget and display-budget exceedances, refresh Hz, requested/effective
tier and live-refraction support into reportData (JSON driver output).
Only the benchmark disables automatic watchdog drops via an injected no-op
timings source; real battery/reduce-motion caps still apply and a mismatch
fails rather than silently reporting the wrong tier. Release has no override.
Timers/listeners/DB/file cleanup use addTearDown. Do not run on-device from the
restricted sandbox; owner runs the command on the phone later.

The normal stress tab workload now maps branch IDs to four nav keys plus nav-add.

## Links comparison (redesign phase 3)

The same FIKRA_GLASS_PERF drive runs links_perf_scenario once per tier: six Browse flings, six Suggestions flings, two accepts and two rejects with collapse, then overview and ego Map pans/zooms through the first segment. Each workload has its own trace and build/raster p50/p90/p95/p99 plus phase/display over-budget frame counts using glassFrameReport. Warm-up/navigation occurs outside measured windows. The isolated seed now has a confirmed chain edge and a nonadjacent AI suggestion per note, five groups (one nested), and grouped/ungrouped topics. It keeps thousands of rows in each segment at 5,000 notes. The normal stress entry opens the Map segment. Exact drive command remains atop glass_perf_scenario.dart; owner runs the phone, never this sandbox.

## Motion workloads (redesign phase 7)

`motion_perf_scenario.dart` (`runMotionPerformance`, called per tier from `glass_perf_scenario.dart` under `'motion'`) measures two traced workloads with `glassFrameReport` (`build` and `raster` `p50/p90/p95/p99` plus budget exceedances): `note_open` (six container-transform card opens from `NotesScreen` and back pops) and `scroll_shrink_bar` (six 2-second alternating scroll sweeps with `navBarShrinkEnabledProvider` enabled and restored in `finally`). Do not run on-device from the sandbox.


## Links Map replacement

`links_perf_scenario.dart` replaces graph_pan with map_pan (overview and ego): six 900 ms pans and two animated pinch zooms per level, warmed/navigated outside measured windows, with build/raster percentiles and budget counters supplied by the existing measure callback. The target is Realme raster p95 <=6.5 ms. `stress_test` opens the Map segment and names its legacy live pan trace map_pan. The reviewer runs the isolated stress build on the phone; host tests do not establish the device target.
