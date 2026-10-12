// Shared source — edit in ios-apps/Shared, then run ios-apps/sync-shared.sh.

import SwiftUI

// MARK: - Model & storage

struct MemberTransaction: Codable, Identifiable {
    enum Kind: String, Codable { case topUp, charge }

    var id = UUID()
    var date = Date()
    var kind: Kind
    /// Always positive; `kind` says whether it adds to or spends the card balance.
    var amount: Int
    var note = ""
    var staff = ""
    var balanceAfter: Int
    /// Receipt number for charges, e.g. "HD-0007".
    var receiptNo = ""
}

struct Member: Codable, Identifiable {
    var id = UUID()
    var createdAt = Date()
    var name: String
    var phone = ""
    var transactions: [MemberTransaction] = []

    var balance: Int { transactions.first?.balanceAfter ?? 0 }
    var totalLoaded: Int { transactions.filter { $0.kind == .topUp }.map(\.amount).reduce(0, +) }
    var totalSpent: Int { transactions.filter { $0.kind == .charge }.map(\.amount).reduce(0, +) }
}

enum MemberError: LocalizedError {
    case invalidAmount
    case insufficientBalance(Int)

    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Số tiền không hợp lệ / Invalid amount"
        case .insufficientBalance(let balance):
            return "Số dư thẻ không đủ (còn \(VND.format(balance))) / Not enough balance (\(VND.format(balance)) left)"
        }
    }
}

/// Member cards and their balances, saved on the iPad in Documents/Members/members.json.
/// Transactions are newest first; each stores the balance after it, so the history is an audit trail.
final class MemberStore: ObservableObject {
    static let shared = MemberStore()

    @Published private(set) var members: [Member] = []

    private let fileURL: URL
    private let nextReceiptKey = "memberNextReceipt"

    private init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let directory = documents.appendingPathComponent("Members", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("members.json")
        load()
    }

    func member(_ id: UUID) -> Member? { members.first { $0.id == id } }

    /// Creates a card; `amount` is what the customer paid for it (the opening balance).
    @discardableResult
    func create(name: String, phone: String, amount: Int, staff: String, note: String) throws -> Member {
        guard amount > 0 else { throw MemberError.invalidAmount }
        var member = Member(name: name.trimmed, phone: phone.trimmed)
        member.transactions = [MemberTransaction(
            kind: .topUp, amount: amount,
            note: note.trimmed.isEmpty ? "Mua thẻ / New card" : note.trimmed,
            staff: staff, balanceAfter: amount
        )]
        members.insert(member, at: 0)
        try persist()
        return member
    }

    func topUp(_ id: UUID, amount: Int, staff: String, note: String) throws {
        guard amount > 0 else { throw MemberError.invalidAmount }
        try update(id) { member in
            member.transactions.insert(MemberTransaction(
                kind: .topUp, amount: amount,
                note: note.trimmed.isEmpty ? "Nạp thêm / Top-up" : note.trimmed,
                staff: staff, balanceAfter: member.balance + amount
            ), at: 0)
        }
    }

    /// Deducts a bill from the card and returns the transaction (with its receipt number).
    @discardableResult
    func charge(_ id: UUID, amount: Int, staff: String, note: String) throws -> MemberTransaction {
        guard amount > 0 else { throw MemberError.invalidAmount }
        guard let current = member(id) else { throw MemberError.invalidAmount }
        guard amount <= current.balance else { throw MemberError.insufficientBalance(current.balance) }
        let receiptNo = takeReceiptNumber()
        var made: MemberTransaction?
        try update(id) { member in
            let transaction = MemberTransaction(
                kind: .charge, amount: amount, note: note.trimmed, staff: staff,
                balanceAfter: member.balance - amount, receiptNo: receiptNo
            )
            member.transactions.insert(transaction, at: 0)
            made = transaction
        }
        return made!
    }

    func delete(_ member: Member) {
        members.removeAll { $0.id == member.id }
        try? persist()
    }

