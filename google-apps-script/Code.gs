/**
 * Seren check-in and bill receiver.
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
    if (data.type === 'bill') return json(saveBill(data)); // from the bill page (see "Bills" below)

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
  sheet.setRowHeightsForced(firstRow, count, 28); // stays one line even when the full form has line breaks
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
 * Optional: run from the editor to switch to the new layout straight away (otherwise it happens by itself
 * with the next check-in) or to re-apply the formatting to every row. The old tab is kept as
 * "Check-ins (old layout)"; nothing is deleted.
 */
function tidyUp() {
  const sheet = getSheet();
  setupSheet(sheet);
  if (sheet.getLastRow() > 1) styleRows(sheet, 2, sheet.getLastRow() - 1);
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

// ===========================================================================
// Bills (from checkin.serensaigon.com/bill/)
//
// Every saved bill becomes one row in "Hoá đơn - Bills" and one row per service in "Chi tiết DV - Lines".
// Saving the same bill again (same bill id) replaces its rows, so nothing is counted twice.
// After each save the two summary tabs are rebuilt:
//   "Tổng kết - Daily"   revenue per day and per month, split by money source.
//   "Nhân viên - Staff"  revenue and commission per staff member, per month and per day.
// Commission rates are read from "Hoa hồng - Rates"; change them there, then SEREN menu › Tính lại / Recalculate.
// Download everything as Excel with File › Download › Microsoft Excel (.xlsx).
// ===========================================================================

const BILL_TABS = {
  bills: 'Hoá đơn - Bills',
  lines: 'Chi tiết DV - Lines',
  daily: 'Tổng kết - Daily',
  staff: 'Nhân viên - Staff',
  rates: 'Hoa hồng - Rates',
};

const SOURCES = ['Tiền mặt', 'Chuyển khoản', 'Cà thẻ', 'Khác'];
const SOURCE_EN = { 'Tiền mặt': 'Cash', 'Chuyển khoản': 'Transfer', 'Cà thẻ': 'Card', 'Khác': 'Other' };
const METHOD_SOURCE = { cash: 'Tiền mặt', transfer: 'Chuyển khoản', card: 'Cà thẻ', momo: 'Khác', zalopay: 'Khác', member: 'Khác' };

// Commission groups sent by the bill page, and how each is paid.
const COMM_GROUPS = {
  nails: { name: 'Nails', kind: 'pct', rate: 0.10 },
  lash: { name: 'Nối mi', kind: 'pct', rate: 0.10 },
  wax: { name: 'Waxing', kind: 'pct', rate: 0.15 },
  heel: { name: 'Chà gót', kind: 'pct', rate: 0.15 },
  massage: { name: 'Massage', kind: 'turn', rate: '' },
  headspa: { name: 'Gội đầu', kind: 'turn', rate: '' },
  none: { name: 'Không HH', kind: 'none', rate: '' },
};

const BILL_COLUMNS = [
  { title: 'Mã / ID', width: 60 },
  { title: 'Số HĐ / No.', width: 115 },
  { title: 'Ngày / Date', width: 95 },
  { title: 'Giờ / Time', width: 60 },
  { title: 'Khách / Customer', width: 150 },
  { title: 'SĐT / Phone', width: 110 },
  { title: 'Dịch vụ / Services', width: 300 },
  { title: 'Nhân viên / Staff', width: 140 },
  { title: 'Tạm tính / Subtotal', width: 105 },
  { title: 'Giảm giá / Discount', width: 95 },
  { title: 'VAT', width: 80 },
  { title: 'Tổng thu / Total paid', width: 115 },
  { title: 'Thanh toán / Method', width: 120 },
  { title: 'Nguồn tiền / Source', width: 115 },
  { title: 'Khách đưa / Received', width: 110 },
  { title: 'Tiền thừa / Change', width: 100 },
  { title: 'Lưu lúc / Saved', width: 140 },
];
const LINE_COLUMNS = [
  { title: 'Mã HĐ / Bill ID', width: 60 },
  { title: 'Số HĐ / No.', width: 115 },
  { title: 'Ngày / Date', width: 95 },
  { title: 'Nhân viên / Staff', width: 120 },
  { title: 'Loại / Category', width: 120 },
  { title: 'Dịch vụ / Service', width: 280 },
  { title: 'SL / Qty', width: 55 },
  { title: 'Đơn giá / Price', width: 95 },
  { title: 'Thành tiền / Amount', width: 105 },
  { title: 'Giảm giá / Discount', width: 95 },
  { title: 'Sau giảm / Net', width: 100 },
  { title: 'Nhóm HH / Commission group', width: 160 },
  { title: 'Lượt / Sessions', width: 75 },
  { title: 'Nguồn tiền / Source', width: 115 },
];
const BILL_MONEY_COLS = [9, 10, 11, 12, 15, 16];
const LINE_MONEY_COLS = [8, 9, 10, 11];

/** Adds the SEREN menu to the Google Sheet. */
function onOpen() {
  SpreadsheetApp.getUi().createMenu('SEREN')
    .addItem('Tính lại tổng kết / Recalculate totals', 'rebuildBillSummaries')
    .addToUi();
}

/** Called from doPost for { type: 'bill' }. */
function saveBill(data) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const uid = String(data.uid || '').replace(/[^\w-]/g, '').slice(0, 64);
  const lines = Array.isArray(data.lines) ? data.lines.slice(0, 200) : [];
  if (!uid || !lines.length) throw new Error('Bill has no id or no services');
  const date = parseIsoDate(data.date);
  if (!date) throw new Error('Bill has no date');

  // First bill: create the tabs in reading order (totals first), after the existing check-in tabs.
  [BILL_TABS.daily, BILL_TABS.staff].forEach((n) => { if (!ss.getSheetByName(n)) ss.insertSheet(n); });
  const billsSheet = billTab(ss, BILL_TABS.bills, BILL_COLUMNS, BILL_MONEY_COLS);
  const linesSheet = billTab(ss, BILL_TABS.lines, LINE_COLUMNS, LINE_MONEY_COLS);
  ratesTab(ss);
  removeBillRows(billsSheet, uid);
  removeBillRows(linesSheet, uid);

  const source = METHOD_SOURCE[data.method] || (SOURCES.includes(data.source) ? data.source : 'Khác');
  const money = (v) => Math.max(0, Math.round(Number(v) || 0));
  const staff = [...new Set(lines.map((l) => cleanText(l.staff, 60)).filter(Boolean))].join(', ');
  const services = lines.map((l) => {
    const qty = Math.max(1, Math.round(Number(l.qty) || 1));
    return `${cleanText(l.name_vi, 120)}${qty > 1 ? ` ×${qty}` : ''}`;
  }).join(', ');

  const billRow = [
    uid, plain(cleanText(data.no, 20)), date, plain(cleanText(data.time, 5)),
    plain(cleanText(data.customer, 80)), plain(cleanText(data.phone, 30)),
    plain(services, 2000), plain(staff),
    money(data.subtotal), money(data.discount), money(data.vat), money(data.total),
    plain(cleanText(data.method_label, 40)), source,
    money(data.received) || '', money(data.change) || '', new Date(),
  ];
  billsSheet.insertRowsAfter(1, 1);
  billsSheet.getRange(2, 1, 1, billRow.length).setValues([billRow]);
  styleBillRows(billsSheet, 2, 1, BILL_COLUMNS, BILL_MONEY_COLS);

  const lineRows = lines.map((l) => {
    const qty = Math.max(1, Math.round(Number(l.qty) || 1));
    const group = COMM_GROUPS[l.comm] ? l.comm : 'none';
    return [
      uid, plain(cleanText(data.no, 20)), date, plain(cleanText(l.staff, 60)),
      plain(cleanText(l.category, 40)), plain(cleanText(l.name_vi, 200)),
      qty, money(l.price), money(l.amount), money(l.discount), money(l.net),
      COMM_GROUPS[group].name, COMM_GROUPS[group].kind === 'turn' ? qty : 0, source,
    ];
  });
  linesSheet.insertRowsAfter(1, lineRows.length);
  linesSheet.getRange(2, 1, lineRows.length, LINE_COLUMNS.length).setValues(lineRows);
  styleBillRows(linesSheet, 2, lineRows.length, LINE_COLUMNS, LINE_MONEY_COLS);

  rebuildBillSummaries();
  return { ok: true };
}

