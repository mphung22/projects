import Foundation

/// All wording for the massage intake & consent form. Edit text here —
/// the iPad form and the PDF both use it.
enum MassageContent {
    static let config = KioskConfig(
        formTitle: L("Phiếu thông tin & Cam kết Massage", "Massage Intake & Consent Form"),
        symbol: "leaf",
        defaultBusinessName: "Seren",
        exportPrefix: "Massage Customers",
        shortName: serviceName
    )

    static let documentTitle = L("PHIẾU THÔNG TIN & CAM KẾT", "INTAKE & CONSENT FORM")
    static let serviceName = L("Massage", "Massage")

    static let intro = L(
        "Để buổi massage an toàn và hiệu quả, vui lòng điền thông tin bên dưới.",
        "To make your massage safe and effective, please complete the form below."
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
    static let serviceType = L("Chọn dịch vụ (một hoặc nhiều)", "Choose your services (one or more)")

    /// SEREN price list (serensaigon.com/pricing). Edit prices here.
    static let priceGroups: [PriceGroup] = [
        PriceGroup(title: L("Body wellness", "Body wellness"), items: [
            PriceItem(id: "body_60", label: L("Thư giãn body", "Body therapy"), price: 450_000, detail: minutes(60)),
            PriceItem(id: "body_90", label: L("Thư giãn body", "Body therapy"), price: 625_000, detail: minutes(90)),
            PriceItem(id: "body_120", label: L("Thư giãn body", "Body therapy"), price: 850_000, detail: minutes(120)),
            PriceItem(id: "neck_30", label: L("Cổ, vai, gáy", "Neck & shoulder"), price: 250_000, detail: minutes(30)),
            PriceItem(id: "neck_60", label: L("Cổ, vai, gáy", "Neck & shoulder"), price: 450_000, detail: minutes(60)),
            PriceItem(id: "foot_30", label: L("Chăm sóc chân", "Foot"), price: 280_000, detail: minutes(30)),
            PriceItem(id: "foot_60", label: L("Chăm sóc chân", "Foot"), price: 450_000, detail: minutes(60)),
        ]),
        PriceGroup(title: L("Tẩy tế bào chết & ủ dưỡng", "Body scrub & glow"), items: [
            PriceItem(id: "body_scrub", label: L("Tẩy tế bào chết body", "Body scrub"), price: 296_000, detail: minutes(30)),
            PriceItem(id: "body_wrap", label: L("Dưỡng ủ body", "Body wrap"), price: 280_000, detail: minutes(30)),
        ]),
    ]

    /// Items that use massage oil.
    static var massageIDs: Set<String> { Set(priceGroups[0].items.map(\.id)) }

    private static func minutes(_ n: Int) -> L {
        L("\(n) phút", "\(n) min", ["zh": "\(n) 分钟", "ko": "\(n)분", "fr": "\(n) min", "ja": "\(n)分", "ru": "\(n) мин"])
    }

    // Massage oil (OILMART professional spa oils)

    static let oilLabel = L("Chọn dầu massage", "Choose your massage oil")
    static let oils: [Option] = [
        Option(id: "calming", label: L("Calming · Oải hương & Hạnh nhân", "Calming · Lavender & Almond")),
        Option(id: "refreshing", label: L("Refreshing · Chanh vàng, Bưởi & Cam", "Refreshing · Lemon, Grapefruit & Orange")),
        Option(id: "comforting", label: L("Comforting · Sả & Xô thơm", "Comforting · Lemongrass & Clary Sage")),
        Option(id: "antiAging", label: L("Anti-Aging · Gừng & Nhụy hoa nghệ tây", "Anti-Aging · Ginger & Saffron")),
    ]
    static let almondWarning = L(
        "Dầu Calming có chứa dầu hạnh nhân. Nếu bạn dị ứng các loại hạt, vui lòng chọn loại dầu khác và báo cho kỹ thuật viên.",
        "Calming oil contains almond oil. If you have a nut allergy, please choose another oil and tell your therapist."
    )

    /// Choices from forms saved before the price list was added (shown on old records only).
    static let legacyServices: [Option] = [
        Option(id: "swedish", label: L("Massage thư giãn toàn thân", "Swedish / Relaxation")),
        Option(id: "deep", label: L("Massage mô sâu", "Deep Tissue")),
        Option(id: "hotstone", label: L("Massage đá nóng", "Hot Stone")),
        Option(id: "aroma", label: L("Massage tinh dầu", "Aromatherapy")),
        Option(id: "neck", label: L("Massage cổ vai gáy", "Neck & Shoulders")),
        Option(id: "foot", label: L("Massage chân / bấm huyệt", "Foot / Reflexology")),
        Option(id: "prenatal", label: L("Massage cho mẹ bầu", "Prenatal")),
    ]
    static let legacyDurations: [Option] = [
        Option(id: "30", label: L("30 phút", "30 minutes")),
        Option(id: "60", label: L("60 phút", "60 minutes")),
        Option(id: "90", label: L("90 phút", "90 minutes")),
        Option(id: "120", label: L("120 phút", "120 minutes")),
    ]
    static let pressureLabel = L("Lực massage mong muốn", "Preferred pressure")
    static let pressures: [Option] = [
        Option(id: "light", label: L("Nhẹ", "Light")),
        Option(id: "medium", label: L("Vừa", "Medium")),
        Option(id: "firm", label: L("Mạnh", "Firm")),
        Option(id: "deep", label: L("Rất mạnh", "Extra firm")),
    ]

    // MARK: 3. Body areas

    static let areasTitle = L("Vùng cơ thể", "Body Areas")
    static let focusLabel = L("Vùng muốn tập trung", "Areas to focus on")
    static let avoidLabel = L("Vùng muốn tránh", "Areas to avoid")
    static let areas: [Option] = [
        Option(id: "head", label: L("Đầu", "Head")),
        Option(id: "face", label: L("Mặt", "Face")),
        Option(id: "neck", label: L("Cổ", "Neck")),
        Option(id: "shoulders", label: L("Vai", "Shoulders")),
        Option(id: "upperBack", label: L("Lưng trên", "Upper back")),
        Option(id: "lowerBack", label: L("Lưng dưới", "Lower back")),
        Option(id: "arms", label: L("Tay", "Arms")),
        Option(id: "hands", label: L("Bàn tay", "Hands")),
        Option(id: "abdomen", label: L("Bụng", "Abdomen")),
        Option(id: "glutes", label: L("Mông", "Glutes")),
        Option(id: "legs", label: L("Chân", "Legs")),
        Option(id: "feet", label: L("Bàn chân", "Feet")),
    ]

    // MARK: 4. Aftercare

    static let aftercareTitle = L("Chăm sóc sau massage", "Aftercare")
    static let aftercare: [L] = [
        L("Uống nhiều nước ấm sau khi massage.", "Drink plenty of water after your massage."),
        L("Nghỉ ngơi, tránh vận động mạnh trong vài giờ.", "Rest and avoid strenuous exercise for a few hours."),
        L("Nên đợi ít nhất 1 giờ rồi mới tắm.", "Wait at least 1 hour before showering."),
        L("Có thể hơi ê ẩm trong 24–48 giờ — đây là điều bình thường.",
          "Mild soreness for 24–48 hours is normal."),
        L("Liên hệ với chúng tôi nếu đau kéo dài hoặc cảm thấy không khoẻ.",
          "Contact us if pain persists or you feel unwell."),
    ]

    // MARK: 5. Your selection & total (wording in Shared/PriceMenu.swift)

    // MARK: 6. Consent

    static let consentTitle = L("Cam kết", "Consent")

    static func agreements(businessName: String) -> [Option] {
        [
            Option(id: "accurate", label: L(
                "Tôi xác nhận thông tin trên là chính xác và sẽ báo cho kỹ thuật viên trước khi bắt đầu nếu có vấn đề sức khoẻ cần lưu ý.",
                "I confirm the information above is accurate and I will tell my therapist before we start about any health concerns.")),
            Option(id: "notMedical", label: L(
                "Tôi hiểu massage nhằm mục đích thư giãn và chăm sóc sức khoẻ, không thay thế cho chẩn đoán hay điều trị y khoa.",
                "I understand massage is for relaxation and wellness and is not a substitute for medical diagnosis or treatment.")),
            Option(id: "communicate", label: L(
                "Tôi sẽ báo cho kỹ thuật viên nếu cảm thấy khó chịu hoặc đau, và có quyền dừng buổi massage bất cứ lúc nào.",
                "I will tell my therapist if I feel any discomfort or pain, and I may stop the session at any time.")),
            Option(id: "conduct", label: L(
                "Tôi hiểu rằng mọi hành vi hoặc yêu cầu không phù hợp sẽ khiến buổi massage kết thúc ngay và vẫn phải thanh toán đầy đủ.",
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
