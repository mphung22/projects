# Seren (serensaigon.com): customer forms, check-in and review tools

This repo was originally Python real-estate notebooks (repo root). The Seren work lives in:

| Path | What it is |
|---|---|
| `ios-apps/Seren.swiftpm` | **The app in use.** All-in-one iPad/iPhone kiosk app. The customer picks Brows & Lashes, Massage, Nails or Head Spa, fills in the bilingual (Vietnamese + English) form and signs. Signed PDFs are saved on the iPad only. Also has customer feedback with a Google review QR, and a PIN-protected staff area (records, CSV export, settings). |
| `ios-apps/{BrowsLashes,Massage,Nails,HeadSpa}.swiftpm` | Single-service versions of the same forms. **Each form's source of truth is its `App/` folder here.** |
| `ios-apps/Shared/` | Shared SwiftUI code (kiosk shell, components, signature pad, PDF, storage, staff area, feedback). |
| `ios-apps/sync-shared.sh` | **Run after editing `Shared/` or any `*/App/`.** It copies `Shared/` into every package and the four forms into `Seren.swiftpm/Services/`. Never edit the copies. |
| `docs/` | **Web check-in**, `https://checkin.serensaigon.com`, on GitHub Pages (branch below, folder `/docs`, `CNAME`). Plain HTML/JS, no build. All four forms are defined in `docs/app.js` (`SERVICES`). |
| `docs/config.js` | Google Apps Script endpoint for check-in submissions. |
| `google-apps-script/Code.gs` | The Apps Script bound to the private Google Sheet "Seren Check-ins". Each check-in becomes a row, the signature is saved as a PNG in Drive, and the owner gets an email. |
| `ios-apps/print/` | Printable Google review cards, the check-in door poster, QR PNGs, and the scripts that make them. |

- **Branch:** `claude/ios-apps-seren-massage-f3sitc`. This is also the GitHub Pages source, so pushing updates the live check-in site. PR: mphung22/projects#1.
- **Main website:** serensaigon.com is a separate Netlify project, `mellow-palmier-d02528`, deployed by Netlify Drop. **Don't drag single files onto it**: a drop replaces the whole site. The DNS is at Namecheap (CNAME `checkin` → `mphung22.github.io`).
- **Google review link:** `https://g.page/r/CTpMl46hoXZSEBM/review`. It's the app default in `ios-apps/Shared/Settings.swift`.

## Conventions
- Every customer-facing string is bilingual: `L("Tiếng Việt", "English")`, in Swift and in `docs/app.js`.
- The iPad app can't be built on Linux. Build it on the Mac in Xcode, and use the Release configuration for speed.
- Test the web check-in with a local static server plus a headless browser. Stub `script.google.com` rather than posting real check-ins.
- Both forms record every consent statement, but the customer agrees with **one** tick (`ConsentBlock` in Swift, the `consents` item in `docs/app.js`).
- Phone number and date of birth are **optional** everywhere. There is **no technician signature**.

## Open tasks (as of the last session)
1. **Prices on the phone check-in.** Read the service prices from serensaigon.com and add `price: '…₫'` to the matching options in `docs/app.js`. The display is already built (`optionLabel` / `withPrice`). Ask the owner whether the iPad app should show prices too.
2. **More languages.** Add the other languages offered on serensaigon.com to the check-in, and possibly to the iPad app. Today `L` holds only `vi`/`en`, and the language picker has VI+EN / VI / EN. Extend the structure; records and PDFs stay Vietnamese + English. Health and consent wording should be checked by a native speaker.
3. Watch that GitHub Pages is on (Settings › Pages › branch above, `/docs`) and that HTTPS is enforced once the DNS resolves.
