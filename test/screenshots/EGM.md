# Screenshot fixtures

Design-review widget captures, tagged `screenshots` and skipped during normal tests. Run `rm -rf build/screenshots && flutter test test/screenshots --run-skipped -t screenshots`. Outputs live under `build/screenshots/{ar,en}/{dark,light}` and are generated, not checked-in goldens.

`screens_test.dart` uses fixed sample time, real app fonts, phone dimensions and the real router. `20_pdf_failure.png` shows a saved PDF whose injected loader fails, in both languages and themes, with the external-open action available. Loaded PDFs are omitted because the widget harness does not initialize native PDFium; actual page rendering and gestures need a device check. `headers_test.dart` covers responsive headers.

Multi-file fixtures render two PDFs, recordings and photos in both locales/themes: `21_details_files`, `22_edit_files`, `23_edit_files_bottom`, `24_add_files`, `25_notes_files`. Photos are generated temporary local PNG fixtures and removed after each test. Native audio is replaced by the harness channel fake. Check file-size LTR runs, card counts, file controls, overflow and RTL/LTR ordering.

`phone_fixes_test.dart` captures `26_pdf_password` (specific message, external action, no retry) and `27_proposal_scale_{1,2,3}` in both locales/themes. The default-scale labels must occupy one line; larger labels wrap in growing stacked buttons. These are widget renders, not device audio/PDFium verification.

The multi-file note fixture uses the restored PDF auto-title without its extension. Review captures include the shared Add/Edit recording controls with the app-wide busy state.

Links phase 2 captures in `screens_test.dart`: `28_link_picker` (two picks, reason, counter), `29_link_picker_keyboard` (336 dp fake keyboard inset), `30_details_links` (with the linked toast), `31_details_links_bottom` (your links and a suggestion), `32_link_options`, `33_link_reason`, `34_link_remove_confirm`. These add user links to the sample RAG note, so later graph captures include them.

Links phase 3 captures in `projects_test.dart` (sample project plus "Study" and a long-named project, both languages and themes): `35_note_options_move`, `36_move_picker` (note counts, long name wrapping), `37_move_confirm` (your links and suggestions, red confirm), `38_move_confirm_no_links` (plain message, primary confirm), `39_delete_project_confirm` (counts), `40_delete_project_empty`, `41_new_project_one_sheet` (UX-16). Finders for the name titles pass the name through `Fmt.isolate`, as the app does; `40_delete_project_empty` shows the no-chat wording. In `screens_test.dart`, `16_new_project` now shows the name sheet alone.
