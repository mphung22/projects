import Foundation

/// All wording for the massage intake & consent form. Edit text here —
/// the iPad form and the PDF both use it.
enum MassageContent {
    static let config = KioskConfig(
        formTitle: L("Phiếu thông tin & Cam kết Massage", "Massage Intake & Consent Form"),
        symbol: "leaf",
        defaultBusinessName: "Seren Massage",
        exportPrefix: "Massage Customers"
    )

    static let documentTitle = L("PHIẾU THÔNG TIN & CAM KẾT", "INTAKE & CONSENT FORM")
    static let serviceName = L("Massage", "Massage")

    static let intro = L(
        "Để buổi massage an toàn và hiệu quả, vui lòng điền thông tin bên dưới và ký tên xác nhận.",
        "To make your massage safe and effective, please complete the form below and sign at the end."
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
    static let serviceType = L("Loại massage", "Massage type")
    static let services: [Option] = [
        Option(id: "swedish", label: L("Massage thư giãn toàn thân", "Swedish / Relaxation")),
        Option(id: "deep", label: L("Massage mô sâu", "Deep Tissue")),
        Option(id: "hotstone", label: L("Massage đá nóng", "Hot Stone")),
        Option(id: "aroma", label: L("Massage tinh dầu", "Aromatherapy")),
        Option(id: "neck", label: L("Massage cổ vai gáy", "Neck & Shoulders")),
        Option(id: "foot", label: L("Massage chân / bấm huyệt", "Foot / Reflexology")),
        Option(id: "prenatal", label: L("Massage cho mẹ bầu", "Prenatal")),
    ]
    static let durationLabel = L("Thời gian", "Duration")
    static let durations: [Option] = [
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
        Option(id: "diabetes", label: L("Tiểu đường", "Diabetes")),
        Option(id: "surgery", label: L("Phẫu thuật hoặc chấn thương trong 6 tháng gần đây",
                                       "Surgery or injury in the last 6 months")),
        Option(id: "clots", label: L("Huyết khối hoặc giãn tĩnh mạch", "Blood clots or varicose veins")),
        Option(id: "bloodThinners", label: L("Đang dùng thuốc chống đông máu", "Taking blood thinners")),
        Option(id: "skin", label: L("Bệnh da, phát ban hoặc vết thương hở", "Skin condition, rash or open wounds")),
        Option(id: "contagious", label: L("Sốt, cảm cúm hoặc bệnh truyền nhiễm", "Fever, flu or contagious illness")),
        Option(id: "joints", label: L("Loãng xương, thoát vị đĩa đệm hoặc bệnh xương khớp",
                                      "Osteoporosis, herniated disc or joint problems")),
        Option(id: "cancer", label: L("Ung thư hoặc đang điều trị", "Cancer or currently in treatment")),
        Option(id: "epilepsy", label: L("Động kinh", "Epilepsy / seizures")),
        Option(id: "allergy", label: L("Dị ứng dầu, kem, hạt hoặc hương liệu",
                                       "Allergy to oils, lotions, nuts or fragrances")),
    ]
    static let noneApply = L("Tôi không có tình trạng nào ở trên.", "None of the above apply to me.")
    static let healthDetails = L("Chi tiết thêm (nếu có)", "Details (if any)")
    static let medications = L("Thuốc đang sử dụng", "Current medications")
    static let healthWarning = L(
        "Vui lòng trao đổi với kỹ thuật viên trước khi bắt đầu. Kỹ thuật viên có thể điều chỉnh hoặc khuyên bạn hỏi ý kiến bác sĩ.",
        "Please talk to your therapist before starting. They may adjust the massage or recommend checking with your doctor."
    )

    // MARK: 5. Aftercare

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

    // MARK: 6. Consent

    static let consentTitle = L("Cam kết & Xác nhận", "Consent & Signature")

    static func agreements(businessName: String) -> [Option] {
        [
            Option(id: "accurate", label: L(
                "Tôi xác nhận thông tin sức khoẻ trên là chính xác và sẽ báo ngay cho kỹ thuật viên nếu có thay đổi.",
                "I confirm the health information above is accurate and I will tell my therapist about any changes.")),
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
