// Shared source — edit in ios-apps/Shared, then run ios-apps/sync-shared.sh.

import Foundation

/// What each app's form answers must provide so the shared store and staff area can use them.
protocol FormAnswers: Codable {
    var customerName: String { get }
    var customerPhone: String { get }
    var serviceSummary: String { get }
    /// Health items the customer flagged, for staff to review. `nil` when nothing was flagged.
    var healthAlert: String? { get }

    static var csvHeader: [String] { get }
    var csvRow: [String] { get }

    func makePDF(businessName: String, submittedAt: Date) -> Data
}

struct Submission<A: FormAnswers>: Codable, Identifiable {
    let id: UUID
    let createdAt: Date
    let pdfFileName: String
    let answers: A
}

/// Saves each submission on the iPad as JSON + a signed PDF in Documents/Submissions.
final class SubmissionStore<A: FormAnswers>: ObservableObject {
    @Published private(set) var submissions: [Submission<A>] = []

    let directory: URL

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    init(folderName: String = "Submissions") {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        directory = documents.appendingPathComponent(folderName, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        load()
    }

    func load() {
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        submissions = files
            .filter { $0.pathExtension == "json" }
            .compactMap { url in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? decoder.decode(Submission<A>.self, from: data)
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func pdfURL(for submission: Submission<A>) -> URL {
        directory.appendingPathComponent(submission.pdfFileName)
    }

    private func jsonURL(for id: UUID) -> URL {
        directory.appendingPathComponent("\(id.uuidString).json")
    }

    @discardableResult
    func save(_ answers: A, businessName: String) throws -> Submission<A> {
        let now = Date()
        let id = UUID()
        let fileName = "\(Self.fileSafe(answers.customerName)) \(Formatters.fileStamp.string(from: now)) \(id.uuidString.prefix(4)).pdf"

        let pdf = answers.makePDF(businessName: businessName, submittedAt: now)
        try pdf.write(to: directory.appendingPathComponent(fileName), options: [.atomic, .completeFileProtection])

        let submission = Submission(id: id, createdAt: now, pdfFileName: fileName, answers: answers)
        try encoder.encode(submission).write(to: jsonURL(for: id), options: [.atomic, .completeFileProtection])

        submissions.insert(submission, at: 0)
        return submission
    }

    func delete(_ submission: Submission<A>) {
        try? FileManager.default.removeItem(at: pdfURL(for: submission))
        try? FileManager.default.removeItem(at: jsonURL(for: submission.id))
        submissions.removeAll { $0.id == submission.id }
    }

    /// Writes all submissions to a CSV (opens in Excel / Numbers / Google Sheets) and returns its URL.
    func exportCSV(prefix: String) throws -> URL {
        var lines = [Self.csvLine(["Submitted"] + A.csvHeader)]
        for submission in submissions {
            lines.append(Self.csvLine([Formatters.dateTime.string(from: submission.createdAt)] + submission.answers.csvRow))
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(prefix) \(Formatters.isoDay.string(from: Date())).csv")
        // BOM so Excel shows Vietnamese characters correctly.
        try ("\u{FEFF}" + lines.joined(separator: "\r\n")).write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private static func csvLine(_ fields: [String]) -> String {
        fields.map { "\"" + $0.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }.joined(separator: ",")
    }

    private static func fileSafe(_ name: String) -> String {
        let folded = name
            .replacingOccurrences(of: "đ", with: "d")
            .replacingOccurrences(of: "Đ", with: "D")
            .folding(options: [.diacriticInsensitive], locale: nil)
        let cleaned = folded.unicodeScalars
            .map { CharacterSet.alphanumerics.contains($0) ? String($0) : " " }
            .joined()
            .split(separator: " ")
            .joined(separator: "-")
        return cleaned.isEmpty ? "Customer" : cleaned
    }
}