/** "2026-10-06" → a date at noon (noon keeps the same calendar day in any time zone setting). */
function parseIsoDate(value) {
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(String(value || ''));
  return m ? new Date(Number(m[1]), Number(m[2]) - 1, Number(m[3]), 12) : null;
}

function cleanText(value, max) {
  return String(value == null ? '' : value).replace(/[\r\n\t]+/g, ' ').trim().slice(0, max || 200);
}

function removeBillRows(sheet, uid) {
  const last = sheet.getLastRow();
  if (last < 2) return;
  const ids = sheet.getRange(2, 1, last - 1, 1).getValues();
  for (let i = ids.length - 1; i >= 0; i -= 1) {
    if (String(ids[i][0]) === uid) sheet.deleteRow(i + 2);
  }
}

/** New rows take the heading's dark style when inserted under it, so set plain formatting explicitly. */
function styleBillRows(sheet, first, count, columns, moneyCols) {
  sheet.getRange(first, 1, count, columns.length)
    .setFontWeight('normal').setBackground('#FFFFFF').setFontColor('#1E2B22').setVerticalAlignment('middle')
    .setWrapStrategy(SpreadsheetApp.WrapStrategy.CLIP);
  sheet.getRange(first, 3, count, 1).setNumberFormat('dd/MM/yyyy');
  moneyCols.forEach((col) => sheet.getRange(first, col, count, 1).setNumberFormat('#,##0'));
  if (columns === BILL_COLUMNS) {
    sheet.getRange(first, 12, count, 1).setFontWeight('bold');
    sheet.getRange(first, columns.length, count, 1).setNumberFormat('dd/MM/yyyy HH:mm');
  }
}

