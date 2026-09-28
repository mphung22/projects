import Foundation

/// All wording for the Brows Lamination & Tint agreement (from the paper form).
/// Edit text here — the iPad form and the PDF both use it.
enum SerenContent {
    static let config = KioskConfig(
        formTitle: L("Hợp đồng dịch vụ · Uốn & Nhuộm Chân Mày", "Service Agreement · Brows Lamination & Tint"),
        symbol: "sparkles",
        defaultBusinessName: "Seren",
        exportPrefix: "Seren Brows Customers"
    )

    static let documentTitle = L("HỢP ĐỒNG DỊCH VỤ", "SERVICE AGREEMENT")
    static let serviceName = L("Uốn & Nhuộm Chân Mày", "Brows Lamination & Tint")

    static let intro = L(
        "Vui lòng điền thông tin, đọc kỹ các mục bên dưới và ký tên xác nhận.",
        "Please fill in your details, read each section carefully and sign at the end."
    )

    // MARK: 1. Customer information

    static let infoTitle = L("Thông tin khách hàng", "Customer Information")
    static let fullName = L("Họ Tên", "Full Name")
    static let phone = L("Số Điện Thoại", "Phone Number")
    static let dateOfBirth = L("Ngày Sinh", "Date of Birth")
    static let idNumber = L("CCCD/CMND", "ID/Passport")
    static let serviceDate = L("Ngày Thực Hiện", "Service Date")
    static let registeredService = L("Dịch Vụ", "Registered Service")
    static let technician = L("Kỹ Thuật Viên", "Technician")

    static let services: [Option] = [
        Option(id: "lamination_tint", label: L("Uốn & Nhuộm chân mày", "Brows Lamination + Tint")),
        Option(id: "lamination", label: L("Uốn chân mày", "Brows Lamination")),
        Option(id: "tint", label: L("Nhuộm chân mày", "Brows Tint")),
    ]

    // MARK: 2. Service details

    static let detailsTitle = L("Nội Dung Dịch Vụ", "Service Details")
    static let details: [L] = [
        L("Uốn chân mày giúp định hình và làm dầy sợi mày.",
          "Brows lamination helps to shape and volumize the brow hairs."),
        L("Nhuộm màu để sợi mày trông đều màu và sắc nét.",
          "Tinting provides even color and better definition to the brows."),
        L("Thời gian: 45–60 phút", "Time: 45–60 minutes"),
        L("Kết quả giữ: 4–6 tuần", "Effect lasts: 4–6 weeks"),
    ]

    // MARK: 3. Contraindications

    static let contraTitle = L("Chống Chỉ Định", "Contraindications")
    static let contraPrompt = L(
        "Vui lòng đánh dấu nếu bạn có bất kỳ tình trạng nào dưới đây:",
        "Please tick any of the following that apply to you:"
    )
    static let contraindications: [Option] = [
        Option(id: "health", label: L(
            "Mang thai, có bệnh lý nền, thể trạng yếu, dùng kháng sinh hoặc hormone không ổn định.",
            "Pregnancy, chronic illness, weak health, antibiotics or hormone instability.")),
        Option(id: "allergy", label: L(
            "Cơ địa dễ dị ứng hoặc nhạy cảm.",
            "Allergy-prone or sensitive skin.")),
        Option(id: "skin", label: L(
            "Da quá mỏng, khô hoặc đang điều trị da.",
            "Overly dry, thin, or treated skin.")),
        Option(id: "retinol", label: L(
            "Đang dùng Retinol, AHA/BHA hoặc da chưa lành.",
            "Using Retinol, AHA/BHA or not fully healed.")),
        Option(id: "recent", label: L(
            "Mới phun/xăm hoặc điều trị laser.",
            "Recent permanent makeup or laser treatment.")),
        Option(id: "acne", label: L(
            "Có mụn hoặc vết thương vùng chân mày.",
            "Acne or wounds near the brow area.")),
        Option(id: "under16", label: L(
            "Dưới 16 tuổi.",
            "Under 16 years old.")),
    ]
    static let noneApply = L("Tôi không có tình trạng nào ở trên.", "None of the above apply to me.")
    static let patchTestNote = L(
        "Lưu ý: Khách có tiền sử dị ứng nên test thử sản phẩm trước 24–48 giờ.",
        "Note: Allergy-prone clients should take a patch test 24–48 hours in advance."
    )
    static let contraWarning = L(
        "Vui lòng báo cho kỹ thuật viên trước khi tiếp tục. Kỹ thuật viên sẽ tư vấn dịch vụ có phù hợp với bạn hay không.",
        "Please let your technician know before continuing. They will advise whether this service is suitable for you."
    )

    // MARK: 4. Aftercare

    static let aftercareTitle = L("Chăm Sóc Sau Dịch Vụ", "Aftercare")
    static let aftercare: [L] = [
        L("Tránh nước, hơi nước, ánh nắng và đổ mồ hôi nhiều trong 24h đầu.",
          "Avoid water, steam, sun, and sweating in the first 24 hours."),
        L("Không va chạm, gãi hoặc makeup vùng chân mày.",
          "No rubbing, scratching, or makeup on brows."),
        L("Chải lông mày nhẹ nhàng 2–3 lần mỗi ngày theo hướng dẫn.",
          "Gently brush brows 2–3 times daily as instructed."),
        L("Có thể dùng serum sau 24h.",
          "Serum may be applied after 24 hours."),
        L("Nếu có nhuộm, tránh tẩy trang vùng mày.",
          "Avoid cleansing agents on tinted brows to preserve color."),
    ]

    // MARK: 5. Acknowledgement

    static let ackTitle = L("Cam Kết", "Acknowledgement")
    static let ackInformed = L(
        "Tôi đã được tư vấn đầy đủ về quy trình, rủi ro và chăm sóc sau dịch vụ.",
        "I have been fully informed about the procedure, risks, and aftercare.")
    static let ackNoContraindications = L(
        "Tôi xác nhận không có chống chỉ định và không đang mang thai.",
        "I confirm that I have no contraindications and I am not pregnant.")
    static let ackDiscussed = L(
        "Tôi đã trao đổi các tình trạng đã đánh dấu ở trên với kỹ thuật viên và đồng ý thực hiện dịch vụ.",
        "I have discussed the conditions ticked above with my technician and agree to proceed.")
    static let photoQuestion = L(
        "Sử dụng hình ảnh cho mục đích quảng bá",
        "Use of my images for promotional purposes")
    static let photoOptions: [Option] = [
        Option(id: "agree", label: L("Đồng ý", "Agree")),
        Option(id: "disagree", label: L("Không đồng ý", "Do not agree")),
    ]

    // MARK: 6. Agreement / signatures

    static let signTitle = L("Xác Nhận", "Agreement")
    static let customerSignature = L("Chữ ký khách hàng", "Customer Signature")
    static let technicianSignature = L("Chữ ký kỹ thuật viên (không bắt buộc)", "Technician Signature (optional)")
    static let submit = L("Hoàn tất & Gửi", "Complete & Submit")
}
