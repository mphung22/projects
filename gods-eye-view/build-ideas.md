# Add-ons worth building

Concrete next moves, ordered by effort. Everything here follows from the two
videos plus the repo's own architecture — each layer is a separate module under
`src/data/`, which is what makes all of this tractable.

## 1. Getting it onto an iPhone

God's Eye View is a **local browser app**. It binds to `localhost` on the machine
running it, so an iPhone cannot reach it out of the box. Four options, best
first:

| Option | How | Trade-off |
|---|---|---|
| **Wait for hosted** | Halfpixel is building an official hosted version — "just give me a link" was the loudest post-launch request | Zero work, no date announced |
| **Private mesh** | Run it on a Mac/PC, put both devices on a Tailscale (or similar) tailnet, open the machine's tailnet address:4173 | Not exposed to the LAN or internet; still brokers your keys to anything on the tailnet |
| **LAN, keyless** | `npm run dev -- --host 0.0.0.0 --port 4173`, then hit `http://<machine-ip>:4173` from Safari | ⚠️ A LAN-visible server **brokers every configured API key to anyone who can reach it**. Do it with no keys set, or set provider quotas and billing alerts *first*, plus `GEV_RATELIMIT_*`. Provider Settings auto-disables when shared. Pinokio's LAN/Cloudflare sharing is deliberately disabled |
| **Share links** | Camera, style, layers and one tracked target serialize into a URL — send yourself a link from the desktop | Read-only handoff, and it still needs a reachable server |

Realistic expectations on the phone: CesiumJS runs in iOS Safari, but
photorealistic 3D tiles are heavy on mobile GPUs and thermals, and the voice
agent wants microphone permission on a secure origin — plain `http://<ip>:4173`
is not one, so mic features will not work over a bare LAN address. Treat the
phone as a **viewer**, not the driver.

**If "iPhone" in your Cowork project means something else** — a native iOS app,
or an iPhone-shaped brief rather than iPhone delivery — say so and this section
gets rewritten around that.

## 2. Reproduce the Hormuz analysis as a repeatable notebook

Video #3 is a method, not a story ([notes](video-notes/01_hormuz-chokehold.md)).
The pieces map cleanly onto the kind of Python work already in this repo:

1. Pull AIS transits through a bounding box around a chokepoint (AISStream, free
   key) → daily transit counts.
2. Detect gaps — a vessel that broadcasts, goes silent for *n* hours inside the
   box, then reappears, is a dark transit. This is the sharpest idea in the
   video and it's just a self-join on timestamps.
3. Join a commodity series (Brent/WTI) on date; plot transits and the spread on
   a shared axis.
4. Overlay the bypass routes (East–West pipeline, Habshan–Fujairah) as static
   geometry so the leverage is bounded visually.

That's a notebook, not an app, and it produces the chart the video is built
around. It would sit naturally alongside the existing
`Average Days On Market Using Analytics`-style notebooks in this repo.

## 3. A custom layer — the real one for this repo

Every layer is a module under `src/data/` with per-folder provenance. The repo
explicitly invites new ones: *"Missing a layer you want? Open an issue — or add
it and send the PR."*

Given what's already in this repository — Zillow rentals, Realtor, Estated,
census population, FRED economic data, foreclosure lists — the obvious build is
a **real-estate / market layer on the 3D globe**:

- Foreclosure filings as pins on photorealistic 3D, clustered by county.
- Rent-to-price ratio as a choropleth over neighborhoods (the repo already
  bundles DataSF-style neighborhood polygons as a pattern to copy).
- Days-on-market as extruded columns per ZIP.
- Then the payoff GEV already gives you for free: click a parcel → **NEAREST**
  public camera → look at the street.

Nobody has built that. It's the same fusion trick the videos do with tankers,
pointed at a dataset you already have pipelines for.

## 4. Smaller, same-day wins

- **Calibrate a camera pack for your city.** CCTV poses are estimated priors you
  fix by dragging a gizmo on the camera. There are ~14 city packs; adding or
  correcting one is a contained PR.
- **Record a scene tour.** The scene director exports cinematic camera paths —
  the fastest way to turn any analysis into something watchable.
- **Add a voice tool.** There are 28; they're plain functions. One that queries
  *your* layer ("how many foreclosures in this view?") is a small diff.
- **Swap the voice provider.** The README says PRs for Gemini or another
  provider behind the mic are welcome.

## 5. Cost discipline before you start

Most of this is $0. The one line item that bills is OpenAI realtime voice — a
few cents per active minute, single-digit dollars for a heavy evening, with a
$2 warning and a $5 hard session cap built in. Google's direct 3D route is
metered but the first 1,000 tile sessions a month are currently free, and one
root request covers roughly three hours of rendering. Enable billing alerts
anyway; app-level throttles are not billing caps.
