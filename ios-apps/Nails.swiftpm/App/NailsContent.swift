import Foundation

/// All wording for the nails service agreement. Edit text here —
/// the iPad form and the PDF both use it.
enum NailsContent {
    static let config = KioskConfig(
        formTitle: L("Phiếu thông tin & Cam kết · Nails", "Service Agreement · Nails"),
        symbol: "hands.sparkles",
        defaultBusinessName: "Seren",
        exportPrefix: "Nails Customers",
        shortName: serviceName
    )

    static let documentTitle = L("PHIẾU THÔNG TIN & CAM KẾT", "SERVICE AGREEMENT")
    static let serviceName = L("Làm Móng", "Nails")

    static let intro = L(
        "Vui lòng điền thông tin và đọc kỹ các mục bên dưới.",
        "Please fill in your details and read each section carefully."
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
    static let servicesLabel = L("Chọn dịch vụ (một hoặc nhiều)", "Choose your services (one or more)")

    /// SEREN price list (serensaigon.com/pricing). Edit prices here.
    static let priceGroups: [PriceGroup] = [
        PriceGroup(title: L("Bộ đặc trưng", "Signature sets"), items: [
            PriceItem(id: "set_touch", label: L("Seren Touch — tay hoặc chân", "Seren Touch — hands or feet"), price: 180_000),
            PriceItem(id: "set_glow", label: L("Seren Glow — bộ gel", "Seren Glow — gel set"), price: 300_000),
            PriceItem(id: "set_bloom", label: L("Seren Bloom — bộ gel kèm design", "Seren Bloom — gel set with design"), price: 450_000),
            PriceItem(id: "set_sole", label: L("Seren Sole — chăm sóc móng chân", "Seren Sole — pedicure"), price: 300_000),
            PriceItem(id: "set_pure", label: L("Seren Pure — móng chân kèm dưỡng thư giãn chân 15 phút và sơn gel",
                                               "Seren Pure — pedicure with 15-min foot relax and gel polish"), price: 550_000),
            PriceItem(id: "set_ritual", label: L("Seren Ritual — móng chân kèm dưỡng thư giãn chân 15 phút",
                                                 "Seren Ritual — pedicure with 15-min foot relax"), price: 450_000),
        ]),
        PriceGroup(title: L("Chăm sóc móng", "Nail care"), items: [
            PriceItem(id: "care_reshape", label: L("Sửa form móng", "Nail reshape"), price: 30_000),
            PriceItem(id: "care_gel_removal", label: L("Tháo gel / cứng móng", "Gel / hard gel removal"), price: 30_000, maxPrice: 50_000),
            PriceItem(id: "care_removal", label: L("Tháo móng úp, gel đắp, bột", "Tips, gel or acrylic removal"), price: 50_000, maxPrice: 100_000),
            PriceItem(id: "care_skin", label: L("Làm sạch da tay / chân", "Hand / foot skin cleansing"), price: 50_000, maxPrice: 60_000),
            PriceItem(id: "care_refill", label: L("Refill / up gel móng cũ", "Refill / old gel touch-up"), price: 100_000, maxPrice: 250_000),
            PriceItem(id: "care_extensions", label: L("Đắp gel, bột, Powder X", "Gel, acrylic, Powder X"), price: 380_000),
            PriceItem(id: "care_base", label: L("Up keo / base", "Glue / base coat application"), price: 100_000, maxPrice: 200_000),
            PriceItem(id: "care_gelx", label: L("Up gel X", "Gel X application"), price: 280_000),
            PriceItem(id: "care_dual", label: L("Dual form", "Dual form"), price: 450_000),
        ]),
        PriceGroup(title: L("Màu và hiệu ứng", "Colour and finish"), items: [
            PriceItem(id: "colour_gel", label: L("Sơn gel / thạch", "Gel polish / jelly"), price: 150_000),
            PriceItem(id: "colour_cateye", label: L("Sơn mắt mèo / nhũ", "Cat eye / flash effect"), price: 220_000),
            PriceItem(id: "colour_chrome", label: L("Tráng gương", "Mirror chrome effect"), price: 250_000),
            PriceItem(id: "colour_ombre", label: L("Ombre / French", "Ombre / French"), price: 250_000),
            PriceItem(id: "colour_biab", label: L("BIAB", "BIAB application"), price: 350_000),
            PriceItem(id: "colour_hard_arc", label: L("Cứng móng có cầu móng", "Hard nail polish with nail arc"), price: 100_000),
            PriceItem(id: "colour_hardener", label: L("Sơn cứng móng", "Nail hardening base coat"), price: 50_000),
            PriceItem(id: "colour_multi", label: L("Sơn trên 3 màu", "More than three colours"), price: 30_000),
            PriceItem(id: "colour_regular", label: L("Sơn thường", "Regular polish"), price: 100_000),
        ]),
        PriceGroup(
            title: L("Vẽ móng, tính theo ngón", "Nail art, per nail"),
            note: L("Chọn số ngón sau khi chọn mẫu.", "Choose how many nails after selecting a design."),
            items: [
                PriceItem(id: "art_french", label: L("Vẽ viền đầu móng / ombre", "French tip / ombre"), price: 20_000, unit: nailUnit),
                PriceItem(id: "art_custom", label: L("Design theo mẫu / hoạt hình", "Custom design / cartoon art"), price: 10_000, maxPrice: 50_000, unit: nailUnit),
                PriceItem(id: "art_marble", label: L("Vẽ vân đá / kim tuyến", "Marble effect / glitter"), price: 10_000, maxPrice: 50_000, unit: nailUnit),
                PriceItem(id: "art_fishscale", label: L("Vảy cá / ẩn xà cừ", "Fish scale / hidden seashell"), price: 10_000, maxPrice: 50_000, unit: nailUnit),
                PriceItem(id: "art_charm", label: L("Gắn charm / đá", "Charm / rhinestone"), price: 10_000, maxPrice: 50_000, unit: nailUnit),
                PriceItem(id: "art_sticker", label: L("Gắn sticker", "Sticker"), price: 10_000, maxPrice: 50_000, unit: nailUnit),
            ]
        ),
    ]
    private static let nailUnit = L("ngón", "nails")

    /// Service ticks from forms saved before the price list was added (shown on old records only).
    static let legacyServices: [Option] = [
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

    // MARK: 3. Good to know & aftercare

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

    // MARK: 4. Acknowledgement

    static let ackTitle = L("Cam Kết", "Acknowledgement")
    static let ackInformed = L(
        "Tôi đã được tư vấn về dịch vụ, sản phẩm sử dụng và cách chăm sóc sau dịch vụ.",
        "I have been informed about the service, the products used and aftercare.")
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

    // MARK: 5. Your selection & total (wording in Shared/PriceMenu.swift)

    // MARK: 6. Signatures

    static let signTitle = L("Xác Nhận", "Agreement")
    static let customerSignature = L("Chữ ký khách hàng", "Customer Signature")
    static let technicianSignature = L("Chữ ký kỹ thuật viên (không bắt buộc)", "Technician Signature (optional)")
    static let submit = L("Hoàn tất & Gửi", "Complete & Submit")
}
