# Overriding Spectrum

Nothing here requires forking the theme. All of it is configuration or CSS
custom properties.

## Pick a palette

```toml
# hugo.toml
[params.spectrum]
  palette = "ultraviolet"   # omit, or "default", for the community palette
  theme   = ""              # "dark" | "light" | "" to follow the OS
  owner   = "Your Name"    # nameplate
  standfirst = "A short line under the nameplate"
```

## Set the publication's timezone

```toml
# hugo.toml
timeZone = 'America/Chicago'      # Hugo's own setting: entry times and day grouping

[params.spectrum]
  timezone = 'America/Chicago'    # must equal timeZone above — the clock reads this

  [[params.spectrum.zones]]       # the clock's selector; the first is the default
    label = 'CST'
    tz    = 'America/Chicago'
  [[params.spectrum.zones]]
    label = 'UTC'
    tz    = 'UTC'
```

`timeZone` is not optional in practice. Unset, Hugo uses the build machine's
zone, so the same commit renders different times on a laptop and in CI.

The two settings are checked against each other: Hugo's `timeZone` governs
what the templates render, and `spectrum.timezone` is what the clock script
reads at runtime. The first entry in `zones` must be the publication's own
zone, or the clock disagrees with the dates beneath it on first paint.

Drop `zones` entirely and the selector is not rendered — the clock still
runs, in the publication's zone.

## Resize the scale

Type, space and the column frame all come from one ratio. The ladder is
stated by index in `tokens.css` (`--s1`..`--s18`) with roles naming the steps
the layout uses most, and `check.sh` fails the build on any length that is
not a step on it.

```css
:root {
  --s9:  1rem;        /* the anchor — the whole ladder moves with it */
  --page: 72rem;      /* the frame; the aside is this over phi cubed */
  --measure: 34rem;   /* the reading column, set by character count */
}
```

`--measure` is the one width the ratio does not set: a reading column is
governed by how many characters fit, not by geometry.

## Shape the spectrum

```toml
[params.spectrum]
  tagHueSpan     = 180    # 180 = the full color wheel; lower confines it to an arc
  tagBandCeiling = 0.68   # how much of the lightness ramp the non-apex bands use
```

Every distinct tag count becomes one band, and a band fixes both hue and
lightness. Two subjects used equally often therefore render identically,
because they are identical.

`tagBandCeiling` is the one knob worth touching. Non-apex bands occupy the
lower part of the lightness ramp so the apex has somewhere brighter to sit.
Raise it and the bands spread further up, crowding the apex and washing the
top of the range toward white. Lower it and the bands compress into the
darker half, keeping color but losing separation.

Banding by distinct count is also the outlier defense: a subject used two
hundred times is simply the next band above one used nineteen times, so a
single dominant tag costs one band rather than compressing everything below
it.

**If you change the lightness or chroma tokens, re-measure.** Contrast is
tight at the dim end — the shipped values clear AA with roughly 5.4:1 to
spare at worst, and the margin is smaller than it looks because chroma is at
full strength for every band except the apex.

## Rotation

```toml
[params.spectrum]
  tagRotate        = false
  tagRotateSeconds = 240
```

Animates `--tag-apex-hue` through one revolution. Brightness never changes,
so the frequency reading holds while the color moves. Off by default — a
community theme should not animate at rest — and it yields to
`prefers-reduced-motion`.

## Re-key everything else

Override any token in your own stylesheet. The full set is documented inline in
`assets/css/tokens.css`, grouped as: type, space, rules, canvas and surface,
text, rules and borders, links, focus, layering, motion, status, disabled, and
the tag spectrum.

Nothing in the stylesheets spells a weight, a tracking, an underline offset, a
z-index or a duration as a literal, so re-keying any of these moves every
component that uses it:

| Token | What it governs |
|---|---|
| `--weight-title` / `--weight-label` / `--weight-quiet` | 600 / 700 / 400 — serif titles, uppercase labels and nav, secondary figures |
| `--tracking-title` | serif titles set at body scale (index rows, plate titles) |
| `--tracking-ref` | reference codes, numerals and compact chip UI |
| `--underline-offset` | one offset for every underline in the theme |
| `--panel-pad` | the body padding shared by the clock, branch, spectrum and archive panels |
| `--z-panel` / `--z-band` / `--z-masthead` / `--z-skip` | 1 / 2 / 10 / 20 — everything that overlaps anything |
| `--motion-quick` | the one transition duration |
| `--tag-glow-radius` | how far the apex glow reaches; `--tag-glow-max` is how much of it a subject gets |
| `--signal-hover` | the fill a filled control takes on hover — see below |

`--signal-hover` exists because the direction is not the same in both modes: on
paper a filled control has to **darken** (the label on it is the paper colour),
and on a dark canvas it **brightens**. The paper palettes alias it to
`--link-hover` and the dark palettes to `--signal-bright`. Using
`--signal-bright` in both dropped the button label to 3.70:1 on the default
paper palette, under AA.

```css
:root {
  --font-serif: 'Your Serif', Georgia, serif;
  --signal: #0F766E;
  --measure: 38rem;
}
```

**If you change a text or surface color, re-measure it.** Every value shipped
here has a contrast ratio recorded beside it in the token file. Run
`scripts/check.sh` after any change to the tag spectrum.

## Replace the crest

Drop an SVG at `assets/brand/crest.svg` in your site. It should use
`currentColor`, carry `class="crest"`, and be square. The theme's geometric
fallback is used if the file is absent.

## Checks

```bash
themes/hugo-pulse-spectrum/scripts/check.sh
```

Builds fixture sites covering no tags, one tag, equal counts, an extreme
outlier, hundreds of tags, and build determinism, then runs the real site with
warnings fatal.