/** Finds or creates a data tab with headings, widths and number formats. */
function billTab(ss, name, columns, moneyCols) {
  let sheet = ss.getSheetByName(name);
  if (sheet) return sheet;
  sheet = ss.insertSheet(name);
  const titles = columns.map((c) => c.title);
  if (sheet.getMaxColumns() < titles.length) sheet.insertColumnsAfter(sheet.getMaxColumns(), titles.length - sheet.getMaxColumns());
  sheet.getRange(1, 1, 1, titles.length).setValues([titles])
    .setFontWeight('bold').setBackground('#1E2B22').setFontColor('#FBF8F3').setVerticalAlignment('middle');
  sheet.setRowHeight(1, 32);
  sheet.setFrozenRows(1);
  columns.forEach((c, i) => sheet.setColumnWidth(i + 1, c.width));
  const rows = sheet.getMaxRows() - 1;
  sheet.getRange(2, 3, rows, 1).setNumberFormat('dd/MM/yyyy');
  moneyCols.forEach((col) => sheet.getRange(2, col, rows, 1).setNumberFormat('#,##0'));
  if (name === BILL_TABS.bills) sheet.getRange(2, columns.length, rows, 1).setNumberFormat('dd/MM/yyyy HH:mm');
  sheet.hideColumns(1);
  sheet.getRange(1, 1, sheet.getMaxRows(), titles.length).createFilter(); // filter by staff, date, source…
  return sheet;
}

