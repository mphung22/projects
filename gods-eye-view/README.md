# God's Eye View — research pack

Notes on the two videos you sent, plus the reference material behind them.
Scraped 2026-09-16.

The videos are both from **Bilawal Sidhu** (ex-Google Maps PM, TED tech curator)
and both about **God's Eye View** — his open-source "spy-satellite simulator in
your browser, except the data is real." It hit #1 on GitHub Trending in August
2026.

## What's here

| File | What it is |
|---|---|
| [video-notes/01_hormuz-chokehold.md](video-notes/01_hormuz-chokehold.md) | *Ex-Google PM Uses God's Eye to Reveal Iran's Chokehold on the World's Oil* (Apr 3, 2026 · 692K views) — chapter map, the data layers used, and the analysis method broken out as a reusable template |
| [video-notes/02_walkthrough.md](video-notes/02_walkthrough.md) | *God's Eye View Blew Up. Here's What You Can Do With It.* (Sep 8, 2026 · 1.95M views) — the hands-on walkthrough: install paths, features demoed, and where coverage honestly breaks down |
| [project-reference.md](project-reference.md) | The app itself, condensed from the official repo: all 15 layers, keys and real costs, architecture, security posture, env vars |
| [series-index.md](series-index.md) | All 9 videos in the series, with which question each one answers |
| [build-ideas.md](build-ideas.md) | What to actually build on top — including how to get it onto an iPhone, and a real-estate layer that uses the data pipelines already in this repo |

## The two videos in one paragraph each

**#3, Hormuz.** Sidhu turns on ship tracking and watches the Strait of Hormuz go
dark — transits dropping from hundreds a day to a handful, sometimes none — and
builds out the layers needed to explain it: AIS tracking, dark-vessel detection
by AIS gap analysis, pipeline bypass routes, Brent/WTI futures, OSINT strike
tracking, before/after imagery, and critical infrastructure including the
desalination plants nobody else was covering. It's the episode where the toy
becomes an analysis tool.

**#9, the walkthrough.** Made after the repo blew up, answering "how do I run
this if I'm not a coder." Pinokio one-click or `npm ci && npm run dev`, then
flight tracking, cockpit ride-alongs, ~3,600 public cameras projected into the
3D city, voice control over 28 tools, recorded camera tours, fires and
earthquakes and submarine cables, and a Nepal flood reconstruction. Plus a
ready-made prompt for handing the whole install to a coding agent.

## One honest gap

**Spoken transcripts could not be retrieved.** youtube.com, every third-party
transcript service, and the creator's newsletter are all blocked by this
environment's network egress policy, and YouTube's transcript endpoint refuses
unauthenticated requests. What got through: YouTube's InnerTube API (titles,
channel, dates, view counts, full descriptions, chapter lists, the playlist) and
`raw.githubusercontent.com` for the project's own README, SECURITY.md,
DATA_SOURCES.md, .env.example and package.json.

So these notes are built from official metadata and the project's own
documentation — accurate, but not quote-level on what's said out loud. Nothing
was inferred to paper over that. If you want the spoken detail, open each video
in the YouTube app on your phone, ⋯ → **Show transcript**, and paste it into the
relevant file under `video-notes/` — the structure is already there to receive
it.
