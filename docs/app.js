/* Seren check-in: customers choose a service, fill in the form on their phone and sign.
   Submissions are sent to Seren's Google Apps Script (see google-apps-script/Code.gs), which adds a row to a
   private Google Sheet and saves the signature to Google Drive. The endpoint URL is set in config.js.
   The wording matches the iPad app (ios-apps/*Content.swift). */
'use strict';

const BUSINESS = 'Seren';

// Languages besides Vietnamese and English come from i18n.js, looked up by the English text.
const I18N = window.SEREN_I18N || { languages: [], strings: {}, health: {} };
const TRANSLATIONS = { ...I18N.strings, ...I18N.health };
const EXTRA_LANGS = I18N.languages.map((l) => l.code);
/** A customer-facing string: L('Tiếng Việt', 'English'), plus zh/ko/fr/ja/ru from i18n.js when available. */
const L = (vi, en, more = {}) => ({ vi, en, ...(TRANSLATIONS[en] || {}), ...more });

// ---------------------------------------------------------------------------
// Shared wording
// ---------------------------------------------------------------------------

const T = {
  back: L('Quay lại', 'Back'),
  chooseTitle: L('Chào mừng đến với Seren', 'Welcome to Seren'),
  chooseSub: L('Vui lòng chọn dịch vụ để check-in', 'Please choose your service to check in'),
  submit: L('Hoàn tất & Gửi', 'Complete & Submit'),
  sending: L('Đang gửi…', 'Sending…'),
  pleaseComplete: L('Vui lòng hoàn thành:', 'Please complete:'),
  notConfigured: L('Hệ thống check-in chưa được cài đặt. Vui lòng báo lễ tân.', 'Check-in is not set up yet. Please tell reception.'),
  sendError: L('Không gửi được. Vui lòng kiểm tra kết nối mạng và thử lại, hoặc báo lễ tân.',
               'Could not send. Please check your connection and try again, or tell reception.'),
  thanks: L('Cảm ơn quý khách!', 'Thank you!'),
  checkedIn: L('Bạn đã check-in thành công. Vui lòng báo lễ tân — chúng tôi sẽ phục vụ bạn ngay.',
               'You are checked in. Please let reception know — we will be with you shortly.'),
  another: L('Check-in thêm dịch vụ khác', 'Check in for another service'),
  signHint: L('Ký bằng ngón tay trong khung', 'Sign with your finger in the box'),
  clear: L('Ký lại', 'Clear'),
  chooseDate: L('Chọn ngày', 'Select date'),
  optional: L('không bắt buộc', 'optional'),
  noneApply: L('Tôi không có tình trạng nào ở trên.', 'None of the above apply to me.'),
  tickPrompt: L('Vui lòng đánh dấu nếu bạn có bất kỳ tình trạng nào dưới đây:',
                'Please tick any of the following that apply to you:'),
  healthMissing: L('Sức khoẻ: đánh dấu mục phù hợp hoặc “Không có”', 'Health: tick what applies or “None of the above”'),
  agreeMissing: L('Đánh dấu ô đồng ý các cam kết', 'Tick the box to agree to the statements'),
  agreeAll: L('Tôi đã đọc và đồng ý với tất cả các cam kết trên.', 'I have read and agree to all of the above.'),
  privacy: L(
    `Tôi đồng ý để ${BUSINESS} lưu trữ thông tin trong phiếu này (bao gồm thông tin sức khoẻ và chữ ký) để phục vụ tôi an toàn. Thông tin được bảo mật và không chia sẻ cho bên thứ ba.`,
    `I agree to ${BUSINESS} storing the information in this form (including health information and my signature) to look after me safely. It is kept confidential and not shared with third parties.`),
  signature: L('Chữ ký khách hàng', 'Customer Signature'),
  date: L('Ngày', 'Date'),
};

const F = {
  name: { type: 'text', key: 'full_name', label: L('Họ Tên', 'Full Name'), required: true, input: 'text', autocomplete: 'name' },
  phone: { type: 'text', key: 'phone', label: L('Số Điện Thoại', 'Phone Number'), input: 'tel', autocomplete: 'tel' },
  email: { type: 'text', key: 'email', label: L('Email', 'Email'), input: 'email', autocomplete: 'email' },
  dob: (required) => ({ type: 'date', key: 'date_of_birth', label: L('Ngày Sinh', 'Date of Birth'), required }),
  emergency: { type: 'text', key: 'emergency_contact', label: L('Liên hệ khẩn cấp (tên & SĐT)', 'Emergency Contact (name & phone)'), input: 'text' },
  technician: (label) => ({ type: 'text', key: 'technician', label: label || L('Kỹ Thuật Viên (nếu biết)', 'Technician (if known)'), input: 'text' }),
};

const photoConsent = {
  type: 'single', key: 'photo_consent', required: true,
  options: [{ id: 'agree', label: L('Đồng ý', 'Agree') }, { id: 'disagree', label: L('Không đồng ý', 'Do not agree') }],
};

/** Itemised bill with the total of every priced option chosen on the form. */
const totalSection = {
  title: L('Dịch vụ đã chọn & Tổng tiền', 'Your selection & total'),
  items: [{ type: 'total', dynamic: true }],
};

const signatureSection = {
  title: L('Chữ ký', 'Signature'),
  items: [
    { type: 'signature', key: 'signature', label: T.signature, required: true },
  ],
};

/** All of a form's statements, agreed to with a single tick. */
const consents = (statements, extra = {}) => ({
  type: 'consents', key: 'consent_all', dynamic: true, statements: [...statements, T.privacy], ...extra,
});

// Massage and Head Spa have no health questions, so the customer agrees to raise any health concerns in person.
const wellnessAgreements = (activity) => [consents([
  L('Tôi xác nhận thông tin trên là chính xác và sẽ báo cho kỹ thuật viên trước khi bắt đầu nếu có vấn đề sức khoẻ cần lưu ý.',
    'I confirm the information above is accurate and I will tell my therapist before we start about any health concerns.'),
  L(`Tôi hiểu ${activity.vi} nhằm mục đích thư giãn và chăm sóc sức khoẻ, không thay thế cho chẩn đoán hay điều trị y khoa.`,
    `I understand ${activity.en} is for relaxation and wellness and is not a substitute for medical diagnosis or treatment.`),
  L('Tôi sẽ báo cho kỹ thuật viên nếu cảm thấy khó chịu hoặc đau, và có quyền dừng buổi dịch vụ bất cứ lúc nào.',
    'I will tell my therapist if I feel any discomfort or pain, and I may stop the session at any time.'),
  L('Tôi hiểu rằng mọi hành vi hoặc yêu cầu không phù hợp sẽ khiến buổi dịch vụ kết thúc ngay và vẫn phải thanh toán đầy đủ.',
    'I understand that any inappropriate behaviour or requests will end the session immediately, with full payment due.'),
  L(`Tôi tự nguyện sử dụng dịch vụ và không yêu cầu ${BUSINESS} chịu trách nhiệm về các vấn đề phát sinh do thông tin sức khoẻ không chính xác hoặc không được khai báo.`,
    `I receive this service voluntarily and release ${BUSINESS} from liability for issues arising from inaccurate or undisclosed health information.`),
])];

// ---------------------------------------------------------------------------
// Services
// ---------------------------------------------------------------------------

// Which service details and aftercare to show for the chosen Brows & Lashes services.
const COMBO_IDS = ['combo_lift_lam', 'combo_lift_tint_lam'];
const BROW_IDS = ['brow_cleanup', 'brow_wax', 'brow_black_tint', 'brow_colour_tint', 'brow_lamination', ...COMBO_IDS];
const LIFT_IDS = ['lash_lift', 'lash_design_lift', 'lash_lift_backtint', 'lash_tinting', 'lash_straightening', ...COMBO_IDS];
const EXT_IDS = ['set_classic', 'set_babe', 'set_wispy', 'set_kimk', 'set_cateye', 'set_volume', 'set_animefox', 'set_douyin',
  'upgrade_natural', 'upgrade_matte', 'lash_lower', 'lash_removal', 'lash_colour_mix', 'lash_custom'];
const pick = (selected, ids) => !selected.length || selected.some((id) => ids.includes(id));
const hasLashes = (s) => pick(s.brow_services || [], [...LIFT_IDS, ...EXT_IDS]);
// Massage services that use oil, and the almond note for the Calming oil.
const MASSAGE_OIL_IDS = ['body_60', 'body_90', 'body_120', 'neck_30', 'neck_60', 'foot_30', 'foot_60'];
const ALMOND_NOTE = L('Dầu Calming có chứa dầu hạnh nhân. Nếu bạn dị ứng các loại hạt, vui lòng chọn loại dầu khác và báo cho kỹ thuật viên.',
  'Calming oil contains almond oil. If you have a nut allergy, please choose another oil and tell your therapist.');
