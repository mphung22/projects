import Foundation

extension WaxingAnswers {
    func makePDF(businessName: String, submittedAt: Date) -> Data {
        let submitted = Formatters.dateTime.string(from: submittedAt)
        let pdf = PDFComposer(footer: "\(businessName) · \(WaxingContent.documentTitle.both) · \(submitted)")

        pdf.title(businessName)
        pdf.subtitle(WaxingContent.documentTitle.both)
        pdf.subtitle(WaxingContent.serviceName.both)
        pdf.space(6)
        pdf.rule()

        pdf.heading(1, WaxingContent.infoTitle)
        pdf.field(WaxingContent.fullName, fullName)
        pdf.field(WaxingContent.phone, phone)
        pdf.field(WaxingContent.dateOfBirth, dateOfBirth.dayString)
        pdf.field(WaxingContent.serviceDate, Formatters.date.string(from: serviceDate))
        pdf.field(WaxingContent.areasLabel, priceLines.map(\.label.both).joined(separator: ", "))
        pdf.field(WaxingContent.technician, technician)

        pdf.heading(2, WaxingContent.contraTitle)
        if let healthAlert {
            pdf.alert(healthAlert)
        }
        for option in WaxingContent.contraindications {
            pdf.check(contraindications.contains(option.id), option.label)
        }
        pdf.check(noContraindications, WaxingContent.noneApply)

        pdf.heading(3, WaxingContent.aftercareTitle)
        WaxingContent.aftercare.forEach(pdf.bullet)

        pdf.heading(4, WaxingContent.ackTitle)
        for statement in ackStatements {
            pdf.check(ackInformed && ackHealth, statement)
        }

        pdf.heading(5, PriceText.summaryTitle)
        pdf.priceSummary(groups: WaxingContent.priceGroups, selection: prices)

        pdf.heading(6, WaxingContent.signTitle)
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
