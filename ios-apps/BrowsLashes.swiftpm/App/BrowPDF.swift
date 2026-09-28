import Foundation

extension BrowAnswers {
    func makePDF(businessName: String, submittedAt: Date) -> Data {
        let submitted = Formatters.dateTime.string(from: submittedAt)
        let pdf = PDFComposer(footer: "\(businessName) · \(SerenContent.documentTitle.both) · \(submitted)")

        pdf.title(businessName)
        pdf.subtitle(SerenContent.documentTitle.both)
        pdf.subtitle(SerenContent.serviceName.both)
        pdf.space(6)
        pdf.rule()

        pdf.heading(1, SerenContent.infoTitle)
        pdf.field(SerenContent.fullName, fullName)
        pdf.field(SerenContent.phone, phone)
        pdf.field(SerenContent.dateOfBirth, dateOfBirth.dayString)
        pdf.field(SerenContent.idNumber, idNumber)
        pdf.field(SerenContent.serviceDate, Formatters.date.string(from: serviceDate))
        pdf.field(SerenContent.registeredService, serviceLabels.map(\.both).joined(separator: ", "))
        pdf.field(SerenContent.technician, technician)

        pdf.heading(2, SerenContent.detailsTitle)
        pdf.groups(SerenContent.details(for: selectedServices))

        pdf.heading(3, SerenContent.contraTitle)
        if let healthAlert {
            pdf.alert(healthAlert)
        }
        for option in SerenContent.contraindications {
            pdf.check(contraindications.contains(option.id), option.label)
        }
        pdf.check(noContraindications, SerenContent.noneApply)
        pdf.bilingual(SerenContent.patchTestNote)
        if SerenContent.includesLashes(selectedServices) {
            pdf.bilingual(SerenContent.contactLensNote)
        }

        pdf.heading(4, SerenContent.aftercareTitle)
        pdf.groups(SerenContent.aftercare(for: selectedServices))

        pdf.heading(5, SerenContent.ackTitle)
        pdf.check(ackInformed, SerenContent.ackInformed)
        pdf.check(ackHealth, healthAckText)
        pdf.bilingual(SerenContent.photoQuestion)
        for option in SerenContent.photoOptions {
            pdf.check(photoConsent == option.id, option.label)
        }

        pdf.heading(6, SerenContent.signTitle)
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
