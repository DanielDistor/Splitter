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

private struct BillEditor: View {
    @Binding var bill: Bill
    let onDeleteBill: () -> Void
    @State private var newPersonName = ""
    @State private var editingItem: BillItem?
    @State private var editingPerson: PersonRef?
    @State private var expandedPeople: Set<UUID> = []
    @State private var showAddPerson = false
    @State private var addPersonText = ""
    @State private var confirmDeleteBill = false
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
            VStack(spacing: 18) {
                hero(summary)
                peopleCard
                itemsCard
                taxAndTipCard(summary)
                if !summary.shares.isEmpty {
                    whoOwesCard(summary)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 40)
            .animation(.snappy, value: summary)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(bill.title.isEmpty ? "New Bill" : bill.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbar {
            ShareLink(item: shareText(summary)) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .disabled(summary.shares.isEmpty)
            Menu {
                Button("Delete Bill", systemImage: "trash", role: .destructive) { confirmDeleteBill = true }
            } label: {
                Label("More", systemImage: "ellipsis.circle")
            }
        }
        .confirmationDialog("Delete this bill?", isPresented: $confirmDeleteBill, titleVisibility: .visible) {
            Button("Delete Bill", role: .destructive, action: onDeleteBill)
        } message: {
            Text("This can't be undone.")
        }
        .sheet(item: $editingPerson) { ref in
            PersonEditor(bill: $bill, personID: ref.id)
        }
        .alert("Add Person", isPresented: $showAddPerson) {
            TextField("Name", text: $addPersonText)
            Button("Cancel", role: .cancel) {}
            Button("Add") {
                let name = addPersonText.trimmingCharacters(in: .whitespaces)
                if !name.isEmpty { withAnimation(.snappy) { bill.people.append(Person(name: name)) } }
            }
        } message: {
            Text("Anything marked \"Everyone\" will include them automatically.")
        }
        .sheet(item: $editingItem) { item in
            let isExisting = bill.items.contains { $0.id == item.id }
            ItemEditor(item: item, people: bill.people, onDelete: isExisting ? { bill.items.removeAll { $0.id == item.id } } : nil) { saved in
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
        .task {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-scanDemoReceipt"), scanned == nil {
                scan(DemoData.receiptImage())
            }
            #endif
        }
    }

    // MARK: Hero

    private func hero(_ summary: BillSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField("What's this bill for?", text: $bill.title,
                      prompt: Text("What's this bill for?").foregroundStyle(.white.opacity(0.55)))
                .font(.title2.bold())

            DatePicker("Date", selection: $bill.date, displayedComponents: .date)
                .labelsHidden()
                .colorScheme(.dark)
                .tint(.white)

            Rectangle().fill(.white.opacity(0.2)).frame(height: 1)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TOTAL")
                        .font(.caption.weight(.semibold))
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.7))
                    Text(Money.format(summary.totalCents))
                        .font(.money(42))
                        .contentTransition(.numericText())
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
                Spacer()
                if !bill.people.isEmpty {
                    VStack(alignment: .trailing, spacing: 6) {
                        AvatarStack(people: bill.people, size: 30, outline: Theme.brand)
                        Text(bill.people.count == 1 ? "1 person" : "\(bill.people.count) people")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
            }
        }
        .foregroundStyle(.white)
        .padding(22)
        .background(Theme.brandFill, in: .rect(cornerRadius: 26))
    }

    // MARK: People

