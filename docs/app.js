/* Seren check-in: customers choose a service, fill in the form on their phone and sign.
   Submissions are sent to Seren's Google Apps Script (see google-apps-script/Code.gs), which adds a row to a
   private Google Sheet and saves the signature to Google Drive. The endpoint URL is set in config.js.
   The wording matches the iPad app (ios-apps/*Content.swift). */
'use strict';

const BUSINESS = 'Seren';
const L = (vi, en) => ({ vi, en });

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
  agreeMissing: L('Đánh dấu tất cả các mục Cam kết', 'Tick every agreement box'),
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

const signatureSection = {
  title: L('Chữ ký', 'Signature'),
  items: [
    { type: 'agree', key: 'privacy_consent', label: T.privacy },
    { type: 'signature', key: 'signature', label: T.signature, required: true },
  ],
};

const wellnessAgreements = (activity) => [
  { type: 'agree', key: 'agree_accurate', label: L(
    'Tôi xác nhận thông tin sức khoẻ trên là chính xác và sẽ báo ngay cho kỹ thuật viên nếu có thay đổi.',
    'I confirm the health information above is accurate and I will tell my therapist about any changes.') },
  { type: 'agree', key: 'agree_not_medical', label: L(
    `Tôi hiểu ${activity.vi} nhằm mục đích thư giãn và chăm sóc sức khoẻ, không thay thế cho chẩn đoán hay điều trị y khoa.`,
    `I understand ${activity.en} is for relaxation and wellness and is not a substitute for medical diagnosis or treatment.`) },
  { type: 'agree', key: 'agree_communicate', label: L(
    'Tôi sẽ báo cho kỹ thuật viên nếu cảm thấy khó chịu hoặc đau, và có quyền dừng buổi dịch vụ bất cứ lúc nào.',
    'I will tell my therapist if I feel any discomfort or pain, and I may stop the session at any time.') },
  { type: 'agree', key: 'agree_conduct', label: L(
    'Tôi hiểu rằng mọi hành vi hoặc yêu cầu không phù hợp sẽ khiến buổi dịch vụ kết thúc ngay và vẫn phải thanh toán đầy đủ.',
    'I understand that any inappropriate behaviour or requests will end the session immediately, with full payment due.') },
  { type: 'agree', key: 'agree_release', label: L(
    `Tôi tự nguyện sử dụng dịch vụ và không yêu cầu ${BUSINESS} chịu trách nhiệm về các vấn đề phát sinh do thông tin sức khoẻ không chính xác hoặc không được khai báo.`,
    `I receive this service voluntarily and release ${BUSINESS} from liability for issues arising from inaccurate or undisclosed health information.`) },
];

// ---------------------------------------------------------------------------
// Services
// ---------------------------------------------------------------------------

