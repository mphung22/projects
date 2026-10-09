/* Seren bill: reception adds every service a customer had, from any category and in any quantity,
   then shows the total, prints a receipt or shares it as an image (for Zalo, WeChat, email…).

   The menu and prices come from ../app.js (SERVICES), the same list the check-in forms use, so a price changed
   there changes here too. Only the member cards below are listed in this file.
   Each service line records which staff member did it. "Lưu hoá đơn / Save bill" (and printing) sends the bill to
   Seren's private Google Sheet through the same Google Apps Script as the check-in (config.js), where the sheet
   adds daily totals by money source and staff commission. Saving the same bill again replaces it.
   The bill in progress is kept on this device so a page reload does not lose it; a bill that could not be sent
   (no internet) is kept and sent again automatically. */
(() => {
  'use strict';

  const W = (vi, en) => ({ vi, en });

  const SHOP = {
    name: 'SEREN',
    sub: 'by Serendipity Retreat',
    address: '10E Đ. Lương Hữu Khánh, P. Bến Thành, TP.HCM',
    contact: '+84 879 303 993 · serensaigon.com',
  };
  const VAT_RATE = 0.08;
  // Receipt printer: Xprinter XP-58IIT (58 mm thermal paper). Change PAPER_MM to 80 for an 80 mm printer
  // (and the 48mm width in bill.css to 72mm).
  const PAPER_MM = 58;
  /** Payment methods that always add VAT on top of the bill. */
  const VAT_PAYMENTS = ['card'];
  const TZ = 'Asia/Ho_Chi_Minh';
  const STORE_KEY = 'seren-bill';
  const QUEUE_KEY = 'seren-bill-queue';

  // Staff who do services. Add or remove names here.
  const STAFF = ['Hà Khanh', 'Mỹ An'];
  // Outside workers' names typed on this device, offered again next time (newest first).
  const OUTSIDE_KEY = 'seren-bill-outside-staff';

  // Commission groups. The rates themselves live in the Google Sheet ("Hoa hồng - Rates" tab):
  // Nails and lash extensions 10% after discount, waxing and heel scrub 15%, massage and head spa per session.
  const COMM = {
    nails: W('Nails', 'Nails'),
    lash: W('Nối mi', 'Lash extensions'),
    wax: W('Waxing', 'Waxing'),
    heel: W('Chà gót', 'Heel scrub'),
    massage: W('Massage / body (20%)', 'Massage / body (20%)'),
    headspa: W('Gội đầu (15%)', 'Head spa (15%)'),
    none: W('Không hoa hồng', 'No commission'),
  };
  // Which money source each payment method counts under in the daily totals.
  const SOURCE = { cash: 'Tiền mặt', transfer: 'Chuyển khoản', card: 'Cà thẻ', momo: 'Khác', zalopay: 'Khác', member: 'Khác' };
  const LANG_KEY = 'seren-bill-lang';

  // ---------------------------------------------------------------------------
  // Wording
  // ---------------------------------------------------------------------------

  const S = {
    title: W('Hoá đơn', 'Bill'),
    sub: W('Thêm tất cả dịch vụ khách đã dùng', 'Add every service the customer had'),
    customer: W('Khách hàng', 'Customer'),
    name: W('Tên khách', 'Customer name'),
    phone: W('Số điện thoại', 'Phone'),
    staff: W('Kỹ thuật viên', 'Staff'),
    optional: W('không bắt buộc', 'optional'),
    add: W('Thêm dịch vụ', 'Add services'),
    addHint: W('Chạm để thêm. Chạm lại để thêm một lần nữa.', 'Tap to add. Tap again to add another.'),
    bill: W('Hoá đơn', 'Bill'),
    empty: W('Chưa có dịch vụ nào.', 'No services added yet.'),
    subtotal: W('Tạm tính', 'Subtotal'),
    discount: W('Giảm giá', 'Discount'),
    vat: W('Thuế VAT 8%', 'VAT 8%'),
    total: W('Tổng cộng', 'Total'),
    payment: W('Thanh toán', 'Payment'),
    received: W('Khách đưa', 'Cash received'),
    change: W('Tiền thừa', 'Change'),
    view: W('Xem hoá đơn', 'View receipt'),
    newBill: W('Hoá đơn mới', 'New bill'),
    edit: W('Sửa hoá đơn', 'Edit bill'),
    print: W('In', 'Print'),
    share: W('Gửi ảnh', 'Share image'),
    save: W('Lưu ảnh', 'Save image'),
    receipt: W('Hoá đơn', 'Receipt'),
    billNo: W('Số', 'No.'),
    date: W('Ngày', 'Date'),
    paidBy: W('Thanh toán', 'Paid by'),
    thanks: W('Cảm ơn quý khách! Hẹn gặp lại.', 'Thank you! See you again soon.'),
    enterPrice: W('Giá thực tế', 'Actual price'),
    from: W('Bảng giá', 'Menu price'),
    custom: W('Khác', 'Other'),
    customName: W('Tên dịch vụ / sản phẩm', 'Service or product'),
    customPrice: W('Giá (₫)', 'Price (₫)'),
    addBtn: W('Thêm vào hoá đơn', 'Add to bill'),
    remove: W('Xoá', 'Remove'),
    items: W('dịch vụ', 'items'),
    confirmNew: W('Bắt đầu hoá đơn mới? Hoá đơn hiện tại sẽ bị xoá.', 'Start a new bill? The current bill will be cleared.'),
    rangeWarn: W('Có dịch vụ giá theo khoảng. Vui lòng nhập giá thực tế trước khi xem hoá đơn.',
                 'Some items have a price range. Enter the actual price before viewing the receipt.'),
    nothing: W('Thêm ít nhất một dịch vụ.', 'Add at least one service.'),
    memberCards: W('Thẻ thành viên', 'Member cards'),
    vatNote: W('Thanh toán bằng thẻ: cộng thêm 8% VAT.', 'Card payments: 8% VAT is added.'),
    qty: W('SL', 'Qty'),
    staffShort: W('KTV', 'Staff'),
    whoDid: W('Nhân viên làm', 'Done by'),
    staffWarn: W('Chọn nhân viên cho từng dịch vụ trước khi xem hoá đơn.', 'Choose who did each service before viewing the receipt.'),
    outside: W('+ Thợ ngoài', '+ Outside'),
    outsideName: W('Tên thợ ngoài', 'Outside worker name'),
    commGroup: W('Nhóm hoa hồng', 'Commission group'),
    comboHint: W('Gói gội + body: thêm 2 dòng riêng (phần gội, phần body) với giá từng phần, để hoa hồng tính đúng 15% và 20%.',
                 'Head spa + body combo: add two separate lines (head spa part, body part) with each part\'s price, so commission is 15% and 20% correctly.'),
    saveBill: W('Lưu hoá đơn', 'Save bill'),
    saving: W('Đang lưu…', 'Saving…'),
    saved: W('Đã lưu vào Google Sheet', 'Saved to Google Sheet'),
    notSaved: W('Chưa lưu', 'Not saved yet'),
    changed: W('Đã sửa sau khi lưu, vui lòng lưu lại', 'Changed since saving, please save again'),
    queued: W('Không có mạng. Hoá đơn sẽ tự gửi lại khi có mạng.', 'No connection. The bill will be sent automatically when back online.'),
    saveError: W('Không lưu được. Vui lòng thử lại.', 'Could not save. Please try again.'),
    notConfigured: W('Chưa cài đặt nơi lưu hoá đơn.', 'Bill saving is not set up.'),
    confirmUnsaved: W('Hoá đơn này CHƯA được lưu. Vẫn bắt đầu hoá đơn mới?', 'This bill has NOT been saved. Start a new bill anyway?'),
  };

  const PAYMENTS = [
    { id: 'cash', label: W('Tiền mặt', 'Cash') },
    { id: 'card', label: W('Thẻ ngân hàng (+8% VAT)', 'Card (+8% VAT)'), onReceipt: W('Thẻ ngân hàng', 'Card') },
    { id: 'transfer', label: W('Chuyển khoản', 'Bank transfer') },
    { id: 'momo', label: W('Momo', 'Momo') },
    { id: 'zalopay', label: W('ZaloPay', 'ZaloPay') },
    { id: 'member', label: W('Thẻ thành viên', 'Member card') },
  ];

  // Prepaid member cards, as on serensaigon.com/pricing (SEREN membership).
  const MEMBER_CARDS = [
    { id: 'card_touch', label: W('Thẻ Seren Touch · dùng 550.000₫', 'Seren Touch card · 550.000₫ to spend'), price: '500.000₫' },
    { id: 'card_flow', label: W('Thẻ Seren Flow · dùng 1.150.000₫', 'Seren Flow card · 1.150.000₫ to spend'), price: '1.000.000₫' },
    { id: 'card_glow', label: W('Thẻ Seren Glow · dùng 2.250.000₫', 'Seren Glow card · 2.250.000₫ to spend'), price: '2.000.000₫' },
    { id: 'card_balance', label: W('Thẻ Seren Balance · dùng 3.450.000₫', 'Seren Balance card · 3.450.000₫ to spend'), price: '3.000.000₫' },
    { id: 'card_vip', label: W('Thẻ Serendipity VIP · dùng 5.900.000₫', 'Serendipity VIP card · 5.900.000₫ to spend'), price: '5.000.000₫' },
  ];

  // ---------------------------------------------------------------------------
  // Menu, built from the check-in forms
  // ---------------------------------------------------------------------------

  /** '450.000₫' → { lo: 450000, hi: 450000 }; '10.000 – 50.000₫' → { lo: 10000, hi: 50000 }. */
  function parsePrice(price) {
    const nums = (String(price).match(/\d[\d.]*/g) || []).map((n) => Number(n.replace(/\./g, '')));
    return { lo: nums[0] || 0, hi: nums[1] || nums[0] || 0 };
  }
  const money = (n) => `${String(Math.round(n)).replace(/\B(?=(\d{3})+(?!\d))/g, '.')}₫`;
  const moneyRange = (lo, hi) => (lo === hi ? money(lo) : `${money(lo).slice(0, -1)} – ${money(hi)}`);
  const digits = (v) => Number(String(v || '').replace(/\D/g, '')) || 0;
  const plainLabel = (l) => ({ vi: l.vi, en: l.en });

  /** Commission group for a menu item (see COMM). */
  function commissionGroup(serviceId, itemKey, optionId) {
    if (serviceId === 'nails') return 'nails';
    if (serviceId === 'waxing') return 'wax';
    if (serviceId === 'massage') return 'massage';
    if (serviceId === 'head_spa') return 'headspa'; // rituals and add-ons, 15% of the selling price
    if (serviceId === 'brows_lashes') {
      const ext = typeof EXT_IDS !== 'undefined' ? EXT_IDS : [];
      return ext.includes(optionId) ? 'lash' : 'none';
    }
    return 'none';
  }
  const COMM_BY_KEY = {};
  const ADDON_KEYS = new Set(); // head spa add-ons: commission yes, but not counted as a session
  const commOf = (line) => line.comm || COMM_BY_KEY[line.key] || 'none';
  const needsStaff = (line) => line.cat !== 'member';

  function buildMenu() {
    const menuServices = typeof SERVICES !== 'undefined' ? SERVICES : [];
    const cats = menuServices.map((s) => {
      const pricedItems = s.sections.flatMap((sec) => sec.items)
        .filter((it) => (it.type === 'single' || it.type === 'multi') && Array.isArray(it.options) && it.options.some((o) => o.price));
      const groups = [];
      for (const item of pricedItems) {
        let group = null;
        for (const o of item.options) {
          if (o.heading) { group = { heading: plainLabel(o.heading), options: [] }; groups.push(group); continue; }
          if (!o.price) continue;
          if (!group) {
            const heading = pricedItems.length > 1 && item.label ? plainLabel(item.label) : null;
            group = { heading, options: [] };
            groups.push(group);
          }
          const key = `${s.id}:${o.id}`;
          COMM_BY_KEY[key] = commissionGroup(s.id, item.key, o.id);
          if (s.id === 'head_spa' && item.key === 'addons') ADDON_KEYS.add(key);
          group.options.push({ key, label: plainLabel(o.label), price: o.price, ...parsePrice(o.price) });
        }
      }
      return { id: s.id, icon: s.icon, name: plainLabel(s.name), groups: groups.filter((g) => g.options.length) };
    }).filter((c) => c.groups.length);
    // Most-booked first; anything not listed keeps its check-in order after these.
    const ORDER = ['head_spa', 'nails', 'massage', 'brows_lashes', 'waxing'];
    const rank = (c) => (ORDER.includes(c.id) ? ORDER.indexOf(c.id) : ORDER.length);
    cats.sort((a, b) => rank(a) - rank(b));

    cats.push({
      id: 'member', icon: '🎁', name: S.memberCards,
      groups: [{ heading: null, options: MEMBER_CARDS.map((o) => ({ key: `member:${o.id}`, label: o.label, price: o.price, ...parsePrice(o.price) })) }],
    });
    cats.push({ id: 'custom', icon: '＋', name: S.custom, groups: [] });
    return cats;
  }
  const CATS = buildMenu();

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  const storage = {
    get(key) { try { return localStorage.getItem(key); } catch { return null; } },
    set(key, value) { try { localStorage.setItem(key, value); } catch { /* private mode */ } },
  };

  let lang = ['both', 'vi', 'en'].includes(storage.get(LANG_KEY)) ? storage.get(LANG_KEY) : 'both';
  let screen = 'edit';
  let tab = CATS[0] ? CATS[0].id : 'custom';
  let imageBlob = null;

  const blankBill = () => ({
    uid: null, created: null, customer: '', phone: '',
    lines: [], discount: '', discountMode: 'vnd', pay: 'cash', received: '',
    savedHash: null, savedAt: null,
  });
  const newUid = () => `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`;
  function startBill() {
    if (!bill.lines.length) { bill.created = new Date().toISOString(); bill.uid = newUid(); }
    if (!bill.uid) bill.uid = newUid();
  }
  let bill = (() => {
    try { return { ...blankBill(), ...JSON.parse(storage.get(STORE_KEY) || '{}') }; } catch { return blankBill(); }
  })();
  const save = () => storage.set(STORE_KEY, JSON.stringify(bill));

  /** Bill number and date, in Vietnam time: S261003-1430 and 03/10/2026 14:30. */
  function stamp(iso) {
    const d = iso ? new Date(iso) : new Date();
    const parts = Object.fromEntries(new Intl.DateTimeFormat('en-GB', {
      timeZone: TZ, year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit', hourCycle: 'h23',
    }).formatToParts(d).map((p) => [p.type, p.value]));
    return {
      no: `S${parts.year.slice(2)}${parts.month}${parts.day}-${parts.hour}${parts.minute}`,
      date: `${parts.day}/${parts.month}/${parts.year} ${parts.hour}:${parts.minute}`,
      iso: `${parts.year}-${parts.month}-${parts.day}`,
      time: `${parts.hour}:${parts.minute}`,
    };
  }

  function totals() {
    const subtotal = bill.lines.reduce((sum, l) => sum + l.price * l.qty, 0);
    const d = digits(bill.discount);
    const discount = bill.discountMode === 'pct'
      ? Math.round((subtotal * Math.min(d, 100)) / 100 / 1000) * 1000
      : Math.min(d, subtotal);
    const afterDiscount = subtotal - discount;
    const vat = VAT_PAYMENTS.includes(bill.pay) ? Math.round((afterDiscount * VAT_RATE) / 1000) * 1000 : 0;
    const total = afterDiscount + vat;
    const received = digits(bill.received);
    const change = bill.pay === 'cash' && received > 0 ? received - total : null;
    const count = bill.lines.reduce((sum, l) => sum + l.qty, 0);
    return { subtotal, discount, vat, total, received, change, count };
  }

  const isRange = (line) => line.lo !== line.hi;
  const unconfirmed = () => bill.lines.filter((l) => isRange(l) && !l.confirmed);
  const missingStaff = () => bill.lines.filter((l) => needsStaff(l) && !(l.staff || '').trim());
  const isOutside = (line) => !!line.outside || (!!line.staff && !STAFF.includes(line.staff));
  const outsideNames = () => { try { return JSON.parse(storage.get(OUTSIDE_KEY) || '[]'); } catch { return []; } };
  function rememberOutside(name) {
    const n = (name || '').trim();
    if (!n || STAFF.includes(n)) return;
    storage.set(OUTSIDE_KEY, JSON.stringify([n, ...outsideNames().filter((x) => x !== n)].slice(0, 15)));
  }

  function addLine(option, cat) {
    startBill();
    const existing = bill.lines.find((l) => l.key === option.key && !l.custom);
    if (existing) existing.qty += 1;
    else {
      bill.lines.push({
        key: option.key, cat: cat.id, icon: cat.icon, label: option.label,
        lo: option.lo, hi: option.hi, price: option.lo, qty: 1, confirmed: option.lo === option.hi, staff: '',
      });
    }
    save();
  }

  // ---------------------------------------------------------------------------
  // Small helpers
  // ---------------------------------------------------------------------------

  const both = (l) => (l.vi === l.en ? l.vi : `${l.vi} / ${l.en}`);
  const txt = (l) => (lang === 'both' ? both(l) : l[lang] || l.en);

  function h(tag, attrs = {}, ...children) {
    const node = document.createElement(tag);
    for (const [key, value] of Object.entries(attrs)) {
      if (value == null || value === false) continue;
      if (key === 'class') node.className = value;
      else if (key.startsWith('on')) node.addEventListener(key.slice(2), value);
      else node.setAttribute(key, value === true ? '' : value);
    }
    for (const child of children.flat()) {
      if (child == null || child === false) continue;
      node.append(child instanceof Node ? child : document.createTextNode(child));
    }
    return node;
  }
  /** Vietnamese with English underneath, or one language. */
  function lt(l, tag = 'span', cls) {
    if (lang !== 'both' || l.vi === l.en) return h(tag, { class: cls }, txt(l));
    return h(tag, { class: cls }, l.vi, h('br'), h('span', { class: 'en' }, l.en));
  }
  const sectionTitle = (n, l) => h('div', { class: 'section-title' }, h('span', { class: 'num' }, String(n)), lt(l, 'h2'));

  function moneyInput(value, oninput, attrs = {}) {
    return h('input', {
      type: 'text', inputmode: 'numeric', autocomplete: 'off', value: value ? money(digits(value)).slice(0, -1) : '',
      // Thousands dots appear while typing (300000 → 300.000). Formatting on blur instead made the page jump.
      oninput: (e) => {
        const n = digits(e.target.value);
        const shown = n ? money(n).slice(0, -1) : '';
        if (e.target.value !== shown) e.target.value = shown;
        oninput(shown);
      },
      ...attrs,
    });
  }

  const app = document.getElementById('bill-app');
  const langSelect = document.getElementById('bill-lang');

  // ---------------------------------------------------------------------------
  // Edit screen
  // ---------------------------------------------------------------------------

  function renderEdit() {
    screen = 'edit';
    document.body.classList.remove('on-receipt');
    app.replaceChildren(
      h('div', { class: 'hero' }, lt(S.title, 'h1'), h('p', {}, lt(S.sub))),
      h('div', { class: 'stack two-col' },
        h('section', { class: 'card', id: 'menu-card' }, sectionTitle(1, S.add), h('div', { id: 'menu' })),
        h('section', { class: 'card', id: 'bill-card' }, sectionTitle(2, S.bill), h('div', { id: 'bill' }))),
      h('div', { class: 'sticky-total', id: 'sticky' }),
    );
    renderMenu();
    renderBill();
  }

  function customerFields() {
    const field = (key, label, attrs) => h('label', { class: 'field' },
      h('span', { class: 'label' }, txt(label)),
      h('input', { type: 'text', value: bill[key], oninput: (e) => { bill[key] = e.target.value; save(); }, ...attrs }));
    const filled = ['customer', 'phone'].some((k) => (bill[k] || '').trim());
    return h('details', { class: 'cust', open: filled },
      h('summary', {}, txt(S.customer), h('span', { class: 'opt' }, ` (${txt(S.optional)})`)),
      h('div', { class: 'cust-grid' },
        field('customer', S.name, { autocomplete: 'off' }),
        field('phone', S.phone, { type: 'tel', inputmode: 'tel', autocomplete: 'off' })));
  }

  function renderMenu() {
    const box = document.getElementById('menu');
    if (!box) return;
    const cat = CATS.find((c) => c.id === tab) || CATS[0];
    const inBill = (key) => bill.lines.filter((l) => l.key === key).reduce((s, l) => s + l.qty, 0);
    const tabs = h('div', { class: 'tabs', role: 'tablist' }, CATS.map((c) => h('button', {
      type: 'button', class: 'tab', role: 'tab', 'aria-selected': String(c.id === cat.id),
      onclick: () => { tab = c.id; renderMenu(); },
    }, h('span', { class: 'tab-icon', 'aria-hidden': 'true' }, c.icon), h('span', {}, txt(c.name)))));

    let body;
    if (cat.id === 'custom') body = customForm();
    else {
      body = h('div', {}, h('p', { class: 'muted hint' }, txt(S.addHint)),
        cat.groups.map((g) => h('div', { class: 'menu-group' },
          g.heading ? lt(g.heading, 'h3', 'choice-heading') : null,
          h('div', { class: 'choices' }, g.options.map((o) => {
            const n = inBill(o.key);
            return h('button', {
              type: 'button', class: 'chip menu-item', 'aria-pressed': String(n > 0),
              onclick: () => { addLine(o, cat); renderMenu(); renderBill(); },
            },
            h('span', { class: 'with-price' }, lt(o.label), h('span', { class: 'price' }, o.price)),
            n ? h('span', { class: 'badge' }, `×${n}`) : null);
          })))));
    }
    box.replaceChildren(tabs, body);
  }

  function customForm() {
    let name = '';
    let price = '';
    let comm = 'none';
    const commSelect = h('select', { class: 'comm-select', onchange: (e) => { comm = e.target.value; } },
      Object.entries(COMM).map(([id, l]) => h('option', { value: id, selected: id === 'none' }, txt(l))));
    const nameInput = h('input', { type: 'text', autocomplete: 'off', oninput: (e) => { name = e.target.value; } });
    const priceInput = moneyInput('', (v) => { price = v; });
    const add = () => {
      if (!name.trim() || !digits(price)) {
        (!name.trim() ? nameInput : priceInput).classList.add('invalid');
        return;
      }
      startBill();
      const p = digits(price);
      bill.lines.push({ key: `custom:${Date.now()}`, cat: 'custom', icon: '＋', custom: true, label: { vi: name.trim(), en: name.trim() },
        lo: p, hi: p, price: p, qty: 1, confirmed: true, comm, staff: '' });
      save();
      renderMenu();
      renderBill();
    };
    return h('div', { class: 'custom-form' },
      h('label', { class: 'field' }, h('span', { class: 'label' }, txt(S.customName)), nameInput),
      h('label', { class: 'field' }, h('span', { class: 'label' }, txt(S.customPrice)), priceInput),
      h('label', { class: 'field' }, h('span', { class: 'label' }, txt(S.commGroup)), commSelect),
      h('p', { class: 'muted' }, txt(S.comboHint)),
      h('button', { type: 'button', class: 'secondary', onclick: add }, txt(S.addBtn)));
  }

  function renderBill() {
    const box = document.getElementById('bill');
    if (!box) return;
    if (!bill.lines.length) {
      box.replaceChildren(h('p', { class: 'muted' }, txt(S.empty)));
      renderTotals();
      return;
    }

    const lines = h('div', { class: 'lines' }, bill.lines.map((line, i) => {
      const amount = h('span', { class: 'price line-amount' }, money(line.price * line.qty));
      const step = (d) => {
        line.qty += d;
        if (line.qty < 1) bill.lines.splice(i, 1);
        save(); renderBill(); renderMenu();
      };
      // Every price can be changed (special price, promotion, extra work). The menu price stays visible underneath.
      const menuHint = () => {
        if (line.custom) return null;
        if (isRange(line)) return `${txt(S.from)}: ${moneyRange(line.lo, line.hi)}`;
        return line.price !== line.lo ? `${txt(S.from)}: ${money(line.lo)}` : null;
      };
      const hint = h('span', { class: 'muted range' }, menuHint() || '');
      hint.hidden = !menuHint();
      const input = moneyInput(line.price, (v) => {
        line.price = digits(v);
        line.confirmed = true;
        input.classList.remove('needs-price', 'invalid');
        input.classList.toggle('changed', !line.custom && !isRange(line) && line.price !== line.lo);
        amount.textContent = money(line.price * line.qty);
        hint.textContent = menuHint() || '';
        hint.hidden = !menuHint();
        save(); renderTotals();
      }, {
        class: `price-input${line.confirmed ? '' : ' needs-price'}${!line.custom && !isRange(line) && line.price !== line.lo ? ' changed' : ''}`,
        'aria-label': txt(S.enterPrice),
      });
      const priceNode = h('div', { class: 'price-edit' }, input, hint);
      let staffPick = null;
      if (needsStaff(line)) {
        const outside = isOutside(line);
        staffPick = h('div', { class: `staff-pick${(line.staff || '').trim() ? '' : ' needs-staff'}`, role: 'radiogroup', 'aria-label': txt(S.whoDid) },
          h('span', { class: 'staff-label' }, `${txt(S.staffShort)}:`),
          STAFF.map((name) => h('button', {
            type: 'button', class: 'staff-chip', role: 'radio', 'aria-checked': String(!outside && line.staff === name),
            onclick: () => { line.outside = false; line.staff = line.staff === name ? '' : name; save(); renderBill(); },
          }, name)),
          h('button', {
            type: 'button', class: 'staff-chip outside', role: 'radio', 'aria-checked': String(outside),
            onclick: () => {
              line.outside = !outside;
              line.staff = line.outside ? (outsideNames()[0] || '') : '';
              save(); renderBill();
              if (line.outside) setTimeout(() => { const el = document.getElementById(`outside-${i}`); if (el) { el.focus(); el.select(); } }, 0);
            },
          }, lang === 'en' ? S.outside.en : S.outside.vi));
        if (outside) {
          // Free-text name for someone who isn't on the staff list; names used before are suggested.
          const pick = staffPick;
          staffPick.append(h('input', {
            type: 'text', id: `outside-${i}`, class: 'outside-name', list: 'outside-staff-list', autocomplete: 'off',
            placeholder: txt(S.outsideName), 'aria-label': txt(S.outsideName), value: line.staff || '',
            oninput: (e) => {
              line.staff = e.target.value.replace(/\s+/g, ' ').trimStart().slice(0, 60);
              pick.classList.toggle('needs-staff', !line.staff.trim());
              if (line.staff.trim()) pick.classList.remove('invalid');
              save(); renderTotals();
            },
            onchange: (e) => { line.staff = e.target.value.trim(); rememberOutside(line.staff); save(); },
          }));
        }
      }
      return h('div', { class: 'line' },
        h('div', { class: 'line-main' },
          h('span', { class: 'line-icon', 'aria-hidden': 'true' }, line.icon || ''),
          h('div', { class: 'line-name' }, lt(line.label), priceNode, staffPick)),
        h('div', { class: 'line-side' },
          h('div', { class: 'stepper' },
            h('button', { type: 'button', 'aria-label': line.qty === 1 ? txt(S.remove) : '−', onclick: () => step(-1) }, line.qty === 1 ? '🗑' : '−'),
            h('span', { class: 'qty' }, String(line.qty)),
            h('button', { type: 'button', 'aria-label': '+', onclick: () => step(1) }, '+')),
          amount));
    }));

    const discountRow = h('div', { class: 'row-field' },
      h('span', { class: 'label' }, txt(S.discount)),
      h('div', { class: 'discount' },
        moneyInput(bill.discount, (v) => { bill.discount = v; save(); renderTotals(); }, { 'aria-label': txt(S.discount) }),
        h('div', { class: 'seg' }, ['vnd', 'pct'].map((m) => h('button', {
          type: 'button', 'aria-pressed': String(bill.discountMode === m),
          onclick: () => { bill.discountMode = m; save(); renderBill(); },
        }, m === 'vnd' ? '₫' : '%')))));

    const payRow = h('div', { class: 'row-field' },
      h('span', { class: 'label' }, txt(S.payment)),
      h('div', { class: 'choices pay' }, PAYMENTS.map((p) => h('button', {
        type: 'button', class: 'chip round', role: 'radio', 'aria-checked': String(bill.pay === p.id),
        onclick: () => { bill.pay = p.id; save(); renderBill(); },
      }, h('span', { class: 'box' }), lt(p.label)))),
      VAT_PAYMENTS.includes(bill.pay) ? h('div', { class: 'notice info' }, h('span', { class: 'i' }, 'ℹ️'), lt(S.vatNote)) : null);

    const receivedRow = bill.pay === 'cash' ? h('label', { class: 'row-field field' },
      h('span', { class: 'label' }, txt(S.received), h('span', { class: 'opt' }, ` (${txt(S.optional)})`)),
      moneyInput(bill.received, (v) => { bill.received = v; save(); renderTotals(); })) : null;

    const outsideList = h('datalist', { id: 'outside-staff-list' }, outsideNames().map((n) => h('option', { value: n })));
    box.replaceChildren(...[lines, outsideList, h('hr', { class: 'divider' }), customerFields(), discountRow, payRow, receivedRow,
      h('div', { id: 'totals' }), h('div', { id: 'bill-errors' }),
      h('div', { class: 'actions' },
        h('button', { type: 'button', class: 'primary', onclick: viewReceipt }, txt(S.view)),
        h('button', { type: 'button', class: 'link-button', onclick: newBill }, txt(S.newBill)))].filter(Boolean));
    renderTotals();
  }

  function renderTotals() {
    const t = totals();
    const box = document.getElementById('totals');
    const row = (label, value, cls = '') => h('div', { class: `t-row ${cls}` }, h('span', {}, txt(label)), h('span', { class: 'price' }, value));
    if (box) {
      box.replaceChildren(...[
        row(S.subtotal, money(t.subtotal)),
        t.discount ? row(S.discount, `− ${money(t.discount)}`) : null,
        t.vat ? row(S.vat, money(t.vat)) : null,
        h('div', { class: 'bill-total' }, h('span', {}, txt(S.total)), h('span', { class: 'price' }, money(t.total))),
        t.change != null ? row(S.change, t.change < 0 ? `− ${money(-t.change)}` : money(t.change), t.change < 0 ? 'short' : '') : null,
      ].filter(Boolean));
    }
    const sticky = document.getElementById('sticky');
    if (sticky) {
      sticky.hidden = !bill.lines.length;
      sticky.replaceChildren(h('button', {
        type: 'button', onclick: () => document.getElementById('bill-card').scrollIntoView({ behavior: 'smooth', block: 'start' }),
      }, h('span', {}, `${t.count} ${txt(S.items)}`), h('strong', {}, money(t.total)), h('span', { 'aria-hidden': 'true' }, '↓')));
    }
  }

  function newBill() {
    if (bill.lines.length && !window.confirm(txt(isSaved() ? S.confirmNew : S.confirmUnsaved))) return;
    bill = blankBill();
    save();
    tab = CATS[0] ? CATS[0].id : 'custom';
    renderEdit();
    window.scrollTo(0, 0);
  }

  function viewReceipt() {
    const errors = document.getElementById('bill-errors');
    const problem = !bill.lines.length ? S.nothing : unconfirmed().length ? S.rangeWarn : missingStaff().length ? S.staffWarn : null;
    if (problem) {
      errors.replaceChildren(h('div', { class: 'notice', role: 'alert' }, h('span', { class: 'i' }, '⚠️'), lt(problem)));
      document.querySelectorAll('.needs-price, .needs-staff').forEach((n) => n.classList.add('invalid'));
      (document.querySelector('.needs-price') || document.querySelector('.needs-staff') || errors).scrollIntoView({ behavior: 'smooth', block: 'center' });
      return;
    }
    renderReceipt();
  }

  // ---------------------------------------------------------------------------
  // Receipt
  // ---------------------------------------------------------------------------

  const staffNames = () => [...new Set(bill.lines.map((l) => (l.staff || '').trim()).filter(Boolean))];

  /** Everything the receipt shows, used by both the on-screen receipt and the shared image. */
  function receiptData() {
    const t = totals();
    const st = stamp(bill.created);
    const pay = PAYMENTS.find((p) => p.id === bill.pay) || PAYMENTS[0];
    const meta = [
      [S.billNo, st.no],
      [S.date, st.date],
      bill.customer.trim() ? [S.customer, bill.customer.trim()] : null,
      bill.phone.trim() ? [S.phone, bill.phone.trim()] : null,
      staffNames().length ? [S.staff, staffNames().join(', ')] : null,
    ].filter(Boolean);
    const sums = [
      [S.subtotal, money(t.subtotal)],
      t.discount ? [S.discount, `− ${money(t.discount)}`] : null,
      t.vat ? [S.vat, money(t.vat)] : null,
    ].filter(Boolean);
    const after = [[S.paidBy, txt(pay.onReceipt || pay.label)]];
    if (bill.pay === 'cash' && t.received) {
      after.push([S.received, money(t.received)]);
      if (t.change >= 0) after.push([S.change, money(t.change)]);
    }
    return { t, st, meta, sums, after };
  }

  function renderReceipt() {
    screen = 'receipt';
    document.body.classList.add('on-receipt');
    const { t, meta, sums, after } = receiptData();
    const kv = ([label, value], cls = '') => h('div', { class: `r-row ${cls}` }, h('span', {}, txt(label)), h('span', {}, value));

    const receipt = h('article', { class: 'receipt', id: 'receipt' },
      h('header', { class: 'r-head' },
        h('div', { class: 'r-brand' }, 'S E R E N'),
        h('div', { class: 'r-sub' }, SHOP.sub),
        h('div', { class: 'r-addr' }, SHOP.address),
        h('div', { class: 'r-addr' }, SHOP.contact)),
      h('div', { class: 'r-title' }, txt(S.receipt)),
      h('div', { class: 'r-meta' }, meta.map((m) => kv(m))),
      h('div', { class: 'r-items' }, bill.lines.map((l) => h('div', { class: 'r-item' },
        h('div', { class: 'r-item-name' }, lt(l.label),
          l.qty > 1 ? h('span', { class: 'r-item-calc' }, `${l.qty} × ${money(l.price)}`) : null),
        h('span', { class: 'r-amt' }, money(l.price * l.qty))))),
      h('div', { class: 'r-sums' }, sums.map((s) => kv(s))),
      h('div', { class: 'r-total' }, h('span', {}, txt(S.total)), h('span', {}, money(t.total))),
      h('div', { class: 'r-meta' }, after.map((a) => kv(a))),
      h('footer', { class: 'r-foot' }, lt(S.thanks, 'div')));

    const canShareFiles = !!(navigator.canShare && navigator.share);
    const shareBtn = h('button', { type: 'button', class: 'secondary', id: 'share-btn', disabled: true, onclick: shareImage },
      txt(canShareFiles ? S.share : S.save));

    app.replaceChildren(
      h('div', { class: 'receipt-bar' },
        h('button', { type: 'button', class: 'link-button', onclick: () => { renderEdit(); window.scrollTo(0, 0); } }, `‹ ${txt(S.edit)}`)),
      receipt,
      h('div', { class: 'receipt-actions' },
        h('div', { id: 'save-status', class: 'save-status', 'aria-live': 'polite' }),
        h('button', { type: 'button', class: 'primary', id: 'save-btn', onclick: () => saveBill() }, txt(S.saveBill)),
        h('button', { type: 'button', class: 'primary alt', onclick: printReceipt }, txt(S.print)),
        shareBtn,
        h('button', { type: 'button', class: 'link-button', onclick: newBill }, txt(S.newBill))));
    renderSaveStatus();
    window.scrollTo(0, 0);

    // Prepare the image now so the share sheet opens straight from the tap (iPhone/iPad need that).
    imageBlob = null;
    drawReceiptImage().then((blob) => {
      imageBlob = blob;
      const btn = document.getElementById('share-btn');
      if (btn) btn.disabled = false;
    }).catch((err) => console.error(err));
  }

  // ---------------------------------------------------------------------------
  // Saving to the Google Sheet
  // ---------------------------------------------------------------------------

  /** The bill as the Google Sheet stores it. The discount is shared across lines in proportion to their amount. */
  function billPayload() {
    const t = totals();
    const st = stamp(bill.created);
    const amounts = bill.lines.map((l) => l.price * l.qty);
    const shares = amounts.map((a) => (t.subtotal ? Math.round((t.discount * a) / t.subtotal) : 0));
    const drift = t.discount - shares.reduce((x, y) => x + y, 0);
    if (drift && shares.length) {
      const biggest = amounts.indexOf(Math.max(...amounts));
      shares[biggest] += drift;
    }
    const pay = PAYMENTS.find((p) => p.id === bill.pay) || PAYMENTS[0];
    const cat = (id) => (CATS.find((c) => c.id === id) || { name: S.custom }).name;
    return {
      type: 'bill',
      website: '',
      uid: bill.uid,
      no: st.no,
      date: st.iso,
      time: st.time,
      customer: (bill.customer || '').trim(),
      phone: (bill.phone || '').trim(),
      subtotal: t.subtotal,
      discount: t.discount,
      vat: t.vat,
      total: t.total,
      method: pay.id,
      method_label: (pay.onReceipt || pay.label).vi,
      source: SOURCE[pay.id] || 'Khác',
      received: bill.pay === 'cash' ? t.received : 0,
      change: bill.pay === 'cash' && t.received ? Math.max(0, t.change) : 0,
      lines: bill.lines.map((l, i) => ({
        name_vi: l.label.vi,
        name_en: l.label.en,
        category: cat(l.cat).vi,
        staff: (l.staff || '').trim(),
        qty: l.qty,
        price: l.price,
        amount: amounts[i],
        discount: shares[i],
        net: amounts[i] - shares[i],
        comm: commOf(l),
        session: !ADDON_KEYS.has(l.key),
      })),
    };
  }
  const hashOf = (payload) => JSON.stringify({ ...payload, website: undefined });
  const isSaved = () => !!bill.savedHash && bill.lines.length > 0 && bill.savedHash === hashOf(billPayload());

  const queue = {
    all() { try { return JSON.parse(storage.get(QUEUE_KEY) || '{}'); } catch { return {}; } },
    put(payload) { const q = queue.all(); q[payload.uid] = payload; storage.set(QUEUE_KEY, JSON.stringify(q)); },
    drop(uid) { const q = queue.all(); delete q[uid]; storage.set(QUEUE_KEY, JSON.stringify(q)); },
  };

  async function send(payload) {
    const endpoint = (window.SEREN_CHECKIN || {}).endpoint;
    if (!endpoint) throw new Error('not-configured');
    // text/plain keeps this a "simple" request, which Google Apps Script accepts from any site.
    const response = await fetch(endpoint, {
      method: 'POST', headers: { 'Content-Type': 'text/plain;charset=utf-8' }, body: JSON.stringify(payload), redirect: 'follow',
    });
    const result = await response.json().catch(() => ({}));
    if (!response.ok || !result.ok) throw new Error(result.error || `HTTP ${response.status}`);
  }

  let saveState = 'idle'; // idle | saving | error | queued | not-configured
  async function saveBill() {
    if (!bill.lines.length || saveState === 'saving') return;
    bill.lines.forEach((l) => { if (isOutside(l)) rememberOutside(l.staff); });
    const payload = billPayload();
    saveState = 'saving';
    renderSaveStatus();
    try {
      await send(payload);
      queue.drop(payload.uid);
      bill.savedHash = hashOf(payload);
      bill.savedAt = new Date().toISOString();
      save();
      saveState = 'idle';
    } catch (err) {
      console.error(err);
      if (err.message === 'not-configured') saveState = 'not-configured';
      else if (!navigator.onLine || err instanceof TypeError) {
        // Network failure: keep it and send it again later. Saving twice is safe (same bill id).
        queue.put(payload);
        bill.savedHash = hashOf(payload);
        save();
        saveState = 'queued';
      } else saveState = 'error';
    }
    renderSaveStatus();
  }

  function renderSaveStatus() {
    const box = document.getElementById('save-status');
    const btn = document.getElementById('save-btn');
    if (!box) return;
    const pending = bill.uid && queue.all()[bill.uid];
    let cls = 'pending';
    let msg = isSaved() ? null : (bill.savedHash ? S.changed : S.notSaved);
    if (saveState === 'saving') msg = S.saving;
    else if (saveState === 'error') { msg = S.saveError; cls = 'bad'; }
    else if (saveState === 'not-configured') { msg = S.notConfigured; cls = 'bad'; }
    else if (pending) { msg = S.queued; cls = 'bad'; }
    else if (isSaved()) { msg = S.saved; cls = 'ok'; }
    const at = isSaved() && !pending && bill.savedAt ? ` · ${stamp(bill.savedAt).time}` : '';
    box.className = `save-status ${cls}`;
    box.replaceChildren(h('span', { 'aria-hidden': 'true' }, cls === 'ok' ? '✓ ' : cls === 'bad' ? '⚠️ ' : '• '), txt(msg), at);
    if (btn) {
      btn.disabled = saveState === 'saving' || (isSaved() && !pending);
      btn.hidden = isSaved() && !pending;
    }
  }

  /** Sends bills that could not be sent earlier (no internet at the time). */
  async function flushQueue() {
    for (const payload of Object.values(queue.all())) {
      try {
        await send(payload);
        queue.drop(payload.uid);
      } catch (err) {
        console.error(err);
        if (err.message === 'not-configured') return;
      }
    }
    renderSaveStatus();
  }
  window.addEventListener('online', flushQueue);

  // ---------------------------------------------------------------------------
  // Printing on the 58 mm receipt printer
  // ---------------------------------------------------------------------------

  /** Switches the receipt to print size and makes the page exactly as long as the receipt (no blank paper). */
  function sizePageForPrint() {
    document.body.classList.add('printing');
    const receipt = document.getElementById('receipt');
    const lengthMm = receipt ? Math.ceil((receipt.getBoundingClientRect().height * 25.4) / 96) + 4 : 200;
    let style = document.getElementById('page-size');
    if (!style) {
      style = h('style', { id: 'page-size' });
      document.head.append(style);
    }
    style.textContent = `@page { size: ${PAPER_MM}mm ${lengthMm}mm; margin: 0; }`;
  }
  function printReceipt() {
    if (!isSaved()) saveBill(); // printing a receipt also records the sale
    sizePageForPrint();
    window.print();
  }
  // Ctrl+P works too.
  window.addEventListener('beforeprint', sizePageForPrint);
  window.addEventListener('afterprint', () => document.body.classList.remove('printing'));

  function fileName() {
    return `Seren-${stamp(bill.created).no}.png`;
  }

  async function shareImage() {
    if (!imageBlob) return;
    const file = new File([imageBlob], fileName(), { type: 'image/png' });
    if (navigator.canShare && navigator.canShare({ files: [file] })) {
      try {
        await navigator.share({ files: [file], title: `SEREN · ${txt(S.receipt)}` });
        return;
      } catch (err) {
        if (err && err.name === 'AbortError') return; // closed the share sheet
      }
    }
    const url = URL.createObjectURL(imageBlob);
    const a = h('a', { href: url, download: fileName() });
    document.body.append(a);
    a.click();
    a.remove();
    setTimeout(() => URL.revokeObjectURL(url), 10000);
  }

  /** Draws the receipt onto a canvas, 600px wide (doubled for sharpness), and returns a PNG blob. */
  function drawReceiptImage() {
    const { t, meta, sums, after } = receiptData();
    const WIDTH = 600;
    const PAD = 40;
    const SCALE = 2;
    const INK = '#2f2620';
    const MUTED = '#7d7169';
    const ACCENT = '#8b6b4a';
    const LINE = '#e3dbd1';
    const SANS = '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif';
    const SERIF = 'Georgia, "Times New Roman", serif';

    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d');
    const ops = [];
    let y = 0;

    const font = (size, weight = 400, family = SANS, style = '') => `${style} ${weight} ${size}px ${family}`.trim();
    function wrap(text, width, f) {
      ctx.font = f;
      const words = String(text).split(/\s+/);
      const out = [];
      let cur = '';
      for (const w of words) {
        const test = cur ? `${cur} ${w}` : w;
        if (ctx.measureText(test).width > width && cur) { out.push(cur); cur = w; } else cur = test;
      }
      if (cur) out.push(cur);
      return out;
    }
    const text = (s, x, f, color, align = 'left', lh = 1.35, size = 16) => { ops.push({ kind: 'text', s, x, y: y + size, f, color, align }); y += size * lh; };
    const centered = (s, size, f, color) => {
      for (const ln of wrap(s, WIDTH - PAD * 2, f)) text(ln, WIDTH / 2, f, color, 'center', 1.4, size);
    };
    const rule = (dashed = false) => { y += 10; ops.push({ kind: 'rule', y, dashed }); y += 14; };
    /** Label on the left, value on the right; the label wraps if it is long. */
    const kv = (label, value, size = 16, weight = 400, color = INK) => {
      const f = font(size, weight);
      ctx.font = f;
      const valueW = ctx.measureText(value).width;
      const lines = wrap(label, WIDTH - PAD * 2 - valueW - 16, f);
      ops.push({ kind: 'text', s: value, x: WIDTH - PAD, y: y + size, f, color, align: 'right' });
      lines.forEach((ln) => text(ln, PAD, f, color, 'left', 1.4, size));
    };
    const labelOf = (l) => (lang === 'both' ? both(l) : txt(l));

    y = PAD;
    centered('S E R E N', 34, font(34, 400, SERIF), ACCENT);
    y += 2;
    centered(SHOP.sub, 15, font(15, 400, SERIF, 'italic'), MUTED);
    y += 6;
    centered(SHOP.address, 14, font(14), MUTED);
    centered(SHOP.contact, 14, font(14), MUTED);
    rule();
    centered(labelOf(S.receipt).toUpperCase(), 18, font(18, 700), INK);
    y += 6;
    meta.forEach(([l, v]) => kv(labelOf(l), v, 15, 400, INK));
    rule(true);

    for (const line of bill.lines) {
      const amt = money(line.price * line.qty);
      const nameF = font(17, 600);
      ctx.font = nameF;
      const amtW = ctx.measureText(amt).width;
      const nameLines = wrap(line.label.vi, WIDTH - PAD * 2 - amtW - 16, nameF);
      ops.push({ kind: 'text', s: amt, x: WIDTH - PAD, y: y + 17, f: nameF, color: INK, align: 'right' });
      if (lang === 'en') nameLines.length = 0;
      nameLines.forEach((ln) => text(ln, PAD, nameF, INK, 'left', 1.35, 17));
      if (lang !== 'vi' && line.label.en !== line.label.vi) {
        const enF = font(15, 400, SANS, 'italic');
        const enLines = wrap(line.label.en, WIDTH - PAD * 2 - (lang === 'en' ? amtW + 16 : 0), lang === 'en' ? font(17, 600) : enF);
        enLines.forEach((ln) => text(ln, PAD, lang === 'en' ? font(17, 600) : enF, lang === 'en' ? INK : MUTED, 'left', 1.35, lang === 'en' ? 17 : 15));
      }
      if (line.qty > 1) text(`${line.qty} × ${money(line.price)}`, PAD, font(15), MUTED, 'left', 1.35, 15);
      y += 8;
    }
    rule(true);
    sums.forEach(([l, v]) => kv(labelOf(l), v, 16));
    y += 4;
    kv(labelOf(S.total).toUpperCase(), money(t.total), 24, 700, INK);
    rule(true);
    after.forEach(([l, v]) => kv(labelOf(l), v, 15));
    rule();
    if (lang !== 'en') centered(S.thanks.vi, 16, font(16, 400, SERIF), INK);
    if (lang !== 'vi') centered(S.thanks.en, 15, font(15, 400, SERIF, 'italic'), MUTED);
    y += PAD - 10;

    const height = Math.ceil(y);
    canvas.width = WIDTH * SCALE;
    canvas.height = height * SCALE;
    ctx.scale(SCALE, SCALE);
    ctx.fillStyle = '#ffffff';
    ctx.fillRect(0, 0, WIDTH, height);
    for (const op of ops) {
      if (op.kind === 'text') {
        ctx.font = op.f;
        ctx.fillStyle = op.color;
        ctx.textAlign = op.align;
        ctx.fillText(op.s, op.x, op.y);
      } else {
        ctx.strokeStyle = LINE;
        ctx.lineWidth = 1.5;
        ctx.setLineDash(op.dashed ? [6, 6] : []);
        ctx.beginPath();
        ctx.moveTo(PAD, op.y);
        ctx.lineTo(WIDTH - PAD, op.y);
        ctx.stroke();
      }
    }
    return new Promise((resolve, reject) => canvas.toBlob((b) => (b ? resolve(b) : reject(new Error('no image'))), 'image/png'));
  }

  // ---------------------------------------------------------------------------
  // Start
  // ---------------------------------------------------------------------------

  langSelect.value = lang;
  langSelect.addEventListener('change', () => {
    lang = langSelect.value;
    storage.set(LANG_KEY, lang);
    document.documentElement.lang = lang === 'en' ? 'en' : 'vi';
    if (screen === 'receipt') renderReceipt(); else renderEdit();
  });
  document.documentElement.lang = lang === 'en' ? 'en' : 'vi';
  if (bill.lines.length && !bill.uid) { bill.uid = newUid(); save(); } // bills started before saving existed
  renderEdit();
  flushQueue();
})();
