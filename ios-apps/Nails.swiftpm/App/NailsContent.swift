import Foundation

/// All wording for the nails service agreement. Edit text here —
/// the iPad form and the PDF both use it.
enum NailsContent {
    static let config = KioskConfig(
        formTitle: L("Phiếu thông tin & Cam kết · Nails", "Service Agreement · Nails"),
        symbol: "hands.sparkles",
        defaultBusinessName: "Seren",
        exportPrefix: "Nails Customers"
    )

    static let documentTitle = L("PHIẾU THÔNG TIN & CAM KẾT", "SERVICE AGREEMENT")
    static let serviceName = L("Nails", "Nails")

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

    // MARK: 2. Services

    static let servicesTitle = L("Dịch vụ", "Services")
    static let servicesLabel = L("Dịch vụ (chọn một hoặc nhiều)", "Services (choose one or more)")
    static let services: [Option] = [
        Option(id: "manicure", label: L("Làm móng tay", "Manicure")),
        Option(id: "pedicure", label: L("Làm móng chân", "Pedicure")),
        Option(id: "gel", label: L("Sơn gel", "Gel polish")),
        Option(id: "regular", label: L("Sơn thường", "Regular polish")),
        Option(id: "extensions", label: L("Đắp bột / Nối móng", "Acrylic / Extensions")),
        Option(id: "builder", label: L("Gel cứng / Up móng", "Builder gel / Overlay")),
        Option(id: "art", label: L("Vẽ / Đính đá", "Nail art")),
        Option(id: "removal", label: L("Tháo gel / bột", "Gel / acrylic removal")),
        Option(id: "spa", label: L("Chăm sóc da tay / chân", "Hand / foot spa")),
    ]
    static let shapeLabel = L("Dáng móng mong muốn (không bắt buộc)", "Preferred nail shape (optional)")
    static let shapes: [Option] = [
        Option(id: "round", label: L("Tròn", "Round")),
        Option(id: "square", label: L("Vuông", "Square")),
        Option(id: "squoval", label: L("Vuông bo góc", "Squoval")),
        Option(id: "oval", label: L("Oval", "Oval")),
        Option(id: "almond", label: L("Hạnh nhân", "Almond")),
        Option(id: "coffin", label: L("Coffin", "Coffin / Ballerina")),
    ]
    static let notesLabel = L("Màu sắc / mẫu mong muốn (không bắt buộc)", "Colour or design wishes (optional)")

    // MARK: 3. Health

    static let healthTitle = L("Tình trạng sức khoẻ", "Health Check")
    static let healthPrompt = L(
        "Vui lòng đánh dấu nếu bạn có bất kỳ tình trạng nào dưới đây:",
        "Please tick any of the following that apply to you:"
    )
    static let conditions: [Option] = [
        Option(id: "diabetes", label: L("Tiểu đường", "Diabetes")),
        Option(id: "circulation", label: L("Tuần hoàn máu kém", "Poor circulation")),
        Option(id: "bloodThinners", label: L("Đang dùng thuốc chống đông máu", "Taking blood thinners")),
        Option(id: "fungus", label: L("Nấm móng hoặc nhiễm trùng móng/da", "Nail fungus or nail/skin infection")),
        Option(id: "wounds", label: L("Vết cắt, vết thương hở hoặc mụn cóc ở tay/chân", "Cuts, open wounds or warts on hands/feet")),
        Option(id: "eczema", label: L("Chàm, vảy nến hoặc da nhạy cảm", "Eczema, psoriasis or sensitive skin")),
        Option(id: "allergy", label: L("Dị ứng gel, bột, acetone hoặc latex", "Allergy to gel, acrylic, acetone or latex")),
        Option(id: "damaged", label: L("Móng yếu, mỏng hoặc đang bị tổn thương", "Weak, thin or damaged nails")),
        Option(id: "pregnant", label: L("Đang mang thai", "Pregnant")),
    ]
    static let noneApply = L("Tôi không có tình trạng nào ở trên.", "None of the above apply to me.")
    static let healthDetails = L("Chi tiết thêm (nếu có)", "Details (if any)")
    static let healthWarning = L(
        "Vui lòng báo cho kỹ thuật viên trước khi bắt đầu. Để đảm bảo vệ sinh, kỹ thuật viên có thể điều chỉnh hoặc từ chối dịch vụ nếu có dấu hiệu nhiễm trùng.",
        "Please let your technician know before starting. For hygiene, they may adjust or decline the service if there are signs of infection."
    )

