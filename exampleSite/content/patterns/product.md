+++
title       = "Reference cell Mk II"
description = "A sealed, thermally stabilised reference cell. The standard every calibration in the journal resolves back to."
layout      = "conversion"
weight      = 10
standfirst  = "The standard every calibration in the journal resolves back to."
claim       = "Drift under 0.1% per year, measured against an external standard twice annually — and the measurements are published."

sku            = "RC-MK2-001"
brand          = "Spectrum Instruments"
price          = "1850.00"
currency       = "USD"
currencySymbol = "$"
unit           = "cell"
availability   = "InStock"
offerNote      = "Lead time four weeks. Price excludes shipping and duty."
cta            = { label = "Request a quote", url = "/contact/" }
ctaLine        = "Every cell ships with its own calibration record."

[[features]]
  title = "Sealed and stabilised"
  body  = "Thermally controlled, never moved once installed. The enclosure holds its geometry to the resolution we can measure."
[[features]]
  title = "Traceable"
  body  = "Checked against an external standard twice a year. Each check is a journal entry with a citation handle that resolves forever."
[[features]]
  title = "Published drift"
  body  = "The drift figures are in the journal, not in a datasheet. You can read the week they were measured."

[[faq]]
  q = "What does the calibration record contain?"
  a = "Three runs against the external standard with a twenty-minute gap, the warm-up time used, and the ambient conditions. The same fields every entry in the journal carries."
[[faq]]
  q = "Why is the warm-up nineteen minutes?"
  a = "Because that is what it measured. The previous figure was eleven, inherited from the manual of the model this replaced, and it was wrong for six months — see [JRN 26-006](/r/26-006/)."
[[faq]]
  q = "Do you publish failures?"
  a = "Yes. A log that only records incidents reads, a year later, as though the instrument was broken continuously and briefly worked twice."
+++

The cell is the thing everything else is measured against, so the only claim
worth making about it is that its own drift is known — and the only way to
make that claim credibly is to publish the measurements rather than a summary
of them.

A `sku` in front matter is what makes this page a Product. The price,
currency and availability become an Offer attached to it, and the questions
below become an FAQPage in the same graph.

`rating` is a supported field and this page deliberately does not set one.
It is the only offer field that renders nowhere on the page — it exists purely
to emit an `AggregateRating` — so a demo carrying one ships a machine-readable
claim about what customers thought, invisible to anyone copying this directory
into a real site. A fictional business may make claims about its own
operations; it may not carry proof attributed to customers. The field is
exercised in `check.sh` against a fixture that is thrown away.
