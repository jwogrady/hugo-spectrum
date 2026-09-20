+++
title       = "Patterns"
description = "Conversion pages: products, services, booking, and the landing page that routes to them."
+++

The third shape. The journal is time-series, sorted by taxonomy; docs are
hierarchical; these are the pages that ask for something.

Each one declares what it is in front matter, and that declaration builds both
the page and its structured data — a `sku` makes a Product with an Offer, a
`serviceType` makes a Service, a `bookingUrl` makes a Service you can reserve.
The page a reader sees and the graph a crawler reads come from one source, so
they cannot drift apart.
