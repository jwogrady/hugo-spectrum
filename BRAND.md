# Spectrum — brand system

## Statement

Spectrum presents work the way a service publishes doctrine: numbered, dated,
ruled, and findable. It is built for a practical, opinionated founder shipping
AI-powered software for local businesses, and it is addressed to collaborators,
partners, vendors, talent and investors — people who need to assess substance
quickly and will not be moved by decoration.

**The governing idea: an authoritative field manual for future-facing work.**

## Five principles

1. **The index is the product.** The homepage is a publication index, not a
   pitch. A reader should be able to scan what exists and reach it in one click.
2. **Structure carries authority.** Rules, alignment, reference codes and
   consistent tables do the work that marketing language would otherwise attempt.
3. **Every signal must be readable at its dimmest.** Nothing is allowed to look
   good at the expense of being legible. Contrast is a measured value, not taste.
4. **Meaning never rides on hue alone.** Frequency is carried by *luminance*,
   which is perceivable independent of color vision — hue is identity, not
   data. Interaction state is carried structurally, by underline, border and
   outline. Exact counts live in the accessible name and on hover, and are
   printed on the subject index where the page is a reference rather than an
   instrument.
5. **Restraint is the differentiator.** The market this speaks to has seen every
   gradient. Precision reads as competence; ornament reads as compensation.

## Voice and tone

- **Label, don't sell.** "Journal — publication index", not "Insights & Ideas".
- **Date everything.** A claim without a date cannot be checked, and a claim
  that cannot be checked is decoration.
- **Prefer the concrete noun.** "Redirect map", not "migration strategy".
- **Correct in public.** Posts are immutable; corrections are new entries.
- **No exclamation, no hype adjectives, no second person imperative marketing**
  ("Unlock", "Supercharge", "Transform").
- Sentence case in prose. Uppercase only for genuine publication structure —
  table headers, band titles, eyebrows. Never for emphasis.

## Typography

| Role | Face | Why this one |
|---|---|---|
| Nameplate, formal headings, long-form reading, print | **Source Serif 4** | Transitional and institutional. Reads as a document rather than a magazine, and holds up at 10.5pt in print. |
| Navigation, tables, forms, operational headings | **Public Sans** | The US Web Design System face, Franklin-derived, drawn for government forms and dense tabular data. Rare outside `.gov`, so it does not read as a default. |
| Reference codes, numeric columns | **Source Code Pro** | Designed alongside Source Serif; tabular figures. Used only where alignment genuinely matters. |

**Overpass was evaluated and rejected.** Its Highway Gothic ancestry is
genuinely official, but that DNA is *wayfinding* — wide apertures and
distinctive terminals that get noisy in dense publication tables. Public Sans
was drawn for the actual use case. Inter was rejected for being the default of
the category this brand is distinguishing itself from.

Fonts are **self-hosted** (~156KB, latin, variable). A site arguing for platform
independence should not fetch its typography from a third party on every load.

**Scale** — `--size-2xs` 10.5px through `--size-4xl` 38px, every step
`phi^(1/3)` from the 17px reading size. Reading measure is `34rem`. Body
line-height 1.65; prose 1.72; headings 1.18–1.35. Three weights, named by
role: `--weight-title` 600, `--weight-label` 700, `--weight-quiet` 400.

**Capitalization** — uppercase carries `--tracking-eyebrow` (0.1em) and appears
only in band titles, table headers and eyebrows. Letter-spacing is negative on
display sizes (`-0.018em` nameplate) and never applied to body text.

## Color

Two palettes, each with a paper and a dark mode. Selected on `<html>`:

```html
<html data-palette="ultraviolet" data-theme="dark">
```

| | Community default | Ultraviolet preset |
|---|---|---|
| Canvas | field black `#121410` / paper `#F4F1EA` | deep black `#0B0B0F` / `#F6F5F8` |
| Primary text | bone `#E8E4DA` | bone `#E6E3DC` |
| Secondary | olive-gray `#8B9082` | military gray `#7E8578` |
| Active signal | amber `#E0A42A` | ultraviolet `#8E6FF7` |
| Focus | blue `#6FB8FF` | teal `#66E0D0` |
| Warning | amber | amber, held in reserve |

**Focus is deliberately off-hue in both palettes.** Blue and teal sit nowhere
near amber or violet, so a focus ring can never be mistaken for a frequency
signal. This is the single most important color decision in the system.

