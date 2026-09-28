// Shared source — edit in ios-apps/Shared, then run ios-apps/sync-shared.sh.

import SwiftUI

/// Welcome → form → thank you → back to welcome, plus customer feedback and a PIN-protected staff area.
struct KioskRoot<A: FormAnswers, FormContent: View>: View {
    let config: KioskConfig
    @ObservedObject var store: SubmissionStore<A>
    let makeForm: (@escaping (A) -> Void) -> FormContent

    init(
        config: KioskConfig,
        store: SubmissionStore<A>,
        @ViewBuilder form: @escaping (@escaping (A) -> Void) -> FormContent
    ) {
        self.config = config
        self.store = store
        self.makeForm = form
    }

    private enum Screen { case welcome, form, thanks, feedback, feedbackThanks }

    @StateObject private var feedbackStore = FeedbackStore()
    @State private var screen: Screen = .welcome
    @State private var formID = UUID()
    @State private var showStaff = false
    @State private var confirmCancel = false
    @State private var saveError: String?
    @AppStorage(SettingsKey.businessName) private var businessName = ""
    @AppStorage(SettingsKey.languageMode) private var languageRaw = LanguageMode.both.rawValue

    private var language: LanguageMode { LanguageMode(rawValue: languageRaw) ?? .both }

    var body: some View {
        Group {
            switch screen {
            case .welcome:
                WelcomeScreen(
                    config: config,
                    businessName: businessName,
                    languageRaw: $languageRaw,
                    onStart: startForm,
                    onFeedback: { withAnimation { screen = .feedback } },
                    onStaff: { showStaff = true }
                )
                .transition(.opacity)

            case .form:
                NavigationStack {
                    makeForm(submit)
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
            StaffArea(config: config, store: store, feedbackStore: feedbackStore)
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

    private func startForm() {
        formID = UUID()
        withAnimation { screen = .form }
    }

    private func submit(_ answers: A) {
        do {
            try store.save(answers, businessName: businessName)
            withAnimation { screen = .thanks }
        } catch {
            saveError = error.localizedDescription
        }
    }
}

private struct WelcomeScreen: View {
    let config: KioskConfig
    let businessName: String
    @Binding var languageRaw: String
    let onStart: () -> Void
    let onFeedback: () -> Void
    let onStaff: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: config.symbol)
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(Color.accentColor)
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
            .padding(.top, 12)

            Button(action: onStart) {
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
            .padding(.top, 8)

            Button(action: onFeedback) {
                Label("Đánh giá dịch vụ / Leave feedback", systemImage: "star.bubble")
                    .font(.title3.weight(.medium))
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .overlay(Capsule().stroke(Color.accentColor, lineWidth: 1.5))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.accentColor)
            Spacer()
            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
