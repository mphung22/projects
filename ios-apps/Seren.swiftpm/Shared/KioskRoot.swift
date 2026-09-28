// Shared source — edit in ios-apps/Shared, then run ios-apps/sync-shared.sh.

import SwiftUI

/// One customer form the kiosk can offer, with its own records in the staff area.
struct KioskService: Identifiable {
    let id: String
    let config: KioskConfig
    /// Builds the form. Calls `onSaved` after the answers are saved, or `onError` with a message.
    let makeForm: (_ onSaved: @escaping () -> Void, _ onError: @escaping (String) -> Void) -> AnyView
    /// Builds this service's records screen for the staff area.
    let makeRecords: (_ feedback: FeedbackStore, _ switcher: AnyView?, _ onClose: @escaping () -> Void) -> AnyView

    init<A: FormAnswers, FormContent: View>(
        config: KioskConfig,
        store: SubmissionStore<A>,
        @ViewBuilder form: @escaping (@escaping (A) -> Void) -> FormContent
    ) {
        id = config.exportPrefix
        self.config = config
        makeForm = { onSaved, onError in
            AnyView(form { answers in
                let businessName = UserDefaults.standard.string(forKey: SettingsKey.businessName)
                    ?? config.defaultBusinessName
                do {
                    try store.save(answers, businessName: businessName)
                    onSaved()
                } catch {
                    onError(error.localizedDescription)
                }
            })
        }
        makeRecords = { feedback, switcher, onClose in
            AnyView(StaffDashboard(config: config, store: store, feedbackStore: feedback,
                                   switcher: switcher, onClose: onClose))
        }
    }
}

/// Welcome → form → thank you → back to welcome, plus customer feedback and a PIN-protected staff area.
/// With several services, the welcome screen lets the customer choose one.
struct KioskRoot: View {
    let config: KioskConfig
    let services: [KioskService]

    init(config: KioskConfig, services: [KioskService]) {
        self.config = config
        self.services = services
    }

    /// A kiosk with a single form.
    init<A: FormAnswers, FormContent: View>(
        config: KioskConfig,
        store: SubmissionStore<A>,
        @ViewBuilder form: @escaping (@escaping (A) -> Void) -> FormContent
    ) {
        self.init(config: config, services: [KioskService(config: config, store: store, form: form)])
    }

    private enum Screen { case welcome, form, thanks, feedback, feedbackThanks }

    @StateObject private var feedbackStore = FeedbackStore()
    @State private var screen: Screen = .welcome
    @State private var activeServiceID = ""
    @State private var formID = UUID()
    @State private var showStaff = false
    @State private var confirmCancel = false
    @State private var saveError: String?
    @AppStorage(SettingsKey.businessName) private var businessName = ""
    @AppStorage(SettingsKey.languageMode) private var languageRaw = LanguageMode.both.rawValue

    private var language: LanguageMode { LanguageMode(rawValue: languageRaw) ?? .both }

    private var activeService: KioskService? {
        services.first { $0.id == activeServiceID } ?? services.first
    }

    var body: some View {
        Group {
            switch screen {
            case .welcome:
                WelcomeScreen(
                    config: config,
                    services: services,
                    businessName: businessName,
                    languageRaw: $languageRaw,
                    onStart: startForm,
                    onFeedback: { withAnimation { screen = .feedback } },
                    onStaff: { showStaff = true }
                )
                .transition(.opacity)

            case .form:
                NavigationStack {
                    Group {
                        if let service = activeService {
                            service.makeForm(
                                { withAnimation { screen = .thanks } },
                                { saveError = $0 }
                            )
                        }
                    }
                    .id(formID)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(L("Huỷ", "Cancel").text(language)) { confirmCancel = true }
                        }
                        ToolbarItem(placement: .primaryAction) {
                            Menu {
                                LanguagePicker(raw: $languageRaw)
                            } label: {
                                Image(systemName: "globe")
                            }
                        }
                    }
                    .alert(
                        L("Quay lại trang chủ?", "Go back to the start?").text(language),
                        isPresented: $confirmCancel
                    ) {
                        Button(L("Về trang chủ", "Back to start").text(language), role: .destructive) {
                            goHome()
                        }
                        Button(L("Tiếp tục điền", "Keep filling in").text(language), role: .cancel) {}
                    } message: {
                        Text(L("Thông tin đã nhập sẽ bị xoá.", "Your answers will be cleared.").text(language))
                    }
                }
                .transition(.move(edge: .trailing))

            case .thanks:
                ThankYouScreen(onDone: goHome)
                    .transition(.opacity)
                    .task {
                        // Return to the welcome screen automatically for the next customer.
                        try? await Task.sleep(nanoseconds: 10_000_000_000)
                        if screen == .thanks { goHome() }
                    }

            case .feedback:
                NavigationStack {
                    FeedbackFormView(onSubmit: submitFeedback)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button(L("Huỷ", "Cancel").text(language), action: goHome)
                            }
                            ToolbarItem(placement: .primaryAction) {
                                Menu {
                                    LanguagePicker(raw: $languageRaw)
                                } label: {
                                    Image(systemName: "globe")
                                }
                            }
                        }
                }
                .transition(.move(edge: .trailing))

            case .feedbackThanks:
                FeedbackThanksScreen(onDone: goHome)
                    .transition(.opacity)
                    .task {
                        // Leave time to scan the Google review QR code.
                        try? await Task.sleep(nanoseconds: 60_000_000_000)
                        if screen == .feedbackThanks { goHome() }
                    }
            }
        }
        .environment(\.languageMode, language)
        .preferredColorScheme(.light)
        .fullScreenCover(isPresented: $showStaff) {
            StaffArea(services: services, feedbackStore: feedbackStore)
                .environment(\.languageMode, language)
                .preferredColorScheme(.light)
        }
        .alert(
            "Không lưu được / Could not save",
            isPresented: Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveError ?? "")
        }
    }

    private func goHome() {
        withAnimation { screen = .welcome }
    }

    private func submitFeedback(_ feedback: Feedback) {
        do {
            try feedbackStore.add(feedback)
            withAnimation { screen = .feedbackThanks }
        } catch {
            saveError = error.localizedDescription
        }
    }

    private func startForm(_ service: KioskService) {
        activeServiceID = service.id
        formID = UUID()
        withAnimation { screen = .form }
    }
}

