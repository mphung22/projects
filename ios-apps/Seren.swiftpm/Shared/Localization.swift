// Shared source — edit in ios-apps/Shared, then run ios-apps/sync-shared.sh.

import SwiftUI

/// A customer-facing string: Vietnamese and English (matching the paper forms), plus Chinese, Korean, French,
/// Japanese and Russian when a translation exists. Those come from `Translations.table` (generated from
/// docs/i18n.js), looked up by the English text; anything missing falls back to English.
/// Records, PDFs and CSV exports always use Vietnamese + English (`both`).
struct L: Hashable {
    let vi: String
    let en: String
    /// Other languages by code ("zh", "ko", "fr", "ja", "ru").
    let more: [String: String]

    init(_ vi: String, _ en: String, _ more: [String: String] = [:]) {
        self.vi = vi
        self.en = en
        self.more = (Translations.table[en] ?? [:]).merging(more) { _, given in given }
    }

    /// "Tiếng Việt / English" on one line — used for labels and the PDF.
    var both: String { vi == en ? vi : "\(vi) / \(en)" }

    func text(_ mode: LanguageMode) -> String {
        switch mode {
        case .both: return both
        case .vietnamese: return vi
        case .english: return en
        default: return text(code: mode.rawValue)
        }
    }

    /// The text in one of the extra languages, or English when there is no translation.
    func text(code: String) -> String { more[code] ?? en }

    /// Builds a string from other strings in every language, e.g. a name plus its duration.
    static func combine(_ parts: [L], _ join: ([String]) -> String) -> L {
        var more: [String: String] = [:]
        for code in LanguageMode.extraCodes { more[code] = join(parts.map { $0.text(code: code) }) }
        return L(join(parts.map(\.vi)), join(parts.map(\.en)), more)
    }
}

enum LanguageMode: String, CaseIterable, Identifiable {
    case both, vietnamese, english
    // The other languages offered on serensaigon.com. Raw values are language codes.
    case chinese = "zh", korean = "ko", french = "fr", japanese = "ja", russian = "ru"

    var id: String { rawValue }

    static let extraCodes = ["zh", "ko", "fr", "ja", "ru"]

    /// Chinese, Korean, French, Japanese or Russian.
    var isExtra: Bool { Self.extraCodes.contains(rawValue) }

    var label: String {
        switch self {
        case .both: return "Tiếng Việt + English"
        case .vietnamese: return "Tiếng Việt"
        case .english: return "English"
        case .chinese: return "中文"
        case .korean: return "한국어"
        case .french: return "Français"
        case .japanese: return "日本語"
        case .russian: return "Русский"
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
        if mode == .both {
            VStack(alignment: .leading, spacing: 2) {
                Text(l.vi).font(font)
                if l.en != l.vi {
                    Text(l.en).font(font).italic().foregroundStyle(.secondary)
                }
            }
        } else {
            Text(l.text(mode)).font(font)
        }
    }
}

/// A centred heading: Vietnamese with English underneath in VI + EN mode, otherwise one line.
struct LHeading: View {
    @Environment(\.languageMode) private var mode
    let l: L
    var font: Font
    var secondaryFont: Font

    var body: some View {
        VStack(spacing: 4) {
            if mode == .both {
                Text(l.vi).font(font)
                if l.en != l.vi {
                    Text(l.en).font(secondaryFont).italic().foregroundStyle(.secondary)
                }
            } else {
                Text(l.text(mode)).font(font)
            }
        }
        .multilineTextAlignment(.center)
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

/// Language buttons for the welcome screen (too many languages for a segmented control).
struct LanguageButtons: View {
    @Binding var raw: String

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 10)], spacing: 10) {
            ForEach(LanguageMode.allCases) { mode in
                let selected = raw == mode.rawValue
                Button {
                    raw = mode.rawValue
                } label: {
                    Text(mode.label)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(selected ? Color.white : Color.primary)
                        .background(Capsule().fill(selected ? Color.accentColor : Color.white))
                        .overlay(Capsule().stroke(Color.accentColor.opacity(0.35), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
