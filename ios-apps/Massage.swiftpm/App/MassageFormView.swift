import SwiftUI

struct MassageFormView: View {
    let onSubmit: (MassageAnswers) -> Void

    @AppStorage(SettingsKey.businessName) private var businessName = ""
    @Environment(\.horizontalSizeClass) private var sizeClass
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

            FormSection(number: 4, title: MassageContent.healthTitle) { health }

            FormSection(number: 5, title: MassageContent.aftercareTitle) {
                BulletList(items: MassageContent.aftercare)
            }

            FormSection(number: 6, title: MassageContent.consentTitle) { consent }

            SubmitButton(title: MassageContent.submit, action: submit)
                .padding(.bottom, 40)
        }
        .onChange(of: answers.noConditions) { _, none in
            if none { answers.conditions.removeAll() }
        }
        .onChange(of: answers.conditions) { _, ticked in
            if !ticked.isEmpty { answers.noConditions = false }
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
            ChoiceChips(options: MassageContent.services, selection: $answers.serviceID, columns: 3)

            FieldLabel(title: MassageContent.durationLabel, required: true)
                .padding(.top, 12)
            ChoiceChips(options: MassageContent.durations, selection: $answers.durationID, columns: 4)

            FieldLabel(title: MassageContent.pressureLabel, required: true)
                .padding(.top, 12)
            ChoiceChips(options: MassageContent.pressures, selection: $answers.pressureID, columns: 4)
        }
    }

    private var health: some View {
        VStack(alignment: .leading, spacing: 8) {
            LText(MassageContent.healthPrompt, font: .headline)
                .padding(.bottom, 4)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: sizeClass == .compact ? 1 : 2), alignment: .leading, spacing: 4) {
                ForEach(MassageContent.conditions) { option in
                    CheckRow(text: option.label, isOn: $answers.conditions.contains(option.id))
                }
            }
            Divider().padding(.vertical, 4)
            CheckRow(text: MassageContent.noneApply, isOn: $answers.noConditions)

            if !answers.conditions.isEmpty {
                NoticeBanner(text: MassageContent.healthWarning)
                    .padding(.vertical, 8)
            }

            TextFieldRow(title: MassageContent.healthDetails, text: $answers.healthDetails, multiline: true)
                .padding(.top, 8)
            TextFieldRow(title: MassageContent.medications, text: $answers.medications, multiline: true)
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
