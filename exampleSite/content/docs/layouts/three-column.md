+++
title  = "Three columns"
weight = 30
layout = "reference"
tags   = ["calibration", "instrumentation"]
+++

Main plus two asides: the second column is the first one again, so the frame
reads main + gap + aside + gap + aside and still sums to 72rem. The main
column lands at 29.53rem.

## Use it for

**Reference material that is consulted, not read.** A specification, a table of
parameters, a page a reader arrives at already knowing what they want. Look to
the left of this paragraph for the branch and to the right for the subject
field: both are live, and on this page both earn their space.

**Pages where the apparatus is the point.** If a reader needs the surrounding
structure as much as the text — where this sits, what it relates to — then two
columns of it is not excess.

## What it costs

Reading width, and the trade is deliberate. 29.53rem is under the 34rem
measure, which is roughly 55 characters instead of 64. Prose is measurably
worse here. Do not use three columns for anything anyone reads start to
finish.

**It also collapses hardest.** Below 60rem all three columns stack in source
order, so a phone gets the main column first and then two columns of
apparatus underneath it. On a narrow screen this layout is the one-column
layout with a long tail.

## How it is chosen

`layout = "reference"`, which `columns.html` maps to three. The layout fills
both asides itself, so a three-column page can never render an empty one.
