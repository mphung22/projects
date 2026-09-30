// Shared source — edit in ios-apps/Shared, then run ios-apps/sync-shared.sh.

import CoreImage.CIFilterBuiltins
import SwiftUI

// MARK: - Model & storage

struct Feedback: Codable, Identifiable {
    var id = UUID()
    var createdAt = Date()
    var rating = 0
    var comment = ""
    var name = ""
    var phone = ""
    var staff = ""
}

/// Customer feedback, saved on the iPad in Documents/Feedback/feedback.json.
final class FeedbackStore: ObservableObject {
    @Published private(set) var items: [Feedback] = []

    private let fileURL: URL

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let directory = documents.appendingPathComponent("Feedback", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("feedback.json")
        load()
    }

    var averageRating: Double? {
        items.isEmpty ? nil : Double(items.map(\.rating).reduce(0, +)) / Double(items.count)
    }

    func add(_ feedback: Feedback) throws {
        items.insert(feedback, at: 0)
        try persist()
    }

    func delete(_ feedback: Feedback) {
        items.removeAll { $0.id == feedback.id }
        try? persist()
    }

    func exportCSV(prefix: String) throws -> URL {
        var lines = [csvLine(["Date", "Rating", "Name", "Phone", "Staff", "Comment"])]
        for item in items {
            lines.append(csvLine([
                Formatters.dateTime.string(from: item.createdAt), String(item.rating),
                item.name, item.phone, item.staff, item.comment,
            ]))
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(prefix) Feedback \(Formatters.isoDay.string(from: Date())).csv")
        try ("\u{FEFF}" + lines.joined(separator: "\r\n")).write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        items = (try? decoder.decode([Feedback].self, from: data)) ?? []
    }

    private func persist() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted]
        try encoder.encode(items).write(to: fileURL, options: [.atomic, .completeFileProtection])
    }

    private func csvLine(_ fields: [String]) -> String {
        fields.map { "\"" + $0.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }.joined(separator: ",")
    }
}

/// The Google review link from Settings, if it is a valid web address.
func googleReviewURL(_ raw: String) -> URL? {
    guard let url = URL(string: raw.trimmed), let scheme = url.scheme?.lowercased(),
          scheme == "https" || scheme == "http", url.host != nil else { return nil }
    return url
}

// MARK: - Customer screens

struct StarRating: View {
    @Binding var rating: Int
    var size: CGFloat = 52

    var body: some View {
        HStack(spacing: 14) {
            ForEach(1...5, id: \.self) { star in
                Button {
                    rating = star
                } label: {
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .font(.system(size: size))
                        .foregroundStyle(star <= rating ? Color.orange : Color.secondary.opacity(0.5))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(star) star")
            }
        }
    }
}

struct FeedbackFormView: View {
    let onSubmit: (Feedback) -> Void
    @State private var feedback = Feedback()
    @State private var missing: [L] = []

    var body: some View {
        FormPage(title: L("Đánh giá dịch vụ", "Feedback"), missing: $missing) {
            VStack(spacing: 8) {
                LText(L("Bạn cảm thấy thế nào về dịch vụ hôm nay?", "How was your experience today?"),
                      font: .title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                StarRating(rating: $feedback.rating)
                    .padding(.vertical, 16)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))

            VStack(alignment: .leading, spacing: 18) {
                TextFieldRow(title: L("Góp ý của bạn (không bắt buộc)", "Your comments (optional)"),
                             text: $feedback.comment, multiline: true)
                StaffField(title: L("Kỹ thuật viên phục vụ bạn", "Who looked after you?"), name: $feedback.staff)
                AdaptiveRow {
                    TextFieldRow(title: L("Họ Tên (không bắt buộc)", "Name (optional)"), text: $feedback.name,
                                 contentType: .name, capitalization: .words)
                    TextFieldRow(title: L("Số Điện Thoại (không bắt buộc)", "Phone (optional)"), text: $feedback.phone,
                                 keyboard: .phonePad, contentType: .telephoneNumber)
                }
            }
            .padding(24)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))