private struct WelcomeScreen: View {
    let config: KioskConfig
    let services: [KioskService]
    let businessName: String
    @Binding var languageRaw: String
    let onStart: (KioskService) -> Void
    let onFeedback: () -> Void
    let onStaff: () -> Void

    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Image(systemName: config.symbol)
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(Color.accentColor)
                    .padding(.top, 40)
                Text(businessName)
                    .font(.system(size: 56, weight: .light, design: .serif))
                    .multilineTextAlignment(.center)
                VStack(spacing: 4) {
                    Text(config.formTitle.vi).font(.title2)
                    Text(config.formTitle.en).font(.title3).italic().foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)

                Picker("Ngôn ngữ / Language", selection: $languageRaw) {
                    ForEach(LanguageMode.allCases) { Text($0.label).tag($0.rawValue) }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 520)

                if services.count == 1, let only = services.first {
                    Button { onStart(only) } label: {
                        VStack(spacing: 2) {
                            Text("Bắt đầu").font(.title.weight(.semibold))
                            Text("Tap to start").font(.headline)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 80)
                        .padding(.vertical, 22)
                        .background(Capsule().fill(Color.accentColor))
                    }
                    .buttonStyle(.plain)
                } else {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: sizeClass == .compact ? 1 : 2),
                        spacing: 20
                    ) {
                        ForEach(services) { service in
                            ServiceCard(service: service) { onStart(service) }
                        }
                    }
                    .frame(maxWidth: 760)
                }

                Button(action: onFeedback) {
                    Label("Đánh giá dịch vụ / Leave feedback", systemImage: "star.bubble")
                        .font(.title3.weight(.medium))
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .overlay(Capsule().stroke(Color.accentColor, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
        }
        .background(Color.paper.ignoresSafeArea())
        .overlay(alignment: .bottomTrailing) {
            Button(action: onStaff) {
                Image(systemName: "lock.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .padding(20)
            }
            .accessibilityLabel("Staff area")
        }
    }
}

private struct ServiceCard: View {
    let service: KioskService
    let action: () -> Void

    var body: some View {
        let name = service.config.shortName ?? service.config.formTitle
        Button(action: action) {
            HStack(spacing: 18) {
                Image(systemName: service.config.symbol)
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(.white)
                    .frame(width: 68, height: 68)
                    .background(Circle().fill(Color.accentColor))
                VStack(alignment: .leading, spacing: 2) {
                    Text(name.vi).font(.title2.weight(.semibold))
                    if name.en != name.vi {
                        Text(name.en).font(.headline).italic().foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.black.opacity(0.07), lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }
}

private struct ThankYouScreen: View {
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 96))
                .foregroundStyle(Color.accentColor)
            Text("Cảm ơn quý khách!").font(.system(size: 44, weight: .semibold, design: .serif))
            Text("Thank you!").font(.title).italic().foregroundStyle(.secondary)
            VStack(spacing: 4) {
                Text("Vui lòng đưa iPad lại cho nhân viên.")
                Text("Please hand the iPad back to our staff.").italic().foregroundStyle(.secondary)
            }
            .font(.title3)
            .multilineTextAlignment(.center)
            Button("Xong / Done", action: onDone)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, 12)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.paper.ignoresSafeArea())
    }
}