/** A sub-heading inside a list of options. */
const heading = (l) => ({ heading: l });

const SERVICES = [
  {
    id: 'brows_lashes', icon: '✨',
    name: L('Chân Mày & Mi', 'Brows & Lashes'),
    title: L('Hợp đồng dịch vụ', 'Service Agreement'),
    sections: [
      { title: L('Thông tin khách hàng', 'Customer Information'), items: [
        F.name, F.phone, F.dob(false),
        { type: 'text', key: 'id_number', label: L('CCCD/CMND', 'ID/Passport'), input: 'text' },
        F.technician(),
        { type: 'multi', key: 'brow_services', required: true,
          label: L('Dịch Vụ (chọn một hoặc nhiều)', 'Registered Services (choose one or more)'),
          // Menu and prices from serensaigon.com/pricing (lashes, brows, combos).
          options: [
            heading(L('Nối mi — các dáng mi', 'Lash extensions — sets')),
            { id: 'set_classic', label: L('Classic · 8–15 mm', 'Classic · 8–15 mm'), price: '350.000₫' },
            { id: 'set_babe', label: L('Babe · 8–15 mm', 'Babe · 8–15 mm'), price: '350.000₫' },
            { id: 'set_wispy', label: L('Wispy · 9–15 mm', 'Wispy · 9–15 mm'), price: '450.000₫' },
            { id: 'set_kimk', label: L('Kim K · 9–15 mm', 'Kim K · 9–15 mm'), price: '450.000₫' },
            { id: 'set_cateye', label: L('Cat Eye · 9–15 mm', 'Cat Eye · 9–15 mm'), price: '450.000₫' },
            { id: 'set_volume', label: L('Volume · 9–15 mm', 'Volume · 9–15 mm'), price: '450.000₫' },
            { id: 'set_animefox', label: L('Anime Fox · 9–15 mm', 'Anime Fox · 9–15 mm'), price: '450.000₫' },
            { id: 'set_douyin', label: L('Douyin · 8–15 mm', 'Douyin · 8–15 mm'), price: '450.000₫' },
            heading(L('Nâng cấp chất liệu mi (cho mọi dáng mi)', 'Lash fibre upgrades (any set)')),
            { id: 'upgrade_natural', label: L('Mi lông thật', 'Natural-fibre lashes'), price: '+ 100.000₫' },
            { id: 'upgrade_matte', label: L('Mi mun', 'Matte black lashes'), price: '+ 100.000₫' },
            heading(L('Nối mi — dịch vụ khác', 'Lashes — other services')),
            { id: 'lash_lift', label: L('Uốn mi', 'Lash lift'), price: '300.000₫' },
            { id: 'lash_design_lift', label: L('Uốn mi design', 'Design lash lift'), price: '350.000₫' },
            { id: 'lash_lift_backtint', label: L('Uốn & nhuộm phủ đen', 'Lash lift & backtint'), price: '400.000₫' },
            { id: 'lash_tinting', label: L('Phủ đen mi', 'Lash tinting'), price: '150.000₫' },
            { id: 'lash_straightening', label: L('Duỗi mi', 'Lash straightening'), price: '100.000₫' },
            { id: 'lash_lower', label: L('Nối mi dưới', 'Lower lash extension'), price: '100.000₫' },
            { id: 'lash_removal', label: L('Tháo mi, vệ sinh', 'Lash removal & cleansing'), price: '60.000₫' },
            { id: 'lash_colour_mix', label: L('Mi mix màu', 'Colour mix lashes'), price: '50.000 – 100.000₫' },
            { id: 'lash_custom', label: L('Mẫu design riêng', 'Custom lash design'), price: '500.000₫' },
            heading(L('Chân mày', 'Brows')),
            { id: 'brow_cleanup', label: L('Làm sạch chân mày', 'Brow clean up'), price: '50.000₫' },
            { id: 'brow_wax', label: L('Wax chân mày', 'Eyebrow wax'), price: '100.000₫' },
            { id: 'brow_black_tint', label: L('Phủ đen chân mày', 'Brow black tint'), price: '150.000₫' },
            { id: 'brow_colour_tint', label: L('Phủ màu chân mày', 'Brow colour tint'), price: '200.000₫' },
            { id: 'brow_lamination', label: L('Định hình chân mày', 'Brow lamination'), price: '450.000₫' },
            heading(L('Combo mi & mày', 'Lash & brow combo')),
            { id: 'combo_lift_lam', label: L('Uốn mi + uốn chân mày', 'Lash lift + brow lamination'), price: '700.000₫' },
            { id: 'combo_lift_tint_lam', label: L('Uốn mi & nhuộm phủ đen + uốn chân mày', 'Lash lift & backtint + brow lamination'), price: '750.000₫' },
          ] },
      ] },
      { title: L('Nội Dung Dịch Vụ', 'Service Details'), items: [
        { type: 'info', dynamic: true, groups: (s) => [
          pick(s.brow_services || [], BROW_IDS) && { title: L('Chân mày', 'Brows'), items: [
            L('Uốn chân mày giúp định hình và làm dầy sợi mày.', 'Brows lamination helps to shape and volumize the brow hairs.'),
            L('Nhuộm màu để sợi mày trông đều màu và sắc nét.', 'Tinting provides even color and better definition to the brows.'),
            L('Thời gian: 45–60 phút', 'Time: 45–60 minutes'),
            L('Kết quả giữ: 4–6 tuần', 'Effect lasts: 4–6 weeks'),
          ] },
          pick(s.brow_services || [], LIFT_IDS) && { title: L('Uốn & Nhuộm mi', 'Lash Lift & Tint'), items: [
            L('Uốn mi giúp mi thật cong và trông dài hơn một cách tự nhiên.', 'A lash lift curls and lifts your natural lashes so they look longer.'),
            L('Nhuộm mi giúp mi đậm màu và rõ nét hơn.', 'A lash tint darkens your lashes for more definition.'),
            L('Thời gian: 45–60 phút', 'Time: 45–60 minutes'),
            L('Kết quả giữ: 6–8 tuần', 'Effect lasts: 6–8 weeks'),
          ] },
          pick(s.brow_services || [], EXT_IDS) && { title: L('Nối mi', 'Lash Extensions'), items: [
            L('Nối mi là gắn từng sợi mi giả lên mi thật để mi dày và dài hơn.', 'Lash extensions attach individual synthetic lashes to your natural lashes for length and volume.'),
            L('Mắt nhắm trong suốt quá trình thực hiện.', 'Your eyes stay closed during the whole service.'),
            L('Thời gian: 90–120 phút', 'Time: 90–120 minutes'),
            L('Nên dặm mi sau 2–3 tuần.', 'A refill is recommended every 2–3 weeks.'),
          ] },
        ].filter(Boolean) },
      ] },
      { title: L('Chống Chỉ Định', 'Contraindications'), items: [
        { type: 'checklist', key: 'contraindications', autoUnder16: 'under16',
          warning: L('Vui lòng báo cho kỹ thuật viên trước khi tiếp tục. Kỹ thuật viên sẽ tư vấn dịch vụ có phù hợp với bạn hay không.',
                     'Please let your technician know before continuing. They will advise whether this service is suitable for you.'),
          options: [
            { id: 'health', label: L('Mang thai, có bệnh lý nền, thể trạng yếu, dùng kháng sinh hoặc hormone không ổn định.', 'Pregnancy, chronic illness, weak health, antibiotics or hormone instability.') },
            { id: 'allergy', label: L('Cơ địa dễ dị ứng hoặc nhạy cảm.', 'Allergy-prone or sensitive skin.') },
            { id: 'skin', label: L('Da quá mỏng, khô hoặc đang điều trị da.', 'Overly dry, thin, or treated skin.') },
            { id: 'retinol', label: L('Đang dùng Retinol, AHA/BHA hoặc da chưa lành.', 'Using Retinol, AHA/BHA or not fully healed.') },
            { id: 'recent', label: L('Mới phun/xăm hoặc điều trị laser.', 'Recent permanent makeup or laser treatment.') },
            { id: 'acne', label: L('Có mụn hoặc vết thương vùng chân mày hoặc quanh mắt.', 'Acne or wounds near the brow or eye area.') },
            { id: 'eyes', label: L('Nhiễm trùng mắt, viêm kết mạc, mắt nhạy cảm hoặc mới phẫu thuật mắt.', 'Eye infection, conjunctivitis, sensitive eyes or recent eye surgery.') },
            { id: 'under16', label: L('Dưới 16 tuổi.', 'Under 16 years old.') },
          ] },
        { type: 'note', tone: 'info', text: L('Lưu ý: Khách có tiền sử dị ứng nên test thử sản phẩm trước 24–48 giờ.', 'Note: Allergy-prone clients should take a patch test 24–48 hours in advance.') },
        { type: 'note', tone: 'info', dynamic: true, show: hasLashes,
          text: L('Vui lòng tháo kính áp tròng trước khi làm mi.', 'Please remove contact lenses before any lash service.') },
      ] },
      { title: L('Chăm Sóc Sau Dịch Vụ', 'Aftercare'), items: [
        { type: 'info', dynamic: true, groups: (s) => [
          pick(s.brow_services || [], BROW_IDS) && { title: L('Chân mày', 'Brows'), items: [
            L('Tránh nước, hơi nước, ánh nắng và đổ mồ hôi nhiều trong 24h đầu.', 'Avoid water, steam, sun, and sweating in the first 24 hours.'),
            L('Không va chạm, gãi hoặc makeup vùng chân mày.', 'No rubbing, scratching, or makeup on brows.'),
            L('Chải lông mày nhẹ nhàng 2–3 lần mỗi ngày theo hướng dẫn.', 'Gently brush brows 2–3 times daily as instructed.'),
            L('Có thể dùng serum sau 24h.', 'Serum may be applied after 24 hours.'),
            L('Nếu có nhuộm, tránh tẩy trang vùng mày.', 'Avoid cleansing agents on tinted brows to preserve color.'),
          ] },
          pick(s.brow_services || [], LIFT_IDS) && { title: L('Uốn & Nhuộm mi', 'Lash Lift & Tint'), items: [
            L('Giữ mi khô, tránh hơi nước và trang điểm mắt trong 24h đầu.', 'Keep lashes dry and avoid steam and eye makeup for the first 24 hours.'),
            L('Không dụi mắt và tránh ngủ úp mặt.', "Don't rub your eyes and avoid sleeping face-down."),
            L('Không dùng kẹp bấm mi.', "Don't use an eyelash curler."),
            L('Có thể dùng serum dưỡng mi sau 24h.', 'Lash serum may be applied after 24 hours.'),
          ] },
          pick(s.brow_services || [], EXT_IDS) && { title: L('Nối mi', 'Lash Extensions'), items: [
            L('Tránh nước và hơi nước trong 24h đầu.', 'Avoid water and steam for the first 24 hours.'),
            L('Không dùng tẩy trang hoặc sản phẩm có dầu quanh mắt.', 'Avoid oil-based makeup removers and products around the eyes.'),
            L('Không dụi, kéo, cắt mi hoặc dùng kẹp bấm mi.', "Don't rub, pull or cut your lashes, or use an eyelash curler."),
            L('Chải mi nhẹ nhàng mỗi ngày.', 'Brush your lashes gently every day.'),
            L('Đặt lịch dặm mi sau 2–3 tuần.', 'Book a refill every 2–3 weeks.'),
          ] },
        ].filter(Boolean) },
      ] },
      { title: L('Cam Kết', 'Acknowledgement'), items: [
        { ...photoConsent, label: L('Sử dụng hình ảnh cho mục đích quảng bá', 'Use of my images for promotional purposes') },
        consents([
          L('Tôi đã được tư vấn đầy đủ về quy trình, rủi ro và chăm sóc sau dịch vụ.', 'I have been fully informed about the procedure, risks, and aftercare.'),
          (s) => (s.contraindications?.ticked?.length
            ? L('Tôi đã trao đổi các tình trạng đã đánh dấu ở trên với kỹ thuật viên và đồng ý thực hiện dịch vụ.', 'I have discussed the conditions ticked above with my technician and agree to proceed.')
            : L('Tôi xác nhận không có chống chỉ định và không đang mang thai.', 'I confirm that I have no contraindications and I am not pregnant.')),
        ], { resetWith: 'contraindications' }),
      ] },
      totalSection,
      signatureSection,
    ],
  },

  {
    id: 'massage', icon: '🌿',
    name: L('Massage', 'Massage'),
    title: L('Phiếu thông tin & Cam kết', 'Intake & Consent Form'),
    sections: [
      { title: L('Thông tin khách hàng', 'Customer Information'), items: [
        F.name, F.phone, F.email, F.dob(false), F.emergency, F.technician(L('Kỹ Thuật Viên (nếu biết)', 'Therapist (if known)')),
      ] },
      { title: L('Dịch vụ', 'Service'), items: [
        // Menu and prices from serensaigon.com/pricing (Body wellness, Body scrub & glow).
        { type: 'multi', key: 'massage_services', required: true, label: L('Dịch vụ (chọn một hoặc nhiều)', 'Services (choose one or more)'), options: [
          { id: 'body_60', label: L('Thư giãn body · 60 phút', 'Body therapy · 60 min'), price: '450.000₫' },
          { id: 'body_90', label: L('Thư giãn body · 90 phút', 'Body therapy · 90 min'), price: '625.000₫' },
          { id: 'body_120', label: L('Thư giãn body · 120 phút', 'Body therapy · 120 min'), price: '850.000₫' },
          { id: 'neck_30', label: L('Cổ, vai, gáy · 30 phút', 'Neck & shoulder · 30 min'), price: '250.000₫' },
          { id: 'neck_60', label: L('Cổ, vai, gáy · 60 phút', 'Neck & shoulder · 60 min'), price: '450.000₫' },
          { id: 'foot_30', label: L('Chăm sóc chân · 30 phút', 'Foot · 30 min'), price: '280.000₫' },
          { id: 'foot_60', label: L('Chăm sóc chân · 60 phút', 'Foot · 60 min'), price: '450.000₫' },
          { id: 'body_scrub', label: L('Tẩy tế bào chết body · 30 phút', 'Body scrub · 30 min'), price: '296.000₫' },
          { id: 'body_wrap', label: L('Dưỡng ủ body · 30 phút', 'Body wrap · 30 min'), price: '280.000₫' },
        ] },
        // OILMART professional spa oils. Needed when a massage (not only a scrub or wrap) is chosen.
        { type: 'single', key: 'oil', dynamic: true, label: L('Chọn dầu massage', 'Choose your massage oil'),
          required: (s) => (s.massage_services || []).some((id) => MASSAGE_OIL_IDS.includes(id)), options: [
            { id: 'calming', label: L('Calming · Oải hương & Hạnh nhân', 'Calming · Lavender & Almond') },
            { id: 'refreshing', label: L('Refreshing · Chanh vàng, Bưởi & Cam', 'Refreshing · Lemon, Grapefruit & Orange') },
            { id: 'comforting', label: L('Comforting · Sả & Xô thơm', 'Comforting · Lemongrass & Clary Sage') },
            { id: 'anti_aging', label: L('Anti-Aging · Gừng & Nhụy hoa nghệ tây', 'Anti-Aging · Ginger & Saffron') },
          ] },
        { type: 'note', tone: 'info', dynamic: true, show: (s) => s.oil === 'calming', text: ALMOND_NOTE },
        { type: 'single', key: 'pressure', required: true, label: L('Lực massage mong muốn', 'Preferred pressure'), options: [
          { id: 'light', label: L('Nhẹ', 'Light') }, { id: 'medium', label: L('Vừa', 'Medium') },
          { id: 'firm', label: L('Mạnh', 'Firm') }, { id: 'deep', label: L('Rất mạnh', 'Extra firm') },
        ] },
      ] },
      { title: L('Vùng cơ thể', 'Body Areas'), items: [
        { type: 'multi', key: 'focus_areas', exclusiveWith: 'avoid_areas', label: L('Vùng muốn tập trung', 'Areas to focus on'), options: 'areas' },
        { type: 'multi', key: 'avoid_areas', exclusiveWith: 'focus_areas', label: L('Vùng muốn tránh', 'Areas to avoid'), options: 'areas' },
      ] },
      { title: L('Chăm sóc sau massage', 'Aftercare'), items: [
        { type: 'info', groups: () => [{ items: [
          L('Uống nhiều nước ấm sau khi massage.', 'Drink plenty of water after your massage.'),
          L('Nghỉ ngơi, tránh vận động mạnh trong vài giờ.', 'Rest and avoid strenuous exercise for a few hours.'),
          L('Nên đợi ít nhất 1 giờ rồi mới tắm.', 'Wait at least 1 hour before showering.'),
          L('Có thể hơi ê ẩm trong 24–48 giờ — đây là điều bình thường.', 'Mild soreness for 24–48 hours is normal.'),
          L('Liên hệ với chúng tôi nếu đau kéo dài hoặc cảm thấy không khoẻ.', 'Contact us if pain persists or you feel unwell.'),
        ] }] },
      ] },
      { title: L('Cam kết', 'Consent'), items: wellnessAgreements(L('massage', 'massage')) },
      totalSection,
    ],
  },

  {
    id: 'nails', icon: '💅',
    name: L('Làm Móng', 'Nails'),
    title: L('Phiếu thông tin & Cam kết', 'Service Agreement'),
    sections: [
      { title: L('Thông tin khách hàng', 'Customer Information'), items: [F.name, F.phone, F.dob(false), F.technician()] },
      { title: L('Dịch vụ', 'Services'), items: [
        // Menu and prices from serensaigon.com/pricing.
        { type: 'multi', key: 'nail_services', required: true, label: L('Dịch vụ (chọn một hoặc nhiều)', 'Services (choose one or more)'), options: [
          heading(L('Bộ đặc trưng', 'Signature sets')),
          { id: 'set_touch', label: L('Seren Touch — tay hoặc chân', 'Seren Touch — hands or feet'), price: '200.000₫' },
          { id: 'set_glow', label: L('Seren Glow — bộ gel', 'Seren Glow — gel set'), price: '300.000₫' },
          { id: 'set_bloom', label: L('Seren Bloom — bộ gel kèm design', 'Seren Bloom — gel set with design'), price: '450.000₫' },
          { id: 'set_sole', label: L('Seren Sole — chăm sóc móng chân', 'Seren Sole — pedicure'), price: '300.000₫' },
          { id: 'set_pure', label: L('Seren Pure — móng chân kèm dưỡng thư giãn chân 15 phút và sơn gel', 'Seren Pure — pedicure with 15-min foot relax and gel polish'), price: '550.000₫' },
          { id: 'set_ritual', label: L('Seren Ritual — móng chân kèm dưỡng thư giãn chân 15 phút', 'Seren Ritual — pedicure with 15-min foot relax'), price: '450.000₫' },
          heading(L('Chăm sóc móng', 'Nail care')),
          { id: 'care_reshape', label: L('Sửa form móng', 'Nail reshape'), price: '30.000₫' },
          { id: 'care_gel_removal', label: L('Tháo gel / cứng móng', 'Gel / hard gel removal'), price: '30.000 – 50.000₫' },
          { id: 'care_removal', label: L('Tháo móng úp, gel đắp, bột', 'Tips, gel or acrylic removal'), price: '50.000 – 100.000₫' },
          { id: 'care_skin', label: L('Làm sạch da tay / chân', 'Hand / foot skin cleansing'), price: '50.000 – 60.000₫' },
          { id: 'care_refill', label: L('Refill / up gel móng cũ', 'Refill / old gel touch-up'), price: '100.000 – 250.000₫' },
          { id: 'care_extensions', label: L('Đắp gel, bột, Powder X', 'Gel, acrylic, Powder X'), price: '380.000₫' },
          { id: 'care_base', label: L('Up keo / base', 'Glue / base coat application'), price: '100.000 – 200.000₫' },
          { id: 'care_gelx', label: L('Up gel X', 'Gel X application'), price: '280.000₫' },
          { id: 'care_dual', label: L('Dual form', 'Dual form'), price: '450.000₫' },
          heading(L('Màu và hiệu ứng', 'Colour and finish')),
          { id: 'colour_gel', label: L('Sơn gel / thạch', 'Gel polish / jelly'), price: '150.000₫' },
          { id: 'colour_cateye', label: L('Sơn mắt mèo / nhũ', 'Cat eye / flash effect'), price: '220.000₫' },
          { id: 'colour_chrome', label: L('Tráng gương', 'Mirror chrome effect'), price: '250.000₫' },
          { id: 'colour_ombre', label: L('Ombre / French', 'Ombre / French'), price: '250.000₫' },
          { id: 'colour_biab', label: L('BIAB', 'BIAB application'), price: '350.000₫' },
          { id: 'colour_hard_arc', label: L('Cứng móng có cầu móng', 'Hard nail polish with nail arc'), price: '100.000₫' },
          { id: 'colour_hardener', label: L('Sơn cứng móng', 'Nail hardening base coat'), price: '50.000₫' },
          { id: 'colour_multi', label: L('Sơn trên 3 màu', 'More than three colours'), price: '30.000₫' },
          { id: 'colour_regular', label: L('Sơn thường', 'Regular polish'), price: '100.000₫' },
          heading(L('Vẽ móng, giá mỗi ngón', 'Nail art, price per nail')),
          { id: 'art_french', label: L('Vẽ viền đầu móng / ombre', 'French tip / ombre'), price: '20.000₫' },
          { id: 'art_custom', label: L('Design theo mẫu / hoạt hình', 'Custom design / cartoon art'), price: '10.000 – 50.000₫' },
          { id: 'art_marble', label: L('Vẽ vân đá / kim tuyến', 'Marble effect / glitter'), price: '10.000 – 50.000₫' },
          { id: 'art_fishscale', label: L('Vảy cá / ẩn xà cừ', 'Fish scale / hidden seashell'), price: '10.000 – 50.000₫' },
          { id: 'art_charm', label: L('Gắn charm / đá', 'Charm / rhinestone'), price: '10.000 – 50.000₫' },
          { id: 'art_sticker', label: L('Gắn sticker', 'Sticker'), price: '10.000 – 50.000₫' },
        ] },
        { type: 'single', key: 'nail_shape', label: L('Dáng móng mong muốn (không bắt buộc)', 'Preferred nail shape (optional)'), options: [
          { id: 'round', label: L('Tròn', 'Round') }, { id: 'square', label: L('Vuông', 'Square') },
          { id: 'squoval', label: L('Vuông bo góc', 'Squoval') }, { id: 'oval', label: L('Oval', 'Oval') },
          { id: 'almond', label: L('Hạnh nhân', 'Almond') }, { id: 'coffin', label: L('Coffin', 'Coffin / Ballerina') },
        ] },
        { type: 'textarea', key: 'design_notes', label: L('Màu sắc / mẫu mong muốn (không bắt buộc)', 'Colour or design wishes (optional)') },
      ] },
      { title: L('Lưu ý & Chăm sóc', 'Good to Know & Aftercare'), items: [
        { type: 'info', groups: () => [
          { title: L('Lưu ý', 'Good to know'), items: [
            L('Độ bền của sơn gel và móng đắp phụ thuộc vào tình trạng móng thật và thói quen sinh hoạt.', 'How long gel and extensions last depends on your natural nails and daily activities.'),
            L('Có thể hơi đỏ nhẹ quanh da sau khi làm móng — sẽ hết sau vài giờ.', 'Slight redness around the cuticles is normal and fades within a few hours.'),
            L('Tháo gel/bột nên được thực hiện tại tiệm để tránh làm hư móng thật.', 'Gel and acrylic should be removed at the salon to avoid damaging your natural nails.'),
          ] },
          { title: L('Chăm sóc sau dịch vụ', 'Aftercare'), items: [
            L('Thoa dầu dưỡng móng mỗi ngày.', 'Apply cuticle oil every day.'),
            L('Đeo găng tay khi rửa chén hoặc dùng hoá chất tẩy rửa.', 'Wear gloves when washing up or using cleaning products.'),
            L('Không cạy, bóc sơn gel hoặc móng đắp.', "Don't pick or peel off gel or extensions."),
            L('Không dùng móng để cạy, mở đồ vật.', "Don't use your nails as tools."),
            L('Liên hệ với chúng tôi nếu móng bị bong, gãy hoặc có dấu hiệu kích ứng.', 'Contact us if your nails lift, break or show any signs of irritation.'),
          ] },
        ] },
      ] },
      { title: L('Cam Kết', 'Acknowledgement'), items: [
        { ...photoConsent, label: L('Sử dụng hình ảnh móng cho mục đích quảng bá', 'Use of photos of my nails for promotional purposes') },
        consents([
          L('Tôi đã được tư vấn về dịch vụ, sản phẩm sử dụng và cách chăm sóc sau dịch vụ.', 'I have been informed about the service, the products used and aftercare.'),
          L('Tôi hiểu có thể xảy ra trầy xước nhẹ hoặc kích ứng với sản phẩm, và tiệm sẽ luôn cố gắng hạn chế tối đa.', 'I understand minor nicks or a reaction to products can occasionally happen, and the salon takes every care to prevent them.'),
        ]),
      ] },
      totalSection,
    ],
  },

  {
    id: 'head_spa', icon: '💧',
    name: L('Gội Đầu Dưỡng Sinh', 'Head Spa'),
    title: L('Phiếu thông tin & Cam kết', 'Intake & Consent Form'),
    sections: [
      { title: L('Thông tin khách hàng', 'Customer Information'), items: [
        F.name, F.phone, F.email, F.dob(false), F.emergency, F.technician(L('Kỹ Thuật Viên (nếu biết)', 'Therapist (if known)')),
      ] },
      { title: L('Dịch vụ', 'Service'), items: [
        // Rituals and add-ons from serensaigon.com/pricing.
        { type: 'single', key: 'treatment', required: true, label: L('Liệu trình', 'Ritual'), options: [
          { id: 'refresh', label: L('Seren Refresh · 30 phút', 'Seren Refresh · 30 min'), price: '109.000₫' },
          { id: 'balance', label: L('Seren Balance · 60 phút', 'Seren Balance · 60 min'), price: '299.000₫' },
          { id: 'bloom', label: L('Seren Bloom · 80 phút', 'Seren Bloom · 80 min'), price: '389.000₫' },
          { id: 'signature', label: L('Seren Signature Ritual · 100 phút', 'Seren Signature Ritual · 100 min'), price: '559.000₫' },
          { id: 'glow', label: L('Seren Glow · 130 phút', 'Seren Glow · 130 min'), price: '749.000₫' },
          { id: 'sanctuary', label: L('Seren Sanctuary · 160 phút', 'Seren Sanctuary · 160 min'), price: '909.000₫' },
        ] },
        { type: 'multi', key: 'addons', label: L('Dịch vụ thêm (không bắt buộc)', 'Add-ons (optional)'), options: [
          { id: 'facial_scrub', label: L('Tẩy tế bào chết mặt', 'Facial scrub'), price: '50.000₫' },
          { id: 'facial_massage', label: L('Chăm sóc da mặt cơ bản', 'Facial basic'), price: '50.000₫' },
          { id: 'facial_mask', label: L('Đắp mặt nạ', 'Facial mask'), price: '50.000₫' },
          { id: 'eye_mask', label: L('Mặt nạ mắt', 'Eye mask'), price: '30.000₫' },
          { id: 'hot_stone', label: L('Đá nóng', 'Hot stone'), price: '50.000₫' },
          { id: 'head_scrub', label: L('Tẩy tế bào chết da đầu', 'Head scrub'), price: '50.000₫' },
        ] },
        { type: 'single', key: 'pressure', required: true, label: L('Lực massage mong muốn', 'Preferred pressure'), options: [
          { id: 'light', label: L('Nhẹ', 'Light') }, { id: 'medium', label: L('Vừa', 'Medium') }, { id: 'firm', label: L('Mạnh', 'Firm') },
        ] },
      ] },
      { title: L('Da đầu & Tóc', 'Scalp & Hair'), items: [
        { type: 'multi', key: 'scalp_concerns', label: L('Tình trạng da đầu và tóc của bạn (chọn nếu có)', 'Your scalp and hair (tick any that apply)'), options: [
          { id: 'dry', label: L('Da đầu khô', 'Dry scalp') },
          { id: 'oily', label: L('Da đầu dầu', 'Oily scalp') },
          { id: 'dandruff', label: L('Gàu', 'Dandruff') },
          { id: 'itchy', label: L('Ngứa hoặc nhạy cảm', 'Itchy or sensitive scalp') },
          { id: 'hairLoss', label: L('Rụng tóc', 'Hair loss') },
          { id: 'damaged', label: L('Tóc khô, hư tổn', 'Dry or damaged hair') },
          { id: 'chemical', label: L('Mới nhuộm, uốn hoặc duỗi (2 tuần)', 'Coloured, permed or straightened in the last 2 weeks') },
          { id: 'extensions', label: L('Tóc nối', 'Hair extensions') },
        ] },
      ] },
      { title: L('Cam kết', 'Consent'), items: wellnessAgreements(L('gội đầu dưỡng sinh', 'head spa')) },
      totalSection,
    ],
  },
  {
    id: 'waxing', icon: '🌸',
    name: L('Wax lông', 'Waxing'),
    title: L('Hợp đồng dịch vụ', 'Service Agreement'),
    sections: [
      { title: L('Thông tin khách hàng', 'Customer Information'), items: [
        F.name, F.phone, F.dob(false), F.technician(),
        { type: 'multi', key: 'wax_services', required: true,
          label: L('Vùng wax (chọn một hoặc nhiều)', 'Areas to wax (choose one or more)'),
          // Menu and prices from serensaigon.com/pricing (waxing).
          options: [
            { id: 'wax_fingers_toes', label: L('Ngón tay, ngón chân', 'Fingers and toes'), price: '50.000₫' },
            { id: 'wax_underarms', label: L('Nách', 'Underarms'), price: '100.000₫' },
            { id: 'wax_full_arms', label: L('Cánh tay', 'Full arms'), price: '250.000₫' },
            { id: 'wax_half_leg', label: L('½ chân', 'Half leg'), price: '300.000₫' },
            { id: 'wax_full_leg', label: L('Full chân', 'Full leg'), price: '400.000₫' },
            { id: 'wax_back', label: L('Lưng', 'Full back'), price: '450.000₫' },
            { id: 'wax_neck', label: L('Tóc gáy', 'Neck hair'), price: '150.000₫' },
            { id: 'wax_lip_nose', label: L('Mép, lông mũi', 'Lip edge and nose hair'), price: '100.000₫' },
            { id: 'wax_belly_chest', label: L('Bụng, ngực', 'Belly and chest'), price: '200.000₫' },
            { id: 'wax_ears_sideburns', label: L('Lỗ tai, tóc mai', 'Ears and sideburns'), price: '80.000₫' },
            { id: 'wax_eyebrow', label: L('Chân mày', 'Eyebrow'), price: '100.000₫' },
            { id: 'wax_bikini', label: L('Bikini', 'Bikini'), price: '450.000₫' },
            { id: 'wax_butt', label: L('Mông', 'Butt'), price: '450.000₫' },
            { id: 'wax_package', label: L('Gói: tay, chân, nách, bikini', 'Package: arms, legs, underarms and bikini'), price: '950.000₫' },
          ] },
      ] },
      { title: L('Chống Chỉ Định', 'Contraindications'), items: [
        { type: 'checklist', key: 'contraindications', autoUnder16: 'under16',
          warning: L('Vui lòng báo cho kỹ thuật viên trước khi tiếp tục. Kỹ thuật viên sẽ tư vấn dịch vụ có phù hợp với bạn hay không.',
                     'Please let your technician know before continuing. They will advise whether this service is suitable for you.'),
          options: [
            { id: 'retinoid', label: L('Đang hoặc trong 6 tháng qua dùng Retinol, AHA/BHA hoặc thuốc trị mụn (ví dụ isotretinoin).', 'Using Retinol, AHA/BHA or acne medication (e.g. isotretinoin) now or in the last 6 months.') },
            { id: 'skin', label: L('Da bị cháy nắng, trầy xước, kích ứng hoặc mới peel/laser ở vùng wax.', 'Sunburn, broken or irritated skin, or a recent peel or laser treatment on the area.') },
            { id: 'circulation', label: L('Tiểu đường, vấn đề tuần hoàn, giãn tĩnh mạch hoặc đang dùng thuốc chống đông máu.', 'Diabetes, circulation problems, varicose veins or blood-thinning medication.') },
            { id: 'allergy', label: L('Dị ứng với sáp wax, nhựa thông hoặc sản phẩm chăm sóc da.', 'Allergy to wax, rosin or skin care products.') },
            { id: 'pregnant', label: L('Đang mang thai.', 'Pregnant.') },
            { id: 'under16', label: L('Dưới 16 tuổi.', 'Under 16 years old.') },
          ] },
      ] },
      { title: L('Chăm Sóc Sau Dịch Vụ', 'Aftercare'), items: [
        { type: 'info', groups: () => [{ title: L('Sau khi wax', 'After waxing'), items: [
          L('Tránh tắm nước nóng, xông hơi, bơi và tập thể dục trong 24 giờ.', 'Avoid hot showers, saunas, swimming and exercise for 24 hours.'),
          L('Tránh nắng và tắm nắng trong 48 giờ.', 'Avoid the sun and tanning for 48 hours.'),
          L('Không dùng nước hoa, lăn khử mùi hoặc tẩy tế bào chết trên vùng wax trong 24 giờ.', 'No perfume, deodorant or exfoliants on the waxed area for 24 hours.'),
          L('Mặc quần áo rộng rãi. Sau 2–3 ngày, tẩy tế bào chết nhẹ nhàng để tránh lông mọc ngược.', 'Wear loose clothing. After 2–3 days, exfoliate gently to prevent ingrown hairs.'),
          L('Da hơi đỏ hoặc nổi mẩn trong vài giờ là bình thường.', 'Mild redness or bumps for a few hours are normal.'),
        ] }] },
      ] },
      { title: L('Cam Kết', 'Acknowledgement'), items: [
        consents([
          L('Tôi đã được tư vấn đầy đủ về quy trình, rủi ro và chăm sóc sau dịch vụ.', 'I have been fully informed about the procedure, risks, and aftercare.'),
          L('Tôi hiểu da có thể bị đỏ, nhạy cảm hoặc bầm nhẹ sau khi wax.', 'I understand redness, sensitivity or minor bruising can occur after waxing.'),
          (s) => (s.contraindications?.ticked?.length
            ? L('Tôi đã trao đổi các tình trạng đã đánh dấu ở trên với kỹ thuật viên và đồng ý thực hiện dịch vụ.', 'I have discussed the conditions ticked above with my technician and agree to proceed.')
            : L('Tôi xác nhận không có chống chỉ định và không đang mang thai.', 'I confirm that I have no contraindications and I am not pregnant.')),
        ], { resetWith: 'contraindications' }),
      ] },
      totalSection,
      signatureSection,
    ],
  },
];

