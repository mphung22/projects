// Shared source — edit in ios-apps/Shared, then run ios-apps/sync-shared.sh.

import SwiftUI

// MARK: - Model

/// One line of the SEREN price list. Prices are in VND.
struct PriceItem: Identifiable, Hashable {
    let id: String
    let label: L
    /// The price, or the low end when the price is a range.
    let price: Int
    /// The high end of a range (e.g. 30.000 – 50.000₫). `nil` for a fixed price.
    var maxPrice: Int? = nil
    /// Extra detail shown under the name, e.g. the duration.
    var detail: L? = nil
    /// Set for items charged per unit (e.g. per nail). Shows a quantity stepper.
    var unit: L? = nil
    /// Upgrades are shown as "+ 100.000₫".
    var isUpgrade = false

    var priceText: String {
        let text = maxPrice.map { VND.range(price, $0) } ?? VND.format(price)
        return isUpgrade ? "+ " + text : text
    }

    /// Name plus detail, e.g. "Seren Balance · 60 phút".
    var fullLabel: L {
        guard let detail else { return label }
        return L.combine([label, detail]) { "\($0[0]) · \($0[1])" }
    }
}

/// A heading on the price list with its items.
struct PriceGroup: Identifiable {
    let title: L
    var note: L? = nil
    /// Only one item in this group can be chosen (e.g. one head spa ritual).
    var singleChoice = false
    let items: [PriceItem]

    var id: String { title.en }
}

/// What the customer picked: item id → quantity.
typealias PriceSelection = [String: Int]

struct PriceLine: Identifiable {
    let item: PriceItem
    let quantity: Int

    var id: String { item.id }
    var low: Int { item.price * quantity }
    var high: Int { (item.maxPrice ?? item.price) * quantity }

    var label: L {
        let base = item.fullLabel
        if let unit = item.unit {
            return L.combine([base, unit]) { "\($0[0]) × \(quantity) \($0[1])" }
        }
        return quantity > 1 ? L.combine([base]) { "\($0[0]) × \(quantity)" } : base
    }

    var priceText: String { low == high ? VND.format(low) : VND.range(low, high) }
}

struct PriceTotal {
    let low: Int
    let high: Int

    var isRange: Bool { low != high }
    var text: String { isRange ? VND.range(low, high) : VND.format(low) }
}

extension Array where Element == PriceGroup {
    var allItems: [PriceItem] { flatMap(\.items) }

    /// Chosen items in price-list order.
    func lines(for selection: PriceSelection) -> [PriceLine] {
        allItems.compactMap { item in
            guard let quantity = selection[item.id], quantity > 0 else { return nil }
            return PriceLine(item: item, quantity: quantity)
        }
    }

    func total(for selection: PriceSelection) -> PriceTotal {
        let lines = lines(for: selection)
        return PriceTotal(low: lines.reduce(0) { $0 + $1.low }, high: lines.reduce(0) { $0 + $1.high })
    }

    /// English summary for the staff list and CSV, e.g. "Seren Glow — gel set, Cat eye".
    func summary(for selection: PriceSelection) -> String {
        lines(for: selection).map(\.label.en).joined(separator: ", ")
    }

    /// One CSV cell listing each item with its price.
    func csvItems(for selection: PriceSelection) -> String {
        lines(for: selection).map { "\($0.label.en) (\($0.priceText))" }.joined(separator: "; ")
    }
}

enum VND {
    /// 289000 → "289.000₫"
    static func format(_ amount: Int) -> String {
        let digits = String(abs(amount))
        var grouped = ""
        for (index, digit) in digits.enumerated() {
            if index > 0 && (digits.count - index) % 3 == 0 { grouped.append(".") }
            grouped.append(digit)
        }
        return (amount < 0 ? "-" : "") + grouped + "₫"
    }

    static func range(_ low: Int, _ high: Int) -> String {
        "\(format(low).dropLast()) – \(format(high))"
    }
}

enum PriceText {
    static let summaryTitle = L("Dịch vụ đã chọn & Tổng tiền", "Your selection & total")
    static let total = L("Tổng cộng", "Total")
    static let runningTotal = L("Tạm tính", "Running total")
    static let nothingChosen = L("Chưa chọn dịch vụ nào.", "No services chosen yet.")
    static let pricesInVND = L("Giá niêm yết bằng VNĐ.", "Prices are in VND.")
    static let rangeNote = L(
        "Một số dịch vụ có giá theo khoảng hoặc tính theo ngón. Kỹ thuật viên sẽ xác nhận giá cuối cùng trước khi bắt đầu.",
        "Some prices are a range or per nail. Your technician will confirm the final price before starting."
    )
}

