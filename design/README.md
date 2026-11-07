# FIKRA — Design

Source of truth: Figma file **FIKRA — Plasma UI · Arabic**
https://www.figma.com/design/1lXJpY7TEcB9KQfeJUw1RR

| Page / board | What it covers | Link |
|---|---|---|
| Components — المكونات | Icons, Button, Field, Chip, Status bar, Nav item, Bottom nav, Screen header (with project switcher), Note card, Graph node, Chat bubble, Sheet, Project row, Banner, Badge, Progress bar, Segmented control, Skeleton card, Empty state | [open](https://www.figma.com/design/1lXJpY7TEcB9KQfeJUw1RR/?node-id=26-2) |
| Board 0 — الشاشات الأساسية | Add, Notes, Links (graph), Ask, rebuilt from components | [open](https://www.figma.com/design/1lXJpY7TEcB9KQfeJUw1RR/?node-id=37-1282) |
| Board 1 — المشاريع | First project, project switcher, new project, project options, delete confirm | [open](https://www.figma.com/design/1lXJpY7TEcB9KQfeJUw1RR/?node-id=30-3) |
| Board 2 — تفاصيل النوت | Details, AI rewrite proposal, processing, edit, note options | [open](https://www.figma.com/design/1lXJpY7TEcB9KQfeJUw1RR/?node-id=31-424) |
| Board 3 — صوت و PDF | Recording, review, PDF uploading, upload failed, mic permission denied | [open](https://www.figma.com/design/1lXJpY7TEcB9KQfeJUw1RR/?node-id=34-642) |
| Board 4 — الحالات والحساب | Empty notes, loading + offline, answer not found, links error, sign in, sign up | [open](https://www.figma.com/design/1lXJpY7TEcB9KQfeJUw1RR/?node-id=36-947) |
| Page 1 / Style Guide | The original flat import (kept for reference) | [open](https://www.figma.com/design/1lXJpY7TEcB9KQfeJUw1RR/?node-id=2-6) |

`concepts/` holds the AI-generated concept boards (Codex imagegen) that the Figma boards were rebuilt from. They are references only; Figma wins when they differ.

## Tokens (Figma variables → Flutter theme)

- **FIKRA Primitives** (hidden): neutral, white alpha ramp, blue, red, green, amber, black/a60.
- **FIKRA Color** (mode `Dark`): `bg/*`, `surface/*`, `text/*`, `border/*`, `accent/*`, `graph/edge`, `action/*`, `status/*`.
- **FIKRA Layout**: `radius/sm 18 · md 20 · lg 24 · xl 28 · 2xl 38 · full`, `space/4…32`, `space/screen 22`, `size/button 56`, `size/nav 70`, `size/field 48`, `stroke/hairline 0.6`.
- **Paint styles** (gradients): Screen background, Glass surface, Selected, Primary action, Send.
- **Text styles**: Noto Sans Arabic, line height 150%. Title/Screen 26 · Title/Card 18 Bold · Body/Answer 17.5 · Body/Default 16 · Body/Field 15 · Caption/Preview 12.5 · Label/Nav 13 · Label/Button 19 Bold · Meta/Small 11.

### Where they live in code

The app is dark-only, so tokens are plain static classes (no `ThemeExtension`):

| Figma | Flutter (`lib/core/theme/tokens.dart`) |
|---|---|
| FIKRA Color + paint styles | `FikraColors` (gradients too: `screenGradient`, `glassGradient`, …) |
| radius / space / size | `FikraRadius`, `FikraSpace` |
| text styles | `FikraText` |
| Material wiring (no ripple, sheets, snackbars) | `buildFikraTheme()` in `fikra_theme.dart` |
| springs, press scale | `FikraSprings`, `Pressable` in `lib/core/motion/pressable.dart` |

Change a value in `tokens.dart`, never inline in a screen. Two sizes intentionally differ from Figma: Body/Answer is 17 (Figma 17.5) and Label/Button is 18 (Figma 19); both read better on device at 3x.

## Rules learned while building

1. **RTL everywhere.** First item in a row sits on the right. Back arrow is on the right and points right. Progress fills from the right.
2. **Bidi:** a paragraph that *starts* with a Latin word ("RAG …") flips to LTR. Start Arabic text with an Arabic word (`الـRAG …`), and in Flutter always set `TextDirection.rtl` on Arabic text. Avoid labels like `الـAI` — use Arabic (`النسخة المحسّنة`, `اقتراح إعادة صياغة`).
3. **No letter-spacing on Arabic** (the Plasma −4% tracking breaks letter joining). Latin-only strings (file names) may use Inter.
4. **One primary (white) button per screen.** Destructive actions use the Danger button and always confirm.
5. **Never lose input:** upload/processing errors keep the typed text and the attachment; "saved" and "AI finished" are separate states.
6. **Demo mode** shows the `بيانات تجريبية` badge on Ask and anywhere AI output is simulated.
7. **Motion (Plasma):** press scale 0.964 with the smooth spring, sheets slide up ~310 ms ease-in-out over a 60% scrim, enter = fade + scale 0.96→1. Respect Reduce Motion.

## Motion

`lib/core/motion/motion.dart` is the source of truth for transition tokens.

| Motion | Tokens / widget |
|---|---|
| Press feedback, tab / segment pill | `Pressable`, `FikraSprings.smooth`; press scale 0.964 (cards 0.98) |
| Content state swap | `FikraSwitcher`, distinct state keys; exit 120 ms in-cubic, then enter 250 ms out-cubic + scale 0.96→1 |
| Height changes | `FikraSwitcher(animateSize: true)`; expand 280 ms out-cubic |
| Tab branch change | `FikraBranchContainer`; enter tokens, hidden branches stay alive offstage |
| New chat message | Enter fade + 8 dp upward offset; existing messages stay still |
| Screen push / pop | `FikraPageTransitionsBuilder`; 400 ms `Cubic(0.23, 1, 0.32, 1)`, 30 dp from the logical end (left in RTL), 100 ms fade; predictive back scrubs the route |
| Sheets | `showFikraSheet`; 310 ms `Cubic(0.42, 0, 0.58, 1)` in both directions |
| Destructive dialog | `confirmDestructive`; enter tokens, then fast exit fade |

Respect `MediaQuery.disableAnimations`: `FikraMotion.reduced(context)` selects plain 180 ms fades or instant transitions, with no slide, scale, or size animation. Key state changes, never stream ticks; the initial content does not animate.
