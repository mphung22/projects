import Foundation

struct MassageAnswers: FormAnswers {
    var fullName = ""
    var phone = ""
    var email = ""
    var dateOfBirth: Date?
    var emergencyContact = ""
    var serviceDate = Date()
    var therapist = ""

    /// Items chosen from the price list (id → quantity). Optional so records saved by older versions still open.
    var priceSelection: PriceSelection?
    /// Massage oil id; optional for the same reason.
    var oilID: String?
    /// Massage type and duration from forms saved before the price list was added.
    var serviceID = ""
    var durationID = ""
    var pressureID = ""
    var focusAreas: Set<String> = []
    var avoidAreas: Set<String> = []


    /// Ids of the consent statements the customer ticked.
    var agreements: Set<String> = []

    var customerSignature: Data?
    var therapistSignature: Data?

    var prices: PriceSelection {
        get { priceSelection ?? [:] }
        set { priceSelection = newValue }
    }
    var oil: String {
        get { oilID ?? "" }
        set { oilID = newValue.isEmpty ? nil : newValue }
    }
    var priceLines: [PriceLine] { MassageContent.priceGroups.lines(for: prices) }
    var total: PriceTotal { MassageContent.priceGroups.total(for: prices) }
    var needsOil: Bool { !MassageContent.massageIDs.isDisjoint(with: prices.keys) }
    var oilLabel: L? { MassageContent.oils.label(for: oil) }

    var pressureLabel: L? { MassageContent.pressures.label(for: pressureID) }

    /// Massage type + duration saved by older versions of the form.
    var legacyServiceLabels: [L] {
        [MassageContent.legacyServices.label(for: serviceID), MassageContent.legacyDurations.label(for: durationID)]
            .compactMap { $0 }
    }

    func missingItems(businessName: String) -> [L] {
        var missing: [L] = []
        if fullName.trimmed.isEmpty { missing.append(MassageContent.fullName) }
        if priceLines.isEmpty { missing.append(MassageContent.serviceType) }
        if needsOil && oil.isEmpty { missing.append(MassageContent.oilLabel) }
        if pressureID.isEmpty { missing.append(MassageContent.pressureLabel) }
        let allAgreements = Set(MassageContent.agreements(businessName: businessName).map(\.id))
        if !allAgreements.isSubset(of: agreements) {
            missing.append(L("Đánh dấu ô đồng ý các cam kết", "Tick the box to agree to the statements"))
        }
        if customerSignature == nil { missing.append(MassageContent.customerSignature) }
        return missing
    }

    // MARK: FormAnswers

    var customerName: String { fullName }
    var customerPhone: String { phone }

    var serviceSummary: String {
        if priceLines.isEmpty { return legacyServiceLabels.map(\.en).joined(separator: ", ") }
        var parts = [MassageContent.priceGroups.summary(for: prices)]
        if let oilLabel { parts.append("Oil: \(oilLabel.en)") }
        parts.append(total.text)
        return parts.joined(separator: " · ")
    }

    var healthAlert: String? { nil }

    static let csvHeader = [
        "Full name", "Phone", "Email", "Date of birth", "Emergency contact", "Service date", "Therapist",
        "Services", "Total (VND)", "Oil", "Pressure", "Focus areas", "Avoid areas",
    ]

    var csvRow: [String] {
        [
            fullName, phone, email, dateOfBirth.dayString, emergencyContact,
            Formatters.date.string(from: serviceDate), therapist,
            priceLines.isEmpty
                ? legacyServiceLabels.map(\.en).joined(separator: ", ")
                : MassageContent.priceGroups.csvItems(for: prices),
            priceLines.isEmpty ? "" : total.text,
            oilLabel?.en ?? "",
            pressureLabel?.en ?? "",
            MassageContent.areas.labels(for: focusAreas).map(\.en).joined(separator: "; "),
            MassageContent.areas.labels(for: avoidAreas).map(\.en).joined(separator: "; "),
        ]
    }
}
