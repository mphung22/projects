# Seren check-in: Google Sheet receiver

`checkin.serensaigon.com` is hosted on GitHub Pages from the `docs/` folder. Check-ins are sent to
`Code.gs`, a Google Apps Script bound to a private Google Sheet:

- each check-in becomes a row in the **Check-ins** tab;
- the signature is saved as a PNG in the private Drive folder **Seren check-in signatures**;
- the sheet owner gets an email alert (change `NOTIFY_EMAIL` in `Code.gs`).

## Setup
1. Create a Google Sheet named **Seren Check-ins**.
2. Open **Extensions › Apps Script**, replace the code with `Code.gs`, and save.
3. Click **Deploy › New deployment**, choose the type **Web app**, set *Execute as* to **Me** and
   *Who has access* to **Anyone**, then click **Deploy** and authorise.
4. Copy the **Web app URL** (`https://script.google.com/macros/s/…/exec`) into `docs/config.js`.

After you edit `Code.gs`, use **Deploy › Manage deployments › Edit › New version** so the URL stays the same.
