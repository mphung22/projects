import Foundation

/// All wording for the Waxing service agreement. Edit text here — the iPad form and the PDF both use it.
/// The English text matches the phone check-in (docs/app.js), so the same translations are used.
enum WaxingContent {
    static let config = KioskConfig(
        formTitle: L("Hợp đồng dịch vụ · Wax lông", "Service Agreement · Waxing"),
        symbol: "sun.max",
        defaultBusinessName: "Seren",
        exportPrefix: "Waxing Customers",
        shortName: serviceName
    )

    static let documentTitle = L("HỢP ĐỒNG DỊCH VỤ", "SERVICE AGREEMENT")
    static let serviceName = L("Wax lông", "Waxing")

    static let intro = L(
        "Vui lòng điền thông tin, đọc kỹ các mục bên dưới và ký tên xác nhận.",
        "Please fill in your details, read each section carefully and sign at the end."
    )

    // MARK: 1. Customer information

    static let infoTitle = L("Thông tin khách hàng", "Customer Information")
    static let fullName = L("Họ Tên", "Full Name")
    static let phone = L("Số Điện Thoại", "Phone Number")
    static let dateOfBirth = L("Ngày Sinh", "Date of Birth")
    static let serviceDate = L("Ngày Thực Hiện", "Service Date")
    static let technician = L("Kỹ Thuật Viên", "Technician")

    // MARK: 2. Areas and prices

    static let servicesTitle = L("Dịch vụ", "Services")
    static let areasLabel = L("Vùng wax (chọn một hoặc nhiều)", "Areas to wax (choose one or more)")

    /// SEREN price list (serensaigon.com/pricing, waxing). Edit prices here.
    static let priceGroups: [PriceGroup] = [
        PriceGroup(title: L("Wax lông", "Waxing"), items: [
            PriceItem(id: "wax_fingers_toes", label: L("Ngón tay, ngón chân", "Fingers and toes"), price: 50_000),
            PriceItem(id: "wax_underarms", label: L("Nách", "Underarms"), price: 100_000),
            PriceItem(id: "wax_full_arms", label: L("Cánh tay", "Full arms"), price: 250_000),
            PriceItem(id: "wax_half_leg", label: L("½ chân", "Half leg"), price: 300_000),
            PriceItem(id: "wax_full_leg", label: L("Full chân", "Full leg"), price: 400_000),
            PriceItem(id: "wax_back", label: L("Lưng", "Full back"), price: 450_000),
            PriceItem(id: "wax_neck", label: L("Tóc gáy", "Neck hair"), price: 150_000),
            PriceItem(id: "wax_lip_nose", label: L("Mép, lông mũi", "Lip edge and nose hair"), price: 100_000),
            PriceItem(id: "wax_belly_chest", label: L("Bụng, ngực", "Belly and chest"), price: 200_000),
            PriceItem(id: "wax_ears_sideburns", label: L("Lỗ tai, tóc mai", "Ears and sideburns"), price: 80_000),
            PriceItem(id: "wax_eyebrow", label: L("Chân mày", "Eyebrow"), price: 100_000),
            PriceItem(id: "wax_bikini", label: L("Bikini", "Bikini"), price: 450_000),
            PriceItem(id: "wax_butt", label: L("Mông", "Butt"), price: 450_000),
            PriceItem(id: "wax_package", label: L("Gói: tay, chân, nách, bikini", "Package: arms, legs, underarms and bikini"),
                      price: 950_000),
        ]),
    ]

    // MARK: 3. Contraindications

