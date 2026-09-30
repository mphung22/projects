# Seren (serensaigon.com): customer forms, check-in and review tools

This repo was originally Python real-estate notebooks (repo root). The Seren work lives in:

| Path | What it is |
|---|---|
| `ios-apps/Seren.swiftpm` | **The app in use.** All-in-one iPad/iPhone kiosk app. The customer picks Brows & Lashes, Massage, Nails or Head Spa, fills in the bilingual (Vietnamese + English) form and signs. Signed PDFs are saved on the iPad only. Also has customer feedback with a Google review QR, and a PIN-protected staff area (records, CSV export, settings). |
| `ios-apps/{BrowsLashes,Massage,Nails,HeadSpa}.swiftpm` | Single-service versions of the same forms. **Each form's source of truth is its `App/` folder here.** |
| `ios-apps/Shared/` | Shared SwiftUI code (kiosk shell, components, signature pad, PDF, storage, staff area, feedback). |
| `ios-apps/make-translations.py` | Writes `ios-apps/Shared/Translations.swift` from `docs/i18n.js` (needs Node). Run it, then `sync-shared.sh`, after changing translations. |
| `ios-apps/sync-shared.sh` | **Run after editing `Shared/` or any `*/App/`.** It copies `Shared/` into every package and the five forms into `Seren.swiftpm/Services/`. Never edit the copies. |
| `docs/` | **Web check-in**, `https://checkin.serensaigon.com`, on GitHub Pages (branch below, folder `/docs`, `CNAME`). Plain HTML/JS, no build. All five forms (Brows & Lashes, Massage, Nails, Head Spa, Waxing) are defined in `docs/app.js` (`SERVICES`). |
| `docs/config.js` | Google Apps Script endpoint for check-in submissions. |
| `docs/i18n.js` | Chinese, Korean, French, Japanese and Russian wording for the check-in **and the iPad app**, keyed by the English text (`strings`, iPad-only `app`, and `health`). `L(...)` in both apps picks it up. The `health` block (health, contraindication and consent wording) has **not** been checked by native speakers yet. |
| `google-apps-script/Code.gs` | The Apps Script bound to the private Google Sheet "Seren Check-ins". Each check-in becomes one short row at the top of the "Check-ins" tab (newest first), any signature is saved as a PNG in Drive, and the owner gets an email. Deploy changes as a new version of the existing web-app deployment so the URL stays the same. |
| `ios-apps/print/` | Printable Google review cards, the check-in door poster, QR PNGs, and the scripts that make them. |

- **Branch:** `claude/ios-apps-seren-massage-f3sitc`. This is also the GitHub Pages source, so pushing updates the live check-in site. PR: mphung22/projects#1.
- **Main website:** serensaigon.com is a separate Netlify project, `mellow-palmier-d02528`, deployed by Netlify Drop. **Don't drag single files onto it**: a drop replaces the whole site. The DNS is at Namecheap (CNAME `checkin` → `mphung22.github.io`).
- **Google review link:** `https://g.page/r/CTpMl46hoXZSEBM/review`. It's the app default in `ios-apps/Shared/Settings.swift`.

## Conventions
- Every customer-facing string is bilingual: `L("Tiếng Việt", "English")`, in Swift and in `docs/app.js`. In both, `L` also picks up zh/ko/fr/ja/ru from `docs/i18n.js` (Swift via the generated `Translations.swift`; missing ones fall back to English). The iPad staff area stays Vietnamese + English. **When you add or change an English string, add its translations to `i18n.js` too.** Records, the Google Sheet and emails stay Vietnamese + English whatever language the customer picks.
- Services and prices mirror serensaigon.com/pricing in both apps: `price: '…₫'` options in `docs/app.js` (`heading(...)` entries are sub-headings) and `priceGroups` in each iPad `*Content.swift`. Both show a bill with the total near the end of the form. Update both when the site's price list changes.
- Only Brows & Lashes has health questions (contraindications). **Massage, Nails and Head Spa have no health section** in either app (Head Spa has no aftercare either); the Massage/Head Spa consent asks the customer to raise health concerns in person. Massage has an oil choice (OILMART Calming/Refreshing/Comforting/Anti-Aging) with an almond note on Calming.
- The iPad app can't be built on Linux. Build it on the Mac in Xcode, and use the Release configuration for speed.
- Test the web check-in with a local static server plus a headless browser. Stub `script.google.com` rather than posting real check-ins.
- Both forms record every consent statement, but the customer agrees with **one** tick (`ConsentBlock` in Swift, the `consents` item in `docs/app.js`).
- Phone number and date of birth are **optional** everywhere. There is **no technician signature**, and only Brows & Lashes and Waxing ask the customer to sign (web check-in and iPad alike).

## Open tasks (as of the last session)
1. **Native-speaker check** of the `health` block in `docs/i18n.js` for each language (and ideally the rest). Then run `ios-apps/make-translations.py` and `sync-shared.sh`.
2. **Build and test the iPad app in Xcode.** The last session changed the forms (price menus, totals, oils, languages) but could only type-check the non-SwiftUI code on Linux.
3. serensaigon.com's Head Spa pages (EN `/head-spa/` and VI `/vi/goi-dau-duong-sinh/`) say "the 105 and 120 minute" rituals; the rituals are now 100, 130 and 160 minutes. Corrected pages were handed to the owner to add to a full-site Netlify Drop deploy; check whether that happened.
4. Watch that GitHub Pages is on (Settings › Pages › branch above, `/docs`) and that HTTPS is enforced once the DNS resolves.
