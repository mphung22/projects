// Shared source — edit in ios-apps/Shared, then run ios-apps/sync-shared.sh.

import SwiftUI

extension Color {
    static let paper = Color(red: 0.97, green: 0.96, blue: 0.94)
}

/// A selectable answer with a stable id (stored) and a bilingual label (shown).
struct Option: Identifiable, Hashable {
    let id: String
    let label: L
}

extension Array where Element == Option {
    func label(for id: String) -> L? { first { $0.id == id }?.label }

    /// Labels for the selected ids, in the order the options are listed.
    func labels(for ids: Set<String>) -> [L] { filter { ids.contains($0.id) }.map(\.label) }
}

extension Binding where Value == Set<String> {
    func contains(_ id: String) -> Binding<Bool> {
        Binding<Bool>(
            get: { wrappedValue.contains(id) },
            set: { isOn in
                if isOn { wrappedValue.insert(id) } else { wrappedValue.remove(id) }
            }
        )
    }
}

// MARK: - Layout

struct FormSection<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    let number: Int
    let title: L
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 12) {
                Text("\(number)")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.accentColor))
                LText(title, font: .title3.weight(.semibold))
            }
            content
        }
        .padding(sizeClass == .compact ? 16 : 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
        // A hairline border instead of a blurred shadow: shadows on large cards are costly to redraw while scrolling.
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.black.opacity(0.07), lineWidth: 1))
    }
}

struct FieldLabel: View {
    @Environment(\.languageMode) private var mode
    let title: L
    var required = false

    var body: some View {
        HStack(spacing: 2) {
            Text(title.text(mode))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            if required {
                Text("*").font(.subheadline.bold()).foregroundStyle(.red)
            }
        }
    }
}

struct BulletList: View {
    let items: [L]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Text("•").font(.body.bold()).foregroundStyle(Color.accentColor)
                    LText(item)
                }
            }
        }
    }
}

/// A titled list of bullet points, e.g. aftercare for one service.
struct InfoGroup: Identifiable {
    let title: L
    let items: [L]
    var id: String { title.en }
}

struct InfoGroupList: View {
    let groups: [InfoGroup]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(groups) { group in
                VStack(alignment: .leading, spacing: 10) {
                    if groups.count > 1 {
                        LText(group.title, font: .headline)
                    }
                    BulletList(items: group.items)
                }
            }
        }
    }
}

struct NoticeBanner: View {
    let text: L
    var systemImage = "exclamationmark.triangle.fill"
    var tint: Color = .orange

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(tint)
            LText(text)
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(tint.opacity(0.12)))
    }
}

/// Side by side on iPad, stacked on iPhone.
struct AdaptiveRow<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @ViewBuilder var content: Content

    var body: some View {
        if sizeClass == .compact {
            VStack(alignment: .leading, spacing: 18) { content }
        } else {
            HStack(alignment: .top, spacing: 20) { content }
        }
    }
}

// MARK: - Inputs

struct TextFieldRow: View {
    let title: L
    @Binding var text: String
    var required = false
    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType? = nil
    var capitalization: TextInputAutocapitalization = .sentences
    var multiline = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            FieldLabel(title: title, required: required)
            Group {
                if multiline {
                    TextField("", text: $text, axis: .vertical).lineLimit(3...8)
                } else {
                    TextField("", text: $text)
                }
            }
            .keyboardType(keyboard)
            .textContentType(contentType)
            .textInputAutocapitalization(capitalization)
            .autocorrectionDisabled()
            .font(.title3)
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DateFieldRow: View {
    let title: L
    @Binding var date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            FieldLabel(title: title)
            DatePicker("", selection: $date, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)
                .frame(minHeight: 50)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Date that starts empty (e.g. date of birth) so customers must actively choose it.
struct OptionalDateField: View {
    @Environment(\.languageMode) private var mode
    let title: L
    @Binding var date: Date?
    var required = false
    var startingDate = Calendar.current.date(from: DateComponents(year: 1995, month: 1, day: 1)) ?? Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            FieldLabel(title: title, required: required)
            if date != nil {
                DatePicker(
                    "",
                    selection: Binding(get: { date ?? startingDate }, set: { date = $0 }),
                    in: ...Date(),
                    displayedComponents: .date
                )
                .labelsHidden()
                .datePickerStyle(.compact)
                .frame(minHeight: 50)
            } else {
                Button {
                    date = startingDate
                } label: {
                    Label(L("Chọn ngày", "Select date").text(mode), systemImage: "calendar")
                        .font(.title3)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Staff member picker. Uses the names from Settings, or free text if none are set.
struct StaffField: View {
    let title: L
    @Binding var name: String
    @AppStorage(SettingsKey.staffNames) private var staffNames = ""

    private var names: [String] {
        staffNames
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        if names.isEmpty {
            TextFieldRow(title: title, text: $name, contentType: .name, capitalization: .words)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                FieldLabel(title: title)
                Picker("", selection: $name) {
                    Text("—").tag("")
                    ForEach(names, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(minHeight: 50)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct CheckRow: View {
    let text: L
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .font(.title2)
                    .foregroundStyle(isOn ? Color.accentColor : Color.secondary)
                LText(text)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct Chip: View {
    let label: L
    let selected: Bool
    var multiSelect = false
    let action: () -> Void

    private var icon: String {
        if multiSelect { return selected ? "checkmark.square.fill" : "square" }
        return selected ? "checkmark.circle.fill" : "circle"
    }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(selected ? Color.accentColor : Color.secondary)
                LText(label)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selected ? Color.accentColor.opacity(0.12) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Single choice. An empty string means nothing selected yet.
struct ChoiceChips: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    let options: [Option]
    @Binding var selection: String
    var columns = 2

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: sizeClass == .compact ? min(columns, 2) : columns), spacing: 12) {
            ForEach(options) { option in
                Chip(label: option.label, selected: selection == option.id) {
                    // Tapping the selected option again clears it.
                    selection = selection == option.id ? "" : option.id
                }
            }
        }
    }
}

struct MultiChips: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    let options: [Option]
    @Binding var selection: Set<String>
    var columns = 3

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: sizeClass == .compact ? min(columns, 2) : columns), spacing: 12) {
            ForEach(options) { option in
                Chip(label: option.label, selected: selection.contains(option.id), multiSelect: true) {
                    if selection.contains(option.id) {
                        selection.remove(option.id)
                    } else {
                        selection.insert(option.id)
                    }
                }
            }
        }
    }
}

struct SubmitButton: View {
    let title: L
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(title.vi).font(.title2.weight(.semibold))
                if title.en != title.vi {
                    Text(title.en).font(.subheadline)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.accentColor))
        }
        .buttonStyle(.plain)
    }
}

/// Shared chrome for a form: centred readable column on a paper background,
/// plus a "please complete" alert listing anything missing.
struct FormPage<Content: View>: View {
    @Environment(\.languageMode) private var mode
    @Environment(\.horizontalSizeClass) private var sizeClass
    let title: L
    @Binding var missing: [L]
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(spacing: 24) { content }
                .padding(.horizontal, sizeClass == .compact ? 12 : 32)
                .padding(.vertical, 24)
                .frame(maxWidth: 920)
                .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.paper.ignoresSafeArea())
        .navigationTitle(title.text(mode))
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            L("Vui lòng hoàn thành", "Please complete").text(mode),
            isPresented: Binding(get: { !missing.isEmpty }, set: { if !$0 { missing = [] } })
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(missing.map { "• " + $0.text(mode) }.joined(separator: "\n"))
        }
    }
}