const BROW_IDS = ['lamination_tint', 'lamination', 'tint'];
const LIFT_IDS = ['lash_lift_tint', 'lash_lift', 'lash_tint'];
const pick = (selected, ids) => !selected.length || selected.some((id) => ids.includes(id));
const hasLashes = (s) => pick(s.brow_services || [], [...LIFT_IDS, 'lash_ext']);

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
          options: [
            { id: 'lamination_tint', label: L('Uốn & Nhuộm chân mày', 'Brows Lamination + Tint') },
            { id: 'lamination', label: L('Uốn chân mày', 'Brows Lamination') },
            { id: 'tint', label: L('Nhuộm chân mày', 'Brows Tint') },
            { id: 'lash_lift_tint', label: L('Uốn & Nhuộm mi', 'Lash Lift + Tint') },
            { id: 'lash_lift', label: L('Uốn mi', 'Lash Lift') },
            { id: 'lash_tint', label: L('Nhuộm mi', 'Lash Tint') },
            { id: 'lash_ext', label: L('Nối mi', 'Lash Extensions') },
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
          pick(s.brow_services || [], ['lash_ext']) && { title: L('Nối mi', 'Lash Extensions'), items: [
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
          pick(s.brow_services || [], ['lash_ext']) && { title: L('Nối mi', 'Lash Extensions'), items: [
            L('Tránh nước và hơi nước trong 24h đầu.', 'Avoid water and steam for the first 24 hours.'),
            L('Không dùng tẩy trang hoặc sản phẩm có dầu quanh mắt.', 'Avoid oil-based makeup removers and products around the eyes.'),
            L('Không dụi, kéo, cắt mi hoặc dùng kẹp bấm mi.', "Don't rub, pull or cut your lashes, or use an eyelash curler."),
            L('Chải mi nhẹ nhàng mỗi ngày.', 'Brush your lashes gently every day.'),
            L('Đặt lịch dặm mi sau 2–3 tuần.', 'Book a refill every 2–3 weeks.'),
          ] },
        ].filter(Boolean) },
      ] },
      { title: L('Cam Kết', 'Acknowledgement'), items: [
        { type: 'agree', key: 'ack_informed', label: L('Tôi đã được tư vấn đầy đủ về quy trình, rủi ro và chăm sóc sau dịch vụ.', 'I have been fully informed about the procedure, risks, and aftercare.') },
        { type: 'agree', key: 'ack_health', dynamic: true, resetWith: 'contraindications',
          label: (s) => (s.contraindications?.ticked?.length
            ? L('Tôi đã trao đổi các tình trạng đã đánh dấu ở trên với kỹ thuật viên và đồng ý thực hiện dịch vụ.', 'I have discussed the conditions ticked above with my technician and agree to proceed.')
            : L('Tôi xác nhận không có chống chỉ định và không đang mang thai.', 'I confirm that I have no contraindications and I am not pregnant.')) },
        { ...photoConsent, label: L('Sử dụng hình ảnh cho mục đích quảng bá', 'Use of my images for promotional purposes') },
      ] },
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
        { type: 'single', key: 'massage_type', required: true, label: L('Loại massage', 'Massage type'), options: [
          { id: 'swedish', label: L('Massage thư giãn toàn thân', 'Swedish / Relaxation') },
          { id: 'deep', label: L('Massage mô sâu', 'Deep Tissue') },
          { id: 'hotstone', label: L('Massage đá nóng', 'Hot Stone') },
          { id: 'aroma', label: L('Massage tinh dầu', 'Aromatherapy') },
          { id: 'neck', label: L('Massage cổ vai gáy', 'Neck & Shoulders') },
          { id: 'foot', label: L('Massage chân / bấm huyệt', 'Foot / Reflexology') },
          { id: 'prenatal', label: L('Massage cho mẹ bầu', 'Prenatal') },
        ] },
        { type: 'single', key: 'duration', required: true, label: L('Thời gian', 'Duration'), options: [
          { id: '30', label: L('30 phút', '30 minutes') }, { id: '60', label: L('60 phút', '60 minutes') },
          { id: '90', label: L('90 phút', '90 minutes') }, { id: '120', label: L('120 phút', '120 minutes') },
        ] },
        { type: 'single', key: 'pressure', required: true, label: L('Lực massage mong muốn', 'Preferred pressure'), options: [
          { id: 'light', label: L('Nhẹ', 'Light') }, { id: 'medium', label: L('Vừa', 'Medium') },
          { id: 'firm', label: L('Mạnh', 'Firm') }, { id: 'deep', label: L('Rất mạnh', 'Extra firm') },
        ] },
      ] },
      { title: L('Vùng cơ thể', 'Body Areas'), items: [
        { type: 'multi', key: 'focus_areas', exclusiveWith: 'avoid_areas', label: L('Vùng muốn tập trung', 'Areas to focus on'), options: 'areas' },
        { type: 'multi', key: 'avoid_areas', exclusiveWith: 'focus_areas', label: L('Vùng muốn tránh', 'Areas to avoid'), options: 'areas' },
      ] },
      { title: L('Tình trạng sức khoẻ', 'Health Information'), items: [
        { type: 'checklist', key: 'conditions',
          warning: L('Vui lòng trao đổi với kỹ thuật viên trước khi bắt đầu. Kỹ thuật viên có thể điều chỉnh hoặc khuyên bạn hỏi ý kiến bác sĩ.',
                     'Please talk to your therapist before starting. They may adjust the massage or recommend checking with your doctor.'),
          options: [
            { id: 'pregnant', label: L('Đang mang thai', 'Pregnant') },
            { id: 'bloodPressure', label: L('Huyết áp cao hoặc thấp', 'High or low blood pressure') },
            { id: 'heart', label: L('Bệnh tim mạch', 'Heart condition') },
            { id: 'diabetes', label: L('Tiểu đường', 'Diabetes') },
            { id: 'surgery', label: L('Phẫu thuật hoặc chấn thương trong 6 tháng gần đây', 'Surgery or injury in the last 6 months') },
            { id: 'clots', label: L('Huyết khối hoặc giãn tĩnh mạch', 'Blood clots or varicose veins') },
            { id: 'bloodThinners', label: L('Đang dùng thuốc chống đông máu', 'Taking blood thinners') },
            { id: 'skin', label: L('Bệnh da, phát ban hoặc vết thương hở', 'Skin condition, rash or open wounds') },
            { id: 'contagious', label: L('Sốt, cảm cúm hoặc bệnh truyền nhiễm', 'Fever, flu or contagious illness') },
            { id: 'joints', label: L('Loãng xương, thoát vị đĩa đệm hoặc bệnh xương khớp', 'Osteoporosis, herniated disc or joint problems') },
            { id: 'cancer', label: L('Ung thư hoặc đang điều trị', 'Cancer or currently in treatment') },
            { id: 'epilepsy', label: L('Động kinh', 'Epilepsy / seizures') },
            { id: 'allergy', label: L('Dị ứng dầu, kem, hạt hoặc hương liệu', 'Allergy to oils, lotions, nuts or fragrances') },
          ] },
        { type: 'textarea', key: 'health_details', label: L('Chi tiết thêm (nếu có)', 'Details (if any)') },
        { type: 'textarea', key: 'medications', label: L('Thuốc đang sử dụng', 'Current medications') },
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
      signatureSection,
    ],
  },

  {
    id: 'nails', icon: '💅',
    name: L('Làm Móng', 'Nails'),
    title: L('Phiếu thông tin & Cam kết', 'Service Agreement'),
    sections: [
      { title: L('Thông tin khách hàng', 'Customer Information'), items: [F.name, F.phone, F.dob(false), F.technician()] },
      { title: L('Dịch vụ', 'Services'), items: [
        { type: 'multi', key: 'nail_services', required: true, label: L('Dịch vụ (chọn một hoặc nhiều)', 'Services (choose one or more)'), options: [
          { id: 'manicure', label: L('Làm móng tay', 'Manicure') },
          { id: 'pedicure', label: L('Làm móng chân', 'Pedicure') },
          { id: 'gel', label: L('Sơn gel', 'Gel polish') },
          { id: 'regular', label: L('Sơn thường', 'Regular polish') },
          { id: 'extensions', label: L('Đắp bột / Nối móng', 'Acrylic / Extensions') },
          { id: 'builder', label: L('Gel cứng / Up móng', 'Builder gel / Overlay') },
          { id: 'art', label: L('Vẽ / Đính đá', 'Nail art') },
          { id: 'removal', label: L('Tháo gel / bột', 'Gel / acrylic removal') },
          { id: 'spa', label: L('Chăm sóc da tay / chân', 'Hand / foot spa') },
        ] },
        { type: 'single', key: 'nail_shape', label: L('Dáng móng mong muốn (không bắt buộc)', 'Preferred nail shape (optional)'), options: [
          { id: 'round', label: L('Tròn', 'Round') }, { id: 'square', label: L('Vuông', 'Square') },
          { id: 'squoval', label: L('Vuông bo góc', 'Squoval') }, { id: 'oval', label: L('Oval', 'Oval') },
          { id: 'almond', label: L('Hạnh nhân', 'Almond') }, { id: 'coffin', label: L('Coffin', 'Coffin / Ballerina') },
        ] },
        { type: 'textarea', key: 'design_notes', label: L('Màu sắc / mẫu mong muốn (không bắt buộc)', 'Colour or design wishes (optional)') },
      ] },
      { title: L('Tình trạng sức khoẻ', 'Health Check'), items: [
        { type: 'checklist', key: 'conditions',
          warning: L('Vui lòng báo cho kỹ thuật viên trước khi bắt đầu. Để đảm bảo vệ sinh, kỹ thuật viên có thể điều chỉnh hoặc từ chối dịch vụ nếu có dấu hiệu nhiễm trùng.',
                     'Please let your technician know before starting. For hygiene, they may adjust or decline the service if there are signs of infection.'),
          options: [
            { id: 'diabetes', label: L('Tiểu đường', 'Diabetes') },
            { id: 'circulation', label: L('Tuần hoàn máu kém', 'Poor circulation') },
            { id: 'bloodThinners', label: L('Đang dùng thuốc chống đông máu', 'Taking blood thinners') },
            { id: 'fungus', label: L('Nấm móng hoặc nhiễm trùng móng/da', 'Nail fungus or nail/skin infection') },
            { id: 'wounds', label: L('Vết cắt, vết thương hở hoặc mụn cóc ở tay/chân', 'Cuts, open wounds or warts on hands/feet') },
            { id: 'eczema', label: L('Chàm, vảy nến hoặc da nhạy cảm', 'Eczema, psoriasis or sensitive skin') },
            { id: 'allergy', label: L('Dị ứng gel, bột, acetone hoặc latex', 'Allergy to gel, acrylic, acetone or latex') },
            { id: 'damaged', label: L('Móng yếu, mỏng hoặc đang bị tổn thương', 'Weak, thin or damaged nails') },
            { id: 'pregnant', label: L('Đang mang thai', 'Pregnant') },
          ] },
        { type: 'textarea', key: 'health_details', label: L('Chi tiết thêm (nếu có)', 'Details (if any)') },
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
        { type: 'agree', key: 'ack_informed', label: L('Tôi đã được tư vấn về dịch vụ, sản phẩm sử dụng và cách chăm sóc sau dịch vụ.', 'I have been informed about the service, the products used and aftercare.') },
        { type: 'agree', key: 'ack_health', dynamic: true, resetWith: 'conditions',
          label: (s) => (s.conditions?.ticked?.length
            ? L('Tôi đã trao đổi các tình trạng đã đánh dấu ở trên với kỹ thuật viên và đồng ý thực hiện dịch vụ.', 'I have discussed the conditions ticked above with my technician and agree to proceed.')
            : L('Tôi xác nhận không có tình trạng sức khoẻ nào ở trên.', 'I confirm that none of the health conditions above apply to me.')) },
        { type: 'agree', key: 'ack_risk', label: L('Tôi hiểu có thể xảy ra trầy xước nhẹ hoặc kích ứng với sản phẩm, và tiệm sẽ luôn cố gắng hạn chế tối đa.', 'I understand minor nicks or a reaction to products can occasionally happen, and the salon takes every care to prevent them.') },
        { ...photoConsent, label: L('Sử dụng hình ảnh móng cho mục đích quảng bá', 'Use of photos of my nails for promotional purposes') },
      ] },
      signatureSection,
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
        { type: 'single', key: 'treatment', required: true, label: L('Gói dịch vụ', 'Treatment'), options: [
          { id: 'classic', label: L('Gội đầu dưỡng sinh', 'Classic Head Spa') },
          { id: 'neck', label: L('Gội đầu + massage cổ vai gáy', 'Head Spa + Neck & Shoulders') },
          { id: 'facial', label: L('Gội đầu + chăm sóc da mặt', 'Head Spa + Facial') },
          { id: 'scalp', label: L('Gội đầu + tẩy tế bào chết da đầu', 'Head Spa + Scalp Scrub') },
          { id: 'hair', label: L('Gội đầu + hấp dưỡng tóc', 'Head Spa + Hair Treatment') },
          { id: 'foot', label: L('Gội đầu + ngâm chân', 'Head Spa + Foot Soak') },
        ] },
        { type: 'single', key: 'duration', required: true, label: L('Thời gian', 'Duration'), options: [
          { id: '45', label: L('45 phút', '45 minutes') }, { id: '60', label: L('60 phút', '60 minutes') },
          { id: '90', label: L('90 phút', '90 minutes') }, { id: '120', label: L('120 phút', '120 minutes') },
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
      { title: L('Tình trạng sức khoẻ', 'Health Information'), items: [
        { type: 'checklist', key: 'conditions',
          warning: L('Vui lòng trao đổi với kỹ thuật viên trước khi bắt đầu. Kỹ thuật viên có thể điều chỉnh lực, nhiệt độ nước hoặc tư thế cho phù hợp.',
                     'Please talk to your therapist before starting. They can adjust the pressure, water temperature or position for you.'),
          options: [
            { id: 'pregnant', label: L('Đang mang thai', 'Pregnant') },
            { id: 'bloodPressure', label: L('Huyết áp cao hoặc thấp', 'High or low blood pressure') },
            { id: 'heart', label: L('Bệnh tim mạch', 'Heart condition') },
            { id: 'migraine', label: L('Đau nửa đầu hoặc đau đầu thường xuyên', 'Migraines or frequent headaches') },
            { id: 'dizziness', label: L('Hay chóng mặt', 'Frequent dizziness') },
            { id: 'neckSpine', label: L('Thoát vị đĩa đệm hoặc bệnh cột sống cổ', 'Herniated disc or neck/spine problems') },
            { id: 'injury', label: L('Chấn thương hoặc phẫu thuật vùng đầu, cổ trong 6 tháng gần đây', 'Head or neck injury or surgery in the last 6 months') },
            { id: 'scalpSkin', label: L('Vết thương, nhiễm trùng, vảy nến hoặc chàm da đầu', 'Scalp wounds, infection, psoriasis or eczema') },
            { id: 'contagious', label: L('Sốt, cảm cúm hoặc bệnh truyền nhiễm', 'Fever, flu or contagious illness') },
            { id: 'epilepsy', label: L('Động kinh', 'Epilepsy / seizures') },
            { id: 'allergy', label: L('Dị ứng dầu gội, tinh dầu hoặc hương liệu', 'Allergy to shampoos, essential oils or fragrances') },
          ] },
        { type: 'textarea', key: 'health_details', label: L('Chi tiết thêm (nếu có)', 'Details (if any)') },
        { type: 'textarea', key: 'medications', label: L('Thuốc đang sử dụng', 'Current medications') },
      ] },
      { title: L('Chăm sóc sau dịch vụ', 'Aftercare'), items: [
        { type: 'info', groups: () => [{ items: [
          L('Ngồi dậy và đứng lên từ từ để tránh chóng mặt.', 'Sit up and stand up slowly to avoid feeling dizzy.'),
          L('Uống nhiều nước ấm sau khi gội đầu dưỡng sinh.', 'Drink plenty of warm water after your head spa.'),
          L('Tránh gội đầu lại trong ngày để dưỡng chất thẩm thấu.', 'Avoid washing your hair again today so the treatment can work.'),
          L('Sấy tóc ở nhiệt độ vừa phải, tránh ra gió lạnh khi tóc còn ướt.', 'Dry your hair on a medium setting and avoid cold wind while it is still wet.'),
          L('Liên hệ với chúng tôi nếu da đầu bị kích ứng hoặc bạn cảm thấy không khoẻ.', 'Contact us if your scalp becomes irritated or you feel unwell.'),
        ] }] },
      ] },
      { title: L('Cam kết', 'Consent'), items: wellnessAgreements(L('gội đầu dưỡng sinh', 'head spa')) },
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
const optionsOf = (item) => (typeof item.options === 'string' ? OPTION_SETS[item.options] : item.options);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const store = {
  get(key) { try { return localStorage.getItem(key); } catch { return null; } },
  set(key, value) { try { localStorage.setItem(key, value); } catch { /* private mode */ } },
};

let lang = store.get('seren-lang') || 'both';
let service = null;
let state = {};

const both = (l) => (l.vi === l.en ? l.vi : `${l.vi} / ${l.en}`);
const txt = (l) => (lang === 'vi' ? l.vi : lang === 'en' ? l.en : both(l));
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
  document.documentElement.lang = lang === 'en' ? 'en' : 'vi';
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
        T.submit.vi, lang !== 'vi' ? h('span', { class: 'en' }, T.submit.en) : null)),
  );
}

