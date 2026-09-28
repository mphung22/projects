import Foundation

extension NailsAnswers {
    func makePDF(businessName: String, submittedAt: Date) -> Data {
        let submitted = Formatters.dateTime.string(from: submittedAt)
        let pdf = PDFComposer(footer: "\(businessName) · \(NailsContent.documentTitle.both) · \(submitted)")

        pdf.title(businessName)
        pdf.subtitle(NailsContent.documentTitle.both)
        pdf.subtitle(NailsContent.serviceName.both)
        pdf.space(6)
        pdf.rule()

        pdf.heading(1, NailsContent.infoTitle)
        pdf.field(NailsContent.fullName, fullName)
        pdf.field(NailsContent.phone, phone)
        pdf.field(NailsContent.dateOfBirth, dateOfBirth.dayString)
        pdf.field(NailsContent.serviceDate, Formatters.date.string(from: serviceDate))
        pdf.field(NailsContent.technician, technician)

        pdf.heading(2, NailsContent.servicesTitle)
        pdf.field(NailsContent.servicesLabel, serviceLabels.map(\.both).joined(separator: ", "))
        pdf.field(NailsContent.shapeLabel, shapeLabel?.both ?? "")
        pdf.field(NailsContent.notesLabel, designNotes)

        pdf.heading(3, NailsContent.healthTitle)
        if !conditionLabels.isEmpty {
            pdf.alert(conditionLabels.map(\.both).joined(separator: " • "))
        }
        for option in NailsContent.conditions {
            pdf.check(conditions.contains(option.id), option.label)
        }
        pdf.check(noConditions, NailsContent.noneApply)
        pdf.field(NailsContent.healthDetails, healthDetails)

        pdf.heading(4, NailsContent.infoCareTitle)
        pdf.groups([NailsContent.goodToKnow, NailsContent.aftercare])

        pdf.heading(5, NailsContent.ackTitle)
        pdf.check(ackInformed, NailsContent.ackInformed)
        pdf.check(ackHealth, healthAckText)
        pdf.check(ackRisk, NailsContent.ackRisk)
        pdf.bilingual(NailsContent.photoQuestion)
        for option in NailsContent.photoOptions {
            pdf.check(photoConsent == option.id, option.label)
        }

        pdf.heading(6, NailsContent.signTitle)
        pdf.space(6)
        let day = Formatters.date.string(from: submittedAt)
        pdf.signatures([
            .init(title: "\(businessName) — Kỹ thuật viên / Technician",
                  image: technicianSignature.image, name: technician, date: day),
            .init(title: "Khách hàng / Customer",
                  image: customerSignature.image, name: fullName, date: day),
        ])
        pdf.bilingual(L("Ký điện tử trên iPad lúc \(submitted).", "Signed electronically on iPad at \(submitted)."))

        return pdf.render()
    }
}
