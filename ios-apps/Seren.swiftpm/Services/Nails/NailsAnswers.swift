import Foundation

struct NailsAnswers: FormAnswers {
    var fullName = ""
    var phone = ""
    var dateOfBirth: Date?
    var serviceDate = Date()
    var technician = ""

    /// Items chosen from the price list (id → quantity). Optional so records saved by older versions still open.
    var priceSelection: PriceSelection?
    /// Service ticks from forms saved before the price list was added.
    var services: Set<String> = []
    /// "" when no preference.
    var shapeID = ""
    var designNotes = ""

    var ackInformed = false
    var ackRisk = false
    /// "agree" / "disagree" / "" (not answered)
    var photoConsent = ""

    /// Only on records saved before this form stopped asking for a signature.
    var customerSignature: Data?
    var technicianSignature: Data?

    var prices: PriceSelection {
        get { priceSelection ?? [:] }
        set { priceSelection = newValue }
    }
    var priceLines: [PriceLine] { NailsContent.priceGroups.lines(for: prices) }
    var total: PriceTotal { NailsContent.priceGroups.total(for: prices) }
    var legacyServiceLabels: [L] { NailsContent.legacyServices.labels(for: services) }
    var shapeLabel: L? { NailsContent.shapes.label(for: shapeID) }

    var missingItems: [L] {
        var missing: [L] = []
        if fullName.trimmed.isEmpty { missing.append(NailsContent.fullName) }
        if priceLines.isEmpty { missing.append(NailsContent.servicesLabel) }
        if !ackInformed || !ackRisk {
            missing.append(L("Đánh dấu ô đồng ý các cam kết", "Tick the box to agree to the statements"))
        }
        if photoConsent.isEmpty { missing.append(NailsContent.photoQuestion) }
        return missing
    }

    // MARK: FormAnswers

    var customerName: String { fullName }
    var customerPhone: String { phone }

    var serviceSummary: String {
        if priceLines.isEmpty { return legacyServiceLabels.map(\.en).joined(separator: ", ") }
        return NailsContent.priceGroups.summary(for: prices) + " · " + total.text
    }

    var healthAlert: String? { nil }

    static let csvHeader = [
        "Full name", "Phone", "Date of birth", "Service date", "Technician", "Services", "Total (VND)",
        "Nail shape", "Design notes", "Photo consent",
    ]

    var csvRow: [String] {
        [
            fullName, phone, dateOfBirth.dayString, Formatters.date.string(from: serviceDate), technician,
            priceLines.isEmpty
                ? legacyServiceLabels.map(\.en).joined(separator: ", ")
                : NailsContent.priceGroups.csvItems(for: prices),
            priceLines.isEmpty ? "" : total.text,
            shapeLabel?.en ?? "", designNotes,
            photoConsent == "agree" ? "Agree" : "Do not agree",
        ]
    }
}
