# Inter and Arabic typography

The user selected Inter for English while retaining the existing Arabic font.
The shared text tokens and Material themes use Inter first, NotoSansArabic for
Arabic glyphs, and Roboto as a final system fallback. Mixed-language text uses
both faces in one paragraph. Direction continues to follow the selected locale.

Original static Inter 4.1 Regular, Medium, SemiBold, Bold and ExtraBold faces
provide weights 400–800. They are bundled in the APK; there is no font service,
network fetch or new package dependency. NotoSansArabic files and weights remain
unchanged. Existing font sizes, line heights and zero tracking are preserved.

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
