# Capture layout and real recording

Capture follows the HTML overlay: 68dp header, cancel, optional-title chip,
22px title/17px content with auto direction, 16dp gutters, 44dp Voice/PDF/Tag
tools, character count, empty hint and fixed 48dp Save. Explanatory voice/file
panels are removed. PDF items carry a concise device label; they remain local
and are never represented as uploaded note content. Tags use the existing
device catalog and are assigned only after confirmed note creation.

Stop and transcribe uses the real device recorder and repository transcription,
appending each result once into the editable draft. Save remains explicit and
disabled during recording/transcription. The existing 60-second stop, native
permission handling, retry/cooldown and account/epoch guards remain. Closing
Capture cancels audio and late transcription while retaining typed text.

The waveform uses 14 bars, 4dp width, 3dp gaps, 32dp height, 900ms easing and
70ms stagger. It runs only while recording and respects reduced motion.
On narrow screens the recording actions stack and large text wraps the toolbar
to preserve readable copy and 44dp targets; the prototype's overflowing inline
recording row is intentionally not reproduced. Real loading, storage and API
errors use localized copy. Unresolved saves retain their original payload/key.

Four-mode empty, filled and recording captures are under
`build/validation/redesign/{reference,after}/capture-*`. Widget tests cover
Arabic/English at 1x/2x text size, editable RTL text, optional title, close/reopen,
real repository transcription, one-time append and explicit save. Native tests
verify recorder cleanup; no prototype transcript is shipped.
