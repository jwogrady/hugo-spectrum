+++
title      = "Landing page"
weight     = 50
layout     = "landing"
standfirst = "A page whose only job is to send you somewhere else."

[[params.sections]]
  title = "The journal"
  blurb = "Flat, dated, tagged. Reached through the index, the spectrum or the archive — never navigated."
  [[params.sections.items]]
    title = "Latest entries"
    url   = "/"
    blurb = "Twelve entries across four days, grouped by day with sticky heads."
  [[params.sections.items]]
    title = "Subject index"
    url   = "/tags/"
    blurb = "Every subject, coloured by how often it is used."
  [[params.sections.items]]
    title = "Date index"
    url   = "/archives/"
    blurb = "Every year, month and day that has an entry in it."

[[params.sections]]
  title = "Standing pages"
  blurb = "Hierarchical, weighted, navigated. A branch carries its own tree."
  [[params.sections.items]]
    title = "Docs"
    url   = "/docs/"
    blurb = "The procedure, the recording conventions, and how an entry is cited."
  [[params.sections.items]]
    title = "Plates"
    url   = "/plates/"
    blurb = "A page-bundle gallery: drop images beside index.md."
  [[params.sections.items]]
    title = "Contact"
    url   = "/contact/"
    blurb = "A form built entirely from front matter."
+++

## Use it for

**A front door, a section hub, an index of indexes.** Any page whose success is
measured by the reader leaving it quickly, in the right direction.

## What it costs

It is not a document. There is deliberately almost no prose here — the bands
above come from front matter, not from markup, so the page is data. A landing
page that has to be read has stopped being one, and should be a hero page
instead.

## When to use the hero layout instead

If the page has something to say, use `hero`: a banner and then real prose. Use
`landing` only when the content genuinely is a set of routes.

## How it is chosen

`layout = "landing"`, one column, with the bands declared as
`[[params.sections]]` and their links as `[[params.sections.items]]`.
