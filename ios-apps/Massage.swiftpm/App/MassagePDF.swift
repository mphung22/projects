import Foundation

extension MassageAnswers {
    func makePDF(businessName: String, submittedAt: Date) -> Data {
        let submitted = Formatters.dateTime.string(from: submittedAt)
        let pdf = PDFComposer(footer: "\(businessName) · \(MassageContent.documentTitle.both) · \(submitted)")

        pdf.title(businessName)
        pdf.subtitle(MassageContent.documentTitle.both)
        pdf.space(6)
        pdf.rule()

        pdf.heading(1, MassageContent.infoTitle)
        pdf.field(MassageContent.fullName, fullName)
        pdf.field(MassageContent.phone, phone)
        pdf.field(MassageContent.email, email)
        pdf.field(MassageContent.dateOfBirth, dateOfBirth.dayString)
        pdf.field(MassageContent.emergencyContact, emergencyContact)
        pdf.field(MassageContent.serviceDate, Formatters.date.string(from: serviceDate))
        pdf.field(MassageContent.therapist, therapist)

        pdf.heading(2, MassageContent.serviceTitle)
        pdf.field(MassageContent.serviceType, serviceLabel?.both ?? "")
        pdf.field(MassageContent.durationLabel, durationLabel?.both ?? "")
        pdf.field(MassageContent.pressureLabel, pressureLabel?.both ?? "")

        pdf.heading(3, MassageContent.areasTitle)
        pdf.field(MassageContent.focusLabel,
                  MassageContent.areas.labels(for: focusAreas).map(\.both).joined(separator: ", "))
        pdf.field(MassageContent.avoidLabel,
                  MassageContent.areas.labels(for: avoidAreas).map(\.both).joined(separator: ", "))

        pdf.heading(4, MassageContent.healthTitle)
        if !conditionLabels.isEmpty {
            pdf.alert(conditionLabels.map(\.both).joined(separator: " • "))
        }
        for option in MassageContent.conditions {
            pdf.check(conditions.contains(option.id), option.label)
        }
        pdf.check(noConditions, MassageContent.noneApply)
        pdf.field(MassageContent.healthDetails, healthDetails)
        pdf.field(MassageContent.medications, medications)

        pdf.heading(5, MassageContent.aftercareTitle)
        MassageContent.aftercare.forEach(pdf.bullet)

        pdf.heading(6, MassageContent.consentTitle)
        for option in MassageContent.agreements(businessName: businessName) {
            pdf.check(agreements.contains(option.id), option.label)
        }
        pdf.space(8)
        let day = Formatters.date.string(from: submittedAt)
        pdf.signatures([
            .init(title: "Khách hàng / Customer",
                  image: customerSignature.image, name: fullName, date: day),
        ])
        pdf.bilingual(L("Ký điện tử trên iPad lúc \(submitted).", "Signed electronically on iPad at \(submitted)."))

        return pdf.render()
    }
}
