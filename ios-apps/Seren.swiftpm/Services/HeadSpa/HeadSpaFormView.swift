import SwiftUI

struct HeadSpaFormView: View {
    let onSubmit: (HeadSpaAnswers) -> Void

    @AppStorage(SettingsKey.businessName) private var businessName = ""
    @Environment(\.horizontalSizeClass) private var sizeClass
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

            FormSection(number: 4, title: HeadSpaContent.healthTitle) { health }

            FormSection(number: 5, title: HeadSpaContent.aftercareTitle) {
                BulletList(items: HeadSpaContent.aftercare)
            }

            FormSection(number: 6, title: HeadSpaContent.consentTitle) { consent }

            SubmitButton(title: HeadSpaContent.submit, action: submit)
                .padding(.bottom, 40)
        }
        .onChange(of: answers.noConditions) { _, none in
            if none { answers.conditions.removeAll() }
        }
        .onChange(of: answers.conditions) { _, ticked in
            if !ticked.isEmpty { answers.noConditions = false }
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
            ChoiceChips(options: HeadSpaContent.services, selection: $answers.serviceID, columns: 3)

            FieldLabel(title: HeadSpaContent.durationLabel, required: true)
                .padding(.top, 12)
            ChoiceChips(options: HeadSpaContent.durations, selection: $answers.durationID, columns: 4)

            FieldLabel(title: HeadSpaContent.pressureLabel, required: true)
                .padding(.top, 12)
            ChoiceChips(options: HeadSpaContent.pressures, selection: $answers.pressureID, columns: 4)
        }
    }

    private var health: some View {
        VStack(alignment: .leading, spacing: 8) {
            LText(HeadSpaContent.healthPrompt, font: .headline)
                .padding(.bottom, 4)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: sizeClass == .compact ? 1 : 2), alignment: .leading, spacing: 4) {
                ForEach(HeadSpaContent.conditions) { option in
                    CheckRow(text: option.label, isOn: $answers.conditions.contains(option.id))
                }
            }
            Divider().padding(.vertical, 4)
            CheckRow(text: HeadSpaContent.noneApply, isOn: $answers.noConditions)

            if !answers.conditions.isEmpty {
                NoticeBanner(text: HeadSpaContent.healthWarning)
                    .padding(.vertical, 8)
            }

            TextFieldRow(title: HeadSpaContent.healthDetails, text: $answers.healthDetails, multiline: true)
                .padding(.top, 8)
            TextFieldRow(title: HeadSpaContent.medications, text: $answers.medications, multiline: true)
        }
    }

    private var consent: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(HeadSpaContent.agreements(businessName: businessName)) { option in
                CheckRow(text: option.label, isOn: $answers.agreements.contains(option.id))
            }
            SignaturePad(title: HeadSpaContent.customerSignature, signature: $answers.customerSignature, required: true)
                .padding(.top, 20)
            Text("Ngày / Date: \(Formatters.date.string(from: Date()))")
                .foregroundStyle(.secondary)
            SignaturePad(title: HeadSpaContent.therapistSignature, signature: $answers.therapistSignature)
                .padding(.top, 20)
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
