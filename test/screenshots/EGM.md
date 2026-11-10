# Screenshot fixtures

Design-review widget captures, tagged `screenshots` and skipped during normal tests. Run `rm -rf build/screenshots && flutter test test/screenshots --run-skipped -t screenshots`. Outputs live under `build/screenshots/{ar,en}/{dark,light}` and are generated, not checked-in goldens.

`screens_test.dart` uses fixed sample time, real app fonts, phone dimensions and the real router. `20_pdf_failure.png` shows a saved PDF whose injected loader fails, in both languages and themes, with the external-open action available. Loaded PDFs are omitted because the widget harness does not initialize native PDFium; actual page rendering and gestures need a device check. `headers_test.dart` covers responsive headers.
