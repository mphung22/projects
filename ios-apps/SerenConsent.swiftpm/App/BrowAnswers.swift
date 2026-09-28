import Foundation

struct BrowAnswers: FormAnswers {
    var fullName = ""
    var phone = ""
    var dateOfBirth: Date?
    var idNumber = ""
    var serviceDate = Date()
    var serviceID = SerenContent.services[0].id
    var technician = ""

    var contraindications: Set<String> = []
    var noContraindications = false

    var ackInformed = false
    /// "No contraindications" — or, if any were ticked, "discussed with technician".
    var ackHealth = false
    /// "agree" / "disagree" / "" (not answered)
    var photoConsent = ""

    var customerSignature: Data?
    var technicianSignature: Data?

    var serviceLabel: L? { SerenContent.services.label(for: serviceID) }
    var contraindicationLabels: [L] { SerenContent.contraindications.labels(for: contraindications) }
    var healthAckText: L { contraindications.isEmpty ? SerenContent.ackNoContraindications : SerenContent.ackDiscussed }

    /// Anything still required before the form can be submitted.
    var missingItems: [L] {
        var missing: [L] = []
        if fullName.trimmed.isEmpty { missing.append(SerenContent.fullName) }
        if phone.filter(\.isNumber).count < 8 { missing.append(SerenContent.phone) }
        if dateOfBirth == nil { missing.append(SerenContent.dateOfBirth) }
        if serviceID.isEmpty { missing.append(SerenContent.registeredService) }
        if contraindications.isEmpty && !noContraindications {
            missing.append(L("Chống chỉ định: đánh dấu mục phù hợp hoặc “Không có”",
                             "Contraindications: tick what applies or “None of the above”"))
        }
        if !ackInformed || !ackHealth {
            missing.append(L("Đánh dấu các mục Cam Kết", "Tick the Acknowledgement boxes"))
        }
        if photoConsent.isEmpty { missing.append(SerenContent.photoQuestion) }
        if customerSignature == nil { missing.append(SerenContent.customerSignature) }
        return missing
    }

    // MARK: FormAnswers

    var customerName: String { fullName }
    var customerPhone: String { phone }
    var serviceSummary: String { serviceLabel?.en ?? serviceID }

    var healthAlert: String? {
        contraindicationLabels.isEmpty ? nil : contraindicationLabels.map(\.both).joined(separator: " • ")
    }

    static let csvHeader = [
        "Full name", "Phone", "Date of birth", "ID/Passport", "Service date", "Service",
        "Technician", "Contraindications", "Photo consent",
    ]

    var csvRow: [String] {
        [
            fullName, phone, dateOfBirth.dayString, idNumber, Formatters.date.string(from: serviceDate),
            serviceLabel?.en ?? serviceID, technician,
            contraindicationLabels.map(\.en).joined(separator: "; "),
            photoConsent == "agree" ? "Agree" : "Do not agree",
        ]
    }
}
