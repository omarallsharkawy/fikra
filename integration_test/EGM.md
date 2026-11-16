# Integration tests

`stress_test.dart` seeds the isolated stress database in batches, with six ordered attachments (two of each kind) on every fourth note, and times `watchProjectAttachments` as used by cards. No legacy attachment fields are written. It retains the existing scroll/search/graph/AI timing approach and never touches real user files. Run the profile drive command at the top of the file on `com.fikra.app.stress`; do not use the production install for migration experiments.

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

The normal stress tab workload now maps branch IDs to three nav keys plus nav-add.