            SubmitButton(title: L("Gửi đánh giá", "Send feedback")) {
                guard feedback.rating > 0 else {
                    missing = [L("Chọn số sao", "Choose a star rating")]
                    return
                }
                var cleaned = feedback
                cleaned.createdAt = Date()
                cleaned.comment = cleaned.comment.trimmed
                cleaned.name = cleaned.name.trimmed
                cleaned.phone = cleaned.phone.trimmed
                onSubmit(cleaned)
            }
            .padding(.bottom, 40)
        }
    }
}

/// Thanks the customer and invites them to leave a Google review.
/// Shown after every rating, so all customers are invited equally, as Google's review policy requires.
struct FeedbackThanksScreen: View {
    let onDone: () -> Void
    @Environment(\.languageMode) private var mode
    @AppStorage(SettingsKey.googleReviewURL) private var reviewLink = SettingsKey.defaultGoogleReviewURL

    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "heart.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.accentColor)
            LHeading(l: L("Cảm ơn quý khách!", "Thank you for your feedback!"),
                     font: .system(size: 40, weight: .semibold, design: .serif), secondaryFont: .title2)

            if let url = googleReviewURL(reviewLink) {
                VStack(spacing: 14) {
                    LHeading(l: L("Quét mã để đánh giá chúng tôi trên Google", "Scan with your phone camera to review us on Google"),
                             font: .title3.weight(.semibold), secondaryFont: .body)
                    QRCodeView(text: url.absoluteString)
                        .frame(width: 260, height: 260)
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                    HStack(spacing: 4) {
                        ForEach(0..<5, id: \.self) { _ in Image(systemName: "star.fill").foregroundStyle(.orange) }
                        Text("Google").font(.headline).padding(.leading, 6)
                    }
                }
                .padding(.top, 8)
            }

            Button(L("Xong", "Done").text(mode), action: onDone)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, 12)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.paper.ignoresSafeArea())
    }
}

struct QRCodeView: View {
    let text: String

    var body: some View {
        if let image = Self.makeImage(text) {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .accessibilityLabel("QR code")
        }
    }

    static func makeImage(_ text: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 12, y: 12)),
              let cgImage = CIContext().createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Staff screen

struct FeedbackListView: View {
    let exportPrefix: String
    @ObservedObject var store: FeedbackStore
    @Environment(\.dismiss) private var dismiss
    @State private var shareURL: URL?
    @State private var exportError: String?

    var body: some View {
        NavigationStack {
            List {
                if let average = store.averageRating {
                    Section {
                        HStack {
                            Image(systemName: "star.fill").foregroundStyle(.orange)
                            Text(String(format: "%.1f / 5", average)).font(.title2.weight(.semibold))
                            Text("· \(store.items.count) đánh giá / reviews").foregroundStyle(.secondary)
                        }
                    }
                }
                Section {
                    ForEach(store.items) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= item.rating ? "star.fill" : "star")
                                        .foregroundStyle(star <= item.rating ? Color.orange : Color.secondary.opacity(0.4))
                                }
                                Spacer()
                                Text(Formatters.dateTime.string(from: item.createdAt))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            if !item.comment.isEmpty { Text(item.comment) }
                            let who = [item.name, item.phone, item.staff.isEmpty ? "" : "KTV/Staff: \(item.staff)"]
                                .filter { !$0.isEmpty }.joined(separator: " · ")
                            if !who.isEmpty {
                                Text(who).font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { offsets in
                        offsets.map { store.items[$0] }.forEach(store.delete)
                    }
                }
            }
            .overlay {
                if store.items.isEmpty {
                    ContentUnavailableView("Chưa có đánh giá / No feedback yet", systemImage: "star")
                }
            }
            .navigationTitle("Phản hồi / Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng / Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        do {
                            shareURL = try store.exportCSV(prefix: exportPrefix)
                        } catch {
                            exportError = error.localizedDescription
                        }
                    } label: {
                        Label("Xuất CSV / Export CSV", systemImage: "square.and.arrow.up")
                    }
                    .disabled(store.items.isEmpty)
                }
            }
            .sheet(isPresented: Binding(get: { shareURL != nil }, set: { if !$0 { shareURL = nil } })) {
                if let shareURL { ActivityView(items: [shareURL]) }
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
    }
}
