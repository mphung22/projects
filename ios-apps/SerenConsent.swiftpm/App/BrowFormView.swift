import SwiftUI

struct BrowFormView: View {
    let onSubmit: (BrowAnswers) -> Void

    @AppStorage(SettingsKey.businessName) private var businessName = ""
    @State private var answers = BrowAnswers()
    @State private var missing: [L] = []

    var body: some View {
        FormPage(title: SerenContent.serviceName, missing: $missing) {
            header

            FormSection(number: 1, title: SerenContent.infoTitle) { infoFields }

            FormSection(number: 2, title: SerenContent.detailsTitle) {
                BulletList(items: SerenContent.details)
            }

            FormSection(number: 3, title: SerenContent.contraTitle) { contraindications }

            FormSection(number: 4, title: SerenContent.aftercareTitle) {
                BulletList(items: SerenContent.aftercare)
            }

            FormSection(number: 5, title: SerenContent.ackTitle) { acknowledgement }

            FormSection(number: 6, title: SerenContent.signTitle) { signatures }

            SubmitButton(title: SerenContent.submit, action: submit)
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
            LText(SerenContent.documentTitle, font: .headline)
            LText(SerenContent.intro, font: .callout)
                .padding(.top, 6)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    private var infoFields: some View {
        VStack(alignment: .leading, spacing: 18) {
            Grid(horizontalSpacing: 20, verticalSpacing: 18) {
                GridRow {
                    TextFieldRow(title: SerenContent.fullName, text: $answers.fullName, required: true,
                                 contentType: .name, capitalization: .words)
                    TextFieldRow(title: SerenContent.phone, text: $answers.phone, required: true,
                                 keyboard: .phonePad, contentType: .telephoneNumber)
                }
                GridRow {
                    OptionalDateField(title: SerenContent.dateOfBirth, date: $answers.dateOfBirth, required: true)
                    TextFieldRow(title: SerenContent.idNumber, text: $answers.idNumber,
                                 capitalization: .characters)
                }
                GridRow {
                    DateFieldRow(title: SerenContent.serviceDate, date: $answers.serviceDate)
                    StaffField(title: SerenContent.technician, name: $answers.technician)
                }
            }
            FieldLabel(title: SerenContent.registeredService, required: true)
            ChoiceChips(options: SerenContent.services, selection: $answers.serviceID, columns: 3)
        }
    }

    private var contraindications: some View {
        VStack(alignment: .leading, spacing: 8) {
            LText(SerenContent.contraPrompt, font: .headline)
                .padding(.bottom, 4)
            ForEach(SerenContent.contraindications) { option in
                CheckRow(text: option.label, isOn: $answers.contraindications.contains(option.id))
            }
            Divider().padding(.vertical, 4)
            CheckRow(text: SerenContent.noneApply, isOn: $answers.noContraindications)

            if !answers.contraindications.isEmpty {
                NoticeBanner(text: SerenContent.contraWarning)
                    .padding(.top, 8)
            }
            NoticeBanner(text: SerenContent.patchTestNote, systemImage: "info.circle.fill", tint: .blue)
                .padding(.top, 8)
        }
    }

    private var acknowledgement: some View {
        VStack(alignment: .leading, spacing: 8) {
            CheckRow(text: SerenContent.ackInformed, isOn: $answers.ackInformed)
            CheckRow(text: answers.healthAckText, isOn: $answers.ackHealth)
            FieldLabel(title: SerenContent.photoQuestion, required: true)
                .padding(.top, 12)
            ChoiceChips(options: SerenContent.photoOptions, selection: $answers.photoConsent)
        }
    }

    private var signatures: some View {
        VStack(alignment: .leading, spacing: 24) {
            SignaturePad(title: SerenContent.customerSignature, signature: $answers.customerSignature, required: true)
            Text("Ngày / Date: \(Formatters.date.string(from: Date()))")
                .foregroundStyle(.secondary)
            SignaturePad(title: SerenContent.technicianSignature, signature: $answers.technicianSignature)
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
        cleaned.idNumber = cleaned.idNumber.trimmed
        onSubmit(cleaned)
    }
}
