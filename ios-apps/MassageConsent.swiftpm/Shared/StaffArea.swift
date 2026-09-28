// Shared source — edit in ios-apps/Shared, then run ios-apps/sync-shared.sh.

import SwiftUI

struct StaffArea<A: FormAnswers>: View {
    let config: KioskConfig
    @ObservedObject var store: SubmissionStore<A>
    @ObservedObject var feedbackStore: FeedbackStore
    @Environment(\.dismiss) private var dismiss
    @State private var unlocked = false

    var body: some View {
        if unlocked {
            StaffDashboard(config: config, store: store, feedbackStore: feedbackStore, onClose: { dismiss() })
        } else {
            PINGate(onUnlock: { unlocked = true }, onCancel: { dismiss() })
        }
    }
}

// MARK: - PIN

private struct PINGate: View {
    @AppStorage(SettingsKey.staffPIN) private var pin = SettingsKey.defaultPIN
    @State private var entry = ""
    @State private var wrong = false
    let onUnlock: () -> Void
    let onCancel: () -> Void

    private let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "⌫"]

    var body: some View {
        VStack(spacing: 28) {
            Image(systemName: "lock.fill").font(.system(size: 44)).foregroundStyle(Color.accentColor)
            VStack(spacing: 4) {
                Text("Khu vực nhân viên").font(.title.weight(.semibold))
                Text("Staff only — enter PIN").foregroundStyle(.secondary)
            }
            HStack(spacing: 16) {
                ForEach(0..<max(pin.count, 4), id: \.self) { index in
                    Circle()
                        .fill(index < entry.count ? Color.accentColor : Color.secondary.opacity(0.25))
                        .frame(width: 16, height: 16)
                }
            }
            Text(wrong ? "Sai mã PIN / Wrong PIN" : " ")
                .foregroundStyle(.red)

            LazyVGrid(columns: Array(repeating: GridItem(.fixed(96), spacing: 20), count: 3), spacing: 20) {
                ForEach(keys, id: \.self) { key in
                    if key.isEmpty {
                        Color.clear.frame(width: 84, height: 84)
                    } else {
                        Button { tap(key) } label: {
                            Text(key)
                                .font(.system(size: 32, weight: .medium))
                                .frame(width: 84, height: 84)
                                .background(Circle().fill(Color(.secondarySystemBackground)))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(width: 340)

            Button("Huỷ / Cancel", action: onCancel)
                .font(.title3)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.paper.ignoresSafeArea())
    }

    private func tap(_ key: String) {
        wrong = false
        if key == "⌫" {
            if !entry.isEmpty { entry.removeLast() }
            return
        }
        entry += key
        if entry.count >= pin.count {
            if entry == pin {
                onUnlock()
            } else {
                wrong = true
            }
            entry = ""
        }
    }
}

// MARK: - Records

private struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

private struct StaffDashboard<A: FormAnswers>: View {
    let config: KioskConfig
    @ObservedObject var store: SubmissionStore<A>
    @ObservedObject var feedbackStore: FeedbackStore
    let onClose: () -> Void

    @State private var search = ""
    @State private var selection: UUID?
    @State private var showSettings = false
    @State private var showFeedback = false
    @State private var shareItem: ShareItem?
    @State private var exportError: String?

    private var filtered: [Submission<A>] {
        let query = search.trimmed
        guard !query.isEmpty else { return store.submissions }
        return store.submissions.filter {
            $0.answers.customerName.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
                || $0.answers.customerPhone.contains(query)
        }
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(filtered) { submission in
                    SubmissionRow(submission: submission).tag(submission.id)
                }
                .onDelete { offsets in
                    let items = offsets.map { filtered[$0] }
                    items.forEach(store.delete)
                    if let selected = selection, items.contains(where: { $0.id == selected }) { selection = nil }
                }
            }
            .overlay {
                if filtered.isEmpty {
                    ContentUnavailableView("Chưa có hồ sơ / No records", systemImage: "tray")
                }
            }
            .searchable(text: $search, prompt: "Tên hoặc SĐT / Name or phone")
            .navigationTitle("Hồ sơ / Records (\(store.submissions.count))")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng / Close", action: onClose)
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            exportCSV()
                        } label: {
                            Label("Xuất Excel (CSV) / Export CSV", systemImage: "tablecells")
                        }
                        .disabled(store.submissions.isEmpty)
                        Button {
                            showFeedback = true
                        } label: {
                            Label("Phản hồi khách hàng / Feedback (\(feedbackStore.items.count))", systemImage: "star.bubble")
                        }
                        Button {
                            showSettings = true
                        } label: {
                            Label("Cài đặt / Settings", systemImage: "gearshape")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        } detail: {
            if let id = selection, let submission = store.submissions.first(where: { $0.id == id }) {
                SubmissionDetail(submission: submission, url: store.pdfURL(for: submission)) {
                    store.delete(submission)
                    selection = nil
                }
            } else {
                ContentUnavailableView("Chọn một hồ sơ / Select a record", systemImage: "doc.text.magnifyingglass")
            }
        }
        .sheet(item: $shareItem) { item in
            ActivityView(items: [item.url])
        }
        .sheet(isPresented: $showSettings) {
            StaffSettingsView()
        }
        .sheet(isPresented: $showFeedback) {
            FeedbackListView(exportPrefix: config.exportPrefix, store: feedbackStore)
        }
        .alert(
            "Lỗi / Error",
            isPresented: Binding(get: { exportError != nil }, set: { if !$0 { exportError = nil } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportError ?? "")
        }
    }

    private func exportCSV() {
        do {
            shareItem = ShareItem(url: try store.exportCSV(prefix: config.exportPrefix))
        } catch {
            exportError = error.localizedDescription
        }
    }
}

private struct SubmissionRow<A: FormAnswers>: View {
    let submission: Submission<A>

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(submission.answers.customerName).font(.headline)
                if submission.answers.healthAlert != nil {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                }
            }
            Text(submission.answers.customerPhone).font(.subheadline)
            Text("\(Formatters.dateTime.string(from: submission.createdAt)) · \(submission.answers.serviceSummary)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 4)
    }
}

private struct SubmissionDetail<A: FormAnswers>: View {
    let submission: Submission<A>
    let url: URL
    let onDelete: () -> Void
    @State private var confirmDelete = false

    var body: some View {
        VStack(spacing: 0) {
            if let alert = submission.answers.healthAlert {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                    Text(alert).font(.subheadline)
                    Spacer(minLength: 0)
                }
                .padding()
                .background(Color.orange.opacity(0.12))
            }
            PDFKitView(url: url)
        }
        .navigationTitle(submission.answers.customerName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                ShareLink(item: url) {
                    Label("Chia sẻ / Share", systemImage: "square.and.arrow.up")
                }
                Button {
                    Printer.printFile(at: url, jobName: submission.pdfFileName)
                } label: {
                    Label("In / Print", systemImage: "printer")
                }
                Button(role: .destructive) {
                    confirmDelete = true
                } label: {
                    Label("Xoá / Delete", systemImage: "trash")
                }
            }
        }
        .confirmationDialog("Xoá hồ sơ này? / Delete this record?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Xoá / Delete", role: .destructive, action: onDelete)
        }
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