const OPTION_SETS = {
  areas: [
    { id: 'head', label: L('Đầu', 'Head') }, { id: 'face', label: L('Mặt', 'Face') },
    { id: 'neck', label: L('Cổ', 'Neck') }, { id: 'shoulders', label: L('Vai', 'Shoulders') },
    { id: 'upperBack', label: L('Lưng trên', 'Upper back') }, { id: 'lowerBack', label: L('Lưng dưới', 'Lower back') },
    { id: 'arms', label: L('Tay', 'Arms') }, { id: 'hands', label: L('Bàn tay', 'Hands') },
    { id: 'abdomen', label: L('Bụng', 'Abdomen') }, { id: 'glutes', label: L('Mông', 'Glutes') },
    { id: 'legs', label: L('Chân', 'Legs') }, { id: 'feet', label: L('Bàn chân', 'Feet') },
  ],
};
const allOptionsOf = (item) => (typeof item.options === 'string' ? OPTION_SETS[item.options] : item.options);
/** Choosable options only (without sub-headings). */
const optionsOf = (item) => allOptionsOf(item).filter((o) => !o.heading);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const store = {
  get(key) { try { return localStorage.getItem(key); } catch { return null; } },
  set(key, value) { try { localStorage.setItem(key, value); } catch { /* private mode */ } },
};

