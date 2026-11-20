# Screenshot fixtures

Design-review widget captures, tagged `screenshots` and skipped during normal tests. Run `rm -rf build/screenshots && flutter test test/screenshots --run-skipped -t screenshots`. Outputs live under `build/screenshots/{ar,en}/{dark,light}` and are generated, not checked-in goldens.

`screens_test.dart` uses fixed sample time, real app fonts, phone dimensions and the real router. `20_pdf_failure.png` shows a saved PDF whose injected loader fails, in both languages and themes, with the external-open action available. Loaded PDFs are omitted because the widget harness does not initialize native PDFium; actual page rendering and gestures need a device check. `headers_test.dart` covers responsive headers (eight dark width/scale galleries plus light-mode `notes_light` Notes header captures in Arabic and English).

Multi-file fixtures render two PDFs, recordings and photos in both locales/themes: `21_details_files`, `22_edit_files`, `23_edit_files_bottom`, `24_add_files`, `25_notes_files`. Photos are generated temporary local PNG fixtures and removed after each test. Native audio is replaced by the harness channel fake. Check file-size LTR runs, card counts, file controls, overflow and RTL/LTR ordering.

`phone_fixes_test.dart` captures `26_pdf_password` (specific message, external action, no retry) and `27_proposal_scale_{1,2,3}` in both locales/themes. The default-scale labels must occupy one line; larger labels wrap in growing stacked buttons. These are widget renders, not device audio/PDFium verification.

The multi-file note fixture uses the restored PDF auto-title without its extension. Review captures include the shared Add/Edit recording controls with the app-wide busy state.

Links phase 2 captures in `screens_test.dart`: `28_link_picker` (two picks, reason, counter), `29_link_picker_keyboard` (336 dp fake keyboard inset), `30_details_links` (with the linked toast), `31_details_links_bottom` (your links and a suggestion), `32_link_options`, `33_link_reason`, `34_link_remove_confirm`. These add user links to the sample RAG note, so later graph captures include them.

Links phase 3 captures in `projects_test.dart` (sample project plus "Study" and a long-named project, both languages and themes): `35_note_options_move`, `36_move_picker` (note counts, long name wrapping), `37_move_confirm` (your links and suggestions, red confirm), `38_move_confirm_no_links` (plain message, primary confirm), `39_delete_project_confirm` (counts), `40_delete_project_empty`, `41_new_project_one_sheet` (UX-16). Finders for the name titles pass the name through `Fmt.isolate`, as the app does; `40_delete_project_empty` shows the no-chat wording. In `screens_test.dart`, `16_new_project` now shows the name sheet alone.

Links phase 4: `links_test.dart` captures `42_graph_connectors` (nothing selected, mixed user/suggestion edges) and `43_graph_focus` (selected card, direct neighbours, faded unrelated cards/edges, labelled incident capsules with long-label ellipsis) in Arabic RTL / English LTR and dark / light. The six-node fixture includes same-row arcs and bottom-to-top connectors. Captures use real fonts and the app router. Review visible border dots, vertical tangents, solid/dashed distinction, focus and capsule placement.

Independent-review captures retain `42_graph_connectors` and `43_graph_focus`, now showing incident-only edges and readable colour-muted surroundings. `44_graph_nested` is an additional 780 dp wide capture in all four locale/theme variants: two nested arcs with different rises, a long ellipsised heading and selected incident capsules placed away from headings/cards. Review the incoming suggestion near Review/مراجعة for the removed crossing, and inspect label/card/capsule clearance.

Links phase 5a: `selection_test.dart` (sample project with two top-level groups, one sub-group and a "Study" project, both languages and themes): `45_notes_groups` (filter row, card tags), `46_group_filter_parent` (sub-group row, options control), `47_selection_mode`, `48_selection_keyboard` (336 dp fake keyboard), `49_group_sheet` (counts, indented sub-group), `50_new_group_form`, `51_selection_limit` (7 selected, link disabled with its note), `52_move_notes_confirm`, `53_delete_notes_confirm`, `54_link_undo_toast`, `55_group_options` ("put inside" disabled with its reason, since the group has a sub-group), `56_delete_group_confirm`. Notes are picked by index, not title. Review the check marks, bar labels, RTL indent and arrow, and the Undo colour on the light toast.

Phase 5b: graph_frames_test.dart captures 57_graph_groups (coloured parent + child, empty frame and suggested topic), 58_graph_empty (empty project group), 59_graph_selection (check mark/shared action bar with preview hidden), and 60_graph_frame_focus (parent/child focus, faded unrelated frame and preview), in AR/EN and dark/light. The composed graph uses a 0.65 transform so frame bounds, suggested topics and tab-bar clearance fit in a phone capture. Review header/card/arc/capsule separation and mirrored direction.

Review rerenders 10_links and 57–60 in all locale/theme variants. The empty-frame fixture uses the real reading-start transform, rather than overriding it with identity. Inspect inline measured topic controls outside all line ink; free-gutter connectors clear group/child/empty headers and Suggested topics; compact first-row arc lanes; equal 24 dp start margins and an uncut empty summary in Arabic; disabled selection controls and tab-bar clearance. Text bounds include the ambient style/locale and rounding allowance so short English labels and the suggested title do not clip.

