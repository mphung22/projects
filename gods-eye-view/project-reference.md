# God's Eye View — project reference

Condensed from the official repo, fetched 2026-09-16 from
`raw.githubusercontent.com/bilawalsidhu/gods-eye-view/main`
(README.md, CONTRIBUTING.md, SECURITY.md, DATA_SOURCES.md, .env.example,
package.json). Repo: https://github.com/bilawalsidhu/gods-eye-view

> A spy-satellite simulator in your browser — except the sources are public and
> the data is real. Photorealistic 3D globe; live aircraft, ships, satellites,
> earthquakes, traffic and public cameras; hands-free voice control.

**Status:** MIT-licensed, #1 on GitHub Trending (daily and weekly, Aug 2026),
#8 Product of the Day on Product Hunt. Maintained by Bilawal Sidhu and Sameh
Khamis at Halfpixel. Formerly called *WorldView*. An official **hosted version**
is in progress.

## Running it

| Path | How |
|---|---|
| One click | Pinokio **8.2+** → the GEV app page → Install → Start. Windows/macOS/Linux. |
| Terminal | Node **24.14.0+ or 26.x** (not 25 — EOL). `git clone` → `npm ci` → `npm run doctor` → `npm run dev` → `http://localhost:4173` |
| macOS shortcut | `./scripts/dev-fresh.sh` — clears the Vite cache, pulls keys from the Keychain |

It **starts with no account and no API keys**: Esri satellite imagery plus
keyless terrain, with OSM as fallback. Flights, military traffic, satellites,
earthquakes, public cameras, radio and launches all work keyless. A point-in-time
M5/Chrome capture measured a ~1.86s median cold start.

Keys are added **in the app**, not in a file: the **POWER UP** chip
(bottom-right; `?setup=1` if a compact layout hides it) → Provider Settings →
paste → SAVE KEYS → the app restarts with the capability on. Keys land in the
repo-root `.env` (terminal) or `pinokio/ENVIRONMENT` (Pinokio), both made
owner-only before a secret is written and both git-ignored. Values already in
your shell or macOS Keychain show as *configured externally* and are read-only.

## The 15 layers

Thirteen have a keyless path. 🟢 no key · 🟡 free key · 🔴 metered.

| Layer | What you get | Source | Auth |
|---|---|---|---|
| Map stack | Esri imagery, Google Photorealistic 3D, OSM, ion stacks | Esri/Google/Ion/OSM | 🟢🟡🔴 |
| Live flights | 11,000+ live aircraft + route history | OpenSky + adsb.lol | 🟢 |
| Military flights | ADS-B military traffic, in amber | adsb.lol | 🟢 |
| Live vessels | Thousands of ships worldwide | AISStream | 🟡 |
| Satellites | 838-object catalog; DENSE adds the Starlink shell | CelesTrak | 🟢 |
| Earthquakes | Global seismic, last 24h | USGS | 🟢 |
| Traffic | Simulated vehicles on OSM roads; TomTom drives flow speeds | TomTom + OSM | 🟢/🟡 |
| CCTV mesh | ~3,600 public cameras projected into 3D, with viewsheds | City APIs | 🟢 |
| Radio | Geolocated world radio, analog tuner, up to 750 stations | Radio Browser | 🟢 |
| Transit | Live buses/trams/metros/trains/ferries, 7 regions | GTFS-Realtime | 🟢 |
| Bikeshare | Live station availability | GBFS | 🟢 |
| Directions | Street-following drive/walk/cycle routes, then fly them | OSRM/FOSSGIS | 🟢 |
| Active fires | NASA FIRMS detections, trailing 24h | NASA FIRMS | 🟡 |
| Space missions | Rolling 30-day launches, scrubbable ascent replays | Launch Library 2 | 🟢 |
| Mapped installations | Viewport-bounded military-site context | OpenStreetMap | 🟢 |

**Bundled static data:** 4,351 datacenters · 704 dams · 712 submarine cables ·
neighborhood overlays. Some carry their own terms — TeleGeography cables are
**NonCommercial**, datacenters and dams are **ODbL share-alike**. See
DATA_SOURCES.md before reusing anything.

**Basemap ladder:** nothing → Esri 2D satellite · free Cesium ion token →
Google Photorealistic 3D + world terrain (eligible personal, non-commercial) ·
Google Maps key → the same 3D direct, plus in-app place search (metered).

## Keys and what they cost

| | Key | Unlocks |
|---|---|---|
| 🟡 | Cesium ion | Google Photorealistic 3D + world terrain (free Community tier, personal/non-commercial, quotas apply) |
| 🔴 | Google Maps | Direct Google 3D tiles + place search (metered; first 1,000 3D-tile sessions/month currently free) |
| 🔴 | OpenAI | Voice control + AI HUD summary |
| 🟡 | AISStream | Live global ships |
| 🟡 | NASA FIRMS | Live active fires |
| 🟡 | TomTom | Live flow speeds/congestion colours |
| 🟡 | OpenSky | More flight-polling credits (anonymous works) |
| 🟡 | Launch Library 2 | Higher space-missions allowance (works without) |