The tag spectrum bands by frequency. Each distinct count maps to one hue and
one brightness, both climbing together, so subjects used equally often render
identically — which is the truthful result, since they are equally used.
Giving ties different hues makes them look like distinctions they do not have.

Banding by count value rather than by rank matters: only the single highest
count sits at the apex where chroma collapses to white, so exactly one hue is
spent on a color nobody sees.

The cost is that a subject's color is not a stable identity — it moves when
its count moves. That is the correct trade for an index, where the question is
*what dominates*, not *which subject is this*.

Within that, the spectrum follows **black-body behavior**: the most-used subject is
near-white (full illumination, near-zero chroma), color emerges as subjects
cool away from the apex, and the rarest fade to a dim desaturated edge. Hue
never wraps the wheel — it blooms and recedes. This is why the apex is white
rather than colored: the most important subjects should be the most legible,
and an apex that is a hue reads as a choice rather than as a maximum.

Purple behaves as an instrument light: it appears in the warm band of the
frequency spectrum and on active links, and nowhere else. It is never a background, never
a gradient, never a decorative accent.

Every text token is measured against the surface it actually sits on and meets
WCAG AA. Ratios are recorded inline in `assets/css/tokens.css`.

## Layout and spacing

Space is a 4px grid named by role, not size: `--space-hair` through
`--space-major`. Two widths: `--page` (72rem, the publication) and `--measure`
(34rem, the reading column).

Radii are near-square (`2–3px`). Rounded components read as SaaS cards; this is
a publication. There are no drop shadows — a field manual has hairlines.

## Tables, forms, links, focus

- **Tables** are the house style. Uppercase `--size-2xs` headers over a 2px rule,
  1px rules between rows, no vertical rules, no zebra striping. Numerics right-
  aligned in the data face.
- **Forms** follow block-form discipline: label above, uppercase, small; field
  full width; hint below in `--ink-faint`.
- **Links** underline on hover at `--rule-bold` and hold one
  `--underline-offset` in every component. Visited is a distinct hue in every
  palette.
- **Focus** is one treatment everywhere, declared once in `base.css`: 2px solid
  `--focus`, 2px offset, never removed, never restated at higher specificity,
  never replaced by a color change alone.
- **Status** chips always carry a text label; color is redundant encoding.

## Crest, nameplate, portrait

- **Crest** sits upper-left, 2.75rem on screen, 34pt in print, with clear space
  of at least half its width on every side. It is `currentColor` and geometric
  — a mark, not heraldry. A site overrides it at `assets/brand/crest.svg`.
- **Nameplate** is Source Serif `--weight-title` at `--size-2xl`, `-0.018em`,
  with an optional uppercase standfirst beneath at `--size-2xs`, set like any
  other eyebrow. Crest, name and home link are
  one target.
- **Portrait**, where used, is treated as civic documentation: squared corners,
  1px rule, caption in the data face giving date and place. Never circular,
  never a floating avatar.

## Print

The paper palette is forced regardless of screen mode. Interface furniture is
removed. External URLs print after their link text in the data face. Tables keep
their rules and repeat headers across pages. The tag spectrum collapses to ink —
frequency survives because the count prints beside every subject.

## Three correct applications

1. **A Journal index row**: reference code in the data face, ISO date, serif
   title as the only link, claim beneath in `--ink-soft`, tag signals under that.
2. **A tag at minimum intensity**: still 6.4:1 against its canvas, still the same
   type size and weight as the apex tag, with its count printed beside it.
3. **A section header**: black band, uppercase `--size-2xs` title, entry count
   right-aligned in the data face. No icon, no illustration.

## Three traps

1. **The card grid.** Rounded, shadowed, three-across. It is the default of the
   category and it destroys the index reading. Use rows and rules.
2. **Ornamental militaria.** Stencil faces, camouflage, chevrons as decoration.
   The references are *publication systems*, not uniforms. Discipline comes from
   the information hierarchy, not from costume.
3. **A list pretending to be a field.** Ordering tags by frequency in a
   left-aligned wrap gives you a sorted list with color on it. The apex must
   sit in the *center*, with frequency falling away to both edges — the bell
   curve laid out in space as well as in luminance.
4. **Frequency as size.** The moment a common tag is set larger, the field
   becomes a word cloud and stops being an instrument. Size and weight are
   constant; only luminance and hue move.
