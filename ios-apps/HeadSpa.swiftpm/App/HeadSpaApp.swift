import SwiftUI

@main
struct HeadSpaApp: App {
    @StateObject private var store = SubmissionStore<HeadSpaAnswers>()

    init() {
        SettingsKey.registerDefaults(businessName: HeadSpaContent.config.defaultBusinessName)
    }

    var body: some Scene {
        WindowGroup {
            KioskRoot(config: HeadSpaContent.config, store: store) { submit in
                HeadSpaFormView(onSubmit: submit)
            }
        }
    }
}