    func exportCSV(prefix: String) throws -> URL {
        var lines = [csvLine(["Date", "Name", "Phone", "Type", "Amount", "Balance after", "Receipt", "Staff", "Note"])]
        for member in members {
            for t in member.transactions.reversed() {
                lines.append(csvLine([
                    Formatters.dateTime.string(from: t.date), member.name, member.phone,
                    t.kind == .topUp ? "Top-up" : "Charge", String(t.amount), String(t.balanceAfter),
                    t.receiptNo, t.staff, t.note,
                ]))
            }
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(prefix) Member cards \(Formatters.isoDay.string(from: Date())).csv")
        try ("\u{FEFF}" + lines.joined(separator: "\r\n")).write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    /// A one-page receipt for a charge.
    func receiptPDF(member: Member, transaction t: MemberTransaction, businessName: String) -> Data {
        let pdf = PDFComposer(footer: businessName)
        pdf.title(businessName)
        pdf.subtitle("HOÁ ĐƠN / RECEIPT \(t.receiptNo)")
        pdf.space(10)
        pdf.rule()
        pdf.field(L("Ngày", "Date"), Formatters.dateTime.string(from: t.date))
        pdf.field(L("Khách hàng", "Customer"), member.name)
        pdf.field(L("Số điện thoại", "Phone"), member.phone)
        pdf.field(L("Nhân viên", "Staff"), t.staff)
        pdf.field(L("Dịch vụ", "Services"), t.note)
        pdf.rule()
        pdf.field(L("Tổng thanh toán", "Total"), VND.format(t.amount))
        pdf.field(L("Số dư trước", "Balance before"), VND.format(t.balanceAfter + t.amount))
        pdf.field(L("Số dư còn lại", "Balance remaining"), VND.format(t.balanceAfter))
        pdf.space(12)
        pdf.bilingual(L("Đã trừ vào thẻ thành viên. Cảm ơn quý khách!", "Paid from your member card. Thank you!"))
        return pdf.render()
    }

    func receiptURL(member: Member, transaction t: MemberTransaction, businessName: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(t.receiptNo) \(member.name).pdf")
        try receiptPDF(member: member, transaction: t, businessName: businessName).write(to: url, options: .atomic)
        return url
    }

    // MARK: Persistence

    private func update(_ id: UUID, _ change: (inout Member) -> Void) throws {
        guard let index = members.firstIndex(where: { $0.id == id }) else { return }
        let backup = members
        change(&members[index])
        do { try persist() } catch {
            members = backup
            throw error
        }
    }

    private func takeReceiptNumber() -> String {
        let number = max(UserDefaults.standard.integer(forKey: nextReceiptKey), 1)
        UserDefaults.standard.set(number + 1, forKey: nextReceiptKey)
        return String(format: "HD-%04d", number)
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        members = (try? decoder.decode([Member].self, from: data)) ?? []
    }

    private func persist() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted]
        try encoder.encode(members).write(to: fileURL, options: [.atomic, .completeFileProtection])
    }

    private func csvLine(_ fields: [String]) -> String {
        fields.map { "\"" + $0.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }.joined(separator: ",")
    }
}

// MARK: - Staff screens

private func staffNameList() -> [String] {
    (UserDefaults.standard.string(forKey: SettingsKey.staffNames) ?? "")
        .split(whereSeparator: \.isNewline)
        .map { String($0).trimmed }
        .filter { !$0.isEmpty }
}

private func parseAmount(_ text: String) -> Int {
    Int(text.filter(\.isNumber)) ?? 0
}

struct MembersView: View {
    let exportPrefix: String
    @ObservedObject var store: MemberStore
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    @State private var showNew = false
    @State private var shareURL: URL?
    @State private var exportError: String?

