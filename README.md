# Spectrum

**A field manual for work that has to be read, not skimmed.**

Spectrum is a Hugo theme for sites whose substance is text: a journal, a
catalog of what you do, a set of standing pages. It assumes no entry is going
to be read because of a picture at the top of it, and that the way to make
dense prose compelling is to give it the apparatus of a publication — dated,
numbered, ruled, findable — and then to spend the interest budget on the
index rather than on the page.

That is a claim about the journal, where the reader has already arrived. A
front door is a different job: the hero and landing layouts carry a banner
plate, because a page whose work is to make someone stay has to do something
in the first screen.

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
git submodule add https://github.com/jwogrady/hugo-spectrum \
  themes/hugo-spectrum
```

```toml
# hugo.toml
theme    = 'hugo-spectrum'
timeZone = 'America/Chicago'   # the publication's zone; see below

[params.spectrum]
  owner      = 'Your Name'
  standfirst = 'A short line under the nameplate'
  palette    = ''              # '' for the default, 'ultraviolet' for the preset
  copyright  = ''              # the legal entity, when it is not `owner`
  themeCredit = true           # false removes the theme's line from the foot
  timezone   = 'America/Chicago'  # must equal timeZone above

  [[params.spectrum.zones]]     # the clock's zone selector; any order
    label = 'CT'
    tz    = 'America/Chicago'
  [[params.spectrum.zones]]
    label = 'UTC'
    tz    = 'UTC'
  [[params.spectrum.zones]]     # 'local' is the reader's own machine zone
    label = 'Local'
    tz    = 'local'