const LANGS = ['both', 'vi', 'en', ...EXTRA_LANGS];
/** First visit: use the phone's language if the page offers it, otherwise Vietnamese + English. */
function defaultLang() {
  const code = (navigator.language || '').toLowerCase().slice(0, 2);
  return EXTRA_LANGS.includes(code) ? code : 'both';
}
let lang = LANGS.includes(store.get('seren-lang')) ? store.get('seren-lang') : defaultLang();
let service = null;
let state = {};

const both = (l) => (l.vi === l.en ? l.vi : `${l.vi} / ${l.en}`);
// Records always use both(); the screen shows the chosen language (English when a translation is missing).
const txt = (l) => (lang === 'both' ? both(l) : l[lang] || l.en);
const resolve = (value) => (typeof value === 'function' ? value(state) : value);

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

/** Vietnamese with English underneath (or one language). */
function lt(l, tag = 'span', cls) {
  if (lang !== 'both' || l.vi === l.en) return h(tag, { class: cls }, txt(l));
  return h(tag, { class: cls }, l.vi, h('br'), h('span', { class: 'en' }, l.en));
}

/** An option's label, with its price on the right when it has one (e.g. price: '350.000₫'). */
function optionLabel(o) {
  if (!o.price) return lt(o.label);
  return h('span', { class: 'with-price' }, lt(o.label), h('span', { class: 'price' }, o.price));
}