    private var filtered: [Member] {
        let query = search.trimmed
        guard !query.isEmpty else { return store.members }
        return store.members.filter {
            $0.name.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil || $0.phone.contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { member in
                NavigationLink {
                    MemberDetailView(store: store, memberID: member.id)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(member.name).font(.headline)
                            if !member.phone.isEmpty { Text(member.phone).font(.subheadline).foregroundStyle(.secondary) }
                        }
                        Spacer()
                        Text(VND.format(member.balance)).font(.headline).monospacedDigit()
                    }
                }
            }
            .overlay {
                if filtered.isEmpty {
                    ContentUnavailableView("Chưa có thẻ member / No member cards", systemImage: "creditcard")
                }
            }
            .searchable(text: $search, prompt: "Tên hoặc SĐT / Name or phone")
            .navigationTitle("Thẻ member / Member cards (\(store.members.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng / Close") { dismiss() }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        do { shareURL = try store.exportCSV(prefix: exportPrefix) } catch { exportError = error.localizedDescription }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(store.members.isEmpty)
                    Button { showNew = true } label: {
                        Label("Thẻ mới / New card", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showNew) { NewMemberView(store: store) }
            .sheet(item: Binding(get: { shareURL.map(ShareURL.init) }, set: { shareURL = $0?.url })) {
                ActivityView(items: [$0.url])
            }
            .alert("Lỗi / Error", isPresented: Binding(get: { exportError != nil }, set: { if !$0 { exportError = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(exportError ?? "")
            }
        }
    }
}

private struct ShareURL: Identifiable {
    let url: URL
    var id: URL { url }
}

private struct StaffPicker: View {
    @Binding var staff: String
    private let names = staffNameList()

    var body: some View {
        if names.isEmpty {
            TextField("Nhân viên / Staff", text: $staff)
        } else {
            Picker("Nhân viên / Staff", selection: $staff) {
                Text("—").tag("")
                ForEach(names, id: \.self) { Text($0).tag($0) }
            }
        }
    }
}

private struct AmountField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        HStack {
            TextField(title, text: $text)
                .keyboardType(.numberPad)
                .onChange(of: text) { _, new in
                    let amount = parseAmount(new)
                    let formatted = amount == 0 ? "" : VND.format(amount).dropLast().description
                    if formatted != new { text = formatted }
                }
            Text("₫").foregroundStyle(.secondary)
        }
    }
}

