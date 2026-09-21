# Contributing

## Two corpora, two jobs

Sample content is asked to do three things that pull against each other:

1. **Find bugs** — be unkind, hit the edges, break the model
2. **Be representative** — real shapes rather than tidy ones
3. **Persuade** — show why the theme is worth choosing

A corpus tuned for (1) is ugly, and nobody chooses a theme from it. A corpus
tuned for (3) is flattering, and a flattering corpus hides bugs. Asking one
body of content to do both produces something that is bad at both.

So this repository has two, and the split is deliberate:

| | `scripts/check.sh` fixtures | `exampleSite/` |
|---|---|---|
| job | find bugs | be representative, and persuade |
| content | synthetic, generated per run | written, and meant to be read |
| shape | adversarial — `notags`, `onetag`, `equal`, `outlier`, `many` | a working site with a real vocabulary |
| may be ugly | yes | no |
| may be flattering | no | yes |

`check.sh` builds its own fixtures from scratch on every run — a site with no
tags, a site with one, a site where every count is equal, a site with a
twenty-to-one outlier, a site with two hundred and twenty tags. They exist to
be hostile and they are thrown away immediately.

That is what frees `exampleSite/` to be attractive. The attacking is done
elsewhere, so the demo does not have to carry a deliberately awkward corpus in
order to keep the suite honest.

**Neither one covers for the other.** A bug found by reading the example site
is a fixture that was missing; add the fixture. A demo that has stopped
depicting what the theme is for is not fixed by a passing suite.

## Sparse is not degenerate

The fixtures cover zero, one, and all-equal. Those get written because they
announce themselves as edge cases.

They are not the cases that break things. In September 2026 the tag spectrum's
lightness ramp was found to be dividing by an interval the apex had already
left, so the documented ceiling was unreachable and the shortfall widened as
the corpus shrank — three bands used half the range they were specified to use.
It survived four releases with a suite that had zero-tag, one-tag and all-equal
fixtures, because **every fixture was either degenerate or large, and the bug
only showed in between.**

Three is the case nobody writes, and three is what every real new site is. When
adding a fixture, prefer sparse-but-plural to one-of-everything.

## The demo is the pitch

`exampleSite/` is the first and usually the only thing anyone reads before
deciding whether to use the theme. Whatever it depicts is what the theme is
understood to be for, and a well-written demo of the wrong thing is worse than
a thin demo of the right one, because it is persuasive.

Spectrum is for the founder, owner or operator building a personal brand. The
demo has to be that, and two properties are load-bearing rather than
decorative:

**The tag vocabulary is the product demo.** The index is legible as a field
because subjects are coloured by frequency, and resolution is the number of
*distinct counts* — so a vocabulary that ladders (one subject at 10 uses, one
at 7, one at 6, and so on) renders as a spectrum, and a flat vocabulary renders
as muted grey text. Shape the counts on purpose. `check.sh` fails the build if
the example site drops below four bands.

**The entries teach the register.** `claim` is the index's second line and it
should assert something; the fallback to `description` exists so a missing
claim costs a line of register rather than a hole in the column, and it is not
a licence to skip the field. Whatever the exemplars do, every consuming site
will do.

## Before you open a pull request

```sh
scripts/check.sh                                     # 47 assertions
hugo server --source exampleSite --themesDir ../.. --port 1314
```

Run the two build flags separately — combined, an idle partial becomes a broken
build:

```sh
hugo --gc --panicOnWarning --printPathWarnings
hugo --printUnusedTemplates
```

Every check in `check.sh` is written twice: once so it passes, once so it
fails. The second run is the only one that proves anything. A check anchored to
rendered output eventually loses its anchor and starts reporting "no findings"
as success, so the ones here fail when they match nothing.

## Commits

Conventional Commits, enforced by release-please. A subject that does not parse
is dropped from the changelog silently. See [RELEASING.md](RELEASING.md) — in
particular, squash from the CLI with `scripts/release-message.sh`, and check
that the generated body has not replayed the subject, which counts the same
change twice.
