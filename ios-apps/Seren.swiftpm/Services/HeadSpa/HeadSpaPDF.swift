import Foundation

extension HeadSpaAnswers {
    func makePDF(businessName: String, submittedAt: Date) -> Data {
        let submitted = Formatters.dateTime.string(from: submittedAt)
        let pdf = PDFComposer(footer: "\(businessName) · \(HeadSpaContent.documentTitle.both) · \(submitted)")

        pdf.title(businessName)
        pdf.subtitle(HeadSpaContent.documentTitle.both)
        pdf.space(6)
        pdf.rule()

        pdf.heading(1, HeadSpaContent.infoTitle)
        pdf.field(HeadSpaContent.fullName, fullName)
        pdf.field(HeadSpaContent.phone, phone)
        pdf.field(HeadSpaContent.email, email)
        pdf.field(HeadSpaContent.dateOfBirth, dateOfBirth.dayString)
        pdf.field(HeadSpaContent.emergencyContact, emergencyContact)
        pdf.field(HeadSpaContent.serviceDate, Formatters.date.string(from: serviceDate))
        pdf.field(HeadSpaContent.therapist, therapist)

        pdf.heading(2, HeadSpaContent.serviceTitle)
        pdf.field(HeadSpaContent.serviceType, priceLines.isEmpty
            ? legacyServiceLabels.map(\.both).joined(separator: ", ")
            : priceLines.map(\.label.both).joined(separator: ", "))
        pdf.field(HeadSpaContent.pressureLabel, pressureLabel?.both ?? "")

        pdf.heading(3, HeadSpaContent.scalpTitle)
        pdf.field(HeadSpaContent.scalpPrompt,
                  HeadSpaContent.scalpConcerns.labels(for: scalpConcerns).map(\.both).joined(separator: ", "))

        pdf.heading(4, PriceText.summaryTitle)
        pdf.priceSummary(groups: HeadSpaContent.priceGroups, selection: prices)

        pdf.heading(5, HeadSpaContent.consentTitle)
        for option in HeadSpaContent.agreements(businessName: businessName) {
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