    private var peopleCard: some View {
        CardSection("People") {
            if !bill.people.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(bill.people.enumerated()), id: \.element.id) { index, person in
                            Button {
                                editingPerson = PersonRef(id: person.id)
                            } label: {
                                HStack(spacing: 8) {
                                    Avatar(name: person.name, color: Theme.color(for: index), size: 30)
                                    Text(person.name.isEmpty ? "Unnamed" : person.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                }
                                .padding(4)
                                .padding(.trailing, 10)
                                .background(Theme.color(for: index).opacity(0.12), in: Capsule())
                            }
                            .accessibilityLabel(person.name)
                        }
                    }
                }
                .scrollClipDisabled()
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
            .padding(.vertical, 10)
            .background(Theme.field, in: .rect(cornerRadius: 14))
        }
    }

    // MARK: Items

    private var itemsCard: some View {
        CardSection("Items",
                    footer: bill.items.isEmpty ? nil : "Tap an item to choose who had it.") {
            VStack(spacing: 0) {
                ForEach(Array(bill.items.enumerated()), id: \.element.id) { index, item in
                    if index > 0 { Divider() }
                    Button {
                        editingItem = item
                    } label: {
                        ItemRow(item: item, people: bill.people)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Delete Item", systemImage: "trash", role: .destructive) {
                            withAnimation { bill.items.removeAll { $0.id == item.id } }
                        }
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
                        .font(.money(22))
                        .foregroundStyle(Theme.brand)
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

    // MARK: Who owes what

    private func whoOwesCard(_ summary: BillSummary) -> some View {
        CardSection("Who Owes What",
                    footer: "Tax and tip are split based on how much each person ordered.") {
            VStack(spacing: 10) {
                ForEach(Array(summary.shares.enumerated()), id: \.element.id) { index, share in
                    PersonShareRow(share: share, color: Theme.color(for: index), isExpanded: expandedPeople.contains(share.id)) {
                        withAnimation(.snappy) {
                            if expandedPeople.contains(share.id) { expandedPeople.remove(share.id) } else { expandedPeople.insert(share.id) }
                        }
                    } onEdit: {
                        editingPerson = PersonRef(id: share.id)
                    }
                }
            }
            Button {
                addPersonText = ""
                showAddPerson = true
            } label: {
                Label("Add Person", systemImage: "person.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PillButtonStyle())
        }
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

    private func addScanned(_ items: [ScannedItem], taxCents: Int?, tipCents: Int?) {
        bill.items += items.map { BillItem(name: $0.name, priceCents: $0.priceCents) }
        if let taxCents { bill.taxCents = taxCents }
        if let tipCents { bill.tip = .amount(cents: tipCents) }
    }

    private func shareText(_ summary: BillSummary) -> String {
        var lines = ["\(bill.title.isEmpty ? "Our bill" : bill.title) — \(bill.date.formatted(date: .abbreviated, time: .omitted))"]
        lines += summary.shares.map { "\($0.person.name): \(Money.format($0.totalCents))" }
        lines.append("Total: \(Money.format(summary.totalCents))")
        return lines.joined(separator: "\n")
    }
}

private struct ItemRow: View {
    let item: BillItem
    let people: [Person]

    var body: some View {
        let sharers = people.enumerated().filter { item.sharedBy.contains($0.element.id) }
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(item.name.isEmpty ? "Unnamed item" : item.name)
                    .font(.body.weight(.medium))
                if sharers.isEmpty || sharers.count == people.count {
                    Text("Everyone")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.brand)
                } else {
                    HStack(spacing: 4) {
                        ForEach(sharers, id: \.element.id) { index, person in
                            Avatar(name: person.name, color: Theme.color(for: index), size: 18)
                        }
                        Text(sharers.map(\.element.name).formatted(.list(type: .and)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            Spacer()
            Text(Money.format(item.priceCents))
                .font(.money(17, weight: .semibold))
        }
        .padding(.vertical, 10)
        .contentShape(.rect)
    }
}

private struct PersonRef: Identifiable {
    let id: UUID
}

private struct PersonShareRow: View {
    let share: PersonShare
    let color: Color
    let isExpanded: Bool
    let toggle: () -> Void
    let onEdit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: toggle) {
                HStack(spacing: 12) {
                    Avatar(name: share.person.name, color: color, size: 42)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(share.person.name.isEmpty ? "Unnamed" : share.person.name)
                            .font(.headline)
                        Text(share.items.count == 1 ? "1 item" : "\(share.items.count) items")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(Money.format(share.totalCents))
                        .font(.money(20))
                        .contentTransition(.numericText())
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(share.person.name), \(Money.format(share.totalCents))")

            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(Array(share.items.enumerated()), id: \.offset) { _, item in
                        line(item.splitCount > 1 ? "\(item.name) (÷\(item.splitCount))" : item.name, item.cents)
                    }
                    Divider()
                    line("Tax", share.taxCents)
                    line("Tip", share.tipCents)
                    Button(action: onEdit) {
                        Label("Edit what \(share.person.name) had", systemImage: "pencil")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PillButtonStyle())
                    .padding(.top, 4)
                }
                .font(.subheadline)
                .padding(14)
                .background(Theme.card, in: .rect(cornerRadius: 14))
                .padding(.top, 10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .background(Theme.field, in: .rect(cornerRadius: 18))
    }

    private func line(_ label: String, _ cents: Int) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(Money.format(cents)).monospacedDigit().foregroundStyle(.secondary)
        }
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
