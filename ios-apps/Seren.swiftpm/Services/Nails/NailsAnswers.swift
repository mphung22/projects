import Foundation

struct NailsAnswers: FormAnswers {
    var fullName = ""
    var phone = ""
    var dateOfBirth: Date?
    var serviceDate = Date()
    var technician = ""

    var services: Set<String> = []
    /// "" when no preference.
    var shapeID = ""
    var designNotes = ""

    var conditions: Set<String> = []
    var noConditions = false
    var healthDetails = ""

    var ackInformed = false
    /// "No conditions" — or, if any were ticked, "discussed with technician".
    var ackHealth = false
    var ackRisk = false
    /// "agree" / "disagree" / "" (not answered)
    var photoConsent = ""

    var customerSignature: Data?
    var technicianSignature: Data?

    var serviceLabels: [L] { NailsContent.services.labels(for: services) }
    var shapeLabel: L? { NailsContent.shapes.label(for: shapeID) }
    var conditionLabels: [L] { NailsContent.conditions.labels(for: conditions) }
    var healthAckText: L { conditions.isEmpty ? NailsContent.ackNoConditions : NailsContent.ackDiscussed }

    var missingItems: [L] {
        var missing: [L] = []
        if fullName.trimmed.isEmpty { missing.append(NailsContent.fullName) }
        if services.isEmpty { missing.append(NailsContent.servicesLabel) }
        if conditions.isEmpty && !noConditions {
            missing.append(L("Sức khoẻ: đánh dấu mục phù hợp hoặc “Không có”",
                             "Health: tick what applies or “None of the above”"))
        }
        if !ackInformed || !ackHealth || !ackRisk {
            missing.append(L("Đánh dấu ô đồng ý các cam kết", "Tick the box to agree to the statements"))
        }
        if photoConsent.isEmpty { missing.append(NailsContent.photoQuestion) }
        if customerSignature == nil { missing.append(NailsContent.customerSignature) }
        return missing
    }

    // MARK: FormAnswers

    var customerName: String { fullName }
    var customerPhone: String { phone }
    var serviceSummary: String { serviceLabels.map(\.en).joined(separator: ", ") }

    var healthAlert: String? {
        var notes = conditionLabels.map(\.both)
        if !healthDetails.trimmed.isEmpty { notes.append(healthDetails.trimmed) }
        return notes.isEmpty ? nil : notes.joined(separator: " • ")
    }

    static let csvHeader = [
        "Full name", "Phone", "Date of birth", "Service date", "Technician", "Services", "Nail shape",
        "Design notes", "Health conditions", "Health details", "Photo consent",
    ]

    var csvRow: [String] {
        [
            fullName, phone, dateOfBirth.dayString, Formatters.date.string(from: serviceDate), technician,
            serviceSummary, shapeLabel?.en ?? "", designNotes,
            conditionLabels.map(\.en).joined(separator: "; "), healthDetails,
            photoConsent == "agree" ? "Agree" : "Do not agree",
        ]
    }
}
