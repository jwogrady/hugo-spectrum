+++
title       = "Book bench time"
description = "Reserve a slot on the optics bench or in the thermal chamber."
layout      = "conversion"
weight      = 30
standfirst  = "Reserve a slot on the optics bench or in the thermal chamber."
claim       = "Slots are half-days. Nobody has ever finished a thermal soak in two hours."

serviceType    = "Laboratory bench hire"
areaServed     = "On site"
bookingUrl     = "https://example.org/contact/?slot={slot}"
price          = "180.00"
currency       = "USD"
currencySymbol = "$"
unit           = "half-day"
availability   = "LimitedAvailability"
offerNote      = "Chamber time is booked overnight and charged as two slots."
cta            = { label = "Check availability", url = "/contact/" }
ctaLine        = "Bring your own fixtures, or ask and we will tell you what we have."

[[features]]
  title = "Optics bench"
  body  = "Breadboard, rebuilt in the order the beam travels. Four fewer mounts on it than it had in September."
[[features]]
  title = "Thermal chamber"
  body  = "Twelve hours at 45C is a normal cycle. Its logger writes local time without an offset, so bring your own clock."
[[features]]
  title = "Vacuum station"
  body  = "Pulldown to 4.1e-6 torr in nineteen minutes, which is the figure from the day the seal was changed."

[[faq]]
  q = "Can I book less than a half-day?"
  a = "No. Setup and teardown eat an hour at each end, and a two-hour slot is an hour of work."
[[faq]]
  q = "What makes this a booking page rather than a service page?"
  a = "The `bookingUrl`. It adds a ReserveAction to the Service in the graph, which is the difference between describing something and offering to schedule it."
+++

Bench time is the one thing here that is genuinely scarce, so the page says
what a slot is and what it costs before it asks for anything.

`bookingUrl` is what makes this a booking. In the structured data the Service
gains a `potentialAction` of type `ReserveAction`, with the URL as its entry
point — a machine reading this page can tell that a reservation is possible,
not merely that a service exists.
