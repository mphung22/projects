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

## Member cards (prepaid balance)
The bill page (`/bill/`) keeps member-card balances in the same Google Sheet:
- selling a Seren Touch / Flow / Glow / Balance / VIP card adds its spendable value to the customer's card;
- choosing **Thẻ thành viên / Member card** as the payment method deducts the bill total from the card;
- tabs **Thẻ thành viên - Members** (balance per customer) and **Thẻ - Giao dịch / Card ledger** (every sale and payment) are created on the first card sale.

One-time setup, because the web app URL is public: in Apps Script open **Project Settings (gear) › Script properties › Add script property**,
name `STAFF_PIN`, value a PIN of 6 or more characters. Then deploy **a new version** of the existing web app. Reception types the PIN
once per computer. Ten wrong PINs lock member requests for 10 minutes. To correct a mistake, edit or delete the row in the ledger tab.
