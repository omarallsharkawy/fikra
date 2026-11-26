# Inter and Arabic typography

The user selected Inter for English while retaining the existing Arabic font.
The shared text tokens and Material themes use Inter first, NotoSansArabic for
Arabic glyphs, and Roboto as a final system fallback. Mixed-language text uses
both faces in one paragraph. Direction continues to follow the selected locale.

Original static Inter 4.1 Regular, Medium, SemiBold, Bold and ExtraBold faces
provide weights 400–800. They are bundled in the APK; there is no font service,
network fetch or new package dependency. NotoSansArabic files and weights remain
unchanged. Zero tracking is retained, including for joined Arabic text.

The mobile UI refresh adopts a quieter hierarchy requested by the user: Regular
400 reading text (16 sp), Medium 500 metadata/navigation, and SemiBold 600
headings/actions. Page titles use 26 sp with 1.2 line height; card titles use
17 sp with 1.35 line height; action labels use 16 sp. Labels remain at least
12.5 sp and continue to respect platform text scaling. This brings the visual
weight closer to the requested iPhone style while keeping the approved fonts.
The same shared text tokens apply to the separate legacy demo.

Source: [Inter official release 4.1](https://github.com/rsms/inter/releases/tag/v4.1).
Archive SHA-256: `9883fdd4a49d4fb66bd8177ba6625ef9a64aa45899767dde3d36aa425756b11e`.
The original SIL Open Font License and copyright notice are distributed as
`assets/fonts/inter/LICENSE.txt`, also declared as an application asset. The
font files are unmodified. No Apple font files are distributed.

Tests load real Inter and Noto faces, compare Arabic shaping advances against
the original Arabic face, verify English Material metrics, and exercise welcome,
product navigation and the main legacy screens/sheets in Arabic/English,
light/dark and enlarged text. See the mobile-branding typography phase record
for execution results.
