+++
title      = "Hero banner"
weight     = 40
layout     = "hero"
standfirst = "A banner built from type, rule and space — because the argument of this theme is that nobody was ever tempted into reading by a photograph."
note       = "One column, always. A banner with a sidebar beside it is two claims on the same attention."
+++

The band above is the layout. Size, one rule, and the space around it — no
image slot, and the frame is not broken to the viewport edge.

## Use it for

**A page that must announce itself before it explains itself.** An about page,
a manifesto, a statement of method, the top of a documentation set. The band
buys about two seconds of attention, and it spends them on a sentence rather
than a stock photograph.

**A front door that is still a document.** Unlike the landing layout, the hero
page expects real prose underneath. The banner is the opening, not the whole
page.

## What it costs

Vertical space above the fold, which is the most expensive space on the page.
A banner on a page nobody needed introducing is a screenful of throat-clearing.

## Why there is no image

Spectrum's premise, stated in the first paragraph of its README: the way to
make dense prose compelling is to give it the apparatus of a publication, not
a photograph. An image hero would also be the only element on the site that
breaks the 72rem frame, so it would be the one page whose outer edges move.

## How it is chosen

`layout = "hero"`. `columns.html` forces one column for it, even inside a
branch — otherwise this page would have inherited the branch's aside and
rendered a 17rem hole beside the banner.
