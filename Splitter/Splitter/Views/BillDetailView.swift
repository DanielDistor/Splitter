import PhotosUI
import SwiftUI

struct BillDetailView: View {
    @Environment(BillStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let billID: UUID

    var body: some View {
        @Bindable var store = store
        if let index = store.bills.firstIndex(where: { $0.id == billID }) {
            BillEditor(bill: $store.bills[index]) {
                dismiss()
                Task {
                    try? await Task.sleep(for: .milliseconds(400))
                    store.delete(ids: [billID])
                }
            }
        } else {
            ContentUnavailableView("Bill Deleted", systemImage: "trash")
        }
    }
}

/// The bill screen, answer first: total and who owes what at the top, then items, tax and tip.
private struct BillEditor: View {
    @Binding var bill: Bill
    let onDeleteBill: () -> Void
    @State private var newPersonName = ""
    @State private var editingItem: BillItem?
    @State private var editingPerson: PersonRef?
    @State private var confirmDeleteBill = false
    @State private var undo: UndoAction?
    @FocusState private var addPersonFocused: Bool

    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var pickedPhoto: PhotosPickerItem?
    @State private var isScanning = false
    @State private var scanned: ScannedReceipt?
    @State private var scanError: String?

    private static let tipPresets = [0, 15, 18, 20]