// MARK: - Views

/// The price list as tappable rows. Chosen rows are highlighted; per-unit items get a stepper.
struct PriceMenuView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    let groups: [PriceGroup]
    @Binding var selection: PriceSelection

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(groups) { group in
                VStack(alignment: .leading, spacing: 10) {
                    LText(group.title, font: .headline)
                    if let note = group.note {
                        LText(note, font: .footnote)
                            .foregroundStyle(.secondary)
                    }
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 12, alignment: .top),
                                       count: sizeClass == .compact ? 1 : 2),
                        spacing: 12
                    ) {
                        ForEach(group.items) { item in
                            PriceItemRow(
                                item: item,
                                singleChoice: group.singleChoice,
                                quantity: selection[item.id] ?? 0,
                                toggle: { toggle(item, in: group) },
                                setQuantity: { selection[item.id] = $0 }
                            )
                        }
                    }
                }
            }
            PriceRunningTotal(groups: groups, selection: selection)
        }
    }

    private func toggle(_ item: PriceItem, in group: PriceGroup) {
        if (selection[item.id] ?? 0) > 0 {
            selection[item.id] = nil
            return
        }
        if group.singleChoice {
            for other in group.items { selection[other.id] = nil }
        }
        selection[item.id] = 1
    }
}

private struct PriceItemRow: View {
    @Environment(\.languageMode) private var mode
    let item: PriceItem
    let singleChoice: Bool
    let quantity: Int
    let toggle: () -> Void
    let setQuantity: (Int) -> Void

    private var selected: Bool { quantity > 0 }

    private var icon: String {
        if singleChoice { return selected ? "checkmark.circle.fill" : "circle" }
        return selected ? "checkmark.square.fill" : "square"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: toggle) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(selected ? Color.accentColor : Color.secondary)
                    VStack(alignment: .leading, spacing: 4) {
                        LText(item.label)
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(.primary)
                        if let detail = item.detail {
                            Text(detail.text(mode))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer(minLength: 8)
                    Text(item.priceText)
                        .font(.body.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.trailing)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if selected, let unit = item.unit {
                Stepper(value: Binding(get: { quantity }, set: setQuantity), in: 1...20) {
                    Text("\(L("Số lượng", "Quantity").text(mode)): \(quantity) \(unit.text(mode))")
                        .font(.subheadline.weight(.medium))
                }
                .padding(.leading, 34)
            }
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
    }
}

/// One line under the menu showing the total so far.
struct PriceRunningTotal: View {
    @Environment(\.languageMode) private var mode
    let groups: [PriceGroup]
    let selection: PriceSelection

    var body: some View {
        let total = groups.total(for: selection)
        HStack {
            Text(PriceText.runningTotal.text(mode))
                .font(.headline)
            Spacer()
            Text(total.text)
                .font(.headline.monospacedDigit())
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.accentColor.opacity(0.08)))
    }
}

/// The itemised bill shown before the customer signs.
struct PriceSummaryView: View {
    @Environment(\.languageMode) private var mode
    let groups: [PriceGroup]
    let selection: PriceSelection

    var body: some View {
        let lines = groups.lines(for: selection)
        let total = groups.total(for: selection)
        VStack(alignment: .leading, spacing: 12) {
            if lines.isEmpty {
                LText(PriceText.nothingChosen)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(lines) { line in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        LText(line.label)
                        Spacer(minLength: 8)
                        Text(line.priceText)
                            .font(.body.monospacedDigit())
                    }
                }
                Divider()
                HStack(alignment: .firstTextBaseline) {
                    Text(PriceText.total.text(mode))
                        .font(.title2.weight(.semibold))
                    Spacer()
                    Text(total.text)
                        .font(.title2.weight(.semibold).monospacedDigit())
                        .foregroundStyle(Color.accentColor)
                }
                Text(PriceText.pricesInVND.text(mode))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if total.isRange {
                    NoticeBanner(text: PriceText.rangeNote, systemImage: "info.circle.fill", tint: .blue)
                }
            }
        }
    }
}

// MARK: - PDF

extension PDFComposer {
    /// Each chosen item with its price, then the total.
    func priceSummary(groups: [PriceGroup], selection: PriceSelection) {
        let lines = groups.lines(for: selection)
        guard !lines.isEmpty else {
            bilingual(PriceText.nothingChosen)
            return
        }
        for line in lines {
            field(line.label, line.priceText)
        }
        let total = groups.total(for: selection)
        space(4)
        field(PriceText.total, total.text)
        if total.isRange {
            bilingual(PriceText.rangeNote)
        }
    }
}
