import SwiftUI

struct NailsFormView: View {
    let onSubmit: (NailsAnswers) -> Void

    @AppStorage(SettingsKey.businessName) private var businessName = ""
    @State private var answers = NailsAnswers()
    @State private var missing: [L] = []

    var body: some View {
        FormPage(title: NailsContent.serviceName, missing: $missing) {
            header

            FormSection(number: 1, title: NailsContent.infoTitle) { infoFields }

            FormSection(number: 2, title: NailsContent.servicesTitle) { serviceChoices }

            FormSection(number: 3, title: NailsContent.infoCareTitle) {
                InfoGroupList(groups: [NailsContent.goodToKnow, NailsContent.aftercare])
            }

            FormSection(number: 4, title: NailsContent.ackTitle) { acknowledgement }

            FormSection(number: 5, title: PriceText.summaryTitle) {
                PriceSummaryView(groups: NailsContent.priceGroups, selection: answers.prices)
            }

            SubmitButton(title: NailsContent.submit, action: submit)
                .padding(.bottom, 40)
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
                TextFieldRow(title: NailsContent.phone, text: $answers.phone,
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
            PriceMenuView(groups: NailsContent.priceGroups, selection: $answers.prices)

            FieldLabel(title: NailsContent.shapeLabel)
                .padding(.top, 12)
            ChoiceChips(options: NailsContent.shapes, selection: $answers.shapeID, columns: 3)

            TextFieldRow(title: NailsContent.notesLabel, text: $answers.designNotes, multiline: true)
                .padding(.top, 12)
        }
    }

    private var acknowledgement: some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabel(title: NailsContent.photoQuestion, required: true)
            ChoiceChips(options: NailsContent.photoOptions, selection: $answers.photoConsent)
            ConsentBlock(
                statements: [NailsContent.ackInformed, NailsContent.ackRisk],
                isOn: Binding(
                    get: { answers.ackInformed && answers.ackRisk },
                    set: { answers.ackInformed = $0; answers.ackRisk = $0 }
                )
            )
            .padding(.top, 16)
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