const withPrice = (o) => (o.price ? `${both(o.label)} (${o.price})` : both(o.label));

// ---- Total -------------------------------------------------------------------
const TOTAL = {
  total: L('Tổng cộng', 'Total'),
  nothing: L('Chưa chọn dịch vụ nào.', 'No services chosen yet.'),
  vnd: L('Giá niêm yết bằng VNĐ.', 'Prices are in VND.'),
  range: L('Một số dịch vụ có giá theo khoảng hoặc tính theo ngón. Kỹ thuật viên sẽ xác nhận giá cuối cùng trước khi bắt đầu.',
           'Some prices are a range or per nail. Your technician will confirm the final price before starting.'),
};
/** '450.000₫' → { lo: 450000, hi: 450000 }; '10.000 – 50.000₫' → { lo: 10000, hi: 50000 }. */
function parsePrice(price) {
  const nums = (String(price).match(/\d[\d.]*/g) || []).map((n) => Number(n.replace(/\./g, '')));
  return { lo: nums[0] || 0, hi: nums[1] || nums[0] || 0 };
}
const vnd = (n) => `${String(n).replace(/\B(?=(\d{3})+(?!\d))/g, '.')}₫`;
const priceRange = (lo, hi) => (lo === hi ? vnd(lo) : `${vnd(lo).slice(0, -1)} – ${vnd(hi)}`);

