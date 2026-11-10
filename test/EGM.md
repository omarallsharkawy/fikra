# Tests

## Overview

Unit and widget tests for FIKRA. Run `flutter test`; screenshot-tagged tests are skipped by default. [support](support/EGM.md) owns the real-app harness; [screenshots](screenshots/EGM.md) owns design-review captures. Generated migration fixtures are not hand-edited.

## PDF coverage

- `app_flow_test.dart`: PDF-row route push through the real router, removal of the card overlay, PDF-icon taps opening the note, missing-file error and external opener path, ignored query-path input, notes without PDFs, deleted notes and unchanged external photo opening.
- `pdf_viewer_test.dart`: injected corrupt/password failures, throwing external opener, default missing-file preflight, native-document disposal after normal and late load completion. Test documents are lifecycle fakes; no PDFium rendering is required.
- Native rendering, zoom gestures, page-indicator tracking, and large-file responsiveness/memory require a device check.

## Verification

`dart format -l 120 lib test integration_test`, `flutter analyze`, `flutter test`, and `rm -rf build/screenshots && flutter test test/screenshots --run-skipped -t screenshots`.