/** Commission rates, editable by the owner. Created once with the agreed defaults. */
function ratesTab(ss) {
  let sheet = ss.getSheetByName(BILL_TABS.rates);
  if (sheet) return sheet;
  sheet = ss.insertSheet(BILL_TABS.rates);
  const rows = [
    ['Nhóm / Group', 'Cách tính / How', 'Mức / Rate', 'Ghi chú / Note'],
    ['Nails', '% sau giảm giá / % after discount', 0.10, 'Tất cả dịch vụ nail / All nail services'],
    ['Nối mi', '% sau giảm giá / % after discount', 0.10, 'Nối mi, nâng cấp sợi, mi dưới, tháo mi / Lash extensions'],
    ['Waxing', '% sau giảm giá / % after discount', 0.15, 'Tất cả waxing / All waxing'],
    ['Chà gót', '% sau giảm giá / % after discount', 0.15, 'Thêm bằng mục "Khác" / Add with "Other"'],
    ['Massage', '₫ mỗi lượt / ₫ per session', '', 'Điền số tiền mỗi lượt / Fill in the amount per session'],
    ['Gội đầu', '₫ mỗi lượt / ₫ per session', '', 'Liệu trình gội đầu (không tính dịch vụ thêm) / Head spa rituals, not add-ons'],
  ];
  sheet.getRange(1, 1, rows.length, 4).setValues(rows);
  sheet.getRange(1, 1, 1, 4).setFontWeight('bold').setBackground('#1E2B22').setFontColor('#FBF8F3');
  sheet.getRange(2, 3, 4, 1).setNumberFormat('0%');
  sheet.getRange(6, 3, 2, 1).setNumberFormat('#,##0');
  sheet.getRange(2, 3, 6, 1).setBackground('#FFF7E0').setFontWeight('bold');
  sheet.setColumnWidths(1, 1, 110);
  sheet.setColumnWidth(2, 230);
  sheet.setColumnWidth(3, 90);
  sheet.setColumnWidth(4, 420);
  sheet.getRange(9, 1).setValue('Sau khi sửa mức hoa hồng: menu SEREN › Tính lại tổng kết. / After changing a rate: SEREN menu › Recalculate totals.')
    .setFontStyle('italic');
  sheet.setFrozenRows(1);
  return sheet;
}

/** { 'Nails': {kind, rate}, … } from the Rates tab. */
function readRates(ss) {
  const sheet = ratesTab(ss);
  const values = sheet.getRange(2, 1, Math.max(1, sheet.getLastRow() - 1), 3).getValues();
  const rates = {};
  Object.values(COMM_GROUPS).forEach((g) => { rates[g.name] = { kind: g.kind, rate: 0 }; });
  values.forEach(([name, how, rate]) => {
    if (!name || !rates[name]) return;
    rates[name].rate = Number(rate) || 0;
  });
  return rates;
}

/** Rebuilds the Daily and Staff tabs from the bill rows. Also on the SEREN menu. */
function rebuildBillSummaries() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const tz = ss.getSpreadsheetTimeZone();
  const billsSheet = billTab(ss, BILL_TABS.bills, BILL_COLUMNS, BILL_MONEY_COLS);
  const linesSheet = billTab(ss, BILL_TABS.lines, LINE_COLUMNS, LINE_MONEY_COLS);
  const read = (sheet, width) => (sheet.getLastRow() < 2 ? [] : sheet.getRange(2, 1, sheet.getLastRow() - 1, width).getValues());
  const day = (d) => (d instanceof Date ? Utilities.formatDate(d, tz, 'yyyy-MM-dd') : String(d || ''));

  const bills = read(billsSheet, BILL_COLUMNS.length).filter((r) => r[0]).map((r) => ({
    day: day(r[2]), discount: Number(r[9]) || 0, vat: Number(r[10]) || 0, total: Number(r[11]) || 0, source: String(r[13] || 'Khác'),
  }));
  const lines = read(linesSheet, LINE_COLUMNS.length).filter((r) => r[0]).map((r) => ({
    day: day(r[2]), staff: String(r[3] || '').trim(), net: Number(r[10]) || 0, group: String(r[11] || 'Không HH'), turns: Number(r[12]) || 0,
  }));
  const s = computeBillSummaries(bills, lines, readRates(ss));
  writeSummary(ss, BILL_TABS.daily, s.dailyBlocks);
  writeSummary(ss, BILL_TABS.staff, s.staffBlocks);
}

