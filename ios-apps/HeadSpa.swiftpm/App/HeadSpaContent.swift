import Foundation

/// All wording for the head spa intake & consent form. Edit text here —
/// the iPad form and the PDF both use it.
enum HeadSpaContent {
    static let config = KioskConfig(
        formTitle: L("Phiếu thông tin & Cam kết Gội Đầu Dưỡng Sinh", "Head Spa Intake & Consent Form"),
        symbol: "drop",
        defaultBusinessName: "Seren",
        exportPrefix: "Head Spa Customers"
    )

    static let documentTitle = L("PHIẾU THÔNG TIN & CAM KẾT", "INTAKE & CONSENT FORM")
    static let serviceName = L("Gội Đầu Dưỡng Sinh", "Head Spa")

    static let intro = L(
        "Để buổi gội đầu dưỡng sinh an toàn và thư giãn, vui lòng điền thông tin bên dưới và ký tên xác nhận.",
        "To make your head spa safe and relaxing, please complete the form below and sign at the end."
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
    static let serviceType = L("Gói dịch vụ", "Treatment")
    static let services: [Option] = [
        Option(id: "classic", label: L("Gội đầu dưỡng sinh", "Classic Head Spa")),
        Option(id: "neck", label: L("Gội đầu + massage cổ vai gáy", "Head Spa + Neck & Shoulders")),
        Option(id: "facial", label: L("Gội đầu + chăm sóc da mặt", "Head Spa + Facial")),
        Option(id: "scalp", label: L("Gội đầu + tẩy tế bào chết da đầu", "Head Spa + Scalp Scrub")),
        Option(id: "hair", label: L("Gội đầu + hấp dưỡng tóc", "Head Spa + Hair Treatment")),
        Option(id: "foot", label: L("Gội đầu + ngâm chân", "Head Spa + Foot Soak")),
    ]
    static let durationLabel = L("Thời gian", "Duration")
    static let durations: [Option] = [
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

    // MARK: 4. Health

    static let healthTitle = L("Tình trạng sức khoẻ", "Health Information")
    static let healthPrompt = L(
        "Vui lòng đánh dấu nếu bạn có bất kỳ tình trạng nào dưới đây:",
        "Please tick any of the following that apply to you:"
    )
    static let conditions: [Option] = [
        Option(id: "pregnant", label: L("Đang mang thai", "Pregnant")),
        Option(id: "bloodPressure", label: L("Huyết áp cao hoặc thấp", "High or low blood pressure")),
        Option(id: "heart", label: L("Bệnh tim mạch", "Heart condition")),
        Option(id: "migraine", label: L("Đau nửa đầu hoặc đau đầu thường xuyên", "Migraines or frequent headaches")),
        Option(id: "dizziness", label: L("Hay chóng mặt", "Frequent dizziness")),
        Option(id: "neckSpine", label: L("Thoát vị đĩa đệm hoặc bệnh cột sống cổ", "Herniated disc or neck/spine problems")),
        Option(id: "injury", label: L("Chấn thương hoặc phẫu thuật vùng đầu, cổ trong 6 tháng gần đây",
                                      "Head or neck injury or surgery in the last 6 months")),
        Option(id: "scalpSkin", label: L("Vết thương, nhiễm trùng, vảy nến hoặc chàm da đầu",
                                         "Scalp wounds, infection, psoriasis or eczema")),
        Option(id: "contagious", label: L("Sốt, cảm cúm hoặc bệnh truyền nhiễm", "Fever, flu or contagious illness")),
        Option(id: "epilepsy", label: L("Động kinh", "Epilepsy / seizures")),
        Option(id: "allergy", label: L("Dị ứng dầu gội, tinh dầu hoặc hương liệu",
                                       "Allergy to shampoos, essential oils or fragrances")),
    ]
    static let noneApply = L("Tôi không có tình trạng nào ở trên.", "None of the above apply to me.")
    static let healthDetails = L("Chi tiết thêm (nếu có)", "Details (if any)")
    static let medications = L("Thuốc đang sử dụng", "Current medications")
    static let healthWarning = L(
        "Vui lòng trao đổi với kỹ thuật viên trước khi bắt đầu. Kỹ thuật viên có thể điều chỉnh lực, nhiệt độ nước hoặc tư thế cho phù hợp.",
        "Please talk to your therapist before starting. They can adjust the pressure, water temperature or position for you."
    )

    // MARK: 5. Aftercare

    static let aftercareTitle = L("Chăm sóc sau dịch vụ", "Aftercare")
    static let aftercare: [L] = [
        L("Ngồi dậy và đứng lên từ từ để tránh chóng mặt.",
          "Sit up and stand up slowly to avoid feeling dizzy."),
        L("Uống nhiều nước ấm sau khi gội đầu dưỡng sinh.",
          "Drink plenty of warm water after your head spa."),
        L("Tránh gội đầu lại trong ngày để dưỡng chất thẩm thấu.",
          "Avoid washing your hair again today so the treatment can work."),
        L("Sấy tóc ở nhiệt độ vừa phải, tránh ra gió lạnh khi tóc còn ướt.",
          "Dry your hair on a medium setting and avoid cold wind while it is still wet."),
        L("Liên hệ với chúng tôi nếu da đầu bị kích ứng hoặc bạn cảm thấy không khoẻ.",
          "Contact us if your scalp becomes irritated or you feel unwell."),
    ]

    // MARK: 6. Consent

    static let consentTitle = L("Cam kết & Xác nhận", "Consent & Signature")

    static func agreements(businessName: String) -> [Option] {
        [
            Option(id: "accurate", label: L(
                "Tôi xác nhận thông tin sức khoẻ trên là chính xác và sẽ báo ngay cho kỹ thuật viên nếu có thay đổi.",
                "I confirm the health information above is accurate and I will tell my therapist about any changes.")),
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
