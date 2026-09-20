# Spectrum

**A field manual for work that has to be read, not skimmed.**

Spectrum is a Hugo theme for sites whose substance is text: a journal, a
catalog of what you do, a set of standing pages. It assumes nobody is going
to be tempted into reading by a hero image, and that the way to make dense
prose compelling is to give it the apparatus of a publication — dated,
numbered, ruled, findable — and then to spend the interest budget on the
index rather than on the page.

The index is where that budget goes. Every subject carries a colour derived
from how often it is used, so a table of fifty entries is legible as a field
before a word is read, and a headline is gradient-filled from its own
subjects, so it previews what it is about. Frequency is never type size and
never weight: the tables stay flat and scannable, and the colour does the
work that decoration usually does badly.

Spectrum is the presentation half of
[Pulse](https://github.com/jwogrady/hugo-pulse). It carries no content types,
no taxonomy and no URL structure; those belong to the site.

## Install

```
git submodule add https://github.com/jwogrady/hugo-pulse-spectrum \
  themes/hugo-pulse-spectrum
```

```toml
# hugo.toml
theme    = 'hugo-pulse-spectrum'
timeZone = 'America/Chicago'   # the publication's zone; see below

[params.spectrum]
  owner      = 'Your Name'
  standfirst = 'A short line under the nameplate'
  palette    = ''              # '' for the default, 'ultraviolet' for the preset
  timezone   = 'America/Chicago'  # must equal timeZone above

  [[params.spectrum.zones]]     # the clock's zone selector; first is the default
    label = 'CST'
    tz    = 'America/Chicago'
  [[params.spectrum.zones]]
    label = 'UTC'
    tz    = 'UTC'
```

Requires **Hugo 0.146+ extended** — built against 0.166.0. No Node, no npm,
no build step.

`timeZone` is not optional in practice. Unset, Hugo uses the build machine's
zone, so the same commit renders different times on a laptop and in CI.
Everything dated renders in the publication's zone: entry times, the day a
record files under, and the clock.

## The journal

**Days, not rows.** Entries group by day. Each day is a row group headed by
its own date and weekday, and that head sticks to the top of the viewport
while you scroll its entries, so whatever you are reading, the date it
belongs to is on screen. Newest first.

**Dates are navigation.** Every day head links to its own archive page, and
every day page carries previous and next. Both ends come from the taxonomy,
so navigation can never walk into an empty calendar.

**Lines mark time.** The only rule in the table is the one under each day
head. A horizontal line always means the date changed; everything else is
separated by space. There are no row rules, no boxes and no hover
backgrounds — the entry's own title underlines, in its own colour.

**References are permanent.** Each entry carries a citation handle,
`JRN 26-015`, assigned once and never renumbered, resolving at `/r/26-015/`.
It lives in front matter rather than on the page: a handle is for citing an
entry, not for reading on the way into one.

## The spectrum

Every distinct tag count becomes a band, and a band fixes hue and lightness
together — so two subjects used equally often render identically, always.
Colour climbs the wheel as frequency rises and only the most-used subject
reaches white. Ties cannot drift apart, because they are the same band.

Counts appear in the accessible name and on hover, so colour is never the
only channel. Type size and weight are identical at every frequency.

The sidebar carries the whole field, the date archive, and a mission clock
whose zone the reader can change — switching it re-renders the journal,
regrouping days in the new zone rather than moving times out from under
their dates.

## Layout

One frame, 72rem, on every page. Five layouts divide it; none of them
changes it, so the outer edges sit in the same place everywhere.

| layout | frame | use it for |
|---|---|---|
| one column | 72rem | entries, plates, flat pages — anything whose apparatus would be noise |
| two columns | 50.76 + 17 | the journal, tag results, a page in a branch — a reader still choosing |
| three columns | 29.53 + 17 + 17 | reference material that is consulted, not read |
| hero | 72rem | a page that must announce itself before it explains itself |
| landing | 72rem | a front door: a set of routes, not a document |

The third column is the aside again rather than a new width, so the frame
still sums to 72rem. It costs reading width — 29.53rem is under the 34rem
measure — which is the trade: two columns of apparatus are only worth it when
the apparatus is the point.

The hero is a banner made of type, rule and space. There is no image slot and
it does not break the frame; see the first paragraph of this README for why.
A landing page carries its bands in front matter rather than markup, like the
contact form, because a landing page is data.

`exampleSite/patterns/` has one page per layout, each built with the layout it
describes.

Both columns reserve their first slot — the breadcrumb on the left, the
clock's zone selector on the right — so a headline does not drop by the
trail's height the moment a page is nested, and the panels do not rise on
pages that have no selector. Navigating changes the contents of the columns
and nothing else.

## The ratio

One number governs the type scale, the space scale and the column frame.

```
phi      1.618034   the ratio
phi^1/2  1.272020   the space step — two steps make phi
phi^1/3  1.173985   the type step  — three steps make phi
```

Type is anchored on 17px, the reading size, not on 16px: this is a
publishing engine, so the size prose is set at is the size everything else
answers to. Space is a ladder stated by index (`--s1`..`--s18`) with roles
naming the steps the layout uses most. The frame is derived, not chosen: the
aside is the page over phi cubed, which lands on 17rem exactly.

`check.sh` fails the build on any length that is not a step on that ladder.

## Accessibility

Every text token is measured against the surface it sits on and meets WCAG
AA; ratios are recorded inline in `assets/css/tokens.css`. Frequency is
carried by luminance, perceivable independent of colour vision. Interaction
state is structural — underline, outline — so it can never be confused with
a frequency signal, and focus rings are deliberately off-hue in both
palettes. Motion is off by default and yields to `prefers-reduced-motion`.

Column heads are hidden from the page but kept in the markup: a screen
reader announcing "Time, 18:38" is how a data table is meant to work.
Repeated dates are clipped rather than removed, so a visually empty cell
still tells a screen reader which day its row belongs to.

## JavaScript

One script, ~4KB, inline in the footer. It runs the mission clock and lets
the reader put the publication into another zone. It is an upgrade to markup
that already renders correctly: with scripting off, the clock shows the date
the publication last changed and the zone selector is not offered, because a
control that cannot work should not be drawn. Nothing you can read, submit
or navigate depends on it.

## Weight

```
stylesheet   72.5 KB raw, 18.8 KB gzipped
fonts       148 KB — four latin variable subsets, self-hosted
script        4.2 KB inline
```

Deliberately not minified. Hugo's CSS minifier strips whitespace after a
closing paren, which is safe for `calc()` but not for `var()`: substitution
happens after parsing, so `var(--rule-hair)solid` becomes `1pxsolid` and the
declaration is dropped. It silently broke every border, the focus ring and
twelve padding shorthands. Gzip recovers most of the difference.

## Example site

`exampleSite/` is the demo and review harness. It supplies the content types,
taxonomy and URLs the theme deliberately does not carry, and it exercises every
template the theme ships — so `--printUnusedTemplates` reports nothing.

```
hugo server --source exampleSite --themesDir ../..
```

The two shapes a Spectrum site has, side by side:

**The journal** is `posts` — flat, dated, tagged, never navigated. Twelve
entries across four days, with a tag distribution chosen to put six distinct
bands on the field and only one subject at the apex. You reach an entry through
the index, the spectrum or the date archive.

**Docs** is a branch — hierarchical, weighted, navigated. An introduction and
three child pages, with the aside carrying the branch on every page in it and
the current page marked. Order comes from `weight`, not the filename.

**Patterns** is one page per layout — one column, two, three, hero and landing
— each built with the layout it documents, so the three-column page really has
three columns.

Also a page-bundle gallery, a contact form built from front matter, the masthead
menu, and a citation handle resolving at `/r/26-002/`. The plate images are
generated rather than photographed, so the demo carries no licensing questions.

## Checks

```
scripts/check.sh
```

34 assertions, each written twice — once so it passes, once so it fails.
The second run is the only one that proves anything. They cover the tag
field at its edges (no tags, one tag, all counts equal, a single extreme
outlier, hundreds of tags), build determinism, and a long tail of structural
invariants: every length on the ladder, every line-height a token, every
class in the markup backed by a rule, every palette tuning its own tags for
its own surface, braces balanced, the reserved slots holding their height.

Several exist because a check went blind. A check anchored to rendered
output eventually loses its anchor and starts reporting "no findings" as
success — so the ones here fail when they match nothing.

Run the two build flags separately:

```
hugo --gc --panicOnWarning --printPathWarnings
hugo --printUnusedTemplates
```

`--printUnusedTemplates` reports partials the build never reached, which is
information; `--panicOnWarning` turns a warning into a failure, which is
correctness. Combined, an idle partial becomes a broken build.

## Customising

See [TOKENS.md](TOKENS.md). Nothing requires forking: palettes, the spectrum
shape, typography and every colour are CSS custom properties or site params.
[BRAND.md](BRAND.md) documents the design system and the reasoning.

## Contract

A consuming site must contain no layouts and no CSS, and swapping this theme
for another must still render every content type. If that breaks,
presentation has leaked into content.

## Not in this version

- **Media in layouts.** Plates are a page-bundle gallery; entries take a
  featured image and nothing else. Figures, captions in the flow, and media
  as a first-class part of an entry are v2.
- **The build pipeline.** The stylesheet is concatenated and fingerprinted,
  not minified or split. Critical CSS, per-page bundles and a minifier that
  understands `var()` are v2.
- Verified in a Chromium-family browser only.

## Known issues

- Visited tag signals can collapse to the apex hue in some engines
  ([#1](https://github.com/jwogrady/hugo-pulse-spectrum/issues/1)). Custom
  properties set inline do not reach the restricted `:visited` pass.

## License

MIT — see [LICENSE](LICENSE). Bundled typefaces are SIL OFL 1.1; see
[assets/fonts/LICENSES.md](assets/fonts/LICENSES.md).
