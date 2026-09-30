import SwiftUI

struct MassageFormView: View {
    let onSubmit: (MassageAnswers) -> Void

    @AppStorage(SettingsKey.businessName) private var businessName = ""
    @State private var answers = MassageAnswers()
    @State private var missing: [L] = []

    var body: some View {
        FormPage(title: MassageContent.serviceName, missing: $missing) {
            header

            FormSection(number: 1, title: MassageContent.infoTitle) { infoFields }

            FormSection(number: 2, title: MassageContent.serviceTitle) { serviceChoices }

            FormSection(number: 3, title: MassageContent.areasTitle) {
                VStack(alignment: .leading, spacing: 12) {
                    FieldLabel(title: MassageContent.focusLabel)
                    MultiChips(options: MassageContent.areas, selection: $answers.focusAreas, columns: 4)
                    FieldLabel(title: MassageContent.avoidLabel)
                        .padding(.top, 12)
                    MultiChips(options: MassageContent.areas, selection: $answers.avoidAreas, columns: 4)
                }
            }

            FormSection(number: 4, title: MassageContent.aftercareTitle) {
                BulletList(items: MassageContent.aftercare)
            }

            FormSection(number: 5, title: PriceText.summaryTitle) {
                PriceSummaryView(groups: MassageContent.priceGroups, selection: answers.prices)
            }

            FormSection(number: 6, title: MassageContent.consentTitle) { consent }

            SubmitButton(title: MassageContent.submit, action: submit)
                .padding(.bottom, 40)
        }
        // An area can't be both "focus" and "avoid".
        .onChange(of: answers.focusAreas) { _, focus in
            answers.avoidAreas.subtract(focus)
        }
        .onChange(of: answers.avoidAreas) { _, avoid in
            answers.focusAreas.subtract(avoid)
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text(businessName).font(.system(size: 34, weight: .light, design: .serif))
            LText(MassageContent.documentTitle, font: .headline)
            LText(MassageContent.intro, font: .callout)
                .padding(.top, 6)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    private var infoFields: some View {
        VStack(alignment: .leading, spacing: 18) {
            AdaptiveRow {
                TextFieldRow(title: MassageContent.fullName, text: $answers.fullName, required: true,
                             contentType: .name, capitalization: .words)
                TextFieldRow(title: MassageContent.phone, text: $answers.phone,
                             keyboard: .phonePad, contentType: .telephoneNumber)
            }
            AdaptiveRow {
                TextFieldRow(title: MassageContent.email, text: $answers.email,
                             keyboard: .emailAddress, contentType: .emailAddress, capitalization: .never)
                OptionalDateField(title: MassageContent.dateOfBirth, date: $answers.dateOfBirth)
            }
            AdaptiveRow {
                TextFieldRow(title: MassageContent.emergencyContact, text: $answers.emergencyContact,
                             capitalization: .words)
                DateFieldRow(title: MassageContent.serviceDate, date: $answers.serviceDate)
            }
            StaffField(title: MassageContent.therapist, name: $answers.therapist)
        }
    }

    private var serviceChoices: some View {
        VStack(alignment: .leading, spacing: 12) {
            FieldLabel(title: MassageContent.serviceType, required: true)
            PriceMenuView(groups: MassageContent.priceGroups, selection: $answers.prices)

            FieldLabel(title: MassageContent.oilLabel, required: answers.needsOil)
                .padding(.top, 12)
            ChoiceChips(options: MassageContent.oils, selection: $answers.oil, columns: 2)
            if answers.oil == "calming" {
                NoticeBanner(text: MassageContent.almondWarning, systemImage: "info.circle.fill", tint: .blue)
            }

            FieldLabel(title: MassageContent.pressureLabel, required: true)
                .padding(.top, 12)
            ChoiceChips(options: MassageContent.pressures, selection: $answers.pressureID, columns: 4)
        }
    }

    private var consent: some View {
        VStack(alignment: .leading, spacing: 8) {
            let agreements = MassageContent.agreements(businessName: businessName)
            ConsentBlock(
                statements: agreements.map(\.label),
                isOn: Binding(
                    get: { Set(agreements.map(\.id)).isSubset(of: answers.agreements) },
                    set: { answers.agreements = $0 ? Set(agreements.map(\.id)) : [] }
                )
            )
            SignaturePad(title: MassageContent.customerSignature, signature: $answers.customerSignature, required: true)
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