    static let contraTitle = L("Chống Chỉ Định", "Contraindications")
    static let contraPrompt = L(
        "Vui lòng đánh dấu nếu bạn có bất kỳ tình trạng nào dưới đây:",
        "Please tick any of the following that apply to you:"
    )
    static let contraindications: [Option] = [
        Option(id: "retinoid", label: L(
            "Đang hoặc trong 6 tháng qua dùng Retinol, AHA/BHA hoặc thuốc trị mụn (ví dụ isotretinoin).",
            "Using Retinol, AHA/BHA or acne medication (e.g. isotretinoin) now or in the last 6 months.")),
        Option(id: "skin", label: L(
            "Da bị cháy nắng, trầy xước, kích ứng hoặc mới peel/laser ở vùng wax.",
            "Sunburn, broken or irritated skin, or a recent peel or laser treatment on the area.")),
        Option(id: "circulation", label: L(
            "Tiểu đường, vấn đề tuần hoàn, giãn tĩnh mạch hoặc đang dùng thuốc chống đông máu.",
            "Diabetes, circulation problems, varicose veins or blood-thinning medication.")),
        Option(id: "allergy", label: L(
            "Dị ứng với sáp wax, nhựa thông hoặc sản phẩm chăm sóc da.",
            "Allergy to wax, rosin or skin care products.")),
        Option(id: "pregnant", label: L("Đang mang thai.", "Pregnant.")),
        Option(id: "under16", label: L("Dưới 16 tuổi.", "Under 16 years old.")),
    ]
    static let noneApply = L("Tôi không có tình trạng nào ở trên.", "None of the above apply to me.")
    static let contraWarning = L(
        "Vui lòng báo cho kỹ thuật viên trước khi tiếp tục. Kỹ thuật viên sẽ tư vấn dịch vụ có phù hợp với bạn hay không.",
        "Please let your technician know before continuing. They will advise whether this service is suitable for you."
    )

    // MARK: 4. Aftercare

    static let aftercareTitle = L("Chăm Sóc Sau Dịch Vụ", "Aftercare")
    static let aftercare: [L] = [
        L("Tránh tắm nước nóng, xông hơi, bơi và tập thể dục trong 24 giờ.",
          "Avoid hot showers, saunas, swimming and exercise for 24 hours."),
        L("Tránh nắng và tắm nắng trong 48 giờ.",
          "Avoid the sun and tanning for 48 hours."),
        L("Không dùng nước hoa, lăn khử mùi hoặc tẩy tế bào chết trên vùng wax trong 24 giờ.",
          "No perfume, deodorant or exfoliants on the waxed area for 24 hours."),
        L("Mặc quần áo rộng rãi. Sau 2–3 ngày, tẩy tế bào chết nhẹ nhàng để tránh lông mọc ngược.",
          "Wear loose clothing. After 2–3 days, exfoliate gently to prevent ingrown hairs."),
        L("Da hơi đỏ hoặc nổi mẩn trong vài giờ là bình thường.",
          "Mild redness or bumps for a few hours are normal."),
    ]

    // MARK: 5. Acknowledgement

    static let ackTitle = L("Cam Kết", "Acknowledgement")
    static let ackInformed = L(
        "Tôi đã được tư vấn đầy đủ về quy trình, rủi ro và chăm sóc sau dịch vụ.",
        "I have been fully informed about the procedure, risks, and aftercare.")
    static let ackRedness = L(
        "Tôi hiểu da có thể bị đỏ, nhạy cảm hoặc bầm nhẹ sau khi wax.",
        "I understand redness, sensitivity or minor bruising can occur after waxing.")
    static let ackNoContraindications = L(
        "Tôi xác nhận không có chống chỉ định và không đang mang thai.",
        "I confirm that I have no contraindications and I am not pregnant.")
    static let ackDiscussed = L(
        "Tôi đã trao đổi các tình trạng đã đánh dấu ở trên với kỹ thuật viên và đồng ý thực hiện dịch vụ.",
        "I have discussed the conditions ticked above with my technician and agree to proceed.")

    // MARK: 6. Your selection & total (wording in Shared/PriceMenu.swift)

    // MARK: 7. Signature

    static let signTitle = L("Xác Nhận", "Agreement")
    static let customerSignature = L("Chữ ký khách hàng", "Customer Signature")
    static let submit = L("Hoàn tất & Gửi", "Complete & Submit")
}
