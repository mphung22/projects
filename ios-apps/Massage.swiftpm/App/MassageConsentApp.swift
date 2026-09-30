import SwiftUI

@main
struct MassageConsentApp: App {
    @StateObject private var store = SubmissionStore<MassageAnswers>()

    init() {
        SettingsKey.registerDefaults(businessName: MassageContent.config.defaultBusinessName)
    }

    var body: some Scene {
        WindowGroup {
            KioskRoot(config: MassageContent.config, store: store) { submit in
                MassageFormView(onSubmit: submit)
            }
        }
    }
}
