# Lantern and Apple's Human Interface Guidelines

How the app follows the HIG, what it deliberately does, and what is still open. Updated 2026-11-05.

## App icon

What Apple asks for, and why the first drafts failed:

- **One simple subject, no text, no photos, no UI chrome.** The icon must read at 29 px. Rendered lanterns with glass and brass turned to mud below 60 px.
- **Full-bleed square, no baked-in corners.** The system applies the mask.
- **It has to work as a silhouette.** iOS 18 added Dark and Tinted appearances; iOS 26's Liquid Glass added Clear. In Tinted and Clear the system reduces the artwork to one color, so an icon that depends on shading or color to be recognizable disappears. This is the test that matters now.
- **Layers for Liquid Glass.** Icon Composer (Xcode 26+) takes a background and up to three foreground layers and applies glass lighting. Simple filled shapes work; fine detail and gradients do not.

What Lantern ships: a solid navy lantern silhouette cut out of a flat amber disc with a darker halo ring,
generated in Runway and snapped to the brand palette, at 1024 px with explicit Dark and Tinted variants in the
asset catalog. Source and preview sheet are in `docs/brand/icon/`. Next step when the Mac is connected: rebuild
the three layers (ground, disc and halo, lantern) in Icon Composer so Clear mode gets real glass.

## Color

- **Accent color** is Ink in light mode and slate blue in dark mode. System controls (toggles, links, prominent buttons) pick it up. Amber is never a button.
- **Amber (Glow)** is applied only to the selected tab, progress bars and the onboarding symbol, via explicit tint.
- **Semantic colors** Moss, Ember and Signal are asset colors with light and dark values, used only for status. Signal (true red) appears only for expired medicine.
- Everything else is system color so Dark Mode, Increase Contrast and Reduce Transparency work without extra code.

## Navigation and layout

- Five tabs via the iOS 18 `Tab` API. Each tab is a `NavigationSplitView` (`SplitContainer`) with a large title
  at the root: one column on a phone, two columns on the open iPhone Duo and iPad, where any window 600 points
  or wider is promoted to the regular width class. Push links in the sidebar open in the detail column.
- Game screens share one content margin (20 points), a 560-point maximum content width so boards stay
  reachable on wide screens, and a Dynamic Type cap at the largest non-accessibility size on boards with
  fixed cell sizes (`gameContent()`, `boardTypeCap()`).
- Toolbars use standard placements. Icon-only toolbar buttons carry accessibility labels.
- Lists are system `List` and `Form`, with `LabeledContent` for label and value pairs, so Dynamic Type, VoiceOver and swipe actions behave like every other iOS app.
- Empty states use `ContentUnavailableView` with a label, description and actions.
- Destructive actions are confirmed with a confirmation dialog, and delete swipes use `role: .destructive`.
- Sheets for create and edit, with Cancel and Save in the standard placements.
- Liquid Glass on iOS 26 arrives automatically for navigation bars, tab bars and toolbars when built with Xcode 26 or later. No custom blur or glass is used.

## Animated SF Symbols

Used to confirm something happened, never as decoration, and never looping where the user is reading:

| Where | Effect | Why |
|---|---|---|
| Onboarding welcome symbol | `.breathe` (iOS 18) | Gentle, ambient, the lantern is "on" |
| Item row category icon | `.bounce` on quantity change | Confirms "used one" |
| Scanner chips | `.bounce` when a barcode or date lands | Confirms the camera caught it |
| Scanner lookup | `.variableColor.iterative` while fetching | Activity without a spinner |
| Shopping list check | `.contentTransition(.symbolEffect(.replace))` | Circle to checkmark |
| Ready tab "covered" | `.bounce` when gaps reach zero | A small reward |
| Onboarding finish | `.bounce` once | Done |
| Game outcomes (`GameUI.outcome`) | `.bounce` once | A win, a draw, a round done, a word guessed |
| Trivia answer marks | `.bounce` once | Right or wrong, as the mark appears |
| Memory match tile | `.bounce` on match | Pair found; the card flip itself is off under Reduce Motion |
| Higher or lower arrows | `.bounce` per guess | The hint changed |
| Scavenger hunt rows, status text Copy | `.contentTransition(.symbolEffect(.replace))` | Circle to checkmark, copy to done |
| Dice and coin | `.bounce` on roll and flip | The result landed |
| Rock, paper, scissors hands | `.contentTransition(.symbolEffect(.replace))` | The reveal |
| Would you rather | `.bounce` on vote | Counted |
| Story twist | `.bounce` once as the twist appears | Something changed |

All symbol effects respect Reduce Motion automatically.

## Haptics

`sensoryFeedback` only on outcomes: `.success` when an equipment check is marked done or a name is picked, `.impact(.light)` on "Used 1" and on a game move, `.selection` on a vote. Nothing on navigation.

## Typography

System fonts throughout, so Dynamic Type and Bold Text work. Numbers that line up use `monospacedDigit()`.

## Still open

- Icon Composer `.icon` bundle for Clear mode (needs the Mac).
- VoiceOver pass on the scanner overlay.
- iPad as a sold platform (the layout now works there; the target is still iPhone-only).
- The hinge posture code has not run on a hinge.
- Widgets and Live Activities for "use this week" and outage mode.