```

`tz` is an IANA zone name, or the sentinel `local` for whatever zone the
reader's machine is in. Order them however you like — geographically, in the
example site. The one rule is that `timezone` above must appear somewhere in
the list, or a reader who switches away can never get back to the zone the
archive pages are built in.

Readers do not land on the first entry. If any listed zone keeps their
machine's own wall clock — matched on January *and* July, so it follows the
DST rule and not just the current offset — they land on `local`, and both
buttons light, because both are true. If none does, they land on `UTC`: an
instrument log is not local to a reader it does not cover, and pretending
otherwise files its days under a calendar the archive pages do not have. List
`UTC` if you want that fallback; without it the first entry is used instead.
The page is always *served* in `timezone`, whatever the reader later picks.

Prefer a `label` that names the zone (`CT`) over one that names an offset
(`CST`): the clock prints the abbreviation actually in force, so a `CST` button
reads `CDT` for two thirds of the year.

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

The sidebar carries the whole field, the date archive, and a mission time
whose zone the reader can change — switching it re-renders the journal,
regrouping days in the new zone rather than moving times out from under
their dates.

## Layout

One frame, 72rem, on every page. Six layouts divide it; none of them changes
it, so the outer edges sit in the same place everywhere.

| layout | frame | use it for |
|---|---|---|
| one column | 72rem | entries, plates, flat pages — anything whose apparatus would be noise |
| two columns | 50.76 + 17 | the journal, tag results, a page in a branch — a reader still choosing |
| three columns | 29.53 + 17 + 17 | reference material that is consulted, not read |
| hero | 72rem | a page that must announce itself before it explains itself |
| landing | 72rem | a front door: a set of routes, not a document |
| conversion | 72rem | products, services and booking — a page that asks for something |

The third column is the aside again rather than a new width, so the frame
still sums to 72rem. It costs reading width — 29.53rem at a full frame, under
the 34rem measure — which is the trade: two columns of apparatus are only
worth it when the apparatus is the point. It engages at 72rem rather than the
60rem two columns use, because two asides and two gaps take 42.47rem before
the main column gets any: below that the middle column is narrower than the
sides and the hierarchy reads backwards.

The hero is a banner plate above a large headline. The plate is drawn from a
page bundle named by `spectrum.banners`, chosen per page from a hash of the
page's own path — not shuffled, so a commit builds the same banner every time.
A page can name its own with `banner = "x.png"`. Text is never set over the
plate: the palettes guarantee contrast against a surface token and nothing can
guarantee it against a photograph. The band keeps the frame.
A landing page carries its bands in front matter rather than markup, like the
contact form, because a landing page is data.

`exampleSite/docs/layouts/` documents one, two and three columns and the hero,
each page built with the layout it describes. The landing and conversion
layouts are shown working under `exampleSite/patterns/` instead.

Both columns reserve their first slot — the breadcrumb on the left, the
clock's zone selector on the right — so a headline does not drop by the
trail's height the moment a page is nested, and the panels do not rise on
pages that have no selector. Navigating changes the contents of the columns
and nothing else.

## Structured data

Every page carries a JSON-LD graph. It is built as Hugo maps and handed to
`jsonify`, never written out as JSON in a template — a title like
`The "drift" problem` ends a hand-written string early and silently drops the
whole graph.

The graph always names the publication and the page. What else it carries is
keyed off the front matter the page declares, so the page a reader sees and
the graph a crawler reads are built from one source and cannot drift:

| front matter | graph |
|---|---|
| a dated entry in `posts` | `BlogPosting`, with its tags as keywords and its citation handle as `identifier` |
| a page inside a branch | `TechArticle` |
| `sku` | `Product` with `Offer`, and `AggregateRating` if `rating` is set |
| `serviceType` | `Service` with `Offer`, `areaServed` and the site as `provider` |
| `bookingUrl` | the `Service` gains a `ReserveAction` with an `EntryPoint` |
| `faq` | `FAQPage`, from the same list the page renders |
| `form` | `ContactPage` |
| any nested page | `BreadcrumbList`, from the same ancestry the visible trail uses |

The block is `safeJS`. Without it Go's `html/template` treats the script body
as JavaScript and quotes the whole document, so the page carries a JSON
*string* whose value is the graph. It parses, round-trips and validates —
which is why `check.sh` asserts the shape rather than the validity.

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

Visited state never touches hue or brightness. Browsers resolve `:visited`
through a separate restricted pass that inline custom properties do not reach,
so an anchor carrying its own `--tag-hue` loses it once clicked and repaints at
the apex — every visited subject the same colour, and the frequency signal
gone. The channels are therefore emitted on the inner span and the anchor is
`color: inherit`: the restricted pass applies to the link element, not to its
descendants, so a tag looks identical before and after it is clicked. Visited
is marked by the anchor's border, which is a property that pass does allow.
Repeated dates are clipped rather than removed, so a visually empty cell
still tells a screen reader which day its row belongs to.

## JavaScript

One executable script, ~4KB, inline in the footer. The JSON-LD block is a
`<script>` element that runs nothing, and the check counts accordingly. It drives the mission time and lets
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

**Patterns** is the third shape: conversion pages. A product with an offer and
a rating, a service, a booking with a reservable action, and a landing page
routing to all three. Each declares what it is in front matter, and that one
declaration builds both the page and its structured data.

The layout reference lives under Docs, at `/docs/layouts/`, where each page is
built with the layout it documents — and where the branch nests two levels
deep, which is what the child navigation is for.

Also a page-bundle gallery, a contact form built from front matter, the masthead
menu, and a citation handle resolving at `/r/26-002/`. The plate images are
generated rather than photographed, so the demo carries no licensing questions.

### Deploying the demo

`netlify.toml` builds `exampleSite/` and publishes `public/`. The one awkward
part is the theme path: the site asks for a theme named `hugo-spectrum`, and
Netlify checks the repository out at `/opt/build/repo`, so the lookup misses.
The build makes a themes directory elsewhere holding a symlink under the name
the site asks for — the same move `check.sh` makes, and for the same reason.
It goes outside the repository so nothing points a directory at its own
ancestor.

`baseURL` comes from the deploy context: `$URL` in production,
`$DEPLOY_PRIME_URL` for previews and branch deploys. The context also decides
the Hugo environment, and `layouts/robots.txt` is what reads it — a production
build invites indexing, anything else refuses it, so a preview cannot compete
with the site it is a copy of. Both directions are checked.

Hugo **extended is not required**: the stylesheet is plain CSS through Pipes,
not Sass. `HUGO_VERSION` pins the version CI builds against rather than the
floor in `theme.toml`.

No `TZ` is set. Every rendered date goes through `params.spectrum.timezone`
rather than the build machine's zone, so the deploy and CI agree by
construction.

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

## License

Copyright © 2026 Status26, Inc. Written by jwogrady.

MIT — see [LICENSE](LICENSE). Bundled typefaces are SIL OFL 1.1; see
[assets/fonts/LICENSES.md](assets/fonts/LICENSES.md).
