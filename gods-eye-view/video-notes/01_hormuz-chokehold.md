# Ex-Google PM Uses God's Eye to Reveal Iran's Chokehold on the World's Oil

| | |
|---|---|
| **Channel** | Bilawal Sidhu |
| **Published** | Apr 3, 2026 |
| **Views at scrape** | 691,968 |
| **Runtime** | ~16 min (last chapter starts 15:20) |
| **URL** | https://www.youtube.com/watch?v=ccZzOGnT4Cg |
| **Series** | God's Eye View / "Mapping the World" — video 3 of 9 |
| **Scraped** | 2026-09-16 |

## What the video is

The third God's Eye View episode, and the one that turns the toy into an
analysis tool. Sidhu turns on ship tracking in God's Eye View and watches the
**Strait of Hormuz go dark** — ship crossings dropping from hundreds a day to a
handful, some days none. His framing: Iran has effectively shut down the most
important waterway on Earth, a ~21-mile chokepoint carrying roughly **a fifth of
the world's oil**.

To tell that story he ships new layers into the app — ship tracking, dark-vessel
detection, pipeline routes, oil futures, and strike tracking — and syncs the
whole operational picture to the 3D globe.

> "What you're about to see is the full operational picture of the Hormuz crisis
> — every ship, every strike, every dark transit — synced to a 3D globe."
> — video description

He also notes the audience that showed up after the first two videos: OSINT
people, hedge funds, defense tech, and journalists.

## Chapter map

Timestamps link straight into the video.

| Time | Chapter | What it covers |
|---|---|---|
| [0:00](https://www.youtube.com/watch?v=ccZzOGnT4Cg&t=0s) | God's Eye View | Setup — what the tool is, why this build exists |
| [1:00](https://www.youtube.com/watch?v=ccZzOGnT4Cg&t=60s) | Strait of Hormuz Choke Point | The ~21-mile chokepoint, geography, why it matters |
| [1:54](https://www.youtube.com/watch?v=ccZzOGnT4Cg&t=114s) | Impact on Transits & Oil Prices | Transit collapse vs. Brent/WTI response |
| [2:55](https://www.youtube.com/watch?v=ccZzOGnT4Cg&t=175s) | Iran's Toll Booth | Chokepoint as leverage — the coercion mechanic |
| [5:48](https://www.youtube.com/watch?v=ccZzOGnT4Cg&t=348s) | Dark Vessel Detection | AIS gap analysis — ships that stop broadcasting |
| [7:16](https://www.youtube.com/watch?v=ccZzOGnT4Cg&t=436s) | The Oil Pipeline Bypasses | East–West pipeline, Habshan–Fujairah — the routes around Hormuz |
| [8:30](https://www.youtube.com/watch?v=ccZzOGnT4Cg&t=510s) | Desalination Plants & The Water Crisis | The under-covered second-order risk in the Gulf |
| [9:17](https://www.youtube.com/watch?v=ccZzOGnT4Cg&t=557s) | The Strikes: Tankers Under Fire | Strike tracking against shipping |
| [10:22](https://www.youtube.com/watch?v=ccZzOGnT4Cg&t=622s) | The Strikes: Refineries & Bases | Before/after imagery on fixed infrastructure |
| [12:44](https://www.youtube.com/watch?v=ccZzOGnT4Cg&t=764s) | Why Satellites Are Now Delayed | Imagery latency during a hot conflict |
| [13:13](https://www.youtube.com/watch?v=ccZzOGnT4Cg&t=793s) | The Global Economic Ripple Effect | Reserves, dependency, who actually eats the cost |
| [15:20](https://www.youtube.com/watch?v=ccZzOGnT4Cg&t=920s) | What's Next | Roadmap / where the project goes |

## Data layers in this build

Listed by the creator in the description — this is effectively the recipe for
reproducing the analysis:

- **AIS ship tracking** (live vessel positions)
- **Dark vessel detection** — AIS gap analysis (a ship going silent is the signal)
- **Oil pipeline bypass routes** — East–West pipeline, Habshan–Fujairah
- **Oil futures** — Brent crude, WTI, and the spread between them
- **Military strike tracking** from OSINT reporting (Israel/US ↔ Iran)
- **Before/after satellite imagery**
- **Critical infrastructure** — desalination plants, refineries, airbases
- **Country-level reserve and dependency data**

## The method worth stealing

The episode is a template, not a one-off:

1. **Pick a chokepoint.** One piece of geography that a disproportionate share of
   some flow has to pass through.
2. **Instrument the flow.** A live positional feed (AIS here) plus a count over
   time — transits per day is the whole story in one number.
3. **Mine the absence.** Dark-vessel detection is the sharpest idea in the video:
   the interesting signal isn't the ships you see, it's the ones that stopped
   broadcasting. Gaps in a feed are data.
4. **Attach a price.** Overlay a market series (Brent/WTI) on the physical
   series. The correlation — or the lack of one — is the finding.
5. **Map the alternatives.** Pipelines that bypass the chokepoint bound how much
   leverage the chokepoint actually confers.
6. **Find the second-order target.** Desalination plants: Gulf states drink from
   the same water the tankers sit in. Nobody was covering it.
7. **Show your latency.** He explicitly covers *why satellite imagery is delayed*
   rather than pretending the picture is live. Honest about the seams.

## Links from the description

- Full written breakdown / newsletter: https://spatialintelligence.ai
- Channel: https://www.youtube.com/@bilawalsidhu
- X: https://x.com/bilawalsidhu

## Scrape note

Title, channel, publish date, view count, chapter list and description were
pulled directly from YouTube's InnerTube API. **The spoken transcript could not
be retrieved** — youtube.com and every third-party transcript service are
blocked by this environment's egress policy, and YouTube's transcript endpoint
refuses unauthenticated calls. Everything above is from official metadata plus
the project's own repository docs; nothing has been invented to fill the gap.
If you want quote-level notes, the fastest path is pasting the transcript from
the YouTube app on your phone (⋯ → Show transcript) into this file.
