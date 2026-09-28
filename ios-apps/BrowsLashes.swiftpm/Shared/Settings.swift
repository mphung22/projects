// Shared source — edit in ios-apps/Shared, then run ios-apps/sync-shared.sh.

import Foundation

/// Per-app look & text for the kiosk shell.
struct KioskConfig {
    /// Title shown on the welcome screen, e.g. "Brows Lamination & Tint".
    let formTitle: L
    /// SF Symbol shown on the welcome screen.
    let symbol: String
    /// Business name used until staff change it in Settings.
    let defaultBusinessName: String
    /// Prefix for exported CSV files.
    let exportPrefix: String
}

enum SettingsKey {
    static let businessName = "businessName"
    static let staffPIN = "staffPIN"
    static let staffNames = "staffNames"
    static let languageMode = "languageMode"
    static let googleReviewURL = "googleReviewURL"

    static let defaultPIN = "1234"

    static func registerDefaults(businessName: String) {
        UserDefaults.standard.register(defaults: [
            SettingsKey.businessName: businessName,
            SettingsKey.staffPIN: defaultPIN,
            SettingsKey.staffNames: "",
            SettingsKey.languageMode: LanguageMode.both.rawValue,
            SettingsKey.googleReviewURL: "",
        ])
    }
}

enum Formatters {
    static let date: DateFormatter = make("dd/MM/yyyy")
    static let dateTime: DateFormatter = make("dd/MM/yyyy HH:mm")
    static let fileStamp: DateFormatter = make("yyyy-MM-dd HHmm")
    static let isoDay: DateFormatter = make("yyyy-MM-dd")

    private static func make(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = format
        return formatter
    }
}

func age(from birthday: Date, on day: Date = Date()) -> Int {
    Calendar.current.dateComponents([.year], from: birthday, to: day).year ?? 0
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

extension Optional where Wrapped == Date {
    var dayString: String { map { Formatters.date.string(from: $0) } ?? "" }
}