/** Every priced option chosen on the current form, in form order, with the total. */
function priced() {
  const lines = [];
  for (const item of allItems()) {
    if (item.type !== 'single' && item.type !== 'multi') continue;
    const chosen = item.type === 'single' ? [state[item.key]] : state[item.key] || [];
    for (const o of optionsOf(item)) if (o.price && chosen.includes(o.id)) lines.push({ option: o, ...parsePrice(o.price) });
  }
  const lo = lines.reduce((sum, l) => sum + l.lo, 0);
  const hi = lines.reduce((sum, l) => sum + l.hi, 0);
  return { lines, lo, hi, text: priceRange(lo, hi), isRange: lo !== hi };
}

function ageFrom(isoDate) {
  const birth = new Date(isoDate);
  if (Number.isNaN(birth.getTime())) return null;
  const now = new Date();
  let age = now.getFullYear() - birth.getFullYear();
  const m = now.getMonth() - birth.getMonth();
  if (m < 0 || (m === 0 && now.getDate() < birth.getDate())) age -= 1;
  return age;
}

const today = () => new Date().toLocaleDateString('vi-VN');

// ---------------------------------------------------------------------------
// Rendering
// ---------------------------------------------------------------------------

const app = document.getElementById('app');
const backButton = document.getElementById('back');
const langSelect = document.getElementById('lang');
let wrappers = [];   // { item, node } for re-rendering
let signaturePad = null;

function setStatic() {
  const extra = I18N.languages.find((l) => l.code === lang);
  document.documentElement.lang = extra ? extra.htmlLang : lang === 'en' ? 'en' : 'vi';
  backButton.replaceChildren('‹ ', txt(T.back));
  langSelect.value = lang;
}

function showChooser() {
  service = null;
  backButton.hidden = true;
  setStatic();
  app.replaceChildren(
    h('div', { class: 'hero' }, lt(T.chooseTitle, 'h1'), h('p', {}, lt(T.chooseSub))),
    h('div', { class: 'service-list' }, SERVICES.map((s) =>
      h('button', { class: 'service', type: 'button', onclick: () => startService(s) },
        h('span', { class: 'icon', 'aria-hidden': 'true' }, s.icon),
        lt(s.name, 'span', 'name'),
        h('span', { class: 'chev', 'aria-hidden': 'true' }, '›')))),
  );
  window.scrollTo(0, 0);
}

function startService(s) {
  service = s;
  state = {};
  renderForm();
  window.scrollTo(0, 0);
}

function renderForm() {
  backButton.hidden = false;
  setStatic();
  wrappers = [];
  const sections = service.sections.map((section, index) =>
    h('section', { class: 'card' },
      h('div', { class: 'section-title' }, h('span', { class: 'num' }, String(index + 1)), lt(section.title, 'h2')),
      section.items.map((item) => {
        const node = h('div', { class: 'item' });
        wrappers.push({ item, node });
        node.append(renderItem(item));
        return node;
      })));
  app.replaceChildren(
    h('div', { class: 'hero' }, lt(service.name, 'h1'), h('p', {}, lt(service.title))),
    h('div', { id: 'errors' }),
    h('div', { class: 'stack' }, sections),
    h('div', { style: 'margin-top:24px' },
      h('button', { class: 'primary', id: 'submit', type: 'button', onclick: submit },
        submitLabel())),
  );
}

function submitLabel() {
  if (EXTRA_LANGS.includes(lang)) return [txt(T.submit)];
  return [T.submit.vi, lang !== 'vi' ? h('span', { class: 'en' }, T.submit.en) : null];
}

