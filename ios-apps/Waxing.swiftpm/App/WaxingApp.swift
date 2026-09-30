import SwiftUI

@main
struct WaxingApp: App {
    @StateObject private var store = SubmissionStore<WaxingAnswers>()

    init() {
        SettingsKey.registerDefaults(businessName: WaxingContent.config.defaultBusinessName)
    }

    var body: some Scene {
        WindowGroup {
            KioskRoot(config: WaxingContent.config, store: store) { submit in
                WaxingFormView(onSubmit: submit)
            }
        }
    }
}