// MARK: - Settings

private struct StaffSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKey.businessName) private var businessName = ""
    @AppStorage(SettingsKey.staffNames) private var staffNames = ""
    @AppStorage(SettingsKey.staffPIN) private var pin = SettingsKey.defaultPIN
    @AppStorage(SettingsKey.googleReviewURL) private var reviewLink = ""
    @State private var newPIN = ""
    @State private var confirmPIN = ""
    @State private var pinMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Tên cơ sở / Business name") {
                    TextField("Business name", text: $businessName)
                }

                Section {
                    TextField("https://g.page/r/…", text: $reviewLink)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    if !reviewLink.trimmed.isEmpty && googleReviewURL(reviewLink) == nil {
                        Text("Link không hợp lệ — phải bắt đầu bằng https:// / Invalid link — must start with https://")
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("Link đánh giá Google / Google review link")
                } footer: {
                    Text("Google Business Profile › Ask for reviews / Get more reviews › copy the link. Khách sẽ thấy mã QR sau khi đánh giá. / Customers see it as a QR code after leaving feedback.")
                }

                Section {
                    TextEditor(text: $staffNames)
                        .frame(minHeight: 140)
                } header: {
                    Text("Nhân viên / Staff")
                } footer: {
                    Text("Mỗi dòng một tên. Khách sẽ chọn từ danh sách này. / One name per line; customers pick from this list.")
                }

                Section {
                    SecureField("PIN mới / New PIN (4–8 số / digits)", text: $newPIN)
                        .keyboardType(.numberPad)
                    SecureField("Nhập lại / Confirm PIN", text: $confirmPIN)
                        .keyboardType(.numberPad)
                    Button("Lưu PIN / Save PIN", action: savePIN)
                    if let pinMessage {
                        Text(pinMessage).font(.footnote)
                    }
                } header: {
                    Text("Mã PIN nhân viên / Staff PIN")
                } footer: {
                    if pin == SettingsKey.defaultPIN {
                        Text("⚠︎ Bạn đang dùng PIN mặc định 1234 — hãy đổi ngay. / You are using the default PIN 1234 — please change it.")
                            .foregroundStyle(.red)
                    }
                }

                Section("Mẹo / Tips") {
                    Text("Khoá iPad vào ứng dụng này: Cài đặt › Trợ năng › Truy cập được hướng dẫn. / Lock the iPad to this app with Settings › Accessibility › Guided Access.")
                    Text("Hồ sơ chỉ lưu trên iPad này. Xuất CSV/PDF định kỳ để sao lưu. / Records are stored only on this iPad. Export CSV/PDFs regularly as a backup.")
                }
                .font(.footnote)
            }
            .navigationTitle("Cài đặt / Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Xong / Done") { dismiss() }
                }
            }
        }
    }

    private func savePIN() {
        guard (4...8).contains(newPIN.count), newPIN.allSatisfy(\.isNumber) else {
            pinMessage = "PIN phải có 4–8 chữ số / PIN must be 4–8 digits"
            return
        }
        guard newPIN == confirmPIN else {
            pinMessage = "PIN không khớp / PINs do not match"
            return
        }
        pin = newPIN
        newPIN = ""
        confirmPIN = ""
        pinMessage = "✓ Đã lưu PIN / PIN saved"
    }
}
