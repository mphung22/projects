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
        pdf.field(NailsContent.servicesLabel, priceLines.isEmpty
            ? legacyServiceLabels.map(\.both).joined(separator: ", ")
            : priceLines.map(\.label.both).joined(separator: ", "))
        pdf.field(NailsContent.shapeLabel, shapeLabel?.both ?? "")
        pdf.field(NailsContent.notesLabel, designNotes)

        pdf.heading(3, NailsContent.infoCareTitle)
        pdf.groups([NailsContent.goodToKnow, NailsContent.aftercare])

        pdf.heading(4, NailsContent.ackTitle)
        pdf.check(ackInformed, NailsContent.ackInformed)
        pdf.check(ackRisk, NailsContent.ackRisk)
        pdf.bilingual(NailsContent.photoQuestion)
        for option in NailsContent.photoOptions {
            pdf.check(photoConsent == option.id, option.label)
        }

        pdf.heading(5, PriceText.summaryTitle)
        pdf.priceSummary(groups: NailsContent.priceGroups, selection: prices)

        pdf.heading(6, NailsContent.signTitle)
        pdf.space(6)
        let day = Formatters.date.string(from: submittedAt)
        pdf.signatures([
            .init(title: "Khách hàng / Customer",
                  image: customerSignature.image, name: fullName, date: day),
        ])
        pdf.bilingual(L("Ký điện tử trên iPad lúc \(submitted).", "Signed electronically on iPad at \(submitted)."))

        return pdf.render()
    }
}
