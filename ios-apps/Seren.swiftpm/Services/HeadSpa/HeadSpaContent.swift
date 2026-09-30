import Foundation

/// All wording for the head spa intake & consent form. Edit text here —
/// the iPad form and the PDF both use it.
enum HeadSpaContent {
    static let config = KioskConfig(
        formTitle: L("Phiếu thông tin & Cam kết Gội Đầu Dưỡng Sinh", "Head Spa Intake & Consent Form"),
        symbol: "drop",
        defaultBusinessName: "Seren",
        exportPrefix: "Head Spa Customers",
        shortName: serviceName
    )

    static let documentTitle = L("PHIẾU THÔNG TIN & CAM KẾT", "INTAKE & CONSENT FORM")
    static let serviceName = L("Gội Đầu Dưỡng Sinh", "Head Spa")

    static let intro = L(
        "Để buổi gội đầu dưỡng sinh an toàn và thư giãn, vui lòng điền thông tin bên dưới.",
        "To make your head spa safe and relaxing, please complete the form below."
    )

    // MARK: 1. Customer information

    static let infoTitle = L("Thông tin khách hàng", "Customer Information")
    static let fullName = L("Họ Tên", "Full Name")
    static let phone = L("Số Điện Thoại", "Phone Number")
    static let email = L("Email", "Email")
    static let dateOfBirth = L("Ngày Sinh", "Date of Birth")
    static let emergencyContact = L("Liên hệ khẩn cấp (tên & SĐT)", "Emergency Contact (name & phone)")
    static let serviceDate = L("Ngày Thực Hiện", "Service Date")
    static let therapist = L("Kỹ Thuật Viên", "Therapist")

    // MARK: 2. Service

    static let serviceTitle = L("Dịch vụ", "Service")
    static let serviceType = L("Chọn liệu trình (và dịch vụ thêm nếu muốn)", "Choose your ritual (and any add-ons)")
    static let ritualRequired = L("Chọn một liệu trình gội đầu", "Choose a head spa ritual")

    /// SEREN price list (serensaigon.com/pricing). Edit prices here.
    static let priceGroups: [PriceGroup] = [
        PriceGroup(title: L("Liệu trình gội đầu dưỡng sinh", "Head spa rituals"), singleChoice: true, items: [
            PriceItem(id: "ritual_refresh", label: L("Seren Refresh", "Seren Refresh"), price: 109_000, detail: minutes(30)),
            PriceItem(id: "ritual_balance", label: L("Seren Balance", "Seren Balance"), price: 289_000, detail: minutes(60)),
            PriceItem(id: "ritual_bloom", label: L("Seren Bloom", "Seren Bloom"), price: 329_000, detail: minutes(80)),
            PriceItem(id: "ritual_signature", label: L("Seren Signature Ritual", "Seren Signature Ritual"), price: 539_000, detail: minutes(100)),
            PriceItem(id: "ritual_glow", label: L("Seren Glow", "Seren Glow"), price: 709_000, detail: minutes(130)),
            PriceItem(id: "ritual_sanctuary", label: L("Seren Sanctuary", "Seren Sanctuary"), price: 909_000, detail: minutes(160)),
        ]),
        PriceGroup(title: L("Dịch vụ thêm", "Ritual add-ons"), items: [
            PriceItem(id: "addon_facial_scrub", label: L("Tẩy tế bào chết mặt", "Facial scrub"), price: 50_000),
            PriceItem(id: "addon_facial_massage", label: L("Massage mặt", "Facial massage"), price: 50_000),
            PriceItem(id: "addon_facial_mask", label: L("Đắp mặt nạ", "Facial mask"), price: 50_000),
            PriceItem(id: "addon_eye_mask", label: L("Mặt nạ mắt", "Eye mask"), price: 30_000),
            PriceItem(id: "addon_hot_stone", label: L("Đá nóng", "Hot stone"), price: 50_000),
            PriceItem(id: "addon_head_scrub", label: L("Tẩy tế bào chết da đầu", "Head scrub"), price: 50_000),
        ]),
    ]

    static var ritualIDs: Set<String> { Set(priceGroups[0].items.map(\.id)) }

    private static func minutes(_ n: Int) -> L {
        L("\(n) phút", "\(n) min", ["zh": "\(n) 分钟", "ko": "\(n)분", "fr": "\(n) min", "ja": "\(n)分", "ru": "\(n) мин"])
    }