private struct NewMemberView: View {
    @ObservedObject var store: MemberStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var phone = ""
    @State private var amount = ""
    @State private var note = ""
    @State private var staff = ""
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Khách hàng / Customer") {
                    TextField("Họ tên / Full name", text: $name)
                    TextField("Số điện thoại / Phone", text: $phone).keyboardType(.phonePad)
                }
                Section {
                    AmountField(title: "Số tiền mua thẻ / Card amount", text: $amount)
                    TextField("Ghi chú / Note (vd. thẻ 5.000.000₫ tặng 10%)", text: $note)
                    StaffPicker(staff: $staff)
                } header: {
                    Text("Mua thẻ / Card purchase")
                } footer: {
                    Text("Số tiền này là số dư ban đầu của thẻ. / This amount becomes the card's opening balance.")
                }
                if let error { Text(error).foregroundStyle(.red) }
            }
            .navigationTitle("Thẻ mới / New card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Huỷ / Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu / Save", action: save)
                        .disabled(name.trimmed.isEmpty || parseAmount(amount) == 0)
                }
            }
        }
    }

    private func save() {
        do {
            try store.create(name: name, phone: phone, amount: parseAmount(amount), staff: staff, note: note)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

private struct MemberDetailView: View {
    @ObservedObject var store: MemberStore
    let memberID: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var showTopUp = false
    @State private var showCharge = false
    @State private var confirmDelete = false
    @State private var receipt: ShareURL?
    @State private var errorText: String?

    var body: some View {
        if let member = store.member(memberID) {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Số dư / Balance").font(.subheadline).foregroundStyle(.secondary)
                        Text(VND.format(member.balance)).font(.system(size: 40, weight: .bold)).monospacedDigit()
                        Text("Đã nạp / Loaded \(VND.format(member.totalLoaded)) · Đã dùng / Spent \(VND.format(member.totalSpent))")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    Button { showCharge = true } label: {
                        Label("Thanh toán & xuất hoá đơn / Charge & receipt", systemImage: "doc.text")
                    }
                    .disabled(member.balance == 0)
                    Button { showTopUp = true } label: {
                        Label("Nạp thêm / Top up", systemImage: "plus.circle")
                    }
                }
                Section("Lịch sử / History") {
                    ForEach(member.transactions) { t in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(t.kind == .topUp ? "Nạp / Top-up" : "Thanh toán / Charge \(t.receiptNo)")
                                    .font(.headline)
                                if !t.note.isEmpty { Text(t.note).font(.subheadline) }
                                Text([Formatters.dateTime.string(from: t.date), t.staff].filter { !$0.isEmpty }.joined(separator: " · "))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text((t.kind == .topUp ? "+" : "−") + VND.format(t.amount))
                                    .foregroundStyle(t.kind == .topUp ? Color.green : Color.red)
                                    .monospacedDigit()
                                Text("còn \(VND.format(t.balanceAfter))").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions {
                            if t.kind == .charge {
                                Button("Hoá đơn / Receipt") { showReceipt(member, t) }
                            }
                        }
                    }
                }
            }
            .navigationTitle(member.name + (member.phone.isEmpty ? "" : " · \(member.phone)"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button(role: .destructive) { confirmDelete = true } label: { Image(systemName: "trash") }
            }
            .sheet(isPresented: $showTopUp) { TopUpView(store: store, member: member) }
            .sheet(isPresented: $showCharge) {
                ChargeView(store: store, member: member) { t in
                    // Wait for the charge sheet to finish closing before presenting the receipt.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showReceipt(store.member(memberID) ?? member, t)
                    }
                }
            }
            .sheet(item: $receipt) { ActivityView(items: [$0.url]) }
            .confirmationDialog("Xoá thẻ này? / Delete this card?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Xoá / Delete", role: .destructive) {
                    store.delete(member)
                    dismiss()
                }
            } message: {
                Text("Số dư và lịch sử sẽ mất. / The balance and history will be lost.")
            }
            .alert("Lỗi / Error", isPresented: Binding(get: { errorText != nil }, set: { if !$0 { errorText = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorText ?? "")
            }
        } else {
            ContentUnavailableView("Không tìm thấy thẻ / Card not found", systemImage: "creditcard")
        }
    }

    private func showReceipt(_ member: Member, _ t: MemberTransaction) {
        let name = UserDefaults.standard.string(forKey: SettingsKey.businessName) ?? "Seren"
        do {
            receipt = ShareURL(url: try store.receiptURL(member: member, transaction: t, businessName: name))
        } catch {
            errorText = error.localizedDescription
        }
    }
}

private struct TopUpView: View {
    @ObservedObject var store: MemberStore
    let member: Member
    @Environment(\.dismiss) private var dismiss
    @State private var amount = ""
    @State private var note = ""
    @State private var staff = ""
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Số dư hiện tại / Current balance: \(VND.format(member.balance))") {
                    AmountField(title: "Số tiền nạp / Top-up amount", text: $amount)
                    TextField("Ghi chú / Note", text: $note)
                    StaffPicker(staff: $staff)
                }
                if let error { Text(error).foregroundStyle(.red) }
            }
            .navigationTitle("Nạp thêm / Top up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Huỷ / Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu / Save") {
                        do {
                            try store.topUp(member.id, amount: parseAmount(amount), staff: staff, note: note)
                            dismiss()
                        } catch {
                            self.error = error.localizedDescription
                        }
                    }
                    .disabled(parseAmount(amount) == 0)
                }
            }
        }
    }
}

private struct ChargeView: View {
    @ObservedObject var store: MemberStore
    let member: Member
    let onCharged: (MemberTransaction) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var amount = ""
    @State private var note = ""
    @State private var staff = ""
    @State private var error: String?

    private var value: Int { parseAmount(amount) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    AmountField(title: "Tổng tiền dịch vụ / Bill total", text: $amount)
                    TextField("Dịch vụ / Services (vd. Gội đầu 100 phút)", text: $note)
                    StaffPicker(staff: $staff)
                } header: {
                    Text("Số dư hiện tại / Current balance: \(VND.format(member.balance))")
                } footer: {
                    if value > member.balance {
                        Text("Không đủ số dư — còn thiếu \(VND.format(value - member.balance)). / Not enough balance — short by \(VND.format(value - member.balance)).")
                            .foregroundStyle(.red)
                    } else if value > 0 {
                        Text("Số dư sau khi trừ / Balance after: \(VND.format(member.balance - value))")
                    }
                }
                if let error { Text(error).foregroundStyle(.red) }
            }
            .navigationTitle("Thanh toán / Charge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Huỷ / Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Trừ thẻ & xuất HĐ / Charge", action: charge)
                        .disabled(value == 0 || value > member.balance)
                }
            }
        }
    }

    private func charge() {
        do {
            let t = try store.charge(member.id, amount: value, staff: staff, note: note)
            dismiss()
            onCharged(t)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
