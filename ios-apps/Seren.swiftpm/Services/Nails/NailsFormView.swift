import SwiftUI

struct NailsFormView: View {
    let onSubmit: (NailsAnswers) -> Void

    @AppStorage(SettingsKey.businessName) private var businessName = ""
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var answers = NailsAnswers()
    @State private var missing: [L] = []

    var body: some View {
        FormPage(title: NailsContent.serviceName, missing: $missing) {
            header

            FormSection(number: 1, title: NailsContent.infoTitle) { infoFields }

            FormSection(number: 2, title: NailsContent.servicesTitle) { serviceChoices }

            FormSection(number: 3, title: NailsContent.healthTitle) { health }

            FormSection(number: 4, title: NailsContent.infoCareTitle) {
                InfoGroupList(groups: [NailsContent.goodToKnow, NailsContent.aftercare])
            }

            FormSection(number: 5, title: NailsContent.ackTitle) { acknowledgement }

            FormSection(number: 6, title: NailsContent.signTitle) { signatures }

            SubmitButton(title: NailsContent.submit, action: submit)
                .padding(.bottom, 40)
        }
        .onChange(of: answers.noConditions) { _, none in
            if none { answers.conditions.removeAll() }
        }
        .onChange(of: answers.conditions) { _, ticked in
            if !ticked.isEmpty { answers.noConditions = false }
            // The health statement changes wording, so ask again.
            answers.ackHealth = false
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text(businessName).font(.system(size: 34, weight: .light, design: .serif))
            LText(NailsContent.documentTitle, font: .headline)
            LText(NailsContent.intro, font: .callout)
                .padding(.top, 6)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    private var infoFields: some View {
        VStack(alignment: .leading, spacing: 18) {
            AdaptiveRow {
                TextFieldRow(title: NailsContent.fullName, text: $answers.fullName, required: true,
                             contentType: .name, capitalization: .words)
                TextFieldRow(title: NailsContent.phone, text: $answers.phone, required: true,
                             keyboard: .phonePad, contentType: .telephoneNumber)
            }
            AdaptiveRow {
                OptionalDateField(title: NailsContent.dateOfBirth, date: $answers.dateOfBirth)
                DateFieldRow(title: NailsContent.serviceDate, date: $answers.serviceDate)
            }
            StaffField(title: NailsContent.technician, name: $answers.technician)
        }
    }

    private var serviceChoices: some View {
        VStack(alignment: .leading, spacing: 12) {
            FieldLabel(title: NailsContent.servicesLabel, required: true)
            MultiChips(options: NailsContent.services, selection: $answers.services, columns: 3)

            FieldLabel(title: NailsContent.shapeLabel)
                .padding(.top, 12)
            ChoiceChips(options: NailsContent.shapes, selection: $answers.shapeID, columns: 3)

            TextFieldRow(title: NailsContent.notesLabel, text: $answers.designNotes, multiline: true)
                .padding(.top, 12)
        }
    }

    private var health: some View {
        VStack(alignment: .leading, spacing: 8) {
            LText(NailsContent.healthPrompt, font: .headline)
                .padding(.bottom, 4)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: sizeClass == .compact ? 1 : 2), alignment: .leading, spacing: 4) {
                ForEach(NailsContent.conditions) { option in
                    CheckRow(text: option.label, isOn: $answers.conditions.contains(option.id))
                }
            }
            Divider().padding(.vertical, 4)
            CheckRow(text: NailsContent.noneApply, isOn: $answers.noConditions)

            if !answers.conditions.isEmpty {
                NoticeBanner(text: NailsContent.healthWarning)
                    .padding(.vertical, 8)
            }

            TextFieldRow(title: NailsContent.healthDetails, text: $answers.healthDetails, multiline: true)
                .padding(.top, 8)
        }
    }

    private var acknowledgement: some View {
        VStack(alignment: .leading, spacing: 8) {
            CheckRow(text: NailsContent.ackInformed, isOn: $answers.ackInformed)
            CheckRow(text: answers.healthAckText, isOn: $answers.ackHealth)
            CheckRow(text: NailsContent.ackRisk, isOn: $answers.ackRisk)
            FieldLabel(title: NailsContent.photoQuestion, required: true)
                .padding(.top, 12)
            ChoiceChips(options: NailsContent.photoOptions, selection: $answers.photoConsent)
        }
    }

    private var signatures: some View {
        VStack(alignment: .leading, spacing: 24) {
            SignaturePad(title: NailsContent.customerSignature, signature: $answers.customerSignature, required: true)
            Text("Ngày / Date: \(Formatters.date.string(from: Date()))")
                .foregroundStyle(.secondary)
            SignaturePad(title: NailsContent.technicianSignature, signature: $answers.technicianSignature)
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
        cleaned.designNotes = cleaned.designNotes.trimmed
        onSubmit(cleaned)
    }
}
