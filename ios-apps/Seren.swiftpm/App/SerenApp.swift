import SwiftUI

/// All-in-one app: the customer chooses Brows & Lashes, Massage, Nails or Head Spa on the welcome screen.
/// The service forms are copied in from the single-service apps by `sync-shared.sh`.
@main
struct SerenApp: App {
    @StateObject private var brows = SubmissionStore<BrowAnswers>(folderName: "Submissions-BrowsLashes")
    @StateObject private var massage = SubmissionStore<MassageAnswers>(folderName: "Submissions-Massage")
    @StateObject private var nails = SubmissionStore<NailsAnswers>(folderName: "Submissions-Nails")
    @StateObject private var headSpa = SubmissionStore<HeadSpaAnswers>(folderName: "Submissions-HeadSpa")

    static let config = KioskConfig(
        formTitle: L("Vui lòng chọn dịch vụ", "Please choose your service"),
        symbol: "sparkles",
        defaultBusinessName: "Seren",
        exportPrefix: "Seren"
    )

    init() {
        SettingsKey.registerDefaults(businessName: Self.config.defaultBusinessName)
    }

    var body: some Scene {
        WindowGroup {
            KioskRoot(config: Self.config, services: [
                KioskService(config: SerenContent.config, store: brows) { BrowFormView(onSubmit: $0) },
                KioskService(config: MassageContent.config, store: massage) { MassageFormView(onSubmit: $0) },
                KioskService(config: NailsContent.config, store: nails) { NailsFormView(onSubmit: $0) },
                KioskService(config: HeadSpaContent.config, store: headSpa) { HeadSpaFormView(onSubmit: $0) },
            ])
        }
    }
}
