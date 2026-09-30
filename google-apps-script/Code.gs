/**
 * Seren check-in receiver.
 *
 * Paste this into Extensions › Apps Script of the private "Seren Check-ins" Google Sheet, then
 * Deploy › Manage deployments › Edit › Version: New version › Deploy (the web app URL stays the same).
 * First time only: Deploy › New deployment › Web app (Execute as: Me, Who has access: Anyone).
 *
 * Each check-in from checkin.serensaigon.com becomes one short row at the TOP of the "Check-ins" tab
 * (newest first), the signature is saved as a PNG in a private Google Drive folder, and an email alert
 * is sent to the sheet owner.
 *
 * Rows saved in the old layout are copied into the new layout automatically the first time this
 * version runs; the old tab is kept (renamed "Check-ins (old layout)"), nothing is deleted.
 */

const SHEET_NAME = 'Check-ins';
const OLD_SHEET_NAME = 'Check-ins (old layout)';
const SIGNATURE_FOLDER = 'Seren check-in signatures';
// Email alerts for each check-in. Leave '' to use the sheet owner's address, or set 'none' to turn off.
const NOTIFY_EMAIL = '';

// Column layout. `width` is in pixels.
const COLUMNS = [
  { title: 'Date', width: 150 },
  { title: 'Name', width: 170 },
  { title: 'Phone', width: 120 },
  { title: 'Service', width: 110 },
  { title: 'Chosen', width: 300 },
  { title: 'Total (₫)', width: 95 },
  { title: 'Health notes', width: 200 },
  { title: 'Photos OK?', width: 110 },
  { title: 'Consent', width: 75 },
  { title: 'Therapist', width: 110 },
  { title: 'Date of birth', width: 100 },
  { title: 'Language', width: 90 },
  { title: 'Signature', width: 80 },
  { title: 'Full form (click the cell to read)', width: 260 },
  { title: 'Raw answers', width: 120 },
];
const COL = Object.fromEntries(COLUMNS.map((c, i) => [c.title, i + 1]));
const HEALTH_COL = 7;
const RAW_COL = COLUMNS.length;

const LANGUAGES = {
  both: 'VI + EN', vi: 'Vietnamese', en: 'English', zh: 'Chinese', ko: 'Korean',
  fr: 'French', ja: 'Japanese', ru: 'Russian',
};

// ---------------------------------------------------------------------------
// Web app
// ---------------------------------------------------------------------------

