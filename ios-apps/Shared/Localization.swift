// Shared source — edit in ios-apps/Shared, then run ios-apps/sync-shared.sh.

import SwiftUI

/// A bilingual (Vietnamese / English) string, matching the paper forms.
struct L: Hashable {
    let vi: String
    let en: String

    init(_ vi: String, _ en: String) {
        self.vi = vi
        self.en = en
    }

    /// "Tiếng Việt / English" on one line — used for labels and the PDF.
    var both: String { vi == en ? vi : "\(vi) / \(en)" }

    func text(_ mode: LanguageMode) -> String {
        switch mode {
        case .both: return both
        case .vietnamese: return vi
        case .english: return en
        }
    }
}

enum LanguageMode: String, CaseIterable, Identifiable {
    case both, vietnamese, english

    var id: String { rawValue }

    var label: String {
        switch self {
        case .both: return "Tiếng Việt + English"
        case .vietnamese: return "Tiếng Việt"
        case .english: return "English"
        }
    }
}

private struct LanguageModeKey: EnvironmentKey {
    static let defaultValue: LanguageMode = .both
}

extension EnvironmentValues {
    var languageMode: LanguageMode {
        get { self[LanguageModeKey.self] }
        set { self[LanguageModeKey.self] = newValue }
    }
}

/// Shows Vietnamese with the English translation underneath (or just one language).
struct LText: View {
    @Environment(\.languageMode) private var mode
    let l: L
    var font: Font

    init(_ l: L, font: Font = .body) {
        self.l = l
        self.font = font
    }

    var body: some View {
        switch mode {
        case .both:
            VStack(alignment: .leading, spacing: 2) {
                Text(l.vi).font(font)
                if l.en != l.vi {
                    Text(l.en).font(font).italic().foregroundStyle(.secondary)
                }
            }
        case .vietnamese:
            Text(l.vi).font(font)
        case .english:
            Text(l.en).font(font)
        }
    }
}

struct LanguagePicker: View {
    @Binding var raw: String

    var body: some View {
        Picker(selection: $raw) {
            ForEach(LanguageMode.allCases) { mode in
                Text(mode.label).tag(mode.rawValue)
            }
        } label: {
            Label("Ngôn ngữ / Language", systemImage: "globe")
        }
    }
}