function rerender(predicate) {
  for (const w of wrappers) {
    if (predicate(w.item)) w.node.replaceChildren(renderItem(w.item));
  }
}
const rerenderDynamic = () => rerender((item) => item.dynamic);

const isRequired = (item) => (typeof item.required === 'function' ? item.required(state) : Boolean(item.required));

function label(item) {
  return h('span', { class: 'label' }, txt(resolve(item.label)), isRequired(item) ? h('span', { class: 'req' }, ' *') : null);
}

function renderItem(item) {
  if (item.show && !item.show(state)) return h('span');
  switch (item.type) {
    case 'text': {
      const input = h('input', {
        type: item.input || 'text', id: item.key, autocomplete: item.autocomplete || 'off',
        inputmode: item.input === 'tel' ? 'tel' : null, value: state[item.key] || '',
        oninput: (e) => { state[item.key] = e.target.value; e.target.classList.remove('invalid'); },
      });
      return h('label', { class: 'field' }, label(item), input);
    }
    case 'textarea':
      return h('label', { class: 'field' }, label(item),
        h('textarea', { id: item.key, oninput: (e) => { state[item.key] = e.target.value; } }, state[item.key] || ''));
    case 'date':
      return h('label', { class: 'field' }, label(item), h('input', {
        type: 'date', id: item.key, value: state[item.key] || '', max: new Date().toISOString().slice(0, 10),
        onchange: (e) => { state[item.key] = e.target.value; e.target.classList.remove('invalid'); autoUnder16(); },
      }));
    case 'single': {
      const options = optionsOf(item);
      return h('div', { class: 'field' }, label(item),
        h('div', { class: 'choices', role: 'radiogroup' }, options.map((o) =>
          h('button', {
            type: 'button', class: 'chip round', role: 'radio', 'aria-checked': String(state[item.key] === o.id),
            onclick: () => {
              // Tapping the chosen option again clears it (useful for optional choices).
              state[item.key] = state[item.key] === o.id ? '' : o.id;
              rerender((i) => i === item || i.dynamic);
            },
          }, h('span', { class: 'box' }), optionLabel(o)))));
    }
    case 'multi': {
      const selected = state[item.key] || [];
      return h('div', { class: 'field' }, label(item),
        h('div', { class: 'choices' }, allOptionsOf(item).map((o) => (o.heading
          ? lt(o.heading, 'h3', 'choice-heading')
          : h('button', {
            type: 'button', class: 'chip', 'aria-pressed': String(selected.includes(o.id)),
            onclick: () => {
              const now = new Set(state[item.key] || []);
              if (now.has(o.id)) now.delete(o.id); else now.add(o.id);
              state[item.key] = [...now];
              if (item.exclusiveWith && now.has(o.id)) {
                state[item.exclusiveWith] = (state[item.exclusiveWith] || []).filter((id) => id !== o.id);
              }
              rerender((i) => i === item || i.key === item.exclusiveWith || i.dynamic);
            },
          }, h('span', { class: 'box' }), optionLabel(o))))));
    }
    case 'checklist': {
      const value = state[item.key] || { ticked: [], none: false };
      const set = (next) => {
        state[item.key] = next;
        for (const w of wrappers) if (w.item.resetWith === item.key) state[w.item.key] = false;
        rerender((i) => i === item || i.dynamic);
      };
      return h('div', {},
        h('p', { style: 'margin-top:0' }, h('strong', {}, lt(T.tickPrompt))),
        h('div', { class: 'check-list' }, item.options.map((o) =>
          h('button', {
            type: 'button', class: 'chip', 'aria-pressed': String(value.ticked.includes(o.id)),
            onclick: () => {
              const ticked = value.ticked.includes(o.id) ? value.ticked.filter((id) => id !== o.id) : [...value.ticked, o.id];
              set({ ticked, none: false });
            },
          }, h('span', { class: 'box' }), lt(o.label)))),
        h('hr', { class: 'divider' }),
        h('button', {
          type: 'button', class: 'chip', 'aria-pressed': String(value.none),
          onclick: () => set({ ticked: [], none: !value.none }),
        }, h('span', { class: 'box' }), lt(T.noneApply)),
        value.ticked.length ? h('div', { class: 'notice' }, h('span', { class: 'i' }, '⚠️'), lt(item.warning)) : null);
    }
    case 'info': {
      const groups = item.groups(state);
      return h('div', {}, groups.map((g) => h('div', { class: 'group' },
        g.title && groups.length > 1 ? lt(g.title, 'h3') : null,
        h('ul', { class: 'bullets' }, g.items.map((l) => h('li', {}, lt(l)))))));
    }
    case 'note':
      return h('div', { class: `notice ${item.tone || ''}` }, h('span', { class: 'i' }, item.tone === 'info' ? 'ℹ️' : '⚠️'), lt(item.text));
    case 'consents':
      return h('div', { class: 'consents' },
        h('ul', { class: 'bullets' }, item.statements.map((l) => h('li', {}, lt(resolve(l))))),
        h('button', {
          type: 'button', class: 'chip agree-all', 'aria-pressed': String(Boolean(state[item.key])),
          onclick: () => { state[item.key] = !state[item.key]; rerender((i) => i === item); },
        }, h('span', { class: 'box' }), h('strong', {}, lt(T.agreeAll))));
    case 'total': {
      const bill = priced();
      if (!bill.lines.length) return h('p', { class: 'muted' }, txt(TOTAL.nothing));
      return h('div', { class: 'bill' },
        bill.lines.map((l) => h('div', { class: 'bill-line' }, lt(l.option.label), h('span', { class: 'price' }, l.option.price))),
        h('div', { class: 'bill-total' }, h('span', {}, txt(TOTAL.total)), h('span', { class: 'price' }, bill.text)),
        h('p', { class: 'muted' }, txt(TOTAL.vnd)),
        bill.isRange ? h('div', { class: 'notice info' }, h('span', { class: 'i' }, 'ℹ️'), lt(TOTAL.range)) : null);
    }
    case 'signature':
      return renderSignature(item);
    default:
      return h('span');
  }
}

