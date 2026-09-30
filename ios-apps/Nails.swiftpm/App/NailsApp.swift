import SwiftUI

@main
struct NailsApp: App {
    @StateObject private var store = SubmissionStore<NailsAnswers>()

    init() {
        SettingsKey.registerDefaults(businessName: NailsContent.config.defaultBusinessName)
    }

    var body: some Scene {
        WindowGroup {
            KioskRoot(config: NailsContent.config, store: store) { submit in
                NailsFormView(onSubmit: submit)
            }
        }
    }
}