    // MARK: 4. Good to know & aftercare

    static let infoCareTitle = L("Lưu ý & Chăm sóc", "Good to Know & Aftercare")
    static let goodToKnow = InfoGroup(title: L("Lưu ý", "Good to know"), items: [
        L("Độ bền của sơn gel và móng đắp phụ thuộc vào tình trạng móng thật và thói quen sinh hoạt.",
          "How long gel and extensions last depends on your natural nails and daily activities."),
        L("Có thể hơi đỏ nhẹ quanh da sau khi làm móng — sẽ hết sau vài giờ.",
          "Slight redness around the cuticles is normal and fades within a few hours."),
        L("Tháo gel/bột nên được thực hiện tại tiệm để tránh làm hư móng thật.",
          "Gel and acrylic should be removed at the salon to avoid damaging your natural nails."),
    ])
    static let aftercare = InfoGroup(title: L("Chăm sóc sau dịch vụ", "Aftercare"), items: [
        L("Thoa dầu dưỡng móng mỗi ngày.", "Apply cuticle oil every day."),
        L("Đeo găng tay khi rửa chén hoặc dùng hoá chất tẩy rửa.", "Wear gloves when washing up or using cleaning products."),
        L("Không cạy, bóc sơn gel hoặc móng đắp.", "Don't pick or peel off gel or extensions."),
        L("Không dùng móng để cạy, mở đồ vật.", "Don't use your nails as tools."),
        L("Liên hệ với chúng tôi nếu móng bị bong, gãy hoặc có dấu hiệu kích ứng.",
          "Contact us if your nails lift, break or show any signs of irritation."),
    ])

    // MARK: 5. Acknowledgement

    static let ackTitle = L("Cam Kết", "Acknowledgement")
    static let ackInformed = L(
        "Tôi đã được tư vấn về dịch vụ, sản phẩm sử dụng và cách chăm sóc sau dịch vụ.",
        "I have been informed about the service, the products used and aftercare.")
    static let ackNoConditions = L(
        "Tôi xác nhận không có tình trạng sức khoẻ nào ở trên.",
        "I confirm that none of the health conditions above apply to me.")
    static let ackDiscussed = L(
        "Tôi đã trao đổi các tình trạng đã đánh dấu ở trên với kỹ thuật viên và đồng ý thực hiện dịch vụ.",
        "I have discussed the conditions ticked above with my technician and agree to proceed.")
    static let ackRisk = L(
        "Tôi hiểu có thể xảy ra trầy xước nhẹ hoặc kích ứng với sản phẩm, và tiệm sẽ luôn cố gắng hạn chế tối đa.",
        "I understand minor nicks or a reaction to products can occasionally happen, and the salon takes every care to prevent them.")
    static let photoQuestion = L(
        "Sử dụng hình ảnh móng cho mục đích quảng bá",
        "Use of photos of my nails for promotional purposes")
    static let photoOptions: [Option] = [
        Option(id: "agree", label: L("Đồng ý", "Agree")),
        Option(id: "disagree", label: L("Không đồng ý", "Do not agree")),
    ]

    // MARK: 6. Signatures

    static let signTitle = L("Xác Nhận", "Agreement")
    static let customerSignature = L("Chữ ký khách hàng", "Customer Signature")
    static let technicianSignature = L("Chữ ký kỹ thuật viên (không bắt buộc)", "Technician Signature (optional)")
    static let submit = L("Hoàn tất & Gửi", "Complete & Submit")
}
