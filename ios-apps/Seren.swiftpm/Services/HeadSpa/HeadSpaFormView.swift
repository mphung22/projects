import SwiftUI

struct HeadSpaFormView: View {
    let onSubmit: (HeadSpaAnswers) -> Void

    @AppStorage(SettingsKey.businessName) private var businessName = ""
    @State private var answers = HeadSpaAnswers()
    @State private var missing: [L] = []

    var body: some View {
        FormPage(title: HeadSpaContent.serviceName, missing: $missing) {
            header

            FormSection(number: 1, title: HeadSpaContent.infoTitle) { infoFields }

            FormSection(number: 2, title: HeadSpaContent.serviceTitle) { serviceChoices }

            FormSection(number: 3, title: HeadSpaContent.scalpTitle) {
                VStack(alignment: .leading, spacing: 12) {
                    FieldLabel(title: HeadSpaContent.scalpPrompt)
                    MultiChips(options: HeadSpaContent.scalpConcerns, selection: $answers.scalpConcerns, columns: 3)
                }
            }

            FormSection(number: 4, title: PriceText.summaryTitle) {
                PriceSummaryView(groups: HeadSpaContent.priceGroups, selection: answers.prices)
            }

            FormSection(number: 5, title: HeadSpaContent.consentTitle) { consent }

            SubmitButton(title: HeadSpaContent.submit, action: submit)
                .padding(.bottom, 40)
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text(businessName).font(.system(size: 34, weight: .light, design: .serif))
            LText(HeadSpaContent.documentTitle, font: .headline)
            LText(HeadSpaContent.intro, font: .callout)
                .padding(.top, 6)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    private var infoFields: some View {
        VStack(alignment: .leading, spacing: 18) {
            AdaptiveRow {
                TextFieldRow(title: HeadSpaContent.fullName, text: $answers.fullName, required: true,
                             contentType: .name, capitalization: .words)
                TextFieldRow(title: HeadSpaContent.phone, text: $answers.phone,
                             keyboard: .phonePad, contentType: .telephoneNumber)
            }
            AdaptiveRow {
                TextFieldRow(title: HeadSpaContent.email, text: $answers.email,
                             keyboard: .emailAddress, contentType: .emailAddress, capitalization: .never)
                OptionalDateField(title: HeadSpaContent.dateOfBirth, date: $answers.dateOfBirth)
            }
            AdaptiveRow {
                TextFieldRow(title: HeadSpaContent.emergencyContact, text: $answers.emergencyContact,
                             capitalization: .words)
                DateFieldRow(title: HeadSpaContent.serviceDate, date: $answers.serviceDate)
            }
            StaffField(title: HeadSpaContent.therapist, name: $answers.therapist)
        }
    }

    private var serviceChoices: some View {
        VStack(alignment: .leading, spacing: 12) {
            FieldLabel(title: HeadSpaContent.serviceType, required: true)
            PriceMenuView(groups: HeadSpaContent.priceGroups, selection: $answers.prices)

            FieldLabel(title: HeadSpaContent.pressureLabel, required: true)
                .padding(.top, 12)
            ChoiceChips(options: HeadSpaContent.pressures, selection: $answers.pressureID, columns: 4)
        }
    }

    private var consent: some View {
        VStack(alignment: .leading, spacing: 8) {
            let agreements = HeadSpaContent.agreements(businessName: businessName)
            ConsentBlock(
                statements: agreements.map(\.label),
                isOn: Binding(
                    get: { Set(agreements.map(\.id)).isSubset(of: answers.agreements) },
                    set: { answers.agreements = $0 ? Set(agreements.map(\.id)) : [] }
                )
            )
            SignaturePad(title: HeadSpaContent.customerSignature, signature: $answers.customerSignature, required: true)
                .padding(.top, 20)
            Text("Ngày / Date: \(Formatters.date.string(from: Date()))")
                .foregroundStyle(.secondary)
        }
    }

    private func submit() {
        let problems = answers.missingItems(businessName: businessName)
        guard problems.isEmpty else {
            missing = problems
            return
        }
        var cleaned = answers
        cleaned.fullName = cleaned.fullName.trimmed
        cleaned.phone = cleaned.phone.trimmed
        cleaned.email = cleaned.email.trimmed
        onSubmit(cleaned)
    }
}