    var body: some View {
        let summary = Split.summarize(bill)
        ScrollView {
            VStack(spacing: 16) {
                hero(summary)
                whoOwesCard(summary)
                itemsCard
                taxAndTipCard(summary)
                if !summary.shares.isEmpty {
                    ShareLink(item: shareText(summary)) {
                        Label("Share with the Group", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PillButtonStyle(isSelected: true))
                    .controlSize(.large)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 40)
            .animation(.snappy, value: summary)
            .animation(.snappy, value: bill.settled)
            .animation(.snappy, value: bill.paidBy)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(bill.title.isEmpty ? "New Bill" : bill.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbar {
            Menu {
                ShareLink(item: shareText(summary)) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                Button("Delete Bill", systemImage: "trash", role: .destructive) { confirmDeleteBill = true }
            } label: {
                Label("More", systemImage: "ellipsis.circle")
            }
        }
        .confirmationDialog("Delete this bill?", isPresented: $confirmDeleteBill, titleVisibility: .visible) {
            Button("Delete Bill", role: .destructive, action: onDeleteBill)
        } message: {
            Text("You can undo this for a few seconds.")
        }
        .sheet(item: $editingPerson) { ref in
            PersonEditor(bill: $bill, personID: ref.id) { removePerson(ref.id) }
        }
        .sheet(item: $editingItem) { item in
            let isExisting = bill.items.contains { $0.id == item.id }
            ItemEditor(item: item, people: bill.people,
                       onDelete: isExisting ? { deleteItem(item) } : nil,
                       onSplit: isExisting ? splitItem : nil) { saved in
                if let index = bill.items.firstIndex(where: { $0.id == saved.id }) {
                    bill.items[index] = saved
                } else {
                    bill.items.append(saved)
                }
            }
        }
        .sheet(item: $scanned) { receipt in
            ReceiptReviewView(receipt: receipt, onAdd: addScanned)
        }
        .fullScreenCover(isPresented: $showCamera) {
            DocumentCamera { image in
                showCamera = false
                scan(image)
            } onCancel: {
                showCamera = false
            }
            .ignoresSafeArea()
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $pickedPhoto, matching: .images)
        .onChange(of: pickedPhoto) { _, item in
            guard let item else { return }
            pickedPhoto = nil
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    scan(image)
                } else {
                    scanError = "That photo couldn't be opened."
                }
            }
        }
        .overlay {
            if isScanning {
                VStack(spacing: 14) {
                    ProgressView().controlSize(.large).tint(Theme.brand)
                    Text("Reading receipt…").font(.headline)
                }
                .padding(28)
                .background(.regularMaterial, in: .rect(cornerRadius: 22))
            }
        }
        .alert("Couldn't Scan", isPresented: Binding { scanError != nil } set: { if !$0 { scanError = nil } }) {
            Button("OK") {}
        } message: {
            Text(scanError ?? "")
        }
        .safeAreaInset(edge: .bottom) {
            if let undo {
                UndoToast(action: undo) { withAnimation { self.undo = nil } }
                    .padding(.bottom, 8)
            }
        }
        .animation(.snappy, value: undo?.id)
        .task {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-scanDemoReceipt"), scanned == nil {
                scan(DemoData.receiptImage())
            }
            #endif
        }
    }

    // MARK: Header

    private func hero(_ summary: BillSummary) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            TextField("What's this bill for?", text: $bill.title,
                      prompt: Text("What's this bill for?").foregroundStyle(.white.opacity(0.55)))
                .font(.title2.bold())

            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TOTAL")
                        .font(.caption.weight(.semibold))
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.7))
                    Text(Money.format(summary.totalCents))
                        .font(.money(40))
                        .contentTransition(.numericText())
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
                Spacer()
                DatePicker("Date", selection: $bill.date, displayedComponents: .date)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .tint(.white)
            }

            if bill.paidBy != nil {
                Text(settleSummary)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .foregroundStyle(.white)
        .padding(22)
        .background(Theme.brandFill, in: .rect(cornerRadius: 26))
    }

    private var settleSummary: String {
        guard let payer = bill.payer else { return "" }
        if bill.isFullySettled { return "Everyone has paid \(payer.name) back." }
        return "\(payer.name) paid · waiting on \(Money.format(bill.outstandingCents))"
    }

    // MARK: Who owes what

    private func whoOwesCard(_ summary: BillSummary) -> some View {
        CardSection("Who Owes What",
                    footer: summary.shares.isEmpty ? nil : "Tax and tip are split based on how much each person ordered. Tap someone to see their breakdown.") {
            if !bill.people.isEmpty {
                payerPicker
            }

            VStack(spacing: 8) {
                ForEach(Array(summary.shares.enumerated()), id: \.element.id) { index, share in
                    ShareRow(
                        share: share,
                        color: Theme.color(for: index),
                        status: status(for: share.person),
                        open: { editingPerson = PersonRef(id: share.id) },
                        toggleSettled: { toggleSettled(share.id) }
                    )
                }
            }

            HStack(spacing: 10) {
                Image(systemName: "person.badge.plus")
                    .foregroundStyle(Theme.brand)
                TextField("Add a person", text: $newPersonName)
                    .focused($addPersonFocused)
                    .submitLabel(.next)
                    .onSubmit(addPerson)
                if !newPersonName.trimmingCharacters(in: .whitespaces).isEmpty {
                    Button("Add", action: addPerson)
                        .buttonStyle(PillButtonStyle(isSelected: true))
                        .controlSize(.small)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Theme.field, in: .rect(cornerRadius: 14))
        }
    }

    private var payerPicker: some View {
        HStack {
            Text("Who paid?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Menu {
                Button("Not set") { bill.paidBy = nil; bill.settled = [] }
                ForEach(bill.people) { person in
                    Button(person.name) {
                        bill.paidBy = person.id
                        bill.settled.remove(person.id)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(bill.payer?.name ?? "Choose")
                    Image(systemName: "chevron.up.chevron.down").font(.caption2)
                }
                .font(.subheadline.weight(.semibold))
            }
            .accessibilityLabel("Who paid")
        }
    }

    private func status(for person: Person) -> ShareRow.Status {
        guard let payer = bill.payer else { return .none }
        if person.id == payer.id { return .paid(waitingOn: bill.outstandingCents) }
        return bill.settled.contains(person.id) ? .settled(payer: payer.name) : .owes(payer: payer.name)
    }

    private func toggleSettled(_ id: UUID) {
        if bill.settled.contains(id) { bill.settled.remove(id) } else { bill.settled.insert(id) }
    }

    // MARK: Items

    private var itemsCard: some View {
        CardSection("Items",
                    footer: bill.items.isEmpty || bill.people.isEmpty ? nil : "Tap the initials to choose who had each item. Tap the name to edit it.") {
            VStack(spacing: 0) {
                ForEach(Array(bill.items.enumerated()), id: \.element.id) { index, item in
                    if index > 0 { Divider() }
                    QuickAssignRow(item: item, bill: bill, edit: { editingItem = item }) { personID in
                        let had = bill.person(personID, had: item)
                        withAnimation(.snappy(duration: 0.2)) {
                            _ = bill.setPerson(personID, had: !had, itemID: item.id)
                        }
                    }
                    .contextMenu {
                        Button("Delete Item", systemImage: "trash", role: .destructive) { deleteItem(item) }
                    }
                }
            }

            HStack(spacing: 10) {
                Button {
                    editingItem = BillItem(name: "", priceCents: 0)
                } label: {
                    Label("Add Item", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PillButtonStyle(isSelected: true))

                Menu {
                    if DocumentCamera.isAvailable {
                        Button("Take Photo", systemImage: "camera") { showCamera = true }
                    }
                    Button("Choose from Photos", systemImage: "photo.on.rectangle") { showPhotoPicker = true }
                } label: {
                    Label("Scan Receipt", systemImage: "doc.text.viewfinder")
                        .frame(maxWidth: .infinity)
                        .font(.subheadline.weight(.semibold))
                        .padding(.vertical, 10)
                        .foregroundStyle(Theme.brand)
                        .background(Theme.brand.opacity(0.1), in: Capsule())
                }
                .disabled(isScanning)
            }
        }
    }

    // MARK: Tax & tip

    private func taxAndTipCard(_ summary: BillSummary) -> some View {
        CardSection("Tax & Tip") {
            HStack {
                Text("Tax")
                Spacer()
                CurrencyField(cents: $bill.taxCents)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Theme.field, in: .rect(cornerRadius: 14))

            HStack(spacing: 6) {
                ForEach(Self.tipPresets, id: \.self) { percent in
                    Button {
                        bill.tip = .percent(Double(percent))
                    } label: {
                        Text("\(percent)%").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PillButtonStyle(isSelected: selectedTipPreset == percent))
                }
                Button {
                    if selectedTipPreset != nil { bill.tip = .amount(cents: summary.tipCents) }
                } label: {
                    Text("Custom").fixedSize()
                }
                .buttonStyle(PillButtonStyle(isSelected: selectedTipPreset == nil))
            }
            .frame(maxWidth: .infinity)

            if case .amount = bill.tip {
                HStack {
                    Text("Tip amount")
                    Spacer()
                    CurrencyField(cents: customTipCents)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Theme.field, in: .rect(cornerRadius: 14))
            }

            VStack(spacing: 10) {
                summaryRow("Subtotal", summary.subtotalCents)
                summaryRow("Tax", summary.taxCents)
                summaryRow(tipLabel, summary.tipCents)
                Divider()
                HStack {
                    Text("Total").font(.headline)
                    Spacer()
                    Text(Money.format(summary.totalCents))
                        .font(.money(20))
                        .contentTransition(.numericText())
                }
            }
            .padding(.top, 4)
        }
    }

    private func summaryRow(_ label: String, _ cents: Int) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(Money.format(cents)).monospacedDigit()
        }
        .font(.subheadline)
    }

    // MARK: Helpers

    private var selectedTipPreset: Int? {
        if case .percent(let percent) = bill.tip, percent == percent.rounded(), Self.tipPresets.contains(Int(percent)) {
            return Int(percent)
        }
        return nil
    }

    private var tipLabel: String {
        if case .percent(let percent) = bill.tip {
            return "Tip (\(percent.formatted())%)"
        }
        return "Tip"
    }

    private var customTipCents: Binding<Int> {
        Binding {
            if case .amount(let cents) = bill.tip { return cents }
            return 0
        } set: {
            bill.tip = .amount(cents: $0)
        }
    }

    private func addPerson() {
        let name = newPersonName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        withAnimation(.snappy) { bill.people.append(Person(name: name)) }
        newPersonName = ""
        addPersonFocused = true
    }

    private func scan(_ image: UIImage) {
        isScanning = true
        Task {
            defer { isScanning = false }
            do {
                scanned = try await ReceiptScanner.scan(image)
            } catch {
                scanError = error.localizedDescription
            }
        }
    }

    private func undoable(_ message: String, _ change: () -> Void) {
        let before = bill
        let binding = $bill
        withAnimation(.snappy) { change() }
        undo = UndoAction(message: message) {
            withAnimation(.snappy) { binding.wrappedValue = before }
        }
    }

    private func deleteItem(_ item: BillItem) {
        undoable("Deleted \(item.name.isEmpty ? "item" : item.name)") {
            bill.items.removeAll { $0.id == item.id }
        }
    }

    private func removePerson(_ id: UUID) {
        let name = bill.people.first { $0.id == id }?.name ?? "person"
        undoable("Removed \(name.isEmpty ? "person" : name)") {
            bill.removePerson(id)
        }
    }

    private func splitItem(_ item: BillItem, into count: Int) {
        guard let index = bill.items.firstIndex(where: { $0.id == item.id }) else { return }
        undoable("Split \(item.name) into \(count)") {
            bill.items.replaceSubrange(index...index, with: item.split(into: count))
        }
    }

    private func addScanned(_ items: [ScannedItem], taxCents: Int?, tipCents: Int?) {
        bill.items += items.flatMap { BillItem(name: $0.name, priceCents: $0.priceCents).split(into: $0.quantity) }
        if let taxCents { bill.taxCents = taxCents }
        if let tipCents { bill.tip = .amount(cents: tipCents) }
    }

    private func shareText(_ summary: BillSummary) -> String {
        var lines = ["\(bill.title.isEmpty ? "Our bill" : bill.title) — \(bill.date.formatted(date: .abbreviated, time: .omitted))"]
        if let payer = bill.payer {
            lines.append("\(payer.name) paid \(Money.format(summary.totalCents)).")
            lines += summary.shares
                .filter { $0.id != payer.id }
                .map { "\($0.person.name) owes \(payer.name) \(Money.format($0.totalCents))\(bill.settled.contains($0.id) ? " ✓ paid" : "")" }
        } else {
            lines += summary.shares.map { "\($0.person.name): \(Money.format($0.totalCents))" }
            lines.append("Total: \(Money.format(summary.totalCents))")
        }
        return lines.joined(separator: "\n")
    }
}