    /// Choices from forms saved before the price list was added (shown on old records only).
    static let legacyServices: [Option] = [
        Option(id: "classic", label: L("Gội đầu dưỡng sinh", "Classic Head Spa")),
        Option(id: "neck", label: L("Gội đầu + massage cổ vai gáy", "Head Spa + Neck & Shoulders")),
        Option(id: "facial", label: L("Gội đầu + chăm sóc da mặt", "Head Spa + Facial")),
        Option(id: "scalp", label: L("Gội đầu + tẩy tế bào chết da đầu", "Head Spa + Scalp Scrub")),
        Option(id: "hair", label: L("Gội đầu + hấp dưỡng tóc", "Head Spa + Hair Treatment")),
        Option(id: "foot", label: L("Gội đầu + ngâm chân", "Head Spa + Foot Soak")),
    ]
    static let legacyDurations: [Option] = [
        Option(id: "45", label: L("45 phút", "45 minutes")),
        Option(id: "60", label: L("60 phút", "60 minutes")),
        Option(id: "90", label: L("90 phút", "90 minutes")),
        Option(id: "120", label: L("120 phút", "120 minutes")),
    ]
    static let pressureLabel = L("Lực massage mong muốn", "Preferred pressure")
    static let pressures: [Option] = [
        Option(id: "light", label: L("Nhẹ", "Light")),
        Option(id: "medium", label: L("Vừa", "Medium")),
        Option(id: "firm", label: L("Mạnh", "Firm")),
    ]

    // MARK: 3. Scalp & hair

    static let scalpTitle = L("Da đầu & Tóc", "Scalp & Hair")
    static let scalpPrompt = L("Tình trạng da đầu và tóc của bạn (chọn nếu có)", "Your scalp and hair (tick any that apply)")
    static let scalpConcerns: [Option] = [
        Option(id: "dry", label: L("Da đầu khô", "Dry scalp")),
        Option(id: "oily", label: L("Da đầu dầu", "Oily scalp")),
        Option(id: "dandruff", label: L("Gàu", "Dandruff")),
        Option(id: "itchy", label: L("Ngứa hoặc nhạy cảm", "Itchy or sensitive scalp")),
        Option(id: "hairLoss", label: L("Rụng tóc", "Hair loss")),
        Option(id: "damaged", label: L("Tóc khô, hư tổn", "Dry or damaged hair")),
        Option(id: "chemical", label: L("Mới nhuộm, uốn hoặc duỗi (2 tuần)", "Coloured, permed or straightened in the last 2 weeks")),
        Option(id: "extensions", label: L("Tóc nối", "Hair extensions")),
    ]

    // MARK: 4. Your selection & total (wording in Shared/PriceMenu.swift)

    // MARK: 5. Consent

    static let consentTitle = L("Cam kết", "Consent")

    static func agreements(businessName: String) -> [Option] {
        [
            Option(id: "accurate", label: L(
                "Tôi xác nhận thông tin trên là chính xác và sẽ báo cho kỹ thuật viên trước khi bắt đầu nếu có vấn đề sức khoẻ cần lưu ý.",
                "I confirm the information above is accurate and I will tell my therapist before we start about any health concerns.")),
            Option(id: "notMedical", label: L(
                "Tôi hiểu gội đầu dưỡng sinh nhằm mục đích thư giãn và chăm sóc, không thay thế cho chẩn đoán hay điều trị y khoa.",
                "I understand head spa is for relaxation and care and is not a substitute for medical diagnosis or treatment.")),
            Option(id: "communicate", label: L(
                "Tôi sẽ báo cho kỹ thuật viên nếu nước quá nóng/lạnh, lực quá mạnh hoặc cảm thấy khó chịu, và có quyền dừng bất cứ lúc nào.",
                "I will tell my therapist if the water is too hot or cold, the pressure is too strong or I feel uncomfortable, and I may stop at any time.")),
            Option(id: "conduct", label: L(
                "Tôi hiểu rằng mọi hành vi hoặc yêu cầu không phù hợp sẽ khiến buổi dịch vụ kết thúc ngay và vẫn phải thanh toán đầy đủ.",
                "I understand that any inappropriate behaviour or requests will end the session immediately, with full payment due.")),
            Option(id: "release", label: L(
                "Tôi tự nguyện sử dụng dịch vụ và không yêu cầu \(businessName) chịu trách nhiệm về các vấn đề phát sinh do thông tin sức khoẻ không chính xác hoặc không được khai báo.",
                "I receive this service voluntarily and release \(businessName) from liability for issues arising from inaccurate or undisclosed health information.")),
        ]
    }

    static let customerSignature = L("Chữ ký khách hàng", "Customer Signature")
    static let therapistSignature = L("Chữ ký kỹ thuật viên (không bắt buộc)", "Therapist Signature (optional)")
    static let submit = L("Hoàn tất & Gửi", "Complete & Submit")
}