function autoUnder16() {
  const age = state.date_of_birth ? ageFrom(state.date_of_birth) : null;
  for (const w of wrappers) {
    const item = w.item;
    if (item.type === 'checklist' && item.autoUnder16 && age != null && age < 16) {
      const value = state[item.key] || { ticked: [], none: false };
      if (!value.ticked.includes(item.autoUnder16)) {
        state[item.key] = { ticked: [...value.ticked, item.autoUnder16], none: false };
        rerender((i) => i === item || i.dynamic);
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Signature pad
// ---------------------------------------------------------------------------

function renderSignature(item) {
  const canvas = h('canvas', { 'aria-label': txt(item.label) });
  const wrap = h('div', { class: 'sig-wrap', id: 'signature' }, h('span', { class: 'sig-x' }, '✕'), h('span', { class: 'sig-line' }), canvas);
  const pad = { canvas, drawn: false };
  signaturePad = pad;

  const ctx = canvas.getContext('2d');
  let drawing = false;
  let last = null;

  const setup = () => {
    const ratio = window.devicePixelRatio || 1;
    const rect = canvas.getBoundingClientRect();
    if (!rect.width) return;
    canvas.width = Math.round(rect.width * ratio);
    canvas.height = Math.round(rect.height * ratio);
    ctx.setTransform(ratio, 0, 0, ratio, 0, 0);
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    ctx.lineWidth = 2.6;
    ctx.strokeStyle = '#111';
    if (state[item.key]) {
      // Redraw a signature made before a language switch.
      const img = new Image();
      img.onload = () => ctx.drawImage(img, 0, 0, rect.width, rect.height);
      img.src = state[item.key];
      pad.drawn = true;
    }
  };
  requestAnimationFrame(setup);

  const point = (e) => {
    const rect = canvas.getBoundingClientRect();
    return { x: e.clientX - rect.left, y: e.clientY - rect.top };
  };
  canvas.addEventListener('pointerdown', (e) => {
    e.preventDefault();
    canvas.setPointerCapture(e.pointerId);
    drawing = true;
    last = point(e);
    ctx.beginPath();
    ctx.arc(last.x, last.y, 1.2, 0, Math.PI * 2);
    ctx.fillStyle = '#111';
    ctx.fill();
  });
  canvas.addEventListener('pointermove', (e) => {
    if (!drawing) return;
    e.preventDefault();
    const p = point(e);
    ctx.beginPath();
    ctx.moveTo(last.x, last.y);
    ctx.lineTo(p.x, p.y);
    ctx.stroke();
    last = p;
  });
  const end = () => {
    if (!drawing) return;
    drawing = false;
    pad.drawn = true;
    state[item.key] = canvas.toDataURL('image/png');
    wrap.classList.remove('invalid');
  };
  canvas.addEventListener('pointerup', end);
  canvas.addEventListener('pointercancel', end);

  const clear = () => {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    pad.drawn = false;
    delete state[item.key];
  };

  return h('div', { class: 'field' }, label(item), wrap,
    h('div', { class: 'sig-actions' },
      h('span', {}, `${txt(T.signHint)} · ${txt(T.date)}: ${today()}`),
      h('button', { type: 'button', class: 'link-button', onclick: clear }, txt(T.clear))));
}

/** Whether the current form asks for a signature (Brows & Lashes and Waxing do). */
const hasSignature = () => !!signaturePad && allItems().some((item) => item.type === 'signature');

/** The signature on a white background, as a PNG data URL. */
function signatureDataURL() {
  const src = signaturePad.canvas;
  const out = document.createElement('canvas');
  out.width = src.width;
  out.height = src.height;
  const ctx = out.getContext('2d');
  ctx.fillStyle = '#fff';
  ctx.fillRect(0, 0, out.width, out.height);
  ctx.drawImage(src, 0, 0);
  return out.toDataURL('image/png');
}

// ---------------------------------------------------------------------------
// Validation & submission
// ---------------------------------------------------------------------------

function allItems() {
  return service.sections.flatMap((s) => s.items).filter((item) => !item.show || item.show(state));
}

function validate() {
  const missing = [];
  const bad = [];
  for (const item of allItems()) {
    const value = state[item.key];
    switch (item.type) {
      case 'text':
        if (isRequired(item) && !(value || '').trim()) { missing.push(item.label); bad.push(item.key); }
        break;
      case 'date':
        if (isRequired(item) && !value) { missing.push(item.label); bad.push(item.key); }
        break;
      case 'single':
        if (isRequired(item) && !value) missing.push(item.label);
        break;
      case 'multi':
        if (isRequired(item) && !(value || []).length) missing.push(item.label);
        break;
      case 'checklist':
        if (!value || (!value.ticked.length && !value.none)) missing.push(T.healthMissing);
        break;
      case 'signature':
        if (!signaturePad || !signaturePad.drawn) { missing.push(item.label); bad.push('signature'); }
        break;
      default:
        break;
    }
  }
  const agreements = allItems().filter((i) => i.type === 'consents');
  if (agreements.some((i) => !state[i.key])) missing.push(T.agreeMissing);
  return { missing, bad };
}

function showErrors(missing, bad) {
  const box = document.getElementById('errors');
  document.querySelectorAll('.invalid').forEach((n) => n.classList.remove('invalid'));
  bad.forEach((key) => document.getElementById(key)?.classList.add('invalid'));
  box.replaceChildren(h('div', { class: 'card errors', role: 'alert', style: 'margin-bottom:16px' },
    h('strong', {}, txt(T.pleaseComplete)),
    h('ul', {}, missing.map((l) => h('li', {}, txt(resolve(l)))))));
  box.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

function formatValue(item) {
  const value = state[item.key];
  switch (item.type) {
    case 'text': case 'textarea': case 'date':
      return (value || '').trim() || '—';
    case 'single': {
      const chosen = optionsOf(item).find((o) => o.id === value);
      return chosen ? withPrice(chosen) : '—';
    }
    case 'multi':
      return (value || []).length ? optionsOf(item).filter((o) => value.includes(o.id)).map(withPrice).join(', ') : '—';
    case 'checklist': {
      if (!value) return '—';
      if (value.none) return both(T.noneApply);
      return item.options.filter((o) => value.ticked.includes(o.id)).map((o) => `⚠ ${both(o.label)}`).join('\n');
    }
    default:
      return '';
  }
}

function buildSummary() {
  const lines = [`${both(service.name)} — ${both(service.title)}`, `${both(T.date)}: ${new Date().toLocaleString('vi-VN')}`, ''];
  service.sections.forEach((section, index) => {
    lines.push(`${index + 1}. ${both(section.title)}`);
    for (const item of section.items) {
      if (item.show && !item.show(state)) continue;
      if (item.type === 'consents') {
        item.statements.forEach((l) => lines.push(`• ${both(resolve(l))}`));
        lines.push(`${state[item.key] ? '☑' : '☐'} ${both(T.agreeAll)}`);
      }
      else if (item.type === 'total') {
        const bill = priced();
        bill.lines.forEach((l) => lines.push(`• ${both(l.option.label)}: ${l.option.price}`));
        lines.push(`${both(TOTAL.total)}: ${bill.lines.length ? bill.text : '—'}`);
      }
      else if (item.type === 'signature') lines.push(`${both(item.label)}: ${signaturePad?.drawn ? '✓ (signature.png)' : '—'}`);
      else if (item.key) lines.push(`${both(resolve(item.label) || T.tickPrompt)}: ${formatValue(item)}`);
    }
    lines.push('');
  });
  return lines.join('\n');
}

function healthFlags() {
  const flags = [];
  for (const item of allItems()) {
    if (item.type !== 'checklist') continue;
    const value = state[item.key];
    if (value?.ticked?.length) flags.push(...item.options.filter((o) => value.ticked.includes(o.id)).map((o) => both(o.label)));
  }
  if ((state.health_details || '').trim()) flags.push(state.health_details.trim());
  return flags.length ? flags.join('; ') : 'None';
}

async function submit() {
  const { missing, bad } = validate();
  if (missing.length) { showErrors(missing, bad); return; }
  document.getElementById('errors').replaceChildren();

  const button = document.getElementById('submit');
  button.disabled = true;
  button.replaceChildren(txt(T.sending));

  try {
    const endpoint = (window.SEREN_CHECKIN || {}).endpoint;
    if (!endpoint) throw new Error('not-configured');
    const answers = { ...state };
    delete answers.signature;
    const photo = allItems().find((i) => i.key === 'photo_consent');
    const payload = {
      website: '', // honeypot: real people never fill this in
      service: both(service.name),
      full_name: (state.full_name || '').trim(),
      phone: (state.phone || '').trim(),
      date_of_birth: state.date_of_birth || '',
      technician: (state.technician || '').trim(),
      health_flags: healthFlags(),
      photo_consent: photo ? formatValue(photo) : '—',
      language: lang,
      summary: buildSummary(),
      answers_json: JSON.stringify({ service: service.id, ...answers }),
      signature: hasSignature() ? signatureDataURL() : '',
      // Short English versions for the Google Sheet.
      service_en: service.name.en,
      chosen_en: priced().lines.map((l) => l.option.label.en).join(', '),
      total_vnd: priced().lines.length ? priced().lo : '',
    };
    // text/plain keeps this a "simple" request, which Google Apps Script accepts from any site.
    const response = await fetch(endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'text/plain;charset=utf-8' },
      body: JSON.stringify(payload),
      redirect: 'follow',
    });
    const result = await response.json().catch(() => ({}));
    if (!response.ok || !result.ok) throw new Error(result.error || `HTTP ${response.status}`);
    showThanks();
  } catch (error) {
    console.error(error);
    button.disabled = false;
    button.replaceChildren(...submitLabel());
    const box = document.getElementById('errors');
    const message = error.message === 'not-configured' ? T.notConfigured : T.sendError;
    box.replaceChildren(h('div', { class: 'card errors', role: 'alert', style: 'margin-bottom:16px' }, txt(message)));
    box.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }
}

function showThanks() {
  backButton.hidden = true;
  state = {};
  signaturePad = null;
  app.replaceChildren(h('div', { class: 'card done' },
    h('div', { class: 'big', 'aria-hidden': 'true' }, '💛'),
    lt(T.thanks, 'h1'),
    h('p', {}, lt(T.checkedIn)),
    h('button', { type: 'button', class: 'secondary', onclick: showChooser }, txt(T.another))));
  window.scrollTo(0, 0);
}

// ---------------------------------------------------------------------------
// Start
// ---------------------------------------------------------------------------

for (const l of I18N.languages) langSelect.append(h('option', { value: l.code }, l.name));
langSelect.value = lang;
langSelect.addEventListener('change', () => {
  lang = langSelect.value;
  store.set('seren-lang', lang);
  if (service && app.querySelector('#submit')) renderForm(); else if (service) showThanks(); else showChooser();
});
backButton.addEventListener('click', () => {
  if (Object.keys(state).length && !window.confirm(txt(L('Quay lại? Thông tin đã nhập sẽ bị xoá.', 'Go back? Your answers will be cleared.')))) return;
  showChooser();
});

// Deep link: checkin.serensaigon.com/?service=nails opens that form directly.
const requested = new URLSearchParams(location.search).get('service');
const direct = SERVICES.find((s) => s.id === requested);
if (direct) startService(direct); else showChooser();
