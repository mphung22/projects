import SwiftUI

@main
struct SerenConsentApp: App {
    @StateObject private var store = SubmissionStore<BrowAnswers>()

    init() {
        SettingsKey.registerDefaults(businessName: SerenContent.config.defaultBusinessName)
    }

    var body: some Scene {
        WindowGroup {
            KioskRoot(config: SerenContent.config, store: store) { submit in
                BrowFormView(onSubmit: submit)
            }
        }
    }
}