function rerender(predicate) {
  for (const w of wrappers) {
    if (predicate(w.item)) w.node.replaceChildren(renderItem(w.item));
  }
}
const rerenderDynamic = () => rerender((item) => item.dynamic);

function label(item) {
  return h('span', { class: 'label' }, txt(resolve(item.label)), item.required ? h('span', { class: 'req' }, ' *') : null);
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
          }, h('span', { class: 'box' }), lt(o.label)))));
    }
    case 'multi': {
      const selected = state[item.key] || [];
      return h('div', { class: 'field' }, label(item),
        h('div', { class: 'choices' }, optionsOf(item).map((o) =>
          h('button', {
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
          }, h('span', { class: 'box' }), lt(o.label)))));
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
    case 'agree':
      return h('button', {
        type: 'button', class: 'chip', 'aria-pressed': String(Boolean(state[item.key])), style: 'margin-top:8px',
        onclick: () => { state[item.key] = !state[item.key]; rerender((i) => i === item); },
      }, h('span', { class: 'box' }), lt(resolve(item.label)));
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
        if (item.required && !(value || '').trim()) { missing.push(item.label); bad.push(item.key); }
        break;
      case 'date':
        if (item.required && !value) { missing.push(item.label); bad.push(item.key); }
        break;
      case 'single':
        if (item.required && !value) missing.push(item.label);
        break;
      case 'multi':
        if (item.required && !(value || []).length) missing.push(item.label);
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
  const agreements = allItems().filter((i) => i.type === 'agree');
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
    case 'single':
      return optionsOf(item).find((o) => o.id === value)?.label ? both(optionsOf(item).find((o) => o.id === value).label) : '—';
    case 'multi':
      return (value || []).length ? optionsOf(item).filter((o) => value.includes(o.id)).map((o) => both(o.label)).join(', ') : '—';
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
      if (item.type === 'agree') lines.push(`${state[item.key] ? '☑' : '☐'} ${both(resolve(item.label))}`);
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
      signature: signatureDataURL(),
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
    button.replaceChildren(T.submit.vi, lang !== 'vi' ? h('span', { class: 'en' }, T.submit.en) : null);
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
