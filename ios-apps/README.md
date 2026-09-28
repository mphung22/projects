# iPad & iPhone customer forms: Seren

These are four apps that replace the paper forms. They are designed for iPad and also work on iPhone. The customer fills in the form and signs on the device. The app then saves a signed, bilingual (Vietnamese and English) PDF on that device.

| App (home-screen name) | Folder | Form |
|---|---|---|
| **Brows and Lashes** | `BrowsLashes.swiftpm` | Brows lamination & tint (from the paper form), lash lift & tint, lash extensions |
| **Massage** | `Massage.swiftpm` | Massage intake and consent |
| **Nails** | `Nails.swiftpm` | Manicure, pedicure, gel, acrylic, nail art: health check, aftercare, photo consent |
| **Head Spa** | `HeadSpa.swiftpm` | Head spa (gội đầu dưỡng sinh): scalp & hair, health check, consent |

## What the apps do

- **Kiosk flow:** Welcome screen → customer taps **Bắt đầu / Start** → fills in the form → signs → sees a thank-you screen. After 10 seconds the app goes back to the welcome screen for the next customer.
- **Bilingual:** The customer can pick Tiếng Việt + English (the default), Tiếng Việt only, or English only. The saved PDF always includes both languages.
- **Signatures:** The customer signs with a finger or Apple Pencil. The technician's signature is optional.
- **Checks before submit:** Required fields, the health questions, the consent checkboxes and the customer signature must all be filled in before the form can be submitted.
- **Health warnings:** If a customer ticks a contraindication or health condition, the form asks them to tell the technician. In the staff area the record gets a ⚠️ mark so staff notice it.
  - *Brows:* if the date of birth shows the customer is under 16, "Under 16" is ticked automatically.
- **Customer feedback and Google reviews:** a **Đánh giá dịch vụ / Leave feedback** button on the welcome screen. After the service, customers give 1–5 stars, can add a comment, and choose who looked after them. Then they see a QR code for your Google review page. Every customer sees the QR code whatever their rating, because Google doesn't allow asking only happy customers for reviews. Paste your review link in Settings (Google Business Profile › Ask for reviews / Get more reviews).
- **Staff area** (the 🔒 icon at the bottom right of the welcome screen, protected by a PIN):
  - Search past forms by name or phone number.
  - View, print, share (AirDrop, email, Files) or delete each signed PDF.
  - Export all customers to a CSV file that opens in Excel, Numbers or Google Sheets.
  - Read customer feedback and the average rating, and export it to CSV.
  - Settings: business name, Google review link, staff list (customers pick their technician from it), change the PIN.

> ⚠️ **The default staff PIN is `1234`.** Change it in Staff area → ⋯ → Settings the first time you open each app.

## How to install on the iPad

Each `.swiftpm` folder is a complete app. You can install it either way:

### Option A: Mac with Xcode (recommended)
1. Install **Xcode 15 or newer** from the Mac App Store.
2. Double-click the app folder (e.g. `BrowsLashes.swiftpm`). It opens in Xcode.
3. Connect the iPad with a cable and pick it as the run destination at the top of the window.
4. Under **Signing & Capabilities**, choose your Apple ID as the **Team** (a free Apple ID works).
5. Press **▶ Run**.

On the iPad, the first time only: go to **Settings › General › VPN & Device Management** and trust your developer profile.
(Apps signed with a free Apple ID expire after 7 days. With a paid Apple Developer account ($99/year) they last a year, and you can use TestFlight.)

### Option B: directly on the iPad with Swift Playgrounds (no Mac needed)
1. Install **Swift Playgrounds** from the App Store on the iPad.
2. Copy the app folder (e.g. `BrowsLashes.swiftpm`) into **iCloud Drive** or **On My iPad** using the Files app.
3. Open it in Swift Playgrounds and tap **▶ Run**.
4. To install it as a normal home-screen app, use **App Settings › App Store Connect** in Swift Playgrounds (this needs a paid developer account).

## Using the iPad as a kiosk
Turn on **Guided Access** (Settings › Accessibility › Guided Access) and then triple-click the side or top button in the app. Customers then can't leave the app.

## Data and privacy
- Records are saved **only on that iPad**, in the app's private storage, with iOS data protection turned on.
- Deleting the app deletes the records. **Export the CSV or PDFs regularly**, or keep the iPad backed up to iCloud.

## Changing the wording or the forms
- Brows & lashes: `BrowsLashes.swiftpm/App/SerenContent.swift`
- Massage: `Massage.swiftpm/App/MassageContent.swift`
- Nails: `Nails.swiftpm/App/NailsContent.swift`
- Head spa: `HeadSpa.swiftpm/App/HeadSpaContent.swift`

Each file holds all the text as `L("Tiếng Việt", "English")` pairs. The on-screen form and the PDF both read from the same file.

Code used by all the apps (signature pad, PDF, storage, staff area, kiosk screens) lives in `Shared/`. If you edit anything there, run `./sync-shared.sh` to copy it into every app. Each `.swiftpm` needs its own copy so it can be opened on its own.

App name, bundle ID, icon and accent color are set in each app's `Package.swift`.
