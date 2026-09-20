+++
title    = "Eleven minutes of telemetry we cannot account for"
date     = 2026-09-17T08:05:00-05:00
tags     = ["telemetry", "anomaly"]
archives = ["2026", "2026-09", "2026-09-17"]
aliases  = ["/r/26-003/"]
resolves = "JRN 26-003"
claim    = "The gap is in the recorder, not the instrument."
+++

Between 02:14 and 02:25 the stream contains nothing. Not zeros, not a flatline
— no rows. The instrument's own counter advanced normally across the interval,
which rules out the sensor and puts the loss downstream of it.

The recorder was rotating its own log at 02:14. It has rotated at 02:14 every
night for two years without eating anything, so the rotation is a coincidence
until it happens twice. It is written down here so that if it happens twice, we
find this entry instead of rediscovering it.