Links phase 6: graph_navigation_test.dart captures 61_graph_chips, 62_graph_search_results_keyboard (a 300 dp inset with a drawn keyboard over it, since the test view has none; the query fills the list so it visibly ends at the keyboard), 63_graph_search_empty, 64_graph_collapsed (parent folded into a capsule with re-attached lines, framed at 0.65) and 65_graph_minimap (100 extra notes so the map shows), in both languages and themes. Check the chip row, the list ending above the keyboard, capsule lines, and the minimap above the tab bar at the logical end.

`voice_text_test.dart` (phase 1) captures Settings' Voice section, the default model list, Egyptian present/selected, lower model rows, download confirmation, recording, everyday transcript/seconds, testing expanded and raw numbers. Every case runs in AR/EN and dark/light through the real router and real key/value settings, with a fake native backend. Captures wait for both inventory and preferences before rendering. Filenames use voice_text_default_* and voice_text_egyptian_*.

All reveals use shared revealVoiceText/tapVoiceText with plain keyed targets and an explicit outer Scrollable. Settings supplies its own unique list; SelectableText's nested Scrollable is excluded. No first/last/at wrapper is used for a lazy scroll target. No native recognition, HTTP, microphone or storage-channel call is exercised.

Phase 2 transcription_test.dart adds real-router phone fixtures in AR/EN × light/dark: saved transcript collapsed/expanded, model-missing failure and settings action, selected Add draft toggle, and the voice-settings auto toggle off/on with an installed Egyptian model. All native inference is faked by the app harness. Keyed outer-page scrolling is shared through support/transcription_scroll.dart. These images require the orchestrator's socket-capable Flutter test runner; rendering/visual inspection is not claimed from the restricted sandbox.

Phase 3 external_transcription_test.dart adds AR/EN x light/dark fixtures: engine choices, each of the four prefilled service forms (top and obscured key), upload consent and Settings' named recipient line. It uses real router/SQLite with fake keys and HTTP, and never sends a probe or user recording. Every scroll target is a plain key through the shared explicit-outer-scrollable helper. Images cannot be rendered/inspected in this socket-blocked sandbox.

Pearl foundation: all existing fixtures change visually with the palette and
solid reading surfaces. glass_tiers_test.dart adds ar/glass_tiers.png, a single
1200x900 Arabic gallery with solid/frosted/optical columns and dark/light rows,
using real fonts and the stationary review lens. Widget-host Skia may frost the
package lens rather than refract; the profile phone overlay verifies Impeller.
Run with the same screenshot command above; no image is claimed rendered here.

## Voice 2a

voice2_test.dart captures the catalog picker sheet, recording off/after-save chips, transcript editor and newer-machine-result state in AR/EN × dark/light, using existing real-router/DB fixtures and fake native/services. It never sends audio or performs discovery. Explicit keyed scroll helpers avoid first/last/at wrappers. Rendering/visual inspection require the orchestrator's socket-capable runner.

## Floating navigation (redesign phase 2)

floating_navigation_test.dart captures Arabic/English × light/dark: home, a held
mid-slide lens over Links, Add selected, focused Add with keyboard inset, and the
end of a 35-note list. It forces frosting for deterministic widget-host rendering;
optical settings/fallback are covered separately and optics are measured on the
phone. The keyboard capture reuses saveWithKeyboard’s drawn test keyboard.
The pointer is released only after the mid-slide capture. All view/pointer cleanup
uses addTearDown. Existing screens_test, transcription_test and voice2_test enter
Add through Tabs.addButton. Render these fixtures with the existing screenshots
command; no images have been rendered or visually approved in this environment.

## Links library (redesign phase 3)

links_library_test adds 70_links_browse, 71_links_filtered, 72_links_suggestions, 73_note_connections, 74_links_graph_option and 75_links_suggestions_empty in Arabic/English x light/dark. Real router/SQLite, parent/child groups, topics, previews and three suggestions use the shared fixture and saveScreenshot, with deterministic frosting and real fonts. The old graph captures remain and enter through the new header button in graph_fixture/screens_test. Rendering and visual QA have not run in this sandbox; use the existing screenshot command above on the unrestricted runner.

## Ordering & IA (redesign phase 4)

In `screens_test.dart`, `14_settings` opens Settings via `ValueKey('header-settings')`, and `08_edit_note` opens Edit from `NoteDetailsScreen` via `ValueKey('note-edit')`.

## Motion & delight (redesign phase 7)

`phase7_motion_test.dart` renders `phase7_save_tick` (mid-animation), `phase7_recording` (pulse ring and live waveform), `phase7_capsule_recording`, `phase7_capsule_transcribing` and `phase7_shrunk_bar` in Arabic/English × light/dark using `saveScreenshot(..., settle: Duration.zero)` and deterministic frosting.

## Finishing (redesign phase 8)

`phase8_finishing_test.dart` captures all 14 main screens and sheets at text scale `2.0` (`360 × 800` dp) in Arabic and English light mode (`phase8_scale2_*`), plus a frosted glass sheet (`phase8_glass_sheet`) and a frosted glass toast with Undo above the floating tab bar (`phase8_glass_toast`) in Arabic and English, light and dark.

## Concept navigation (phase 1B)

Floating navigation now captures four tabs, a full-screen Add without chrome,
and Me statistics in AR/EN × light/dark. Add exits through add-close before
returning to tab captures. Header galleries omit Settings and keep project chips;
shared accessibility fixtures enter Me through nav-3 and close Add with X.
