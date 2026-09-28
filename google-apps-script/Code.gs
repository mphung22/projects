/**
 * Seren check-in receiver.
 *
 * Paste this into Extensions › Apps Script of the private "Seren Check-ins" Google Sheet, then
 * Deploy › New deployment › Web app (Execute as: Me, Who has access: Anyone).
 * Each check-in from checkin.serensaigon.com becomes a row in the "Check-ins" tab, the signature is
 * saved as a PNG in a private Google Drive folder, and an email alert is sent to the sheet owner.
 */

const SHEET_NAME = 'Check-ins';
const SIGNATURE_FOLDER = 'Seren check-in signatures';
// Email alerts for each check-in. Leave '' to use the sheet owner's address, or set 'none' to turn off.
const NOTIFY_EMAIL = '';

const HEADERS = [
  'Submitted', 'Service', 'Full name', 'Phone', 'Date of birth', 'Technician',
  'Health flags', 'Photo consent', 'Language', 'Signature', 'Summary', 'Answers (JSON)',
];

function doPost(e) {
  const lock = LockService.getScriptLock();
  lock.waitLock(20000);
  try {
    const data = JSON.parse(e.postData.contents);
    if (data.website) return json({ ok: true }); // honeypot filled in: a bot

    const submitted = new Date();
    const signatureUrl = saveSignature(data.signature, data.full_name, submitted);

    getSheet().appendRow([
      submitted,
      text(data.service),
      text(data.full_name),
      text(data.phone),
      text(data.date_of_birth),
      text(data.technician),
      text(data.health_flags),
      text(data.photo_consent),
      text(data.language),
      signatureUrl,
      text(data.summary, 45000),
      text(data.answers_json, 45000),
    ]);

    notify(data, signatureUrl);
    return json({ ok: true });
  } catch (err) {
    console.error(err);
    return json({ ok: false, error: String(err) });
  } finally {
    lock.releaseLock();
  }
}

/** Lets you open the web app URL in a browser to check it is running. */
function doGet() {
  return json({ ok: true, service: 'Seren check-in' });
}

function getSheet() {
  const spreadsheet = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = spreadsheet.getSheetByName(SHEET_NAME);
  if (!sheet) sheet = spreadsheet.insertSheet(SHEET_NAME);
  if (sheet.getLastRow() === 0) {
    sheet.appendRow(HEADERS);
    sheet.setFrozenRows(1);
    sheet.getRange(1, 1, 1, HEADERS.length).setFontWeight('bold');
  }
  return sheet;
}

function saveSignature(dataUrl, name, submitted) {
  const prefix = 'data:image/png;base64,';
  if (typeof dataUrl !== 'string' || !dataUrl.startsWith(prefix)) return '';
  const bytes = Utilities.base64Decode(dataUrl.slice(prefix.length));
  if (bytes.length > 2 * 1024 * 1024) return ''; // ignore anything unexpectedly large
  const stamp = Utilities.formatDate(submitted, Session.getScriptTimeZone(), 'yyyy-MM-dd HHmm');
  const safeName = String(name || 'customer').replace(/[^\p{L}\p{N} ]+/gu, '').trim().slice(0, 60) || 'customer';
  const blob = Utilities.newBlob(bytes, 'image/png', `${stamp} ${safeName}.png`);
  return getFolder().createFile(blob).getUrl(); // private: only you can open it
}

function getFolder() {
  const folders = DriveApp.getFoldersByName(SIGNATURE_FOLDER);
  return folders.hasNext() ? folders.next() : DriveApp.createFolder(SIGNATURE_FOLDER);
}

function notify(data, signatureUrl) {
  if (NOTIFY_EMAIL === 'none') return;
  const to = NOTIFY_EMAIL || Session.getEffectiveUser().getEmail();
  if (!to) return;
  const flags = String(data.health_flags || 'None');
  const subject = `Check-in: ${data.full_name} · ${data.service}${flags !== 'None' ? ' · ⚠ health note' : ''}`;
  const body = [
    `${data.full_name} (${data.phone}) checked in for ${data.service}.`,
    `Health: ${flags}`,
    '',
    `Sheet: ${SpreadsheetApp.getActiveSpreadsheet().getUrl()}`,
    signatureUrl ? `Signature: ${signatureUrl}` : '',
  ].join('\n');
  MailApp.sendEmail(to, subject, body);
}

/**
 * Stores values as plain text: keeps leading zeros in phone numbers and stops text that starts
 * with = + - @ from being treated as a spreadsheet formula.
 */
function text(value, max) {
  let s = value == null ? '' : String(value);
  if (max && s.length > max) s = s.slice(0, max) + '…';
  return s === '' ? '' : "'" + s;
}

function json(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(ContentService.MimeType.JSON);
}
