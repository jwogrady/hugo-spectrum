+++
title       = "Contact"
layout      = "contact"
description = "How to reach the log, and what happens to what you send."

[params.form]
  name     = "contact"
  netlify  = true
  submit   = "Send"
  note     = "Every field is required unless marked optional."

  [[params.form.fields]]
    name         = "name"
    label        = "Name"
    required     = true
    autocomplete = "name"

  [[params.form.fields]]
    name         = "email"
    label        = "Email"
    type         = "email"
    required     = true
    autocomplete = "email"
    hint         = "Used to reply, and for nothing else."

  [[params.form.fields]]
    name     = "subject"
    label    = "Subject"
    type     = "select"
    required = true
    options  = ["Correction", "Calibration record request", "Something else"]

  [[params.form.fields]]
    name        = "message"
    label       = "Message"
    type        = "textarea"
    required    = true
    rows        = 8
    placeholder = "Entry reference, if you have one."

  [[params.form.fields]]
    name     = "affiliation"
    label    = "Affiliation"
    required = false
+++

Corrections to a published entry are made in place, with the change and its
date recorded at the foot of the entry. Entries are never silently edited and
never deleted — a citation handle that resolved once resolves forever.

The aside you are reading is this page's own content; the form is built from
front matter.