function doPost(e) {
  const lock = LockService.getScriptLock();
  lock.waitLock(20000);
  try {
    const data = JSON.parse(e.postData.contents);
    if (data.website) return json({ ok: true }); // honeypot filled in: a bot

    const submitted = new Date();
    const signatureUrl = saveSignature(data.signature, data.full_name, submitted);
    addRow(getSheet(), buildRow(data, submitted, signatureUrl));

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

// ---------------------------------------------------------------------------
// Turning a check-in into a short row
// ---------------------------------------------------------------------------

/** Values for one row, in COLUMNS order. */
function buildRow(data, submitted, signatureUrl) {
  const summary = String(data.summary || '');
  const parsed = parseSummary(summary);
  const flags = String(data.health_flags || '').trim();
  // Newer check-in pages send short English fields; older rows are read from the summary text.
  const chosen = data.chosen_en != null ? data.chosen_en : parsed.items.map((i) => english(i.label)).join(', ');
  const total = data.total_vnd != null && data.total_vnd !== '' ? Number(data.total_vnd) || '' : parsed.total;
  return [
    submitted,
    plain(data.full_name),
    plain(data.phone),
    plain(data.service_en || english(data.service)),
    plain(chosen),
    total,
    plain(flags === 'None' || flags === '—' ? '' : flags),
    plain(dash(english(data.photo_consent))),
    parsed.signed === null ? '' : parsed.signed ? '✓' : '✗ No',
    plain(data.technician),
    plain(data.date_of_birth),
    LANGUAGES[data.language] || plain(data.language),
    signatureUrl ? `=HYPERLINK("${signatureUrl.replace(/"/g, '')}","View")` : '',
    plain(shortForm(summary), 45000),
    plain(data.answers_json, 45000),
  ];
}

/**
 * Reads the chosen services, total and consent tick out of the summary text the check-in page sends.
 * Returns { items: [{label, price}], total: number|'' , signed: true|false|null }.
 */
function parseSummary(summary) {
  const result = { items: [], total: '', signed: null };
  const blocks = String(summary).split(/\n\s*\n/);
  for (const block of blocks) {
    const lines = block.split('\n').map((l) => l.trim()).filter(Boolean);
    const totalLine = lines.find((l) => /(^|\/ )Total: /.test(l));
    if (totalLine) {
      for (const line of lines) {
        if (!line.startsWith('• ')) continue;
        const cut = line.lastIndexOf(': ');
        if (cut < 0) continue;
        result.items.push({ label: line.slice(2, cut), price: toNumber(line.slice(cut + 2)) });
      }
      result.total = toNumber(totalLine.slice(totalLine.lastIndexOf(': ') + 2));
    }
    const tick = lines.find((l) => l.startsWith('☑') || l.startsWith('☐'));
    if (tick) result.signed = tick.startsWith('☑');
  }
  return result;
}

/** The summary with the long consent statements folded into one line. */
function shortForm(summary) {
  return String(summary).split(/\n\s*\n/).map((block) => {
    const lines = block.split('\n');
    const tick = lines.find((l) => l.startsWith('☑') || l.startsWith('☐'));
    if (!tick) return block;
    return [lines[0], tick.startsWith('☑') ? '☑ Agreed to all consent statements' : '☐ Did NOT agree to the consent statements'].join('\n');
  }).join('\n\n').trim();
}

/** "Tiếng Việt / English" → "English". Text without a " / " is returned unchanged. */
function english(value) {
  const s = String(value == null ? '' : value).trim();
  const parts = s.split(' / ');
  return parts.length > 1 ? parts.slice(1).join(' / ') : s;
}

/** "289.000₫" → 289000. Anything that isn't a price → ''. */
function toNumber(value) {
  const digits = String(value || '').replace(/[^\d]/g, '');
  return digits ? Number(digits) : '';
}

function dash(value) {
  const s = String(value || '').trim();
  return s === '—' || s === '-' ? '' : s;
}

/**
 * Stores values as plain text: keeps leading zeros in phone numbers and stops text that starts
 * with = + - @ from being treated as a spreadsheet formula.
 */
function plain(value, max) {
  let s = value == null ? '' : String(value);
  if (max && s.length > max) s = s.slice(0, max) + '…';
  return s === '' ? '' : "'" + s;
}

// ---------------------------------------------------------------------------
// Sheet layout
// ---------------------------------------------------------------------------

/** Inserts the row at the top (just under the headings), so the newest check-in is always first. */
function addRow(sheet, values) {
  sheet.insertRowAfter(1);
  const range = sheet.getRange(2, 1, 1, values.length);
  range.setValues([values]);
  styleRows(sheet, 2, 1);
}

function styleRows(sheet, firstRow, count) {
  const range = sheet.getRange(firstRow, 1, count, COLUMNS.length);
  range.setFontWeight('normal').setBackground('#FFFFFF').setFontColor('#1E2B22').setVerticalAlignment('middle')
    .setWrapStrategy(SpreadsheetApp.WrapStrategy.CLIP);
  sheet.getRange(firstRow, COL['Date'], count, 1).setNumberFormat('ddd d mmm yyyy, hh:mm');
  sheet.getRange(firstRow, COL['Total (₫)'], count, 1).setNumberFormat('#,##0').setFontWeight('bold');
  sheet.getRange(firstRow, COL['Name'], count, 1).setFontWeight('bold');
  sheet.getRange(firstRow, COL['Consent'], count, 1).setHorizontalAlignment('center');
  sheet.setRowHeights(firstRow, count, 28);
}

/** Headings, widths, frozen panes and the red highlight for health notes. Safe to run again. */
function setupSheet(sheet) {
  const titles = COLUMNS.map((c) => c.title);
  if (sheet.getMaxColumns() < titles.length) sheet.insertColumnsAfter(sheet.getMaxColumns(), titles.length - sheet.getMaxColumns());
  sheet.getRange(1, 1, 1, titles.length).setValues([titles])
    .setFontWeight('bold').setBackground('#1E2B22').setFontColor('#FBF8F3')
    .setVerticalAlignment('middle').setWrapStrategy(SpreadsheetApp.WrapStrategy.CLIP);
  sheet.setRowHeight(1, 32);
  sheet.setFrozenRows(1);
  sheet.setFrozenColumns(2);
  COLUMNS.forEach((c, i) => sheet.setColumnWidth(i + 1, c.width));
  sheet.hideColumns(RAW_COL);

  const health = sheet.getRange(2, HEALTH_COL, Math.max(1, sheet.getMaxRows() - 1), 1);
  const rules = sheet.getConditionalFormatRules().filter((r) =>
    !r.getRanges().some((g) => g.getColumn() === HEALTH_COL));
  rules.push(SpreadsheetApp.newConditionalFormatRule()
    .whenCellNotEmpty().setBackground('#F8D7D3').setFontColor('#8A1C12')
    .setRanges([health]).build());
  sheet.setConditionalFormatRules(rules);
}

function getSheet() {
  const spreadsheet = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = spreadsheet.getSheetByName(SHEET_NAME);
  if (sheet && isOldLayout(sheet)) {
    sheet.setName(OLD_SHEET_NAME);
    sheet = null;
  }
  if (!sheet) {
    sheet = spreadsheet.insertSheet(SHEET_NAME, 0);
    setupSheet(sheet);
    copyOldRows(spreadsheet.getSheetByName(OLD_SHEET_NAME), sheet);
  }
  return sheet;
}

function isOldLayout(sheet) {
  return sheet.getLastRow() > 0 && sheet.getRange(1, 1).getValue() === 'Submitted';
}

/**
 * Optional: run once from the editor to switch to the new layout straight away (otherwise it happens
 * by itself with the next check-in). The old tab is kept as "Check-ins (old layout)"; nothing is deleted.
 */
function tidyUp() {
  setupSheet(getSheet());
}

/** Copies rows from the old-layout tab into the new tab, newest first. */
function copyOldRows(old, sheet) {
  if (!old || old.getLastRow() < 2) return;
  const headers = old.getRange(1, 1, 1, old.getLastColumn()).getValues()[0];
  const idx = Object.fromEntries(headers.map((h, i) => [h, i]));
  const rows = old.getRange(2, 1, old.getLastRow() - 1, old.getLastColumn()).getValues();
  const converted = rows
    .filter((r) => r[idx['Submitted']] && r[idx['Full name']] !== 'TEST - Claude diagnostic')
    .map((r) => buildRow({
      service: r[idx['Service']],
      full_name: r[idx['Full name']],
      phone: r[idx['Phone']],
      date_of_birth: r[idx['Date of birth']],
      technician: r[idx['Technician']],
      health_flags: r[idx['Health flags']],
      photo_consent: r[idx['Photo consent']],
      language: r[idx['Language']],
      summary: r[idx['Summary']],
      answers_json: r[idx['Answers (JSON)']],
    }, r[idx['Submitted']], String(r[idx['Signature']] || '')))
    .sort((a, b) => b[0] - a[0]);
  if (!converted.length) return;
  sheet.insertRowsAfter(1, converted.length);
  sheet.getRange(2, 1, converted.length, COLUMNS.length).setValues(converted);
  styleRows(sheet, 2, converted.length);
}

// ---------------------------------------------------------------------------
// Signature and email alert
// ---------------------------------------------------------------------------

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
  const row = buildRow(data, new Date(), signatureUrl);
  const service = data.service_en || english(data.service);
  const subject = `Check-in: ${data.full_name} · ${service}${flags !== 'None' ? ' · ⚠ health note' : ''}`;
  const body = [
    `${data.full_name} (${data.phone || 'no phone'}) checked in for ${service}.`,
    row[4] ? `Chosen: ${String(row[4]).replace(/^'/, '')}` : null,
    row[5] !== '' ? `Total: ${Number(row[5]).toLocaleString('en-US')}₫` : null,
    `Health: ${flags}`,
    '',
    `Sheet: ${SpreadsheetApp.getActiveSpreadsheet().getUrl()}`,
    signatureUrl ? `Signature: ${signatureUrl}` : null,
  ].filter((line) => line !== null).join('\n');
  MailApp.sendEmail(to, subject, body);
}

function json(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(ContentService.MimeType.JSON);
}