/**
 * Pure calculation (no spreadsheet access), so it can be tested on its own.
 * bills: [{day:'yyyy-MM-dd', discount, vat, total, source}]; lines: [{day, staff, net, group, turns}];
 * rates: {'Nails': {kind:'pct', rate:0.1}, 'Massage': {kind:'turn', rate:50000}, …}.
 * Returns blocks of rows for the two summary tabs: [{title, header, rows, money:[col indexes], date:[col indexes]}].
 */
function computeBillSummaries(bills, lines, rates) {
  const by = (list, keyFn) => {
    const map = new Map();
    list.forEach((item) => {
      const k = keyFn(item);
      if (!map.has(k)) map.set(k, []);
      map.get(k).push(item);
    });
    return map;
  };
  const sum = (list, f) => list.reduce((a, x) => a + f(x), 0);
  const month = (d) => d.slice(0, 7);

  const sourceRows = (groups, labelFn) => [...groups.entries()]
    .sort((a, b) => (a[0] < b[0] ? 1 : -1))
    .map(([k, list]) => {
      const bySource = SOURCES.map((src) => sum(list.filter((b) => b.source === src), (b) => b.total));
      const total = sum(list, (b) => b.total);
      const vat = sum(list, (b) => b.vat);
      return [labelFn(k), list.length, ...bySource, total, vat, total - vat, sum(list, (b) => b.discount)];
    });
  const sourceHeader = ['Số HĐ / Bills', ...SOURCES.map((s) => `${s} / ${SOURCE_EN[s]}`),
    'Tổng thu / Total paid', 'Trong đó VAT / of which VAT', 'Doanh thu (không VAT) / Revenue excl. VAT', 'Giảm giá / Discounts'];
  const sourceMoney = [2, 3, 4, 5, 6, 7, 8, 9];

  const dailyBlocks = [
    {
      title: 'Theo tháng / By month',
      header: ['Tháng / Month', ...sourceHeader],
      rows: sourceRows(by(bills, (b) => month(b.day)), (k) => k),
      money: sourceMoney, date: [],
    },
    {
      title: 'Theo ngày / By day',
      header: ['Ngày / Date', ...sourceHeader],
      rows: sourceRows(by(bills, (b) => b.day), (k) => isoToDate(k)),
      money: sourceMoney, date: [0],
    },
  ];

  const rate = (name) => (rates[name] ? rates[name].rate : 0);
  const staffRow = (list) => {
    const netOf = (names) => sum(list.filter((l) => names.includes(l.group)), (l) => l.net);
    const turnsOf = (name) => sum(list.filter((l) => l.group === name), (l) => l.turns);
    const nailsLash = netOf(['Nails', 'Nối mi']);
    const waxHeel = netOf(['Waxing', 'Chà gót']);
    const pct10 = netOf(['Nails']) * rate('Nails') + netOf(['Nối mi']) * rate('Nối mi');
    const pct15 = netOf(['Waxing']) * rate('Waxing') + netOf(['Chà gót']) * rate('Chà gót');
    const massage = turnsOf('Massage');
    const headspa = turnsOf('Gội đầu');
    const turnPay = massage * rate('Massage') + headspa * rate('Gội đầu');
    return [sum(list, (l) => l.net), nailsLash, Math.round(pct10), waxHeel, Math.round(pct15), massage, headspa,
      Math.round(turnPay), Math.round(pct10 + pct15 + turnPay)];
  };
  const staffHeader = ['Nhân viên / Staff', 'Doanh thu DV (sau giảm) / Service revenue', 'Nails + Nối mi', 'HH Nails + Nối mi / Commission',
    'Waxing + Chà gót', 'HH Waxing + Chà gót / Commission', 'Lượt massage / Massage sessions', 'Lượt gội đầu / Head spa sessions',
    'Tiền lượt / Session pay', 'Tổng hoa hồng / Total commission'];
  const staffName = (l) => l.staff || '(chưa chọn / not set)';
  const staffRows = (periodFn, labelFn) => {
    const rows = [];
    [...by(lines, (l) => periodFn(l.day)).entries()]
      .sort((a, b) => (a[0] < b[0] ? 1 : -1))
      .forEach(([period, list]) => {
        [...by(list, staffName).entries()].sort((a, b) => a[0].localeCompare(b[0]))
          .forEach(([name, items]) => rows.push([labelFn(period), name, ...staffRow(items)]));
      });
    return rows;
  };
  const staffMoney = [2, 3, 4, 5, 6, 9, 10];
  const staffBlocks = [
    {
      title: 'Theo tháng / By month',
      header: ['Tháng / Month', ...staffHeader],
      rows: staffRows(month, (k) => k),
      money: staffMoney, date: [],
    },
    {
      title: 'Theo ngày / By day',
      header: ['Ngày / Date', ...staffHeader],
      rows: staffRows((d) => d, (k) => isoToDate(k)),
      money: staffMoney, date: [0],
    },
  ];
  return { dailyBlocks, staffBlocks };
}

