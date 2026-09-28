import Foundation

struct HeadSpaAnswers: FormAnswers {
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
    var scalpConcerns: Set<String> = []

    var conditions: Set<String> = []
    var noConditions = false
    var healthDetails = ""
    var medications = ""

    /// Ids of the consent statements the customer ticked.
    var agreements: Set<String> = []

    var customerSignature: Data?
    var therapistSignature: Data?

    var serviceLabel: L? { HeadSpaContent.services.label(for: serviceID) }
    var durationLabel: L? { HeadSpaContent.durations.label(for: durationID) }
    var pressureLabel: L? { HeadSpaContent.pressures.label(for: pressureID) }
    var conditionLabels: [L] { HeadSpaContent.conditions.labels(for: conditions) }

    func missingItems(businessName: String) -> [L] {
        var missing: [L] = []
        if fullName.trimmed.isEmpty { missing.append(HeadSpaContent.fullName) }
        if serviceID.isEmpty { missing.append(HeadSpaContent.serviceType) }
        if durationID.isEmpty { missing.append(HeadSpaContent.durationLabel) }
        if pressureID.isEmpty { missing.append(HeadSpaContent.pressureLabel) }
        if conditions.isEmpty && !noConditions {
            missing.append(L("Sức khoẻ: đánh dấu mục phù hợp hoặc “Không có”",
                             "Health: tick what applies or “None of the above”"))
        }
        let allAgreements = Set(HeadSpaContent.agreements(businessName: businessName).map(\.id))
        if !allAgreements.isSubset(of: agreements) {
            missing.append(L("Đánh dấu tất cả các mục Cam kết", "Tick every consent statement"))
        }
        if customerSignature == nil { missing.append(HeadSpaContent.customerSignature) }
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
        "Service", "Duration", "Pressure", "Scalp & hair", "Health conditions",
        "Health details", "Medications",
    ]

    var csvRow: [String] {
        [
            fullName, phone, email, dateOfBirth.dayString, emergencyContact,
            Formatters.date.string(from: serviceDate), therapist,
            serviceLabel?.en ?? "", durationLabel?.en ?? "", pressureLabel?.en ?? "",
            HeadSpaContent.scalpConcerns.labels(for: scalpConcerns).map(\.en).joined(separator: "; "),
            conditionLabels.map(\.en).joined(separator: "; "),
            healthDetails, medications,
        ]
    }
}
