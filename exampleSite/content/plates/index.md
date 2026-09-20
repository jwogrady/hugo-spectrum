+++
title  = "Plates"
layout = "plates"

[[resources]]
  src   = "01-bands.png"
  title = "Discrete bands"
  [resources.params]
    alt        = "Seven vertical bands climbing from deep red to green, each a flat block of colour with no blend between them."
    caption    = "Every distinct count is one band. Two subjects used equally often land on the same band and render identically."
    credit     = "Generated"
    shot_where = "tokens.css"
    shot_on    = "phi ladder"

[[resources]]
  src   = "02-bell.png"
  title = "The field"
  [resources.params]
    alt        = "A bright vertical core fading symmetrically into darkness at both edges."
    caption    = "Tag frequency as a Gaussian field. Only the most-used subject reaches white."
    credit     = "Generated"
    shot_where = "tags/field.html"
    shot_on    = "accentHue 355"

[[resources]]
  src   = "03-drift.png"
  title = "Monotonic climb"
  [resources.params]
    alt        = "A left-to-right colour climb crossed by twelve fine horizontal rules."
    caption    = "The ranked climb, ruled. A line always means the value changed."
    credit     = "Generated"

[[resources]]
  src   = "04-soak.png"
  title = "Thermal"
  [resources.params]
    alt        = "A radial bloom of warm colour off-centre to the left, falling away to near black."
    caption    = "Luminance carries frequency, so the signal survives without colour vision."
    credit     = "Generated"
+++

Plates are a page-bundle gallery: drop images beside this page's `index.md` and
each becomes a numbered plate with its own caption and credit. Titles, alt text
and credits come from the resource's own front matter, not from the filename.

These four are generated rather than photographed, so the theme's demo carries
no licensing questions with it.
