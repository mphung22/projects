import Foundation

struct MassageAnswers: FormAnswers {
    var fullName = ""
    var phone = ""
    var email = ""
    var dateOfBirth: Date?
    var emergencyContact = ""
    var serviceDate = Date()
    var therapist = ""

    var serviceID = ""
    var durationID = ""
    var pressureID = ""
    var focusAreas: Set<String> = []
    var avoidAreas: Set<String> = []

    var conditions: Set<String> = []
    var noConditions = false
    var healthDetails = ""
    var medications = ""

    /// Ids of the consent statements the customer ticked.
    var agreements: Set<String> = []

    var customerSignature: Data?
    var therapistSignature: Data?

    var serviceLabel: L? { MassageContent.services.label(for: serviceID) }
    var durationLabel: L? { MassageContent.durations.label(for: durationID) }
    var pressureLabel: L? { MassageContent.pressures.label(for: pressureID) }
    var conditionLabels: [L] { MassageContent.conditions.labels(for: conditions) }

    func missingItems(businessName: String) -> [L] {
        var missing: [L] = []
        if fullName.trimmed.isEmpty { missing.append(MassageContent.fullName) }
        if serviceID.isEmpty { missing.append(MassageContent.serviceType) }
        if durationID.isEmpty { missing.append(MassageContent.durationLabel) }
        if pressureID.isEmpty { missing.append(MassageContent.pressureLabel) }
        if conditions.isEmpty && !noConditions {
            missing.append(L("Sức khoẻ: đánh dấu mục phù hợp hoặc “Không có”",
                             "Health: tick what applies or “None of the above”"))
        }
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
        [serviceLabel?.en, durationLabel?.en].compactMap { $0 }.joined(separator: ", ")
    }

    var healthAlert: String? {
        var notes = conditionLabels.map(\.both)
        if !healthDetails.trimmed.isEmpty { notes.append(healthDetails.trimmed) }
        return notes.isEmpty ? nil : notes.joined(separator: " • ")
    }

    static let csvHeader = [
        "Full name", "Phone", "Email", "Date of birth", "Emergency contact", "Service date", "Therapist",
        "Service", "Duration", "Pressure", "Focus areas", "Avoid areas", "Health conditions",
        "Health details", "Medications",
    ]

    var csvRow: [String] {
        [
            fullName, phone, email, dateOfBirth.dayString, emergencyContact,
            Formatters.date.string(from: serviceDate), therapist,
            serviceLabel?.en ?? "", durationLabel?.en ?? "", pressureLabel?.en ?? "",
            MassageContent.areas.labels(for: focusAreas).map(\.en).joined(separator: "; "),
            MassageContent.areas.labels(for: avoidAreas).map(\.en).joined(separator: "; "),
            conditionLabels.map(\.en).joined(separator: "; "),
            healthDetails, medications,
        ]
    }
}
