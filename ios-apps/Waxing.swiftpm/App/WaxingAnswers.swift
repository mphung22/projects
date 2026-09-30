import Foundation

struct WaxingAnswers: FormAnswers {
    var fullName = ""
    var phone = ""
    var dateOfBirth: Date?
    var serviceDate = Date()
    var technician = ""
    /// Areas chosen from the price list (id → quantity).
    var priceSelection: PriceSelection?

    var contraindications: Set<String> = []
    var noContraindications = false

    var ackInformed = false
    /// "No contraindications" — or, if any were ticked, "discussed with technician".
    var ackHealth = false

    var customerSignature: Data?

    var prices: PriceSelection {
        get { priceSelection ?? [:] }
        set { priceSelection = newValue }
    }
    var priceLines: [PriceLine] { WaxingContent.priceGroups.lines(for: prices) }
    var total: PriceTotal { WaxingContent.priceGroups.total(for: prices) }
    var contraindicationLabels: [L] { WaxingContent.contraindications.labels(for: contraindications) }
    var healthAckText: L { contraindications.isEmpty ? WaxingContent.ackNoContraindications : WaxingContent.ackDiscussed }
    var ackStatements: [L] { [WaxingContent.ackInformed, WaxingContent.ackRedness, healthAckText] }

    /// Anything still required before the form can be submitted.
    var missingItems: [L] {
        var missing: [L] = []
        if fullName.trimmed.isEmpty { missing.append(WaxingContent.fullName) }
        if priceLines.isEmpty { missing.append(WaxingContent.areasLabel) }
        if contraindications.isEmpty && !noContraindications {
            missing.append(L("Chống chỉ định: đánh dấu mục phù hợp hoặc “Không có”",
                             "Contraindications: tick what applies or “None of the above”"))
        }
        if !ackInformed || !ackHealth {
            missing.append(L("Đánh dấu ô đồng ý các cam kết", "Tick the box to agree to the statements"))
        }
        if customerSignature == nil { missing.append(WaxingContent.customerSignature) }
        return missing
    }

    // MARK: FormAnswers

    var customerName: String { fullName }
    var customerPhone: String { phone }
    var serviceSummary: String {
        priceLines.map(\.label.en).joined(separator: ", ") + " · " + total.text
    }

    var healthAlert: String? {
        contraindicationLabels.isEmpty ? nil : contraindicationLabels.map(\.both).joined(separator: " • ")
    }

    static let csvHeader = [
        "Full name", "Phone", "Date of birth", "Service date", "Areas", "Total (VND)", "Technician", "Contraindications",
    ]

    var csvRow: [String] {
        [
            fullName, phone, dateOfBirth.dayString, Formatters.date.string(from: serviceDate),
            WaxingContent.priceGroups.csvItems(for: prices), total.text, technician,
            contraindicationLabels.map(\.en).joined(separator: "; "),
        ]
    }
}
