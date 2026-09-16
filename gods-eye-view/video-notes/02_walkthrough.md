# God's Eye View Blew Up. Here's What You Can Do With It.

| | |
|---|---|
| **Channel** | Bilawal Sidhu |
| **Published** | Sep 8, 2026 |
| **Views at scrape** | 1,951,045 |
| **Runtime** | ~27 min (last chapter starts 25:55) |
| **URL** | https://www.youtube.com/watch?v=o_FJ1NIH9yw |
| **Series** | God's Eye View / "Mapping the World" — video 9 of 9, the newest |
| **Scraped** | 2026-09-16 |

## What the video is

The hands-on walkthrough, made after the project **hit #1 on GitHub Trending**.
Two questions kept coming in — *how do I run this if I'm not a coder*, and *can
you give a proper walkthrough* — and this answers both: from installation to
tracking aircraft and ships, riding along in a cockpit, exploring public
cameras, driving the globe by voice, recording camera tours, and building your
own tools on top of it. It also covers **where the data comes from, what's
actually live, and where coverage breaks down.**

This is the one to work through with the app open next to you.

## Chapter map

| Time | Chapter | What you get |
|---|---|---|
| [0:00](https://www.youtube.com/watch?v=o_FJ1NIH9yw&t=0s) | God's Eye View Blew Up | #1 GitHub Trending, Product Hunt, the reaction |
| [1:06](https://www.youtube.com/watch?v=o_FJ1NIH9yw&t=66s) | Install God's Eye View | Pinokio one-click, or terminal/coding-agent |
| [2:08](https://www.youtube.com/watch?v=o_FJ1NIH9yw&t=128s) | The Interface, Flight Tracking & Radio | Panels, layers, live aircraft, the radio layer |
| [5:51](https://www.youtube.com/watch?v=o_FJ1NIH9yw&t=351s) | Contacts Mode & Cockpit View | 250 km roster; drop into any aircraft |
| [7:47](https://www.youtube.com/watch?v=o_FJ1NIH9yw&t=467s) | Control the World With Your Voice | The OpenAI realtime agent — 28 tools |
| [11:25](https://www.youtube.com/watch?v=o_FJ1NIH9yw&t=685s) | Area 51 Easter Egg | — |
| [12:40](https://www.youtube.com/watch?v=o_FJ1NIH9yw&t=760s) | Traffic & Public Cameras | ~3,600 CCTV feeds projected *into* the 3D scene |
| [15:55](https://www.youtube.com/watch?v=o_FJ1NIH9yw&t=955s) | Track Ships & Ride Along With Flights | AIS vessels, wake trails, flight ride-alongs |
| [19:55](https://www.youtube.com/watch?v=o_FJ1NIH9yw&t=1195s) | Record Your Own Camera Tours | Scene director — cinematic capture |
| [21:06](https://www.youtube.com/watch?v=o_FJ1NIH9yw&t=1266s) | Fires, Earthquakes & the Physical Internet | FIRMS, USGS, submarine cables + datacenters |
| [24:18](https://www.youtube.com/watch?v=o_FJ1NIH9yw&t=1458s) | Reconstructing Nepal Floods | Event reconstruction — the case study |
| [25:55](https://www.youtube.com/watch?v=o_FJ1NIH9yw&t=1555s) | Building God's Eye View Together | Contributing, roadmap, hosted version |

## Install, straight from the video

**Path 1 — no terminal:** install/update [Pinokio](https://desktop.pinokio.co/)
to **8.2 or later**, open the
[God's Eye View app page](https://pinokio.co/apps/github-com-bilawalsidhu-gods-eye-view),
click Install → Start. Windows, macOS, Linux. If you tried before and the
install failed, that was the pre-8.2 launcher bug — update and retry.

**Path 2 — terminal:** Node 24.14.0+ or 26.x (not 25, it's EOL).

```bash
git clone https://github.com/bilawalsidhu/gods-eye-view.git
cd gods-eye-view
npm ci
npm run doctor
npm run dev
# → http://localhost:4173
```

**Path 3 — the coding-agent prompt.** Sidhu publishes this verbatim in the
description for people who'd rather have an agent do it:

> "Set up God's Eye View from https://github.com/bilawalsidhu/gods-eye-view on
> my computer. Read the current README, check the prerequisites, install it, and
> launch the default keyless version. Then walk me through enabling
> photorealistic 3D and voice in the app's POWER UP panel. Guide me through any
> new API keys I need, but keep API keys local; don't ask me to paste them into
> this chat. Once it's up and running, please give me instructions to use it."

Note the built-in safety instruction: *keys stay local, never pasted into a
chat.* Worth keeping in any version of this prompt you reuse.

## Things the walkthrough demonstrates

- **Flight tracking → cockpit.** Click a live aircraft, the camera locks on and
  draws a trail; **COCKPIT** puts you inside it with real terrain underneath.
  **Contacts** is a 250 km roster — step plane to plane without leaving.
- **Voice control.** With an OpenAI key, the agent pulls live scene context
  before answering, so *"what city is this?"* mid-flight works. It directs the
  camera, annotates real boundaries (not circles), answers analyst questions
  ("how many flights are over Texas right now?"), and operates the console.
- **Public cameras that aren't embeds.** CCTV feeds project into the 3D city;
  VIEWSHED mode draws each camera's estimated coverage volume — including where
  it goes blind. Camera poses are estimated priors you can calibrate by dragging
  a gizmo.
- **Handoffs between layers.** Track a fire or a vessel, hit **NEAREST**, and you
  are looking at it through the closest public camera.
- **Scene director.** Record camera tours for clips — how the video's own
  footage gets made.
- **Event reconstruction.** The Nepal floods segment is the payoff: assembling
  what happened from live and archival public layers.
- **Share links.** Camera, style, layers and one tracked target serialize into a
  URL — a live target is a handoff, not a bookmark.

## Where it breaks down (the honest part)

Called out in the video and the repo: traffic is *simulated* along real roads
(TomTom buys live flow speeds, not live vehicles); CCTV poses and rocket
trajectories are coarse estimates; launch replays are labeled
`RECONSTRUCTED ESTIMATE`; terrestrial AIS goes quiet mid-ocean and satellite AIS
costs real money. Feeds arrive every 15–30s and the globe renders one interval
behind, interpolating between fixes.

## Links from the description

- Repo: https://github.com/bilawalsidhu/gods-eye-view
- One-click installer: https://pinokio.co/apps/github-com-bilawalsidhu-gods-eye-view
- Pinokio 8.2+: https://desktop.pinokio.co/
- Newsletter: https://spatialintelligence.ai
- Previous episode (open-source launch): https://www.youtube.com/watch?v=GRJaKcXZS94

**Open question he asks the audience:** *would you use a hosted version you could
open without installing anything?* The repo already answers it — a hosted God's
Eye View is being built at Halfpixel.

## Scrape note

Metadata, chapters and description came from YouTube's InnerTube API; the
feature detail above is corroborated against the project's own README (fetched
from raw.githubusercontent.com). **The spoken transcript could not be
retrieved** — youtube.com and transcript services are blocked by this
environment's egress policy. Nothing here is invented to cover that gap.
