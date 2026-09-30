import Foundation

struct HeadSpaAnswers: FormAnswers {
    var fullName = ""
    var phone = ""
    var email = ""
    var dateOfBirth: Date?
    var emergencyContact = ""
    var serviceDate = Date()
    var therapist = ""

    /// Items chosen from the price list (id → quantity). Optional so records saved by older versions still open.
    var priceSelection: PriceSelection?
    /// Treatment and duration from forms saved before the price list was added.
    var serviceID = ""
    var durationID = ""
    var pressureID = ""
    var scalpConcerns: Set<String> = []

    /// Ids of the consent statements the customer ticked.
    var agreements: Set<String> = []

    var customerSignature: Data?
    var therapistSignature: Data?

    var prices: PriceSelection {
        get { priceSelection ?? [:] }
        set { priceSelection = newValue }
    }
    var priceLines: [PriceLine] { HeadSpaContent.priceGroups.lines(for: prices) }
    var total: PriceTotal { HeadSpaContent.priceGroups.total(for: prices) }
    var pressureLabel: L? { HeadSpaContent.pressures.label(for: pressureID) }

    /// Treatment + duration saved by older versions of the form.
    var legacyServiceLabels: [L] {
        [HeadSpaContent.legacyServices.label(for: serviceID), HeadSpaContent.legacyDurations.label(for: durationID)]
            .compactMap { $0 }
    }

    func missingItems(businessName: String) -> [L] {
        var missing: [L] = []
        if fullName.trimmed.isEmpty { missing.append(HeadSpaContent.fullName) }
        if HeadSpaContent.ritualIDs.isDisjoint(with: prices.keys) { missing.append(HeadSpaContent.ritualRequired) }
        if pressureID.isEmpty { missing.append(HeadSpaContent.pressureLabel) }
        let allAgreements = Set(HeadSpaContent.agreements(businessName: businessName).map(\.id))
        if !allAgreements.isSubset(of: agreements) {
            missing.append(L("Đánh dấu ô đồng ý các cam kết", "Tick the box to agree to the statements"))
        }
        if customerSignature == nil { missing.append(HeadSpaContent.customerSignature) }
        return missing
    }

    // MARK: FormAnswers

    var customerName: String { fullName }
    var customerPhone: String { phone }

    var serviceSummary: String {
        if priceLines.isEmpty { return legacyServiceLabels.map(\.en).joined(separator: ", ") }
        return HeadSpaContent.priceGroups.summary(for: prices) + " · " + total.text
    }

    var healthAlert: String? { nil }

    static let csvHeader = [
        "Full name", "Phone", "Email", "Date of birth", "Emergency contact", "Service date", "Therapist",
        "Services", "Total (VND)", "Pressure", "Scalp & hair",
    ]

    var csvRow: [String] {
        [
            fullName, phone, email, dateOfBirth.dayString, emergencyContact,
            Formatters.date.string(from: serviceDate), therapist,
            priceLines.isEmpty
                ? legacyServiceLabels.map(\.en).joined(separator: ", ")
                : HeadSpaContent.priceGroups.csvItems(for: prices),
            priceLines.isEmpty ? "" : total.text,
            pressureLabel?.en ?? "",
            HeadSpaContent.scalpConcerns.labels(for: scalpConcerns).map(\.en).joined(separator: "; "),
        ]
    }
}