function isoToDate(iso) {
  return parseIsoDate(iso) || iso;
}

/** Clears a summary tab and writes the blocks one under another. */
function writeSummary(ss, name, blocks) {
  let sheet = ss.getSheetByName(name);
  if (!sheet) sheet = ss.insertSheet(name);
  sheet.clear();
  const width = Math.max(...blocks.map((b) => b.header.length));
  if (sheet.getMaxColumns() < width) sheet.insertColumnsAfter(sheet.getMaxColumns(), width - sheet.getMaxColumns());
  const needed = blocks.reduce((n, b) => n + b.rows.length + 4, 2);
  if (sheet.getMaxRows() < needed) sheet.insertRowsAfter(sheet.getMaxRows(), needed - sheet.getMaxRows());

  sheet.getRange(1, 1).setValue(`Cập nhật / Updated: ${Utilities.formatDate(new Date(), ss.getSpreadsheetTimeZone(), 'dd/MM/yyyy HH:mm')}`)
    .setFontStyle('italic').setFontColor('#7D7169');
  let row = 3;
  blocks.forEach((b) => {
    sheet.getRange(row, 1).setValue(b.title).setFontWeight('bold').setFontSize(13);
    row += 1;
    sheet.getRange(row, 1, 1, b.header.length).setValues([b.header])
      .setFontWeight('bold').setBackground('#1E2B22').setFontColor('#FBF8F3').setWrap(true).setVerticalAlignment('middle');
    sheet.setRowHeight(row, 44);
    row += 1;
    if (b.rows.length) {
      sheet.getRange(row, 1, b.rows.length, b.header.length).setValues(b.rows);
      b.money.forEach((c) => sheet.getRange(row, c + 1, b.rows.length, 1).setNumberFormat('#,##0'));
      b.date.forEach((c) => sheet.getRange(row, c + 1, b.rows.length, 1).setNumberFormat('dd/MM/yyyy'));
      row += b.rows.length;
    } else {
      sheet.getRange(row, 1).setValue('Chưa có hoá đơn / No bills yet').setFontColor('#7D7169');
      row += 1;
    }
    row += 2;
  });
  sheet.setColumnWidth(1, 105);
  for (let c = 2; c <= width; c += 1) sheet.setColumnWidth(c, 120);
  sheet.setFrozenColumns(name === BILL_TABS.staff ? 2 : 1);
}
