+++
title    = "Drift is not noise"
date     = 2026-09-18T11:15:00-05:00
tags     = ["drift", "telemetry", "calibration"]
archives = ["2026", "2026-09", "2026-09-18"]
aliases  = ["/r/26-007/"]
resolves = "JRN 26-007"
claim    = "Averaging a drift produces a number that was never true."
+++

Noise is symmetric about the thing you want and averages away. Drift is not
symmetric about anything and averages into a value the instrument held for
exactly one instant somewhere in the middle of your window.

We have been reporting daily means for six months. The daily mean of a
monotonic drift is the reading from lunchtime, and we have been calling it the
day.
