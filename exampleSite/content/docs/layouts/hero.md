+++
title      = "Hero banner"
weight = 40
layout     = "hero"
standfirst = "A banner plate over a large headline, for a page whose job is to make someone stay."
note       = "One column, always. A banner with a sidebar beside it is two claims on the same attention."
+++

The band above is the layout: a plate, a headline, a standfirst and one rule.

## Use it for

**A page that must announce itself before it explains itself.** An about page,
a manifesto, a statement of method, the top of a documentation set. The band
buys about two seconds of attention and spends them on an image and a sentence
rather than on the first paragraph of the body.

**A front door that is still a document.** Unlike the landing layout, a hero
page expects real prose underneath. The banner is the opening, not the whole
page.

## What it costs

Vertical space above the fold, which is the most expensive space on the page,
plus an image request in the critical path — the plate is `loading="eager"`
precisely because it is the thing the reader sees first, so it cannot be
deferred. A banner on a page nobody needed introducing is a screenful of
throat-clearing with a download attached.

## Where the plate comes from

`spectrum.banners` names a page bundle, and the layout takes its image
resources as a pool. Which one a page gets is a hash of the page's own
permalink modulo the pool size — different per page, identical on every build
of the same commit. `shuffle` would have re-rolled on every build and made the
same commit publish a different banner each time.

A page can override with `banner = "x.png"` in front matter, resolved against
its own bundle. Alt text comes from the plate's own resource params, so it
travels with the image rather than being written per page.

## Why the headline is under the plate, not over it

Every text colour in this theme is measured against the surface it sits on and
recorded in `tokens.css`. Nothing can make that promise against a photograph,
and a scrim dark enough to guarantee it would be a scrim dark enough to make
the image pointless.

## How it is chosen

`layout = "hero"`. `columns.html` forces one column for it, even inside a
branch — otherwise this page would have inherited the branch's aside and
rendered a 17rem hole beside the banner.
