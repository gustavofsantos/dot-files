---
name: explainer
description: >
  Builds a single self-contained HTML page that teaches one concept interactively —
  the warm, clean, distraction-free house style (in the spirit of Anthropic's design).
  Use whenever the user wants to *learn something through a webpage* instead of a wall of
  text: "make me an interactive page about X", "teach me X with a webpage", "build an
  explainer for X", "an HTML page to understand Y", "canvas page about Z", or when an
  explanation would land better as a visual, interactive document than as prose. Output is
  one .html file (CSS + JS inlined) written to ~/engineering/canvas/, openable in Obsidian.
---

# Explainer

Build an **interactive HTML page that teaches one concept**, in a consistent warm, clean,
distraction-free style. The page replaces a wall of text — favor showing, interacting, and
progressive reveal over dumping prose.

## The one hard constraint

**A single, self-contained `.html` file.** All CSS in one `<style>`, all JS in one
`<script>`, both inline. The user opens these in Obsidian.

- **No network.** No `<script src="cdn…">`, no `<link>` web fonts, no external images.
  Need syntax highlighting, a chart, a diagram? Hand-roll it or inline it. Use system font
  stacks (below) and inline SVG.
- If you genuinely need an image, inline it as a base64 data URI or draw it with SVG/CSS.

## Where it goes

Write to `~/engineering/canvas/<kebab-topic>.html` (e.g. `~/engineering/canvas/how-tls-handshake-works.html`).
That directory auto-commits to the vault, so ship a finished page — no throwaway scaffolding.

## How to build one

1. **Start from the template.** Copy [references/template.html](references/template.html).
   It already contains the locked design tokens, the theme toggle, and one example of every
   component. It is also a living style guide — open it to see the house style.
2. **Replace the content, keep the system.** Swap in the real topic. Do **not** touch the
   `:root` / `[data-theme]` token blocks, the font stacks, or the layout width — those are
   what makes every page feel the same.
3. **Pick components per the teaching need** (see below). Use the fewest that carry the idea.
4. **Verify it renders.** Open the file and look at it (both themes). It must read cleanly,
   stay calm, and actually work when clicked.

## Design rules (locked)

The design tokens — warm light primary, warm dark toggle — live **only** in
[references/template.html](references/template.html); copy them from there verbatim, never re-pick.

- **Fonts (system only):** the template's body/heading/code stacks — no web fonts.
- **Reading column:** `max-width: 720px`, centered, generous padding. Body `~18px`, `line-height 1.7`.
- **Accent is a spice, not a sauce.** One accent color, used for links, the active step, one
  highlight per section. Color does not carry meaning the text doesn't already.
- **Calm > clever.** Whitespace, restraint, no gradients-for-decoration, no drop shadows
  beyond a hairline border. Motion only when it explains something; keep transitions ≤200ms
  and respect `prefers-reduced-motion`.

## Component palette (the tight set)

Reach for these; the template has a working copy of each. Don't invent a component zoo.

- **Lede** — one or two sentences under the title framing what the reader will understand.
- **Callout** — `note` / `tip` / `warning`, left accent border. For the one thing not to miss.
- **Steps** — numbered, for sequences and processes.
- **Collapsible** — native `<details>` for depth-on-demand (proofs, asides, "why").
- **Code block** — for code or structured data; pre-formatted, mono, `--code-bg`.
- **Key takeaway** — a closing card per section with the single sentence to remember.
- **Interactive demo** — the payoff. A small hand-rolled widget (slider, toggle, canvas,
  stepper) that lets the reader *change an input and see the idea move*. Prefer one good
  interaction over three static diagrams. See the template's demo for the wiring pattern.

## What "good" looks like

- A reader scrolls once and *gets it* — the interaction did work prose couldn't.
- It is quiet: no element competes for attention; the accent appears a handful of times.
- It works offline in a single file, in both themes, with no console errors.