**The only one that really costs money is OpenAI voice** — realtime audio is a
few cents per active minute, an evening of heavy use is single-digit dollars.
The app meters it for you: a live session-spend readout beside the mic, an
STD/MINI model toggle, a $2 warning and a **$5 hard cap that ends the session**.

## Architecture

No framework. Vanilla JavaScript + **CesiumJS** + **Vite**, plus Google
Photorealistic 3D Tiles and the OpenAI Realtime API. Deps are deliberately thin:
`cesium`, `satellite.js`, `@mapbox/vector-tile`, `pbf`, `mgrs`,
`egm96-universal`.

```
src/
├── main.js                 # Bootstrap: Google 3D tiles, layer registration
├── ui.js                   # Runtime UI — panels, HUD, styles, control facade
├── hud.js                  # Intelligence HUD + AI scene summary
├── keySetup.js             # POWER UP panel (dev server only)
├── mapStackController.js   # Basemap switching
├── voice/                  # OpenAI Realtime session + 28 voice tools
├── data/                   # One module per layer + orchestration + context store
│   ├── iconOrientation.js  # Screen-projected headings + horizon cull
│   └── local_data/         # Bundled datasets (per-folder provenance)
└── scenes/                 # Cinematic scene director
```

`docs/CURRENT-STATE.md` in the repo is the authoritative runtime reference (it's
large — ~370 KB). **Each layer is a separate module**, which is the whole point
for anyone wanting to add one.

Engineering details worth knowing:

- **World-stable icons** — aircraft and ships point along true real-world heading
  at any camera angle, via per-frame screen-space course projection.
- **Smooth motion from choppy data** — feeds arrive every 15–30s; the globe
  renders one interval behind and interpolates, with dead reckoning for gaps.
- **Honest satellites** — SGP4 propagation, orbit rings kept locked via GMST
  realignment.
- **Ground-aligned entities** — heights work with Google 3D tiles, so aircraft
  sit on aprons and cameras stand on corners.
- **Request budgets** — OpenSky credit governor, TomTom daily tile budget,
  disk-cached TLEs. These are not a substitute for provider quotas.
- **Server-side credentials** — every private-key API (OpenAI, AISStream,
  OpenSky OAuth, camera frames) goes through a hardened server-side proxy with
  SSRF protection, response caps and sanitized errors. Only Google Maps and
  Cesium ion keys reach the browser; restrict both at the provider.

## Security posture

The server binds to **localhost** by default and Provider Settings answers only
local requests. Sharing on a LAN is explicit opt-in (`--host 0.0.0.0`) and
⚠️ **a LAN-visible server brokers your configured API keys to anyone who can
reach it** — set `GEV_RATELIMIT_OPENAI_PER_MIN` / `GEV_RATELIMIT_GOOGLE_PER_MIN`
and, more importantly, provider-side quotas and billing alerts first. Provider
Settings is disabled when the server is shared. Pinokio LAN/Cloudflare sharing
is disabled for this launcher; use a separately reviewed auth proxy for remote
access. Full threat model in the repo's SECURITY.md.

Older Pinokio caveat: do **not** enter credentials in Pinokio 8.0.40's native
Configure panel — it doesn't save this nested app file correctly and it logs
submitted values. Use POWER UP → Provider Settings inside the app.

## The stated line

> "This project models **events, assets, infrastructure, and systems** — aircraft,
> vessels, satellites, fires, cameras, cities. It does not build features for
> named-person search, face recognition, or tracking individuals, and pull
> requests that cross that line won't be merged. People are not a query type
> here."

Also stated plainly: data may be delayed, incomplete, modeled, inferred or
wrong. Not for navigation, emergency response, medical, or investment decisions.

## Useful env vars

From `.env.example` — the ones you'd actually touch:

```
CESIUM_ION_TOKEN=           GOOGLE_MAPS_API_KEY=        OPENAI_API_KEY=
AISSTREAM_API_KEY=          FIRMS_MAP_KEY=              TOMTOM_API_KEY=
OPENSKY_CLIENT_ID/SECRET=   OPENSKY_AUTH_MODE=anon      LL2_API_TOKEN=
AISSTREAM_BOUNDING_BOXES=   TOMTOM_DAILY_TILE_BUDGET=   HOST= / PORT=
GEV_RATELIMIT_OPENAI_PER_MIN=   GEV_RATELIMIT_GOOGLE_PER_MIN=
OPENAI_REALTIME_MODEL / _MINI / _VOICE / _CONTEXT_TOKENS
CCTV_<CITY>_ENABLED / _MAX_SOURCES   # per-city camera packs, ~14 of them
```

## npm scripts

`dev` · `dev:secure` · `build` · `preview` · `doctor` (Node/npm + provider
readiness, never prints credential values) · `test` · `test:track` ·
`format` / `format:check` · `check:boundaries` · `qa:transit` ·
`qa:map-source-tray` · `opensky:import`