private struct PersonRef: Identifiable {
    let id: UUID
}

/// One person's line in Who Owes What: their total, and whether they've paid the payer back.
private struct ShareRow: View {
    enum Status {
        case none
        case paid(waitingOn: Int)
        case owes(payer: String)
        case settled(payer: String)
    }

    let share: PersonShare
    let color: Color
    let status: Status
    let open: () -> Void
    let toggleSettled: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: open) {
                HStack(spacing: 12) {
                    Avatar(name: share.person.name, color: color, size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(share.person.name.isEmpty ? "Unnamed" : share.person.name)
                            .font(.headline)
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(isSettled ? Color.green : .secondary)
                    }
                    Spacer()
                    Text(Money.format(share.totalCents))
                        .font(.money(19))
                        .strikethrough(isSettled)
                        .foregroundStyle(isSettled ? .secondary : .primary)
                        .contentTransition(.numericText())
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(share.person.name), \(Money.format(share.totalCents))")

            switch status {
            case .owes, .settled:
                Button(action: toggleSettled) {
                    Image(systemName: isSettled ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(isSettled ? Color.green : Color.secondary.opacity(0.5))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isSettled ? "\(share.person.name) paid back" : "Mark \(share.person.name) as paid back")
            case .paid:
                Image(systemName: "creditcard.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.brand)
                    .frame(width: 28)
                    .accessibilityHidden(true)
            case .none:
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .background(Theme.field, in: .rect(cornerRadius: 18))
        .opacity(isSettled ? 0.75 : 1)
    }

    private var isSettled: Bool {
        if case .settled = status { return true }
        return false
    }

    private var subtitle: String {
        switch status {
        case .none: return share.items.count == 1 ? "1 item" : "\(share.items.count) items"
        case .paid(let waiting): return waiting == 0 ? "Paid the bill · all paid back" : "Paid the bill · gets back \(Money.format(waiting))"
        case .owes(let payer): return "Owes \(payer)"
        case .settled(let payer): return "Paid \(payer) back"
        }
    }
}

/// An item with everyone's initials underneath — tap initials to say who had it.
private struct QuickAssignRow: View {
    let item: BillItem
    let bill: Bill
    let edit: () -> Void
    let toggle: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: edit) {
                HStack {
                    Text(item.name.isEmpty ? "Unnamed item" : item.name)
                        .font(.body.weight(.medium))
                    Spacer()
                    Text(Money.format(item.priceCents))
                        .font(.money(17, weight: .semibold))
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(item.name), \(Money.format(item.priceCents))")

            if !bill.people.isEmpty {
                let sharers = bill.sharers(of: item)
                HStack(spacing: 6) {
                    ForEach(Array(bill.people.enumerated()), id: \.element.id) { index, person in
                        let had = sharers.contains { $0.id == person.id }
                        Button {
                            toggle(person.id)
                        } label: {
                            Avatar(name: person.name, color: had ? Theme.color(for: index) : Color.secondary.opacity(0.25), size: 30)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(person.name) had \(item.name)")
                        .accessibilityAddTraits(had ? .isSelected : [])
                    }
                    Spacer()
                    Text(sharers.count == bill.people.count ? "Everyone" : (sharers.count == 1 ? "1 person" : "Split \(sharers.count) ways"))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.brand)
                }
            }
        }
        .padding(.vertical, 10)
    }
}

#if DEBUG
#Preview {
    let store = BillStore(fileURL: .temporaryDirectory.appending(path: "preview.json"))
    store.bills = DemoData.bills
    return NavigationStack {
        BillDetailView(billID: store.bills[0].id)
    }
    .environment(store)
}
#endif
