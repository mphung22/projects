import SwiftUI

struct WaxingFormView: View {
    let onSubmit: (WaxingAnswers) -> Void

    @AppStorage(SettingsKey.businessName) private var businessName = ""
    @State private var answers = WaxingAnswers()
    @State private var missing: [L] = []

    var body: some View {
        FormPage(title: WaxingContent.serviceName, missing: $missing) {
            header

            FormSection(number: 1, title: WaxingContent.infoTitle) { infoFields }

            FormSection(number: 2, title: WaxingContent.servicesTitle) {
                VStack(alignment: .leading, spacing: 12) {
                    FieldLabel(title: WaxingContent.areasLabel, required: true)
                    PriceMenuView(groups: WaxingContent.priceGroups, selection: $answers.prices)
                }
            }

            FormSection(number: 3, title: WaxingContent.contraTitle) { contraindications }

            FormSection(number: 4, title: WaxingContent.aftercareTitle) {
                BulletList(items: WaxingContent.aftercare)
            }

            FormSection(number: 5, title: WaxingContent.ackTitle) {
                ConsentBlock(
                    statements: answers.ackStatements,
                    isOn: Binding(
                        get: { answers.ackInformed && answers.ackHealth },
                        set: { answers.ackInformed = $0; answers.ackHealth = $0 }
                    )
                )
            }

            FormSection(number: 6, title: PriceText.summaryTitle) {
                PriceSummaryView(groups: WaxingContent.priceGroups, selection: answers.prices)
            }

            FormSection(number: 7, title: WaxingContent.signTitle) { signature }

            SubmitButton(title: WaxingContent.submit, action: submit)
                .padding(.bottom, 40)
        }
        .onChange(of: answers.noContraindications) { _, none in
            if none { answers.contraindications.removeAll() }
        }
        .onChange(of: answers.contraindications) { _, ticked in
            if !ticked.isEmpty { answers.noContraindications = false }
            // The health statement changes wording, so ask again.
            answers.ackHealth = false
        }
        .onChange(of: answers.dateOfBirth) { _, birthday in
            if let birthday, age(from: birthday) < 16 {
                answers.contraindications.insert("under16")
            }
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text(businessName).font(.system(size: 34, weight: .light, design: .serif))
            LText(WaxingContent.documentTitle, font: .headline)
            LText(WaxingContent.intro, font: .callout)
                .padding(.top, 6)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    private var infoFields: some View {
        VStack(alignment: .leading, spacing: 18) {
            AdaptiveRow {
                TextFieldRow(title: WaxingContent.fullName, text: $answers.fullName, required: true,
                             contentType: .name, capitalization: .words)
                TextFieldRow(title: WaxingContent.phone, text: $answers.phone,
                             keyboard: .phonePad, contentType: .telephoneNumber)
            }
            AdaptiveRow {
                OptionalDateField(title: WaxingContent.dateOfBirth, date: $answers.dateOfBirth)
                DateFieldRow(title: WaxingContent.serviceDate, date: $answers.serviceDate)
            }
            StaffField(title: WaxingContent.technician, name: $answers.technician)
        }
    }

    private var contraindications: some View {
        VStack(alignment: .leading, spacing: 8) {
            LText(WaxingContent.contraPrompt, font: .headline)
                .padding(.bottom, 4)
            ForEach(WaxingContent.contraindications) { option in
                CheckRow(text: option.label, isOn: $answers.contraindications.contains(option.id))
            }
            Divider().padding(.vertical, 4)
            CheckRow(text: WaxingContent.noneApply, isOn: $answers.noContraindications)

            if !answers.contraindications.isEmpty {
                NoticeBanner(text: WaxingContent.contraWarning)
                    .padding(.top, 8)
            }
        }
    }

    private var signature: some View {
        VStack(alignment: .leading, spacing: 24) {
            SignaturePad(title: WaxingContent.customerSignature, signature: $answers.customerSignature, required: true)
            Text("Ngày / Date: \(Formatters.date.string(from: Date()))")
                .foregroundStyle(.secondary)
        }
    }

    private func submit() {
        let problems = answers.missingItems
        guard problems.isEmpty else {
            missing = problems
            return
        }
        var cleaned = answers
        cleaned.fullName = cleaned.fullName.trimmed
        cleaned.phone = cleaned.phone.trimmed
        onSubmit(cleaned)
    }
}
