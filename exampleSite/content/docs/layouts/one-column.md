+++
title   = "One column"
weight = 10
columns = "one"
+++

One column, the full width of the frame, with no aside beside it.

## Use it for

**Anything whose apparatus would be noise.** A single journal entry, a flat
standing page, a gallery. The reader arrived to read one thing; a sidebar of
subjects and dates is a set of invitations to stop.

**Pages reached from somewhere, not browsed toward.** An entry is found through
the index, the spectrum or the archive. By the time a reader is on it, the
navigation has already done its job, and repeating it beside the prose is
offering a map to someone who has arrived.

## What it costs

No cross-navigation. A reader who finishes has the breadcrumb and the masthead
and nothing else, so a one-column page must either end somewhere useful or be
somewhere a reader leaves deliberately.

## When an entry should not have it

The argument above assumes the reader arrived through the index. Where a
publication expects them to arrive on an entry directly — from a citation
handle, a search result, a link from somewhere else — the navigation has not
done its job yet, and a page with no apparatus is a dead end rather than a
clean one.

`entryAside` is that case, and the trade is the one this page opens with:
the reader gets the spectrum and the archive, and also gets the invitations
to stop.

```toml
[params.spectrum]
  entryAside = true
```

## How it is chosen

Default for entries, plates and flat pages, or `columns = "one"` in front
matter to force it — which is what this page does, since it lives in a branch
and would otherwise have the branch beside it.

Front matter wins over `entryAside`, so a publication that has opted in can
still take the aside off one page.
